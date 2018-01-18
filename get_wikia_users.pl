#!/usr/bin/perl

use utf8;
use feature 'say';
use warnings;
use diagnostics;
use strict;

use open ':encoding(UTF-8)';

use LWP::UserAgent;
use JSON;
use LWP::ConnCache;
use Data::Dumper;
use HTTP::Status qw(:constants :is status_message);
use IO::Handle;
use URI::Escape;

# browser agent
my $br = LWP::UserAgent->new;
$br->timeout(15);
#$br->conn_cache(LWP::ConnCache->new());
$br->agent("Mozilla/5.0");

# csv variables
my $csv_columns = 'user_id,username,is_bot,registration,gender'; # note that username is quoted with the | symbol
my $output_filename = 'wikia_users.csv';
my $csv_fh;

# one argument: ($filename) => the file name for the file to create and open
sub open_output_file {
    my ($filename) = @_;
    my $encoding = ":encoding(UTF-8)";
    my $filehandle = undef;
    my $create_if_not_exists = not -e $filename;
    open ($filehandle, " >> $encoding", $filename) or die "Error trying to write on $filename: $!\n";
    autoflush $filehandle 1;
    print $filehandle "$csv_columns\n" if $create_if_not_exists;
    return $filehandle;
}

my $base_url = 'http://www.wikia.com/';
my $usids = ''; # a | separated list of user ids to retrieve in shape of string.

my $json_res;
my $aufrom = ''; # Don't escape when retrieving the first users
#~ $aufrom = uri_escape_utf8('Jhoanst'); # fill with last aufrom for continuing in the event of the script was stopped

$csv_fh = open_output_file($output_filename);

sub smartdecode {
    my $x = my $y = uri_unescape($_[0]);
    return $x if utf8::decode($x);
    return $y;
}

my $i = 0;
my $should_continue = 0;
do {
    $i = $i + 1;
    $usids = '';

    # First, retrieve all users in wikia:
    my $allusers_endpoint = $base_url . "api.php?action=query&list=allusers&aulimit=500&format=json&aufrom=$aufrom";
    my $res = $br->get($allusers_endpoint);
    my $raw_users_content = $res->decoded_content();
    #~ say $res->decoded_content();
    $json_res = decode_json($raw_users_content);
    print Dumper($json_res);
    my @users = @{$json_res->{'query'}->{'allusers'}};
    #~ print Dumper(@users);

    # concatenate retrieved users ids into $usids string list
    foreach (@users[0..$#users-1]) {
        $usids .= $_->{'id'} . '|';
    }
    $usids .= $users[$#users]->{'id'};
    say $usids;

    $should_continue = defined $json_res->{'query-continue'};
    $aufrom = $json_res->{'query-continue'}->{'allusers'}->{'aufrom'} if $should_continue;
    say "--> Next username to retrieve in following iteration: $aufrom";
    $aufrom = uri_escape_utf8( $aufrom );

    # Second, use the retrieved user ids in order to get info of those users
    my $usersinfo_endpoint = $base_url . "api.php?action=query&list=users&usprop=groups|gender|registration&format=json&usids=$usids";
    $res = $br->get($usersinfo_endpoint);
    $raw_users_content = $res->decoded_content();
    #~ say $res->decoded_content();
    $json_res = decode_json($raw_users_content);
    #~ print Dumper($json_res);

    # Store it in a file following this format: $csv_columns = 'user_id, username, is_bot, registration, gender';
    my @users_info = @{$json_res->{'query'}->{'users'}};

    foreach my $user (@users_info) {

        $user->{'registration'} = 'NaT' unless defined $user->{'registration'};

        #~ my @user_groups = @{$user->{'groups'}};
        my %user_groups = map { $_ => 1 } @{$user->{'groups'}}; # convert users_groups array to hash
        my $is_bot, my $bot = 'bot', my $bot_global = 'bot-global';
        if( exists($user_groups{$bot}) or exists($user_groups{$bot_global}) ) {
            $is_bot = 'True';
        } else {
            $is_bot = 'False';
        }

        #~ say Dumper($user);
        #~ say ref($user);
        my $username = smartdecode($user->{'name'});

        # using | as delimiter for usernames since some can have whitespaces and other rare symbols
        print $csv_fh "$user->{'userid'},|$username|,$is_bot,$user->{'registration'},$user->{'gender'}\n";

    }

} while ($should_continue);
