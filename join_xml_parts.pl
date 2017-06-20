#!/bin/perl

## WIP!!! ###

use utf8;
use warnings;
use strict;

my $xml_dir = 'data/parts/';

my @files = <data/*.xml>;
for my $i (0 .. $#files) {
        if ($i!=0) {
                perl -ip -e '$_ = undef if $. == 1' $file
        }
        if ($i < $#files-1) {
                
        }
        print "$files[$i]\n";
}

#foreach $file (@files) {
        #next if (@files)
        #print $file . "\n";
#}
