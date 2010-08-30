use strict;
use Irssi;
use vars qw($VERSION %IRSSI);

use TT;

$VERSION = '0.5.20100830';
%IRSSI = (
	authors     => 'Ward Muylaert',
	contact     => 'ward.muylaert@gmail.com',
	name        => 'The Titans Bot - Clanavg',
	description => 'IRC Bot made for The Titans (#thetitans @ irc.swiftirc.net).',
	url         => 'http://s4.zetaboards.com/thetitans',
);


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