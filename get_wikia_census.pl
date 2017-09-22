#!/bin/perl

use utf8;
use feature say;
use warnings;
use strict;

use LWP::UserAgent;
use JSON;
use LWP::ConnCache;
use Data::Dumper;
use HTTP::Cookies;

my $br = LWP::UserAgent->new;
$br->timeout(10);
$br->conn_cache(LWP::ConnCache->new());
$br->cookie_jar(HTTP::Cookies->new("cookies.txt", autosave => 1, ignore_discard => 1));
$br->agent("Mozilla/5.0");


# wikia API
my $wikia_endpoint = 'http://www.wikia.com/api/v1';
my $wikia_id = '55';
my $wikia_params = '/Wikis/Details?ids=' . $wikia_id; # params targetting wikia api to get wiki info

# mediawiki API
my $mediawiki_endpoint = 'api.php';
#my $mediawiki_params = '?action=query&list=allusers&aufrom=Y&format=json';
my $mediawiki_params = '?action=query&meta=siteinfo&siprop=statistics&format=json';

# wiki info
my $wiki_name;
my $wiki_url;
my $wiki_hub;
my $wiki_topic;
my $wiki_articles;
my $wiki_pages;
my $wiki_edits;
my $wiki_lang;

my $wiki_users;
my $wiki_admins;
my $wiki_active_users;

# csv variables
my $output_file = 'wikia_census.csv';
my $csv_columns = 'id, name, url, articles, pages, users, active users, admins, edits, lang, hub, topic';

# other variables
my $wiki_info;
my $api_request = $wikia_endpoint . $wikia_params;

sub extract_wiki_info_from_wikia_json {
        $wiki_name = $wiki_info->{'name'};
        $wiki_url = $wiki_info->{'url'};
        $wiki_hub = $wiki_info->{'hub'};
        $wiki_topic = $wiki_info->{'topic'};
        $wiki_lang = $wiki_info->{'lang'};
        
        my $wiki_stats = $wiki_info->{'stats'};
        $wiki_edits = $wiki_stats->{'edits'};
        $wiki_articles = $wiki_stats->{'articles'};
        $wiki_pages = $wiki_stats->{'pages'};

        $wiki_admins = $wiki_stats->{'admins'};
        #say $wiki_stats->{'users'};
        #say $wiki_stats->{'activeUsers'};
        #say $wiki_admins;
}

#sub print_wiki_to_csv {
        #print CSV "$wikia_id, $wiki_name, $wiki_url\n";
#}


# Getting wiki info from wikia general API
my $res = $br->get($api_request);
if (not $res->is_success) {
        die $res->status_line.' when getting wikias from ' . $api_request;
}

my $json_res = decode_json($res->decoded_content);
#print Dumper($json_res);
$wiki_info = $json_res->{'items'}->{$wikia_id};
extract_wiki_info_from_wikia_json();

# Getting users using Special:ListUsers page
my $listUsers_url = $wiki_url . '/index.php?' . 'action=ajax&rs=ListusersAjax::axShowUsers';
my @form_data = [
        groups => "all,bureaucrat,sysop,authenticated,content-reviewer,council,fandom-editor,global-discussions-moderator,helper,restricted-login,restricted-login-exempt,reviewer,staff,util,vanguard,voldev,vstf,",
        username => "",
        edits => "20",
        limit => "10",
        offset => "0",
        loop => "2",
        numOrder => "1",
        order => "username:asc"
];

$res = $br->post($listUsers_url, @form_data);
if (not $res->is_success) {
        die $res->status_line.' when posting to Special:ListUsers ';
}
my $raw_users_content = $res->decoded_content();
$json_res = decode_json($raw_users_content);
print Dumper($json_res);
my $active_users_var = $json_res->{'iTotalDisplayRecords'};
say $active_users_var;

# Getting wiki info from wikimedia API
#$api_request = $wiki_url . $mediawiki_endpoint . $mediawiki_params;
#my $res = $br->get($api_request);
#if (not $res->is_success) {
        #die $res->status_line." when getting wikias from " . $api_request;
#}
#my $json_res = decode_json($res->decoded_content);
#print Dumper($json_res);
#my $wiki_stats = $json_res->{'query'}->{'statistics'};
#say $wiki_stats->{'users'};
#say $wiki_stats->{'activeusers'};
#say $wiki_stats->{'admins'};

# creating CSV file handler for writing
#open CSV, " >$output_file" or die "Error trying to write on $output_file: $!\n";
#print CSV $csv_columns . "\n";
#print_wiki_to_csv();

# Other possible queries targetting wikia api with useful info:
#my $wikia_params = '/Wikis/List?limit=25&batch=1'; # top wikis by pageviews
#my $wikia_params = '/WikiaHubs/getHubsV3List?lang=en'; # wiki hubs list
#my $wikia_params = '/Wikis/ByString?expand=1&string=mountain&hub=Lifestyle&limit=25&batch=1&includeDomain=true'; # search wiki by name

