use strict;
# Exiting children threads
use POSIX;
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
  my ($target, $text) = split(/ :/, TT::trim($data), 2);
  
  # Clanavg
  if ($target =~ /^#/
      && $text =~ /^([.!@])([^\s\xA0]+)av(?:r?g|erage?)(?: (.+))?$/i) {
    # $1 command delimiter; $2 skill; $3 clan
    my ($cmddelim, $skill, $clan) = ($1, $2, $3);

    my $outputway = $cmddelim eq "@" ? "msg $target" : "notice $nick";

    if (not TT::isIgnored($host)) {
      if (not TT::isAdmin($nick, $host)) {
        TT::setIgnore($host, 3);
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

Irssi::signal_add("event privmsg", "_clanavg_text");