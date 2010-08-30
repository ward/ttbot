use strict;
use Irssi;
use vars qw($VERSION %IRSSI);

use TT;

$VERSION = '0.5.20100830';
%IRSSI = (
	authors     => 'Ward Muylaert',
	contact     => 'ward.muylaert@gmail.com',
	name        => 'The Titans Bot - Usercount',
	description => 'IRC Bot made for The Titans (#thetitans @ irc.swiftirc.net).',
	url         => 'http://s4.zetaboards.com/thetitans',
);

################################################################################
#                                   Usercount                                  #
#                                                                              #
# Takes a channel object as input, returns has with counts for ops, ...        #
################################################################################

sub usercount {
	my $channel = shift;
	my @nicks = $channel->nicks();
	my ($op, $halfop, $voice, $reg) = (0, 0, 0);
	foreach my $nick (@nicks) {
		if ($nick->{op}) {
			$op++;
		}
		elsif ($nick->{halfop}) {
			$halfop++;
		}
		elsif ($nick->{voice}) {
			$voice++;
		}
		else {
			$reg++;
		}
	}
	my $totusers = $op + $halfop + $voice + $reg;
	return (
		"all" => $totusers,
		"op" => $op,
		"halfop" => $halfop,
		"voice" => $voice,
		"regular" => $reg
	);
}

sub _usercount_text {
	my ($server, $data, $nick, $host) = @_;
	my ($target, $text) = split(/ :/, TT::trim($data), 2);

	if ($target =~ /^#/
		&& $text =~ /^([!@.])users?$/i) {
		my $cmddelim = $1;
		if (not TT::isIgnored($host)) {
			if (not TT::isAdmin($nick, $host)) {
				TT::setIgnore($host, 3);
			}
			my %info = usercount($server->channel_find($target));
			my $out = sprintf("[%s] %d users: (@) %d (%) %d (+) %d (-) %d",
			$target,
			$info{all},
			$info{op},
			$info{halfop},
			$info{voice},
			$info{regular});
			my $outputway = $cmddelim eq "@" ? "msg $target" : "notice $nick";
			$server->command("$outputway $out");
		}
	}
}

Irssi::signal_add("event privmsg", "_usercount_text");