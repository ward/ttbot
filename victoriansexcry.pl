use strict;
use POSIX;
use Irssi;
use vars qw($VERSION %IRSSI);

use TT;

$VERSION = '0.5.20100830';
%IRSSI = (
	authors     => 'Ward Muylaert',
	contact     => 'ward.muylaert@gmail.com',
	name        => 'The Titans Bot - Victorian Sex Cry',
	description => 'IRC Bot made for The Titans (#thetitans @ irc.swiftirc.net).',
	url         => 'http://s4.zetaboards.com/thetitans',
);

################################################################################
#                              Victorian Sex Cry                               #
#                                                                              #
# Requires a file with one "sex cry" per line                                  #
################################################################################

use vars qw($sexcryfile);
$sexcryfile = TT::maindir() . "victoriansexcry.txt";

sub victoriansexcry {
  open (my $file, "< $sexcryfile") or return;
  my @lines = <$file>;
  return $lines[rand @lines]; # Random line
}

# This will be added to the event
sub _victoriansexcry_text {
  my ($server, $data, $nick, $host) = @_;
  my ($target, $text) = split(/ :/, TT::trim($data), 2);

  if ($target =~ /^#/
      && $text =~ /^(?:I )?(?:(?:l(?:o|u)ve?|wub)(?: you)?|<3+) (?:(?:The ?)?Titans?|TT) ?(?:<3+)*$/i) {
    if (not TT::isIgnored($host)) {
      if (not TT::isAdmin($nick, $host)) {
        TT::setIgnore($host, 5);
      }
      $server->command("msg $target " . victoriansexcry());
    }
  }
}

sub _victoriansexcry_action {
  my ($server, $text, $nick, $host, $target) = @_;

  if ($target =~ /^#/
      && $text =~ /^huggles (?:$server->{nick})[ .]*(?:<3+)*$/i) {
    if (not TT::isIgnored($host)) {
      if (not TT::isAdmin($nick, $host)) {
        TT::setIgnore($host, 5);
      }
      $server->command("msg $target " . victoriansexcry());
    }
  }
}

Irssi::signal_add("event privmsg", "_victoriansexcry_text");
Irssi::signal_add("ctcp action", "_victoriansexcry_action");