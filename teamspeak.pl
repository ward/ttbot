use strict;
use POSIX;
use Irssi;
use vars qw($VERSION %IRSSI);

use TT;

$VERSION = '0.5.20100830';
%IRSSI = (
	authors     => 'Ward Muylaert',
	contact     => 'ward.muylaert@gmail.com',
	name        => 'The Titans Bot - Teamspeak',
	description => 'IRC Bot made for The Titans (#thetitans @ irc.swiftirc.net).',
	url         => 'http://s4.zetaboards.com/thetitans',
);

################################################################################
#                             Teamspeak checker                                #
#                                                                              #
# Also for Ventrilo or others, needs txt file with the info in it to perform   #
# correctly. Format of that file is:                                           #
# regexpattern@@@clanname@@@site@@@fullurl                                     #
################################################################################

use LWP::Simple;
use vars qw($clantsurlfile);
$clantsurlfile = TT::maindir() . "tsinfo.txt";

# returns array (clanname, site, fullurl)
sub FindTsUrl {
  my ($search) = @_;
  
  # Use a file with data to get the url
  open(my $file, "< $clantsurlfile") or return;
  my @lines = <$file>;
  my $line;
  foreach $line (@lines) {
    # Can split also work with "@@@"? Sounds more efficient.
    my @temp = split(/@@@/, $line);
    if ($search =~ /$temp[0]/i) {
      return @temp[1..3];
    }
  }
  return (0, 0, 0);
}

# Site gives info as to what page will be fetched (so we know what to match)
# eg: GetTsInfo("http://....", "nanospy") -> sub knows it is nanospy format
# Returns hash with:
# users => current amount of online users
# maxusers => max amount of users allowed on server
sub GetTsInfo {
  my ($url, $site) = @_;
  
  # We are going to assume that none of the sites require more
  # than a simple get();
  my $content = get $url or return;
  my %info;
  
  # different matching depending on the site
  if ($site eq "nanospy") {
    $content =~ /(\d+) \/ (\d+) Users/;
    %info = (
      "online" => $1,
      "max" => $2
    );
	}
	elsif ($site eq "gametracker") {
		$content =~ /<span id="HTML_num_players">(\d+)<\/span> \/ <span id="HTML_max_players">(\d+)<\/span>/;
		%info = (
			"online" => $1,
			"max" => $2
		);
	}
  
  return %info;
}

################################################################################
#                         Teamspeak checker text event                         #
################################################################################

sub _teamspeak_text {
  my ($server, $data, $nick, $host) = @_;
  my ($target, $text) = split(/ :/, TT::trim($data), 2);

  if ($target =~ /#(?:ttpk|flameroom)/i
      && $text =~ /^[!@.](?:ts|teamspeak|vent(?:rilo)?) (.+)$/i) {
    my $search = $1;
    if (not TT::isIgnored($host)) {
      if (not TT::isAdmin($nick, $host)) {
        TT::setIgnore($host, 5);
      }

      my $pid = fork();

      if ($pid > 0) {
        Irssi::pidwait_add($pid); # Prevent zombies (chopping heads is so passé)
      }
      else {
        my $output;
        my @clan = FindTsUrl($search);
        if ($clan[0]) {
          if (my %tsinfo = GetTsInfo($clan[2], $clan[1])) {
            $output = sprintf("%s/%s Users Online for %s @ %s",
              $tsinfo{"online"}, $tsinfo{"max"}, $clan[0], $clan[2]);
          }
        }
        else {
          $output = "No info matches your search term";
        }
        $server->command("notice $nick $output");

        POSIX::_exit(0);
      }
    }
  }
}


Irssi::signal_add("event privmsg", "_teamspeak_text");