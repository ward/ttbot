# Last update: 2010/04/09

use strict;
use POSIX;
use Irssi;
use vars qw($VERSION %IRSSI);

# Add cwd to @INC
use vars qw($maindir);
$maindir = "/home/thetitans/.irssi/scripts/";
use lib "/home/thetitans/.irssi/scripts/";


################################################################################
#                            Define version and info                           #
#                                                                              #
# (what are all the kinds of info you can add - KEYS?)                         #
################################################################################
$VERSION = '0.3.20100409';
%IRSSI = (
    authors     => 'Ward Muylaert',
    contact     => 'ward.muylaert@gmail.com',
    name        => 'The Titans Bot',
    description => 'IRC Bot made for The Titans (#thetitans @ irc.swiftirc.net).',
    url         => 'http://thetitans.ipbfree.com/',
);

################################################################################
#                            Auxiliary trim function                           #
#                                                                              #
# Trims trailing and leading whitespaces (regex' \s)                           #
################################################################################

sub trim($) {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

################################################################################
#                                   isAdmin                                    #
################################################################################

sub isAdmin {
  my ($nick, $host) = @_;

  if ($host eq 'Party@My.Place') {
    return 1;
  }
  else {
    return 0;
  }
}

################################################################################
#                    Remove IRC Formatting from a string                       #
# Strips control codes that make text bold, coloured, ...                      #
################################################################################

sub RemoveIrcFormatting {
  my $input = shift;
  
  # Bold
  $input =~ s/\x02//g; # g modifier needed? -> Probably but check
  
  # Underline (what was ASCII code)
  $input =~ s/\x1F//g;
  
  # Reverse (what was ASCII code)
  $input =~ s/\x16//g;
  
  # Colours (check wat ik had bij de regex quiz in #regex @ Undernet.org)
  $input =~ s/\x03(?:\d\d?(?:,\d\d?)?)?//g;
  
  # End of format character
  $input =~ s/\x0F//g;
  
  return $input;
}

################################################################################
#                              Anti Command Spam                               #
################################################################################

# host => endtime
use vars qw(%anticmdspam);

sub isIgnored {
  my ($host) = @_;

  if (defined $anticmdspam{$host}) {
    if ($anticmdspam{$host} < time()) {
      delete $anticmdspam{$host};
      return 0;
    }
    else {
      return 1;
    }
  }
  else {
    return 0;
  }
}

sub setIgnore {
  my ($host, $seconds) = @_;

  $anticmdspam{$host} = time() + $seconds;
}

################################################################################
#                                   Clanavg                                    #
################################################################################

use LWP::Simple;

# Uses runehead, requires clanid of the clan you want to check
sub clanavg {

  my ($clanid, $skill) = @_;
  (defined($clanid) && defined($skill)) or return;
  
  # http://runehead.com/clans/ml.php?clan=titans&skill=Farming
  # Notice that if skill is combat, the default page gets loaded
  my $url = "http://runehead.com/clans/ml.php?clan=" . $clanid
    . "&skill=" . $skill;
  
  my $content = get $url or return;
  
  # This will hold all the data we need to return
  my %infoarray = ("members", &getmembcount($content),
    "clanname", &getclanname($content),
    "url", $url);
  
  # Combat requires some slightly different handling
  if ($skill =~ "Combat") {
    $infoarray{"avglvl"} = &getavglvl($content, "P2P Combat")
      . "/" . &getavglvl($content, "F2P Combat");
  }
  else {
    $infoarray{"avglvl"} = &getavglvl($content, $skill);
		$infoarray{"avgxp"} = &getavgxp($content, $skill),
		$infoarray{"avgrank"} = &getavgrank($content, $skill),
		$infoarray{"totxp"} = &gettotxp($content, $skill);
  }
  
  return %infoarray;
}

sub getclanname {
  my $runeheadpage = shift;
  if ($runeheadpage =~ /<td colspan='6'>(.+?) :: /) {
    return $1;
  }
}

sub clanavg_get_detail {
  my ($haystack, $needle) = @_;
  
  my $startPos = index($haystack, "<b>$needle:</b> ")
                  + length("<b>$needle:</b> ");
  my $info = substr($haystack,
                    $startPos,
                    index($haystack, "<", $startPos) - $startPos);

  return $info;
}

sub getmembcount {
  my ($runeheadpage) = @_;
  return clanavg_get_detail($runeheadpage, "Total Members");
}

sub getavglvl {
  my ($runeheadpage, $skill) = @_;
  return clanavg_get_detail($runeheadpage, "Average $skill");
}

sub getavgxp {
  my ($runeheadpage, $skill) = @_;
  return clanavg_get_detail($runeheadpage, "Average $skill XP");
}

sub getavgrank {
  my ($runeheadpage, $skill) = @_;
  return clanavg_get_detail($runeheadpage, "Average $skill Rank");
}

sub gettotxp {
  my ($runeheadpage, $skill) = @_;
  return clanavg_get_detail($runeheadpage, "Total $skill XP");
}

################################################################################
#                                 Find Clan ID                                 #
################################################################################

use LWP::Simple;

sub findclanid {
  my ($searchterm) = @_;
  defined $searchterm or return;

  # http://runehead.com/feeds/lowtech/searchclan.php?type=2&search=TT
  my $url = "http://runehead.com/feeds/lowtech/searchclan.php?type=2&search="
	    . $searchterm;
  
  # Get the webpage
  my $content = get $url;
  defined $content or return;

  my @splitcontent = split(/\n/, $content);

  # Check if anything found:
  $splitcontent[1] =~ /^\@\@Not Found$/ and return;

  # Extract the url out of every element of the array
  # Note: $#array_name returns the max index
  my @returnarray;
  for (my $i = 1; $i < $#splitcontent; ++$i) {
    my @tmp = split(/\|/, $splitcontent[$i]);
    # 3rd item = runehead highscore link
    @tmp = split(/=/, $tmp[2]);
    # id is after =
    push(@returnarray, $tmp[1]);
  }
  return @returnarray;
}

################################################################################
#                                  Get Skill                                   #
################################################################################

sub getskill {
  my ($skillin) = @_;
  defined $skillin or return;
  if ($skillin =~ /overall?|tot(?:al)?/i) {
    return "Overall";
  }
  elsif ($skillin =~ /(?:combat|cmb)/i) {
    return "Combat";
  }
  elsif ($skillin =~ /att(?:ack)?/i) {
    return "Attack";
  }
  elsif ($skillin =~ /str(?:ength?)?/i) {
    return "Strength";
  }
  elsif ($skillin =~ /def(?:en[cs]e)?/i) {
    return "Defence";
  }
  elsif ($skillin =~ /h(?:it)?p(?:oints?)?/i) {
    return "Hitpoints";
  }
  elsif ($skillin =~ /rang(?:ed?|ing)/i) {
    return "Ranged";
  }
  elsif ($skillin =~ /pray(?:er)?/i) {
    return "Prayer";
  }
  elsif ($skillin =~ /mag(?:e|ic)/i) {
    return "Magic";
  }
  elsif ($skillin =~ /cook(?:ing)?/i) {
    return "Cooking";
  }
  elsif ($skillin =~ /w(?:ood)?c(?:utt?ing)?/i) {
    return "Woodcutting";
  }
  elsif ($skillin =~ /fletch(?:ing)?/i) {
    return "Fletching";
  }
  elsif ($skillin =~ /fish(?:ing)?/i) {
    return "Fishing";
  }
  elsif ($skillin =~ /f(?:ire)?m(?:aking)?/i) {
    return "Firemaking";
  }
  elsif ($skillin =~ /craft(?:ing)?/i) {
    return "Crafting";
  }
  elsif ($skillin =~ /smith(?:ing)?/i) {
    return "Smithing";
  }
  elsif ($skillin =~ /min(?:e|ing)/i) {
    return "Mining";
  }
  elsif ($skillin =~ /herb(?:ore|aw)?/i) {
    return "Herblore";
  }
  elsif ($skillin =~ /agil(?:ity)?/i) {
    return "Agility";
  }
  elsif ($skillin =~ /thie[fv](?:ing)?/i) {
    return "Thieving";
  }
  elsif ($skillin =~ /slay(?:er)?/i) {
    return "Slayer";
  }
  elsif ($skillin =~ /farm(?:er|ing)?/i) {
    return "Farming";
  }
  elsif ($skillin =~ /r(?:une)?c(?:raft)?/i) {
    return "Runecraft";
  }
  elsif ($skillin =~ /hunt(?:ing|er)?/i) {
    return "Hunter";
  }
  elsif ($skillin =~ /cons?(?:truc(?:tion)?)?/i) {
    return "Construction";
  }
  elsif ($skillin =~ /summ?(?:onn?(?:ing)?)?/i) {
    return "Summoning";
  }
  elsif ($skillin =~ /d(?:un)?g(?:eon(?:eer(?:ing)?)?)?/i) {
    return "Dungeoneering";
  }
  else {
    return 0;
  }
}

################################################################################
#                              Clanavg Text Event                              #
################################################################################

sub _clanavg_text {
  my ($server, $data, $nick, $host) = @_;
  my ($target, $text) = split(/ :/, trim($data), 2);
  
  # Clanavg
  if ($target =~ /^#/
      && $text =~ /^([.!@])([^\s\xA0]+)av(?:r?g|erage?)(?: (.+))?$/i) {
    # $1 command delimiter; $2 skill; $3 clan
    my ($cmddelim, $skill, $clan) = ($1, $2, $3);

    my $outputway = $cmddelim eq "@" ? "msg $target" : "notice $nick";

    if (not isIgnored($host)) {
      if (not isAdmin($nick, $host)) {
        setIgnore($host, 3);
      }
    
      my $pid = fork();
      
      if ($pid > 0) {
        Irssi::pidwait_add($pid); # Prevent zombies (chopping heads is so passé)
      }
      else {
        if ($skill = &getskill($skill)) {
          # Remember, findclanid returns an array
          my @clanid = ($clan ? findclanid($clan) : ("titans"));
          if ((defined $clanid[0])
              && (my %info = clanavg($clanid[0], $skill))) {
            my $out;
            if ($skill =~ "Combat") {
              $out = sprintf("[%s %s AVG] -> [#] %s [LVL] %s [ %s ]",
                $info{"clanname"},
                $skill,
                $info{"members"},
                $info{"avglvl"},
                $info{"url"});
            }
            else {
              $out = sprintf("[%s %s AVG] -> [#] %s [LVL] %s [XP] %s [RANK] %s [TOTAL XP] %s [ %s ]",
                $info{"clanname"},
                $skill,
                $info{"members"},
                $info{"avglvl"},
                $info{"avgxp"},
                $info{"avgrank"},
                $info{"totxp"},
                $info{"url"});
            }
            $server->command("$outputway $out");
          }
          else {
            $server->command("$outputway Nothing found while looking for $clan");
          }
        }
        # Exit the child properly (that sounds slightly disturbing)
        POSIX::_exit(0);
      }
    }
  }
}

################################################################################
#                              Victorian Sex Cry                               #
#                                                                              #
# Requires a file with one "sex cry" per line                                  #
################################################################################

use vars qw($sexcryfile);
$sexcryfile = $maindir . "victoriansexcry.txt";

sub victoriansexcry {
  open (my $file, "< $sexcryfile") or return;
  my @lines = <$file>;
  return $lines[rand @lines]; # Random line
}

# This will be added to the event
sub _victoriansexcry_text {
  my ($server, $data, $nick, $host) = @_;
  my ($target, $text) = split(/ :/, trim($data), 2);

  if ($target =~ /^#/
      && $text =~ /^(?:I )?(?:(?:l(?:o|u)ve?|wub)(?: you)?|<3+) (?:(?:The ?)?Titans?|TT) ?(?:<3+)*$/i) {
    if (not isIgnored($host)) {
      if (not isAdmin($nick, $host)) {
        setIgnore($host, 5);
      }
      $server->command("msg $target " . victoriansexcry());
    }
  }
}

sub _victoriansexcry_action {
  my ($server, $text, $nick, $host, $target) = @_;

  if ($target =~ /^#/
      && $text =~ /^huggles (?:$server->{nick})[ .]*(?:<3+)*$/i) {
    if (not isIgnored($host)) {
      if (not isAdmin($nick, $host)) {
        setIgnore($host, 5);
      }
      $server->command("msg $target " . victoriansexcry());
    }
  }
}

################################################################################
#                             Teamspeak checker                                #
#                                                                              #
# Also for Ventrilo or others, needs txt file with the info in it to perform   #
# correctly. Format of that file is:                                           #
# regexpattern@@@clanname@@@site@@@fullurl                                     #
################################################################################

use LWP::Simple;
use vars qw($clantsurlfile);
$clantsurlfile = $maindir . "tsinfo.txt";

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
  
  return %info;
}

