use strict;
use Irssi;
use vars qw($VERSION %IRSSI);

use TT;

$VERSION = '0.5.20100830';
%IRSSI = (
	authors     => 'Ward Muylaert',
	contact     => 'ward.muylaert@gmail.com',
	name        => 'The Titans Bot - Basic IRC stuff',
	description => 'IRC Bot made for The Titans (#thetitans @ irc.swiftirc.net).',
	url         => 'http://s4.zetaboards.com/thetitans',
);


################################################################################
#                          Join a channel                                      #
################################################################################

sub _join_text {
	my ($server, $data, $nick, $host) = @_;
	my ($target, $text) = split(/ :/, TT::trim($data), 2);

	if ($text =~ /^[!@.]join (.+)$/i && TT::isAdmin($nick, $host)) {
		$server->command("JOIN $1");
	}
}

Irssi::signal_add("event privmsg", "_join_text");

################################################################################
#                           Change nick                                        #
################################################################################

sub _nickchange_text {
	my ($server, $data, $nick, $host) = @_;
	my ($target, $text) = split(/ :/, TT::trim($data), 2);

	if ($text =~ /^[!@.]nick ([^ ]+)$/i && TT::isAdmin($nick, $host)) {
		$server->command("NICK $1");
	}
}

Irssi::signal_add("event privmsg", "_nickchange_text");

################################################################################
#                         Custom CTCP VERSION reply                            #
#                                                                              #
# Sends a custom version reply to person                                       #
################################################################################

sub customversion_reply {
  return "$IRSSI{name} v$VERSION by $IRSSI{authors}. $IRSSI{description}";
}
sub _customversion_ctcp {
  my ($server, $text, $nick, $host, $target) = @_;
  $server->ctcp_send_reply("NOTICE $nick :\001VERSION " . customversion_reply() . "\001");
}

Irssi::signal_add_first("ctcp msg version", "_customversion_ctcp");