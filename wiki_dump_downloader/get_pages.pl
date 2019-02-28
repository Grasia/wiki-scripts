#!/bin/perl


#####  Perl built-in usages #####
use utf8;
use warnings;
use strict;


#####  External libs #####
use Time::HiRes qw[time];
use LWP::UserAgent;
use LWP::ConnCache;
use HTTP::Request::Common;
use HTTP::Cookies;
use URI::Escape qw[uri_escape_utf8];
use HTML::Entities qw[decode_entities];
use JSON;


#####  Global vars #####

# output dir
my $output_dir = 'data/'; # output directory where to store the data extracted. Important to end it with a slash (/)
mkdir $output_dir unless -d $output_dir;


# Browser agent
my $br = LWP::UserAgent->new;
$br->conn_cache(LWP::ConnCache->new());
$br->agent("ma_dump/1.2");
$br->requests_redirectable(['POST', 'HEAD', 'GET']);
# saving cookies file
$br->cookie_jar(HTTP::Cookies->new(file => $output_dir . "cookies.txt", autosave => 1, ignore_discard => 1));

# get wiki url from user
my $wiki;
# Define wiki to download
if (@ARGV < 1) {
        print "Please, write the wiki domain (FQDN) you want to get the dump from (eg. es.lagunanegra.wikia.com)\n";
        $wiki = <STDIN>;
        chomp($wiki);
} else {
        $wiki = $ARGV[0];
}

# Make sure url has a http heading
my $wiki_url;


if ( not $wiki =~ /^https?/ ) {
        $wiki_url = 'http://' . $wiki;
} else {
        $wiki_url = $wiki;
        ($wiki) = ($wiki =~ /^https?:\/\/(.+)/); # remove the schema part from $wiki
}

my @possible_api_endpoints = ('/api.php', '/w/api.php');
my @possible_export_endpoints = ('/wiki/Special:Export', '/Special:Export');


#####  Function definitions #####

# From a given url, tries to find the api and export endpoint.
# @input: wiki url
# @output: ($api_url, $export_url) or an error otherwise
sub endpoints_probing {
        my ($wiki_url) = @_;

        # Probing for api endpoint:
        my $api_url;
        my $found = 0;
        foreach (@possible_api_endpoints) {
                $api_url = $wiki_url . $_;
                my $res = $br->head($api_url);
                if ($res->is_success) {
                        $found = 1;
                        $api_url = $res->request()->uri();
                        last;
                }
        }

        unless ($found) { die ("Failed to find api endpoint for $wiki_url.") };

        # Probing for Special:Export endpoint:
        my $export_url;
        $found = 0;
        foreach (@possible_export_endpoints) {
                $export_url = $wiki_url . $_;
                my $res = $br->head($export_url);
                if ($res->is_success) {
                        $found = 1;
                        $export_url = $res->request()->uri();
                        last;
                }
        }

        unless ($found) { die ("Failed to find Special:Export endpoint for $wiki_url.") };

        return ($api_url, $export_url)
}

# Get next value for the $apfrom parameter,
#  from the xml response of a query that asks for the number of pages
#  of a certain namespace
# @input: decoded content of the api query
# @output: ($apfrom value) or undef if $apfrom value was not found.
sub get_next_apfrom {
        my ($xml_content, $apfrom) = @_;
        ($apfrom) = $xml_content =~ m#<allpages apfrom="(.*?)" />#; # Wikia and many other mediawiki wikis
        return $apfrom if ($apfrom);

        ($apfrom) = $xml_content =~ m#<continue apcontinue="(.*?)" continue=".*" />#; # gamepedia wikis
        return $apfrom if ($apfrom);

        return undef;
}


#####  Begin logic #####

#my $language = 'en.';
#my $language = '';
#my $wiki = 'marvel.wikia.com';
my $api_url;
my $export_url;

($api_url, $export_url) = endpoints_probing($wiki_url);
print "Selected api url endpoint: $api_url\n";
print "Selected Special:Export url endpoint: $export_url\n";

