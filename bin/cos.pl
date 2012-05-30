use v5.10.1;
use strict;
use warnings;
use utf8;
use Xchat qw(:all);
# PODNAME: cos.pl
# ABSTRACT: Filter out the noise of a huge IRC channel by lowering The Cone Of Silence
# VERSION

=head1 SYNOPSIS

This L<XChat|http://xchat.org> script may be useful on very busy channels when
you are trying to have a conversation with a handful of people. For example,
when getting support in C<irc.freenode.net #ubuntu>.

You specify who you're talking to with C</cos nick1 nick2 ...>, and now
you only hear from those people. Add more users to your conversation with
C</cos nick3 nick4>. Remove the restrictions with C</cos>. List the
people you can hear with C</list_cone>.

=head2 The Cone Of SilenceE<0x2122>

The Cone Of Silence<0x2122> is a L<fictional device|https://en.wikipedia.org/wiki/Cone_of_Silence>
from the classic 1960s TV show L<Get Smart|https://en.wikipedia.org/wiki/Get_Smart>.

=cut

my @events = (
    'Channel Message', 'Channel Msg Hilight',
    'Channel Action',  'Channel Action Hilight',
    'Channel Notice'
);
my $cones;

register(
    'Cone Of Silence',
    (defined __PACKAGE__->VERSION ? __PACKAGE__->VERSION : 'dev'),
    'The Cone Of Silence™ will make a busy channel peaceful'
);
prnt('The Cone Of Silence is now available.');

hook_command(
    'cos',
    \&cone_of_silence,
    { help_text => <<'END_USAGE' }
Usage:
    /cos nick1 nick2 ... # Brings people under The Cone Of Silence, lowering it if needed
    /cos                 # Raises The Cone Of Silence
END_USAGE
);

hook_command(
    'list_cone',
    \&list_cone,
    { help_text => <<'END_USAGE' }
Usage:
    /list_cone          # Lists who is under the current channel's Cone Of Silence
END_USAGE
);


sub list_cone {
    my $channel = shift;
    my $users = $cones->{$channel}->{users_under_cone};

    prnt defined $users
        ? "Under The Cone Of Silence: @$users"
        : 'Nobody is under The Cone Of Silence except you, Chief';
}

sub cone_of_silence {
    my @cmd = @{ +shift };
    my @nicks = @cmd[1 .. $#cmd];
    my $channel = get_info('channel');

    if (@nicks) {
        foreach my $nick (@nicks) {
            push @{ $cones->{$channel}->{users_under_cone} }, $nick
                if user_info($nick); # skip nonexistent users
        }

        _lower_cone_of_silence($channel) unless $cones->{$channel}->{lowered};
    }
    else {
        _raise_cone_of_silence($channel);
    }
}

sub _raise_cone_of_silence {
    my $channel = shift;
    unless ($cones->{$channel}) {
        prnt(<<'END_USAGE');
Usage:
    /cos nick1 nick2 ... # Brings people under The Cone Of Silence, lowering it if needed
    /cos                 # Raises The Cone Of Silence
END_USAGE
        return;
    }

    unhook($_) for @{ $cones->{$channel}->{cone_hooks} };
    unhook($cones->{$channel}->{nick_change_hook});

    delete $cones->{$channel};
    prnt("We have raised The Cone Of Silence for $channel");
}

sub _lower_cone_of_silence {
    my $channel = shift;

    foreach my $event (@events) {
        push @{ $cones->{$channel}->{cone_hooks} }, hook_print($event, \&_cone_filter);
    }
    $cones->{$channel}->{nick_change_hook} = hook_print('Change Nick', \&_update_nick);

    $cones->{$channel}->{lowered} = 1;
    prnt("We have lowered The Cone Of Silence for $channel");
    list_cone($channel) if $cones->{$channel}->{users_under_cone};
}

sub _cone_filter {
    my $sender = $_[0][0];
    my $channel = get_info('channel');

    return EAT_NONE unless $cones->{$channel}->{lowered};
    return EAT_XCHAT unless $sender ~~ @{ $cones->{$channel}->{users_under_cone} };
    return EAT_NONE;
}

sub _update_nick {
    my $channel = get_info('channel');
    my ($old, $new) = @{ +shift };

    foreach my $nick (@{ $cones->{$channel}->{users_under_cone} }) {
        if (nickcmp($nick, $old) == 0) {
            $nick = $new;
            last;
        }
    }
}
