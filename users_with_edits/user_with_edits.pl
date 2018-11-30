use utf8;
use feature 'say';
#~ use strict;

use Data::Dumper;
use LWP::UserAgent;
use JSON;
use LWP::ConnCache;
use Data::Dumper;
use HTTP::Status qw(:constants :is status_message);
use IO::Handle;
use HTML::Strip;
use TryCatch;
#~ use XML::Simple qw(:strict);

my $hs = HTML::Strip->new();

my $br = LWP::UserAgent->new;
$br->timeout(45);
#$br->conn_cache(LWP::ConnCache->new());
$br->agent("Mozilla/5.0");
$br->requests_redirectable(['POST', 'HEAD', 'GET']);

my $mediawiki_endpoint = 'api.php';
my $mediawiki_params = '?action=query&meta=siteinfo&siprop=general|statistics&format=json';

# listUsers API
my $listUsers_url;
my $listUsers_post_endpoint = 'index.php?' . 'action=ajax&rs=ListusersAjax::axShowUsers';

# file-related variables
my $output_csv_filename = 'wikia_edits-test.csv';
my $output_xml_filename = 'wikia_edits-test.xml';
my $urls_filename = 'wikiaIndex-test.txt';
#my $urls_filename = '20180917-curatedIndex-partk.txt';
my $csv_columns = 'url; wiki_name; total_edits; edits_per_user; bots';

# output messages
my $skipped_error_message = "--> Saving row as \"-1; -1; -1; -1\" <--";

# output filehandlers
my $output_csv_fh;
my $output_xml_fh;

# number of users to get per request
my $limit = 50;

### Aux vars ###

# aux var to store number of users in a wiki
my $users;

# aux hashref to store wiki data
my $wiki;


# one argument: ($filename) => the file name for the file to create and open
sub open_output_file {
    my ($filename) = @_;
    my ($type_of_output) = $filename =~ /\.([^.]+)$/; # get file extension
    my $encoding = ":encoding(UTF-8)";
    my $filehandle = undef;
    my $file_already_sxists = -e $filename;
    if ($file_already_sxists) {
        die "Running this script would overwrite the contents of $filename. " .
            "First remove those contents or save them somewhere else and run this script again.\n";
    } else {
        open ($filehandle, " >> $encoding", $filename) or die "Error trying to write on $filename: $!\n";
        autoflush $filehandle 1;

        if ($type_of_output eq 'csv') {
            print $filehandle "$csv_columns\n";
        } elsif ($type_of_output eq 'xml') {
            print $filehandle "<?xml version=\"1.0\"?>\n";
            print $filehandle "<wikis>\n";
        } else {
            die "output extension: $filename unrecognized. Please use .csv or .xml extensions.";
        }
    }

    return $filehandle;
}


# Get users' data for given usernames and print it in the output xml file.
sub get_user_data_and_print {
    my (@usernames) = @_;

    # Retrieve users data from MediaWiki API
    my $users_query = join('|', @usernames);
    my $url = $wiki_url . "api.php?action=query&list=users&ususers=$users_query&usprop=groups|gender|registration|editcount&format=xml";
    my $res = $br->get($url);
    my $user_xml_data = $res->decoded_content();

    # users data is in inside the <users> element response
    my ($users_data) = $user_xml_data =~ /<users>(.*)<\/users>/;

    # creates a list of <user> in order to print the xml more prettified.
    @users_data_list = split( /<\/user>/, $users_data );

    foreach (@users_data_list) {
        # Note that We have to put back the closing </user>
        #  we took out with the split function prior to print.
        print $output_xml_fh ("\t\t\t$_</user>\n");
    }
}


