use Irssi;
use strict;

use vars qw($VERSION %IRSSI);
$VERSION = '2012020100';
%IRSSI = (
    authors     => 'net-cat',
    contact     => 'the'.'virtual'.'cat'."\x40".'gmail'.'.'."\x63\x6f\x6d",
    name        => 'ctcp_breaker',
    description => 'Makes your CTCP replies funnier.',
    license     => 'BSD',
    url         => 'none',
);

my @version_replies;

sub interceptor
{
	my ( $server, $args, $nick, $addr, $target ) = @_;
	my $reply = int(rand(scalar(@version_replies)));
	Irssi::print("ctcp_breaker: Set ctcp_version_reply to: ${version_replies[$reply]}");
	Irssi::settings_set_str('ctcp_version_reply', $version_replies[$reply]);
}

sub read_reply_files
{
	my $reply_file = Irssi::settings_get_str('ctcp_breaker_version_reply_file');
	if (open(REPLIES, $reply_file))
	{
		@version_replies = <REPLIES>;
		close(REPLIES);

		for ( my $i = 0; $i < scalar(@version_replies); ++$i )
		{
			chomp($version_replies[$i]);
		}

		return 1;
	}
	unless (@version_replies)
	{
		push(@version_replies, Irssi::settings_get_str('ctcp_version_reply'));
	}
	Irssi::print("ctcp_breaker: Unable to open $reply_file.");
	return 0;
}

Irssi::signal_add_first('ctcp msg version', 'interceptor');
Irssi::settings_add_str('misc', 'ctcp_breaker_version_reply_file', "${ENV{'HOME'}}/.irssi/version_replies.txt");
Irssi::command_bind('ctcp_breaker_reload', 'read_reply_files');
read_reply_files();
