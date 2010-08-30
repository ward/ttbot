use strict;
use Irssi;
use vars qw($VERSION %IRSSI);

use TT;

$VERSION = '0.5.20100830';
%IRSSI = (
	authors     => 'Ward Muylaert',
	contact     => 'ward.muylaert@gmail.com',
	name        => 'The Titans Bot - Masshighlight Kicker',
	description => 'IRC Bot made for The Titans (#thetitans @ irc.swiftirc.net).',
	url         => 'http://s4.zetaboards.com/thetitans',
);

################################################################################
#                         Mass Highlight kicker                                #
#                                                                              #
# Kicks a person highlighting many people                                      #
################################################################################

use vars qw(%masshighlight);
# op/halfop/voice refers to whether or not the highlighter can be that
# eg: 0 in all means the script will only trigger for regular people
# max is amount of people to allow to be highlighted in one line
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
  my ($target, $text) = split(/ :/, TT::trim($data), 2);

  masshighlight_check($server, $nick, $target, $text);
}

sub _masshighlight_action {
  my ($server, $text, $nick, $host, $target) = @_;

  masshighlight_check($server, $nick, $target, $text);
}

Irssi::signal_add("event privmsg", "_masshighlight_text");
Irssi::signal_add("ctcp action", "_masshighlight_action");