# order of arguments = ($loop, $url, $query_bots, $first_element)
# first_elemnt is just to know if this is the first time this subroutine is
# executed for a wiki, because in that case we don't want to print a comma
# before the number
sub print_all_users {
    my ($loop, $url, $query_bots, $first_element) = @_;
    $offset = $limit * $loop;
    my @form_data ;
    if (not $query_bots) {
       @form_data = [
            groups => "all,bot,bureaucrat,rollback,sysop,threadmoderator,authenticated,bot-global,content-reviewer,content-volunteer,council,fandom-editor,global-discussions-moderator,helper,restricted-login,restricted-login-exempt,reviewer,staff,util,vanguard,voldev,vstf,",
            username => "",
            edits => 0,
            limit => $limit,
            offset => $offset,
            loop => $loop, # simulate user behaviour
            numOrder => "1",
            order => "username:asc"
        ];
    } else {
        @form_data = [
            groups => "bot,bot-global,",
            username => "",
            edits => 0,
            limit => $limit,
            offset => $offset,
            loop => $loop, # simulate user behaviour
            numOrder => "1",
            order => "username:asc"
        ];
    }

    my $res = $br->post($url, @form_data);
    if (not $res->is_success) {
        if ($res->code == HTTP_INTERNAL_SERVER_ERROR) {
            say STDERR "Received 500 Internal Server Error response when posting to $listUsers_url querying for all users.. Retrying again after 10 seconds...";
            sleep 10;
            return print_all_users($loop, $url, $query_bots);
        } elsif ($res->code == 503) {
            say STDERR "Received 503 Service Unavailable Error response when posting to $listUsers_url querying for all users.. Retrying again after 10 seconds...";
            sleep 10;
            return print_all_users($loop, $url, $query_bots);
        } else {
            return -1;
        }
    }

    my $raw_users_content = $res->decoded_content();
    if ($raw_users_content =~ /^ *$/) { # sometimes there is an empty row (?) that breaks the JSON decoder !!!
        say STDERR "\n->Found an empty row. Skipping!!<-";
        return 0;
    }
    #~ say $res->decoded_content();
    my $json_res = decode_json($raw_users_content);
    #~ print Dumper($json_res);
    $users = $json_res->{'iTotalDisplayRecords'};


    if ($loop == 0) {
        if (not $query_bots) {
            $wiki->{'users'} = $users;
            $wiki_users = $users;
            print_wiki();
            print $output_xml_fh "\t\t<edits_per_user>\n";
            say "Total users with edits equal or higher than 0 is: $users";
        } else {
            print $output_xml_fh "\t\t<edits_per_bot>\n";
            say "\nTotal bots with edits equal or higher than 0 is: $users";
        }
    }


    #~ print Dumper($json_res);

    my $data = $json_res->{'aaData'};

    my @user_edits = @$data;
    my @usernames;

    foreach (@user_edits) {
        # filter out bots in case we aren't querying bots:
        if (not $query_bots and @$_[1] =~ /bot/i) {
            #~ say 'Bot found!!';
            #~ say @$_;
            next;
        }

        # Getting edit count only for .csv

        $dirty_edits = @$_[2];
        my $edits = $hs->parse( $dirty_edits );
        $hs->eof;
        # First element of @user_edits without a trailing comma:
        if ($first_element) {
            #~ print ("$edits");
            print $output_csv_fh ("$edits");
            $first_element = 0;
        } else {
            #~ print (", $edits");
            print $output_csv_fh (", $edits");
        }
        # Extract all usernames for this ListUsers page:
        my ($username) = @$_[0] =~ /href="\/wiki\/Special:Editcount\?username=(\S+)"/;
        push (@usernames, $username);
    }
        # Get userdata for all these users and print it in the output xml file.
        get_user_data_and_print(@usernames);

    #~ exit;

    return 0;

    #~ Recursive looping
    #~ if ($users - $offset > 0) {
        #~ print_all_users($loop + 1, $url);
    #~ } else {
        #~ print ("\n");
        #~ print $output_csv_fh ("\n");
    #~ }
}


sub extract_edits_and_print {
    my ($url) = @_;
    my $loop;
    my $first_element; # to do not print comma before the first element.


    # printing edits per human user using Special:ListUsers page
    $loop = 0;
    $first_element = 1;

    do {
        if (print_all_users($loop, $url, 0, $first_element) < 0) {
            print STDERR $res->status_line.' when posting to Special:ListUsers querying for all users.\n';
            print STDERR "--> Skipping from index <-- \n";
            print $output_csv_fh ("-1; -1\n");
            print_wiki(1);
            return -1;
        }
        $loop++;
        $first_element = 0;
    } while ($loop <= $users / $limit);

    #~ print ("; ");
    print $output_csv_fh ("; ");
    print $output_xml_fh "\t\t</edits_per_user>\n";

    # printing edits per bot user using Special:ListUsers page
    $loop = 0;
    $first_element = 1;

    do {
        if (print_all_users($loop, $url, 1, $first_element) < 0) {
            print STDERR $res->status_line.' when posting to Special:ListUsers querying for all users.\n';
            print STDERR "--> Skipping from index <-- \n";
            print $output_csv_fh ("-1\n");
            print_wiki(1);
            return -1;
        }
        $loop++;
        $first_element = 0;
    } while ($loop <= $users / $limit);

    print $output_xml_fh "\t\t</edits_per_bot>\n";

    return 0;
}


