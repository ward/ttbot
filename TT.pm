package TT;

use strict;

use vars qw($VERSION %IRSSI);
$VERSION = '0.5.20100830';
%IRSSI = (
	authors     => 'Ward Muylaert',
	contact     => 'ward.muylaert@gmail.com',
	name        => 'The Titans Bot - Main',
	description => 'IRC Bot made for The Titans (#thetitans @ irc.swiftirc.net).',
	url         => 'http://s4.zetaboards.com/thetitans',
);

sub maindir {
	return Irssi::get_irssi_dir() . "/scripts/";
}

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
sub removeIrcFormatting {
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

1;