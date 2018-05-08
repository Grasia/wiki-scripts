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

my $br = LWP::UserAgent->new;
$br->timeout(45);
#$br->conn_cache(LWP::ConnCache->new());
$br->agent("Mozilla/5.0");
$br->requests_redirectable(['POST', 'HEAD', 'GET']);

# listUsers API
my $listUsers_url;
my $listUsers_post_endpoint = 'index.php?' . 'action=ajax&rs=ListusersAjax::axShowUsers';

# wiki info
my $wiki_url;

my $bot_users;
my @users_by_contributions = ('', '', '', '', '', '');

# csv variables
my $output_filename = 'wikia_users.csv';
my $urls_filename = '20180220-wikia_index.txt';
my $csv_columns = 'url, users_1, users_5, users_10, users_20, users_50, users_100, bots';

# output filehandlers
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


# order of arguments = ($loop, $edits)
sub request_all_users {
    my ($loop, $edits) = @_;
    my @form_data = [
        groups => "all,bureaucrat,rollback,sysop,threadmoderator,authenticated,content-reviewer,council,fandom-editor,global-discussions-moderator,helper,restricted-login,restricted-login-exempt,reviewer,staff,util,vanguard,voldev,vstf,",
        username => "",
        edits => $edits,
        limit => "10",
        offset => "0",
        loop => $loop, # simulate user behaviour
        numOrder => "1",
        order => "username:asc"
    ];

    my $res = $br->post($listUsers_url, @form_data);
    if (not $res->is_success) {
        if ($res->code == HTTP_INTERNAL_SERVER_ERROR) {
            say STDERR "Received 500 Internal Server Error response when posting to $listUsers_url querying for all users.. Retrying again after 10 seconds...";
            sleep 10;
            return request_all_users($loop, $edits);
        } elsif ($res->code == 503) {
            say STDERR "Received 503 Service Unavailable Error response when posting to $listUsers_url querying for all users.. Retrying again after 10 seconds...";
            sleep 10;
            return request_all_users($loop, $edits);
        } else {
            die $res->status_line.' when posting to Special:ListUsers querying for all users.';
        }
    }

    my $raw_users_content = $res->decoded_content();
    #~ say $res->decoded_content();
    my $json_res = decode_json($raw_users_content);
    #~ print Dumper($json_res);
    my $users = $json_res->{'iTotalDisplayRecords'};
    say "Total users with edits equal or higher than $edits is: $users";
    $users;
}

# order of arguments = ($loop, $edits)
sub request_bot_users {
    my ($loop, $edits) = @_;
    my @form_data_for_bots = [
        groups => "bot,bot-global,",
        username => "",
        edits => $edits,
        limit => "10",
        offset => "0",
        loop => $loop + 1, # simulate user behaviour
        numOrder => "1",
        order => "username:asc"
    ];


    my $res = $br->post($listUsers_url, @form_data_for_bots);
    if (not $res->is_success) {
        if ($res->code == HTTP_INTERNAL_SERVER_ERROR) {
            say STDERR "Received 500 Internal Server Error response when posting to $listUsers_url querying for bot users.. Retrying again after 10 seconds...";
            sleep 10;
            return request_bot_users($loop, $edits);
        } elsif ($res->code == 503) {
            say STDERR "Received 503 Service Unavailable Error response when posting to $listUsers_url querying for all users.. Retrying again after 10 seconds...";
            sleep 10;
            return request_all_users($loop, $edits);
        } else {
            die $res->status_line.' when posting to Special:ListUsers querying for bot users.';
        }
    }

    my $raw_users_content = $res->decoded_content();
    my $json_res = decode_json($raw_users_content);
    #~ print Dumper($json_res);
    my $bot_users = $json_res->{'iTotalDisplayRecords'};
    say "Bot users with edits equal or higher than $edits is: $bot_users";
    $bot_users;
}

