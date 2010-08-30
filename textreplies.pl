use strict;
use Irssi;
use vars qw($VERSION %IRSSI);

use TT;

$VERSION = '0.5.20100830';
%IRSSI = (
	authors     => 'Ward Muylaert',
	contact     => 'ward.muylaert@gmail.com',
	name        => 'The Titans Bot - Text Replies',
	description => 'IRC Bot made for The Titans (#thetitans @ irc.swiftirc.net).',
	url         => 'http://s4.zetaboards.com/thetitans',
);

################################################################################
#                             Basic text replies                               #
#                                                                              #
# Would, for example, return http://www.google.com/ on command !google         #
################################################################################

sub text_replies {
	my $input = shift;

	if ($input eq "site") {
		# Perhaps have a main hash with url info etc instead of hardcoding here?
		return "The Titans Site: http://s4.zetaboards.com/thetitans";
	}
	elsif ($input eq "ml" or $input eq "memblist") {
		return "The Titans Memberlist: http://runehead.com/clans/ml.php?clan=titans";
	}
	elsif ($input eq "falist" or $input eq "fa") {
		return "Future Titans Memberlist: http://www.runehead.com/clans/ml.php?clan=titansfa";
	}
	elsif ($input eq "retiredlist" or $input eq "retlist") {
		return "Titans Retirement Home: http://www.runehead.com/clans/ml.php?clan=minititans";
	}
	elsif ($input eq "totlist") {
		return "The Titans Memberlist by total: "
			. "http://runehead.com/clans/ml.php?clan=titans&skill=Memberlist&sort=overall&style=default&combatType=F2P";
	}
	elsif ($input =~ /^(?:tt)?req(?:uirement)?s?$/i) {
		return "[TT reqs] Future Titan: 92 Att, Str, Def & HP + 75 Range & Magic + 78 Pray;"
			. " Titan: 95 Att, Str, Def & HP + 85 Range & Magic + 78 Pray; ";
	}
	elsif ($input eq "radio1") {
		return "http://www.bbc.co.uk/iplayer/console/radio1/"
	}
}

sub _basic_text_replies_text {
	my ($server, $data, $nick, $host) = @_;
	my ($target, $text) = split(/ :/, TT::trim($data), 2);

	if ($text =~ /^([@!.])(.+)$/) {
		my ($cmddelim, $cmd) = ($1, $2);
		if (my $reply = text_replies($cmd)) {
			if (not TT::isIgnored($host)) {
				if (not TT::isAdmin($nick, $host)) {
					TT::setIgnore($host, 3);
				}
				my $outputway = $cmddelim eq "@" ? "msg $target" : "notice $nick";
				$server->command("$outputway $reply");
			}
		}
	}
}

Irssi::signal_add("event privmsg", "_basic_text_replies_text");