# returns:   1 if $wiki_url is ok,
#           -1 if the wiki's been deleted,
#           -2 in case that Wikia says that it is an invalid wiki url,
#           -3 in case of an 404 error,
#           -4 in case of users database is locked (closed wiki)
#           -5 in case of another unexpected error. For example: 403 Forbidden response
sub is_wiki_url_ok {
    my ($wiki_url, $listUsers_url) = @_;
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

        #~ my $json_res = decode_json($raw_users_content);
        #~ $wikia_users = $json_res->{'iTotalDisplayRecords'};

        #~ print Dumper($res);

        return 1; # return "wiki url is ok"

    } elsif ($res->code == 404) {
        say STDERR "Error found checking wiki $wiki_url: " . $res->status_line;
        return -3; # return "There's a 404 NOT Found error when requesting $wiki_url"
    } else {
        say STDERR "Unexpected HTTP Error found checking wiki $wiki_url: " . $res->status_line;
        return -5; # return 'unknown' error.
    }
}


sub print_wiki {
    my ($error) = @_;
    $error //= 0;
    if ($error) {
        $wiki->{'error'} = "true";
    } else {
        $wiki->{'error'} = "false";
    }

    print Dumper($wiki);

    print $output_xml_fh "\t<wiki url=\"$wiki_url\" error=\"$wiki->{'error'}\"";
    print $output_xml_fh " wiki_name=\"$wiki_name\"" if (defined $wiki_name);
    print $output_xml_fh " >\n";
    print $output_xml_fh "\t\t<total_edits>$wiki_edits</total_edits>\n" if (defined $wiki_edits);
    print $output_xml_fh "\t\t<total_users>$wiki_users</total_users>\n" if (defined $wiki_users);

    #~ XMLout ($wiki, OutputFile => $output_xml_fh, KeyAttr => {"wiki"}, KeepRoot => 1);
}


#### Starts main(): #####

# get urls:
my @wikia_urls;
open URLS_FH, $urls_filename or die $!;
@wikia_urls = <URLS_FH>;
chomp(@wikia_urls);

# creating output files handler for writing
$output_csv_fh = open_output_file($output_csv_filename);
$output_xml_fh = open_output_file($output_xml_filename);

# Iterating over urls
foreach (@wikia_urls) {

    $wiki_url = $_;

    print "\n\n";
    say('#' x 30);
    print "\n\n";

    sleep 0.5; # Artificial delay to not saturate wikia' servers

    # printing url
    print $output_csv_fh ("$wiki_url; ");
    $wiki->{'url'} = $wiki_url;

    say ("Retrieving data for wiki: $wiki_url");

    # Check if wiki OK
    $listUsers_url = $wiki_url . $listUsers_post_endpoint;
    my $wiki_url_status = is_wiki_url_ok($wiki_url, $listUsers_url);
    if ($wiki_url_status < 0) {
        print STDERR $skipped_error_message . "\n";
        print $output_csv_fh ("-1; -1; -1; -1\n");
        print_wiki(1);
        next;
    }

    # get total editions number
    my $api_request = $wiki_url . $mediawiki_endpoint . $mediawiki_params;
    my $res = $br->get($api_request);

    if (not $res->is_success) {
        print STDERR $skipped_error_message . "\n";
        print $output_csv_fh ("-1; -1; -1; -1\n");
        print_wiki(1);
        next;
    }
    my $json_res;
    try { # There are some edge cases where the wiki has been moved or deleted but is difficult to find the pattern
          # With this Try...Catch we skip the ultimate wikis which we couldn't extract the data for some reason
          # This prevents that the scripts get stopped because of these few edge cases
        $json_res = decode_json($res->decoded_content);
    } catch {
        print STDERR "Found fatal error: $_ when retrieving data for wiki: $wiki_url\n" .
            $skipped_error_message . "\n";
        print $output_csv_fh ("-1; -1; -1; -1\n");
        print_wiki(1);
        next;
    }
    #~ print Dumper($json_res);
    $wiki_edits = $json_res->{'query'}->{'statistics'}->{'edits'};
    $wiki->{'edits'} = $wiki_edits;
    $wiki_name = $json_res->{'query'}->{'general'}->{'sitename'};
    $wiki->{'name'} = $wiki_name;
    print $output_csv_fh ("\"$wiki_name\"; $wiki_edits; ");

    # get editions per user
    extract_edits_and_print($listUsers_url);

    print ("\n");
    print $output_csv_fh ("\n");

} continue {
    # Before next wikis, clean values for data variables
    undef $wiki_url;
    undef $wiki_name;
    undef $wiki_edits;
    undef $wiki_users;

    # Before next wiki, close wiki tag.
    print $output_xml_fh "\t</wiki>\n";
}

print $output_xml_fh "</wikis>\n";

print "¡¡I AM DONE with $urls_filename!!\n";

close $output_csv_fh;
