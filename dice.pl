use strict;
use List::Util qw(sum);
use constant BETTER_RNG => eval { require Math::Random::Secure };

use vars qw($VERSION %IRSSI);
$VERSION = '2014073000';
%IRSSI = (
    authors     => 'net-cat',
    contact     => 'the'.'virtual'.'cat'."\x40".'gmail'.'.'."\x63\x6f\x6d",
    name        => 'dice',
    description => 'Throw dice for RP.',
    license     => 'BSD',
    url         => 'none',
    modules     => 'Math::Random::Secure',
);

if ( !BETTER_RNG )
{
	Irssi::print "I suggest installing Math::Random::Secure.\n";
}

sub irand
{
	if ( BETTER_RNG )
	{
		return Math::Random::Secure::irand(shift);
	}
	else
	{
		return int(rand(shift));
	}
}

my %last_dice;

sub make_dice
{
	my ( $count, $sides, $joiner ) = @_;

	my @results;
	
	for ( my $c = 0; $c < $count; ++$c )
	{
		my $value = 1+ irand($sides);

		if ( $sides < 2 )
		{
			$value = 0;
		}
		if ( $sides == 2 )
		{
			$value = $value == 1 ? 'Heads' : 'Tails';
		}

		push(@results, $value);
	}

	return join($joiner, @results);
}

sub do_math
{
	my $data = shift;
	$data =~ s/(\d+)d(\d+)/make_dice($1, $2, '+')/eg;
	my @numbers = split(/\s*\+\s*/, $data);
	return sum(@numbers);
}

sub cmd_dice
{
	my ($data, $server, $witem) = @_;
	my $name = $witem->{'name'};
	my $has_history = exists($last_dice{$name});

	if ( !$name ) # Status window
	{
		return;
	}

	if ( !$data )
	{
		if ( $has_history )
		{
			$data = $last_dice{$name};
		}
		else
		{
			$witem->print('No previous dice string for "' . $name . '".');
			return;
		}
	}
	elsif ( $data =~ /^off\s*$/ )
	{
		if ( $has_history )
		{
			$witem->print('Removing previous dice string for "'. $name .'".');
			delete($last_dice{$name});
		}
		return;
	}
	elsif ( $data =~ /^tell\s*$/ )
	{
		if ( $has_history )
		{
			$witem->print('Dice string for "' . $name . '": ' . $last_dice{$name});
		}
		return;
	}

	$last_dice{$name} = $data;

	if ( $data !~ /^\// )
	{
		$data = '/say ' . $data;
	}

	$data =~ s/{(.+?)}/do_math($1)/eg;
	$data =~ s/(\d+)d(\d+)/make_dice($1, $2, ' ')/eg;
	$witem->command($data);
}

sub do_autocomplete
{
	my ($complist, $window, $word, $linestart, $want_space) = @_;
	my $name = $window->get_active_name();

	$$want_space = 0;
	if ( $linestart =~ /^\/dice/ )
	{
		if ( $word =~ /^of{0,2}/ )
		{
			push(@$complist, 'off');
		}
		elsif ( $word =~ /^t(el{0,2})?/ )
		{
			push(@$complist, 'tell');
			if ( exists($last_dice{$name}) )
			{
				push(@$complist, $last_dice{$name});
			}
		}
	}
}

Irssi::command_bind('dice', \&cmd_dice);
Irssi::signal_add_last('complete word', \&do_autocomplete);

