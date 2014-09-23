use strict;
use Text::Wrap;

use vars qw($VERSION %IRSSI);
$VERSION = '2009111800';
%IRSSI = (
    authors     => 'net-cat',
    contact     => 'the'.'virtual'.'cat'."\x40".'gmail'.'.'."\x63\x6f\x6d",
    name        => 'autowrap_alt',
    description => 'Automatically wraps long sent messages into multiple shorter sent messages. (Based on Bitt Faulk\'s autowrap script. Do not try to use both at the same time.)',
    license     => 'BSD',
    url         => 'none',
    modules     => 'Text::Wrap',
);

#
# Differences from the original autowrap.pl script:
# 
# * Works for both normal lines and /me commands.
# * If Text::Wrap can't figure the line out, it does a hard wrap.
# * Wrap length is set by new setting, autowrap_length (Default is 400, same as the original.)
# * User can set a continuation indicator by setting the autowrap_appendtext setting. (Default is " (continued)")
#

sub hard_split
{
    my ( $line, $splitlen ) = @_;
    my @shortlines;
    my $numlines = int((length($line) - 1) / $splitlen) + 1;

    if ( $numlines <= 1 )
    {
        # shouldn't ever go here
        return undef;
    }

    for ( my $l = 0; $l < $numlines; ++$l )
    {
        push(@shortlines, substr($line, $splitlen * $l, $splitlen));
    }

    return @shortlines;
}

sub soft_split
{
    my ( $line, $splitlen ) = @_;
    my @shortlines;

    if ( length($line) <= $splitlen )
    {
        return undef;
    }

    local($Text::Wrap::columns) = $splitlen;
    @shortlines = split(/\n/, wrap('', '', $line));

    foreach (@shortlines)
    {
        if ( length > $splitlen )
        {
            return hard_split($line, $splitlen);
        }
    }

    return @shortlines;
}

sub event_send_text
{
    my ($line, $server_rec, $wi_item_rec) = @_;
    my $appendtext = Irssi::settings_get_str('autowrap_appendtext');
    my $linelen = Irssi::settings_get_int('autowrap_length');

    unless (length($line) <= $linelen)
    {
        my @shortlines = soft_split($line, $linelen - length($appendtext));
        if ( @shortlines )
        {
            my $lastline = pop(@shortlines);
            foreach (@shortlines)
            {
                Irssi::signal_emit('send command', "${_}${appendtext}",  $server_rec, $wi_item_rec);
            }
            Irssi::signal_emit('send command', $lastline,  $server_rec, $wi_item_rec);
            Irssi::signal_stop();
        }
    }
    return;
}

sub event_send_command
{
    my ( $cmd, $server, $window_item ) = @_;
    my $appendtext = Irssi::settings_get_str('autowrap_appendtext');
    my $linelen = Irssi::settings_get_int('autowrap_length');

    if ( ( substr($cmd, 0, 1) ne '/' || substr($cmd, 0, 4) eq '/me ' ) && length($cmd) > $linelen )
    {
		my @shortlines = soft_split($cmd, $linelen - length($appendtext) - 4);
	    if ( @shortlines )
		{
			Irssi::signal_emit('send command', shift(@shortlines).$appendtext, $server, $window_item);
			my $lastline = pop(@shortlines);
			foreach ( @shortlines )
			{
				Irssi::signal_emit('send command', ">>> ${_}${appendtext}", $server, $window_item);
			}
			Irssi::signal_emit('send command', ">>> $lastline", $server, $window_item);
			Irssi::signal_stop();
		}
    }
    return;
}

Irssi::signal_add_first('send text', "event_send_text");
Irssi::signal_add_first('send command', "event_send_command");

Irssi::settings_add_int('misc', 'autowrap_length', 400);
Irssi::settings_add_str('misc', 'autowrap_appendtext', ' (continued)');

