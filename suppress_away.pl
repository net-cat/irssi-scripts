use Irssi;
use strict;

use vars qw($VERSION %IRSSI);

$VERSION = "0.0.1";
%IRSSI = (
    authors     => 'net-cat',
    contact     => 'the'.'virtual'.'cat'."\x40".'gmail'.'.'."\x63\x6f\x6d",
    name        => 'suppress_away',
    description => 'Suppress activity notification for public away.', 
    license     => 'GPL v2',
    url         => 'none',
);

Irssi::theme_register([
    'action_public_channel', '{pubaction $0}$1'
]);

sub sig_action
{
    my ($server, $msg, $nick, $address, $target) = @_;

    if ( 
        $msg =~ /^is( now)? (back|away|gone)/ ||
        $msg =~ /^returns from/ ||
		$msg =~ /^is no longer away/ &&
        $target =~ /^#/ 
    )
    {
        $server->printformat($target, MSGLEVEL_PUBLIC | MSGLEVEL_ACTIONS | MSGLEVEL_NO_ACT, 'action_public_channel', $nick, $msg);
        Irssi::signal_stop();
    }
}

Irssi::signal_add_last('message irc action', 'sig_action');

