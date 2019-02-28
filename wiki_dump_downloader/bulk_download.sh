#!/bin/sh
# shell script to download the wiki dump for every wiki listed in a wiki index
#  file (first argument) of a list of wikis domain names
#  and join all the parts into one only XML file.
# IMPORTANT: DO NOT INCLUDE PRECEEDING http(s):// in the list of wikis. Just the domain name.
# eg. gardening.wikia.com is OK, but http://gardening.wikia.com is not.

## Variables declaration ##
wiki_index_file=$1
wikis=`cat $wiki_index_file`

for wiki in $wikis; do
	echo "Downloading wiki dump for $wiki..."

	# $wiki_fn is the wiki name but escaping not wanted symbols for a filename from the wiki domain name, e.g. the forward slashes: '/'
	# We do 4 statements of perl here:
	# 1) set $wiki_fn value by the $wiki iterator variable given in the $wikis list of this script
	# 2) get rid of initial schema part in the wiki name (http(s):// ) (it's ugly, so I removed it also in the get_pages.pl script)
	# 3) scape any not valid characters for filename (also done in get_pages.pl script)
	# 4) print $wiki_fn value to be grabbed by $wiki_fn var in this shell script
	wiki_fn=$(
	perl -e 'my $wiki = $ARGV[0];
	my ($wiki_fn) = ($wiki =~ /^https?:\/\/(.+)/) if $wiki =~ /^https?/;
	$wiki_fn =~ s~[^\w\.\-]~_~g;
	print($wiki_fn);' $wiki) # $wiki is the argument to the perl script

	perl get_pages.pl $wiki
	if [ $? -eq 0 ]; then
		echo "Joining all data parts into one xml file for $wiki..."
		sh join_xml_parts.sh $wiki_fn
		rm -r data/processed/$wiki_fn/parts
		python3 ../wiki_dump_parser/wiki_dump_parser.py data/processed/$wiki_fn/full/$wiki_fn.xml
		if [ $? -eq 0 ]; then
			rm data/processed/$wiki_fn/full/$wiki_fn.xml
		else    # error control for parser
			echo "Error when processing dump for $wiki_fn. Skipping..."
			echo $wiki >> skipped.txt
			rm data/$wiki_fn*.xml
		fi
	else	# error control for downloader
		echo "Error when downloading dump for $wiki. Skipping..."
		echo $wiki >> skipped.txt
		rm data/$wikifn*.xml
	fi
done

echo "Done with $wiki_index_file"
