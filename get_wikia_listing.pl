#!/bin/perl

use utf8;
use warnings;
use strict;

use LWP::UserAgent;
use JSON;
use Data::Dumper;

my $br = LWP::UserAgent->new;
$br->timeout(10);

my $api_url = 'http://www.wikia.com/api/v1';
#my $params = '/Wikis/List?limit=25&batch=1'; # top wikis by pageviews
#my $params = '/WikiaHubs/getHubsV3List?lang=en'; # wiki hubs list
#my $params = '/Wikis/ByString?expand=1&string=mountain&hub=Lifestyle&limit=25&batch=1&includeDomain=true'; # search wiki by name
my $params = '/Wikis/Details?ids=4930'; # get wiki info

my $api_request = $api_url . $params;

my $res = $br->get($api_request);
if ($res->is_success) {
        my $json_res = decode_json($res->decoded_content);
        print Dumper($json_res);
} else {
        die $res->status_line." when getting wikias from ".$api_request;
}