# Download params
my $aplimit = 500; # number of page names in one API request; passed to the API; 500 for anon, 1000 for logged in bot
my $pages_per_xml = 5000; # number of pages in one Special::Export request
my $current_only = 0;   # 1 = pages_current, 0 = pages_full

# timing var
my $stm = time;

# Getting namespaces listing for this wiki
#~ (Not being used yet)
#~ my $ns_api_url = $api_url . "?action=query&meta=siteinfo&siprop=namespaces&format=json";
#~ my $res = $br->get($ns_api_url);
#~ if ($res->is_success) {
        #~ my $json_res = decode_json($res->decoded_content);
        #~ #my @hash = $json_res->{'query'}{'namespaces'};
        #~ ##~ print $json_res->{'query'}{'namespaces'}{'-2'}{'id'};
        #~ my @available_namespaces = keys $json_res->{'query'}{'namespaces'};
        #~ print "These are the namespaces available for this wiki: " . join(', ', @available_namespaces) . "\n";
#~ } else {
        #~ die $res->status_line." when getting namespaces from $ns_api_url";
#~ }

#my @namespaces = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 102, 103, 110, 111); # probably should fetch this list from somewhere
#~ my @namespaces = (0); # just the main namespace
my @namespaces = (-2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 110, 111, 500, 501, 502, 503, 1200, 1201, 1202, 2000, 2001, 2002); # list extracted from wikia_dashboard namespace analysis. anyways, why this list?
# more info about namespaces here: http://community.wikia.com/wiki/Help:Namespace

# getting pages listing
my @pages;
print "Getting page list...\n";
foreach my $ns (@namespaces) {
        my $apfrom;
        do {
                my $url = $api_url . "?action=query&list=allpages&apnamespace=$ns&aplimit=$aplimit&format=xml" .
                        ( $apfrom ? "&apfrom=$apfrom" : '' );

                my $res = $br->get($url);
                if ($res->is_success) {
                        push @pages, $res->decoded_content =~ m#<p pageid="\d+" ns="\d+" title="(.*?)" />#g;

                        # look for next apfrom param (in case there is).
                        $apfrom = get_next_apfrom($res->decoded_content);

                } else {
                        die $res->status_line." on $url";
                }

        } while defined $apfrom;
        printf "Done with {{ns:$ns}}, now have %d page(s).\n", scalar @pages;
}

printf "%d page(s) to fetch, %d at a time, %d part(s) expected...\n", scalar @pages, $pages_per_xml, map( int( /^\d+$/ ? $_ : $_+1 ), @pages / $pages_per_xml );

my %export_parms = (
        action => 'submit',
        curonly => 1,
);
delete $export_parms{curonly} unless $current_only;

my $wiki_fn = $wiki;
$wiki_fn =~ s~[^\w\.\-]~_~g;

print "Starting to download wiki dump in chunks...\n";

# getting pages in chunks
my $part = 0;
while (@pages) {
        $part++;

        $export_parms{pages} = join("\n", map(decode_entities($_), splice(@pages, 0, $pages_per_xml) ) );

        my $req = new HTTP::Request POST => $export_url;
        $req->content_type('application/x-www-form-urlencoded');
        $req->content( join('&', map(sprintf("%s=%s", $_, uri_escape_utf8($export_parms{$_}) ), keys %export_parms) ) );

        my $xml_filename = sprintf "%s_pages_%s_hard_part%03d.xml", $wiki_fn, $export_parms{curonly} ? 'current' : 'full', $part;
        my $xml_file = $output_dir . $xml_filename;
        my $res = $br->request($req, $xml_file);

        if ($res->is_success) {
                print "OK. $xml_file ",-s $xml_file," bytes.\n";
        } else {
                die $res->decoded_content, "\n*** ", $res->status_line, "\n";
        }

}

print time-$stm," second(s). $part parts.\n";
