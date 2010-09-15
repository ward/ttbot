use strict;
use POSIX;
use Irssi;
use vars qw($VERSION %IRSSI);

use TT;

$VERSION = '0.5.20100830';
%IRSSI = (
	authors     => 'Ward Muylaert',
	contact     => 'ward.muylaert@gmail.com',
	name        => 'The Titans Bot - Champions League',
	description => 'IRC Bot made for The Titans (#thetitans @ irc.swiftirc.net).',
	url         => 'http://s4.zetaboards.com/thetitans',
);

################################################################################
#                               Champions League                               #
################################################################################

use LWP::Simple;
use XML::Simple;

# Find a way to not have to require another module for this
# but still looking clean
use Switch;

sub groupToId {
	my $look = shift;
	if ($look =~ /b/i) { return 2000792; }
	elsif ($look =~ /c/i) { return 2000793; }
	elsif ($look =~ /d/i) { return 2000794; }
	elsif ($look =~ /e/i) { return 2000795; }
	elsif ($look =~ /f/i) { return 2000796; }
	elsif ($look =~ /g/i) { return 2000797; }
	elsif ($look =~ /h/i) { return 2000798; }
	else { return 2000791; }
}

# Probably better if this only returns an object with what we need?
# Downside is perl is pretty horrible with the referencing and all that
sub groupStandings {
	my $group = shift;

	# Change group to it's id here
	my $gid = groupToId($group);

	my $url = "http://www.uefa.com/uefachampionsleague/standings/round=2000118/group=$gid/index.html";
	my $content = get $url;

	$content =~/<div class="t_standings"><h3 class="bigTitle innerText">.+?([A-H])</;
	$group = $1;

	$content =~ /<table class="tb_stand">.+?(<tbody>.+?<\/tbody>)<\/table>/;
	$content = $1;

	my $xml = new XML::Simple;
	my $data = $xml->XMLin($content);

	my $out = "[GROUP $group]";
	for (my $i = 0; $i < 4; $i++) {
#		print Dumper($data->{tr}[$i]);
		# First get the row, this is an array reference,
		# then dereference with @{...}
		# Perl really is nasty on anything bigger than a short hack <_<
		my @cells = @{$data->{tr}[$i]->{td}};
		my $rank = $cells[0]->{content};
		my $team = $cells[1]->{a}->{content};
		$team =~ s/\xa0//; # nbsp (non-breakable space)
		my $played = $cells[2];
		my $win = $cells[9]->{content};
		my $draw = $cells[10];
		my $loss = $cells[11];
		my $goalsfor = $cells[12];
		my $goalsagainst = $cells[13];
		my $points = $cells[15]->{content};
		$out .= " $rank. $team Pld: $played ($win-$draw-$loss) Pts: $points ($goalsfor-$goalsagainst);";
	}
	return $out;
}

sub _cl_text {
	my ($server, $data, $nick, $host) = @_;
	my ($target, $text) = split(/ :/, TT::trim($data), 2);

	if ($target =~ /#/i
		&& $text =~ /^([!@.])c(?:hampions?)?l(?:eague)? (?:group)?([A-H])$/i) {
		my ($cmddelim, $group) = ($1, $2);
		my $outputway = $cmddelim eq "@" ? "msg $target" : "notice $nick";
		if (not TT::isIgnored($host)) {
			if (not TT::isAdmin($nick, $host)) {
				TT::setIgnore($host, 5);
			}

			my $pid = fork();

			if ($pid > 0) {
				Irssi::pidwait_add($pid);
			}
			else {
				my $output = groupStandings($group);
				$server->command("$outputway $output");

				POSIX::_exit(0);
			}
		}
	}
}

Irssi::signal_add("event privmsg", "_cl_text");