################################################################################
#                         Teamspeak checker text event                         #
################################################################################

# requires a channel check still!
sub _teamspeak_text {
  my ($server, $data, $nick, $host) = @_;
  my ($target, $text) = split(/ :/, trim($data), 2);

  if ($target =~ /#(?:ttpk|flameroom)/i
      && $text =~ /^[!@.](?:ts|teamspeak|vent(?:rilo)?) (.+)$/i) {
    my $search = $1;
    if (not isIgnored($host)) {
      if (not isAdmin($nick, $host)) {
        setIgnore($host, 5);
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

################################################################################
#                             Basic text replies                               #
#                                                                              #
# Would, for example, return http://www.google.com/ on command !google         #
################################################################################

sub basic_text_replies {
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
  my ($target, $text) = split(/ :/, trim($data), 2);

  if ($text =~ /^([@!.])(.+)$/) {
    my ($cmddelim, $cmd) = ($1, $2);
    if (my $reply = basic_text_replies($cmd)) {
      if (not isIgnored($host)) {
        if (not isAdmin($nick, $host)) {
          setIgnore($host, 3);
        }
        my $outputway = $cmddelim eq "@" ? "msg $target" : "notice $nick";
        $server->command("$outputway $reply");
      }
    }
  }
}

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
  my ($target, $text) = split(/ :/, trim($data), 2);

  if ($target =~ /^#/
      && $text =~ /^([!@.])users?$/i) {
    my $cmddelim = $1;
    if (not isIgnored($host)) {
      if (not isAdmin($nick, $host)) {
        setIgnore($host, 3);
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

################################################################################
#                                SMD kicker                                    #
#                                                                              #
# Kicks a person saying "smd" or a variation from the channel                  #
################################################################################

use vars qw($smdkickfile);
$smdkickfile = $maindir . "smdkickmsgs.txt";

sub smdkicker_getline {
  open (my $file, "< $smdkickfile") or return;
  my @lines = <$file>;
  return $lines[rand @lines]; # Random line
}

sub _smdkicker_text {
  my ($server, $data, $nick, $host) = @_;
  my ($target, $text) = split(/ :/, trim($data), 2);

  if ($target =~ /^#thetitans$/i
      && RemoveIrcFormatting($text) =~ /\bs+m+f*d+\b/i) {
    $server->command("kick $target $nick "
      . smdkicker_getline());
  }
}

################################################################################
#                         Mass Highlight kicker                                #
#                                                                              #
# Kicks a person highlighting many people                                      #
################################################################################

use vars qw(%masshighlight);
# op/halfop/voice refers to whether or not the highlighter can be that
# eg: 0 in all means the script will only trigger for regular people
%masshighlight = (
  'kickmsg' => "Suck on it, Attention Whore. You're not loved.",
  'max' => 4,
  'op' => 0,
  'halfop' => 0,
  'voice' => 0
);

sub masshighlight_action {
  my ($server, $user, $target, $text) = @_;

  my $banmask = $user->{host};
  $banmask =~ s/^[^@]+/*!*/;

  $server->command("mode $target +b $banmask");
  $server->command("kick $target $user->{nick} $masshighlight{kickmsg}");
}

sub masshighlight_check {
  my ($server, $nick, $target, $text) = @_;

  if ($target =~ /^#thetitans$/i) {
    my $channel = $server->channel_find($target);
    my $user = $channel->nick_find($nick);
    if ($user
        && $user->{op} == $masshighlight{op}
        && $user->{halfop} == $masshighlight{halfop}
        && $user->{voice} == $masshighlight{voice}) {
      # Should use a different pattern to match all non-valid characters
      my @words = split(/[,@%+~&: ]/, $text);
      my $ctr = 0;
      for my $word (@words) {
        if ($word && $channel->nick_find($word)) {
          $ctr++;
        }
      }

      if ($ctr > $masshighlight{max}) {
        masshighlight_action($server, $user, $target, $text);
      }
    }
  }
}

sub _masshighlight_text {
  my ($server, $data, $nick, $host) = @_;
  my ($target, $text) = split(/ :/, trim($data), 2);

  masshighlight_check($server, $nick, $target, $text);
}

sub _masshighlight_action {
  my ($server, $text, $nick, $host, $target) = @_;

  masshighlight_check($server, $nick, $target, $text);
}

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

# Add functions to appropriate signals
Irssi::signal_add("event privmsg", "_clanavg_text");
Irssi::signal_add("event privmsg", "_victoriansexcry_text");
Irssi::signal_add("ctcp action", "_victoriansexcry_action");
Irssi::signal_add("event privmsg", "_teamspeak_text");
Irssi::signal_add("event privmsg", "_basic_text_replies_text");
Irssi::signal_add("event privmsg", "_usercount_text");
Irssi::signal_add("event privmsg", "_smdkicker_text");
Irssi::signal_add("event privmsg", "_masshighlight_text");
Irssi::signal_add("ctcp action", "_masshighlight_action");
Irssi::signal_add_first("ctcp msg version", "_customversion_ctcp");
