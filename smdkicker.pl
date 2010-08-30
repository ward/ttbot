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
#                                SMD kicker                                    #
#                                                                              #
# Kicks a person saying "smd" or a variation from the channel                  #
################################################################################

use vars qw($smdkickfile);
$smdkickfile = TT::maindir() . "smdkickmsgs.txt";

sub smdkicker_getline {
	open (my $file, "< $smdkickfile") or return;
	my @lines = <$file>;
	return $lines[rand @lines]; # Random line
}

sub _smdkicker_text {
	my ($server, $data, $nick, $host) = @_;
	my ($target, $text) = split(/ :/, TT::trim($data), 2);

	if ($target =~ /^#thetitans$/i
	  && TT::removeIrcFormatting($text) =~ /\bs+m+f*d+\b/i) {
		$server->command("kick $target $nick "
		. smdkicker_getline());
	}
}

Irssi::signal_add("event privmsg", "_smdkicker_text");
