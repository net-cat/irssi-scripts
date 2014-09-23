use strict;
use warnings;
use Math::Units qw(convert);
use Math::Round qw(nearest);

use strict;
use List::Util qw(sum);

use vars qw($VERSION %IRSSI);
$VERSION = '2014073000';
%IRSSI = (
    authors     => 'net-cat',
    contact     => 'the'.'virtual'.'cat'."\x40".'gmail'.'.'."\x63\x6f\x6d",
    name        => 'convert',
    description => 'Easy unit conversion',
    license     => 'BSD',
    url         => 'none',
    modules     => 'Math::Units Math::Round',
);

sub do_convert
{
	my $in_num = shift;
	my $in_unit = shift;
	my @out_units = split(':', shift);
	my $separator = shift // '';
	my @outputs;
	my @bads;
	my $out_num;

	my $do_output = sub
	{
		if ( defined($out_num) )
		{
			$out_num = nearest(0.001, $out_num);
			push(@outputs, $out_num.$separator.$_);
			return 1;
		}
		return 0;
	};

	foreach(@out_units)
	{
		if ( !$_ )
		{
			push(@outputs, $in_num.$separator.$in_unit);
		}
		else
		{
			$out_num = eval { convert($in_num, $in_unit, $_) };

			# Worked!
			if ( $do_output->() ) { next; }

			# Can we invert?
			if ( $_ =~ m|(.+?)/(.+)| )
			{
				$out_num = eval { 1.0 / convert($in_num, $in_unit, $2.'/'.$1) };
				if ( $do_output->() ) { next; }
			}

			# Failed
			push(@bads, $_);
		}
	}

	if ( @bads )
	{
		die \join(' ', @bads);
	}

	if ( $#outputs == 0 )
	{
		return $outputs[0];
	}

	if ( $in_unit =~ m|/| )
	{
		my $rv = $outputs[0] . ' (';
		$rv .= join(' ', @outputs[1 .. $#outputs]);
		return $rv . ')';
	}

	return join('/', @outputs);
}


sub cmd_units
{
	my ($data, $server, $witem) = @_;
	my $name = $witem->{'name'};

	if ( !$name ) # Status window
	{
		return;
	}

	if ( defined(eval {$data =~ s/{(-?\d+(?:\.\d+)?)(\s*)(.+?):(.+?)}/do_convert($1, $3, $4, $2)/ge}) )
	{
		if ( $data !~ /^\// )
		{
			$data = '/say ' . $data;
		}
		$witem->command($data);
	}
	else
	{
		$witem->print('Failed Conversions: '. ${$@});
	}
}

Irssi::command_bind('units', 'cmd_units');