sub extract_users_by_contributions {
    my $users;
    my $edits_query;
    my $loop_query;

    # Do different queries to get contributors by nº of editions made.
    for (my $i = 0; $i < 6; ++$i) {
        if ($i == 0) {$edits_query = 1;}
        elsif ($i == 1) {$edits_query = 5;}
        elsif ($i == 2) {$edits_query = 10;}
        elsif ($i == 3) {$edits_query = 20;}
        elsif ($i == 4) {$edits_query = 50;}
        else {$edits_query = 100; sleep 1;} # ($i == 5)

        $loop_query = $i + 1;
        $users = request_all_users($loop_query, $edits_query);
        $users_by_contributions[$i] = $users;
    }

    $bot_users = request_bot_users($loop_query + 1, 0);
}


# To fill $csv_columns => 'url, users_1, users_5, users_10, users_20, users_50, users_100, bots';

# arguments = ($fh, $filename)
#   $fh: filehandle for the output csv
#   $filename: filename for the output csv
sub print_wiki_to_csv {
    my ($fh, $filename) = @_;

    say "\n ---> Printing info for wiki $wiki_url into $filename .....";
    print $fh "\"$wiki_url\", $users_by_contributions[0], $users_by_contributions[1], $users_by_contributions[2], $users_by_contributions[3], $users_by_contributions[4], $users_by_contributions[5], $bot_users\n";

}

# returns:   1 if $wiki_url is ok,
#           -1 if the wiki's been deleted,
#           -2 in case that Wikia says that it is an invalid wiki url,
#           -3 in case of an 404 error,
#           -4 in case of users database is locked (closed wiki)
#           -5 in case of another unexpected error. For example: 403 Forbidden response

sub is_wiki_url_ok {
    my $res = $br->head($wiki_url);

    my @redirects = $res->redirects();
    foreach my $redirect (@redirects) {

        if (($redirect->as_string()) =~ m/community\.wikia\.com\/wiki\/Special\:CloseWiki/) {
            print STDERR "\n--- Wiki $wiki_url has been deleted from wikia ---\n";
            return -1; # return "wiki has been deleted"
        }
        elsif (($redirect->as_string()) =~ m/community\.wikia\.com\/wiki\/Community_Central:Not_a_valid_community/) {
            print STDERR "\n--- Wiki $wiki_url does not exist or has been moved from wikia ---\n";
            return -2; # return "wiki url is not valid anymore"
        }
    }

    if ($res->is_success) {
        my @form_data = [
                groups => "staff,",
                username => "",
                edits => 20,
                limit => "1",
                offset => "0",
                loop => 1, # simulate user behaviour
                numOrder => "1",
                order => "username:asc"
            ];

        my $res = $br->post($listUsers_url, @form_data);
            if (not $res->is_success) {
                say STDERR $res->status_line ." when posting to $listUsers_url, for wiki $wiki_url";
                return -4; # problem requesting ListUsers
            }

            return 1; # return "wiki url is ok"

    } elsif ($res->code == 404) {
        say STDERR "Error found checking wiki $wiki_url: " . $res->status_line;
        return -3; # return "There's a 404 NOT Found error when requesting $wiki_url"
    } else {
        say STDERR "Unexpected HTTP Error found checking wiki $wiki_url: " . $res->status_line;
        return -5; # return 'unknown' error.
    }
}


#### Starts main(): #####

# get urls:
my @wikia_urls;
open URLS_FH, $urls_filename or die $!;
@wikia_urls = <URLS_FH>;
chomp(@wikia_urls);

# creating CSV files handler for writing
$csv_fh = open_output_file($output_filename);

# Iterating over ids
foreach (@wikia_urls) {

    $wiki_url = $_;

    print "\n\n";
    say('#' x 30);
    print "\n\n";

    sleep 0.5; # Artificial delay to not saturate wikia' servers

    say ("Retrieving data for wiki: $wiki_url");

    # Get
    $listUsers_url = $wiki_url . $listUsers_post_endpoint;
    my $wiki_url_status = is_wiki_url_ok();
    if ($wiki_url_status < 0) {
        print STDERR "--> Skipping from index <-- \n";
        next;
    }

    # Getting users using Special:ListUsers page
    extract_users_by_contributions();


    # Info retrieved, printing:
    print_wiki_to_csv($csv_fh, $output_filename);

    say ("Non bot users per contribution: ");
    print "$_, " foreach (@users_by_contributions);
    print "\n";
}


close $csv_fh;
