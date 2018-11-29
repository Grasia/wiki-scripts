#!/bin/sh
# shell script to download the wiki dump for every wiki listed in a wiki index
#  file (first argument) of a list of wikis
#  and join all the parts into one only XML file.

## Variables declaration ##
wiki_index_file=$1
wikis=`cat $wiki_index_file`

for wiki in $wikis; do
	echo "Downloading wiki dump for $wiki..."
	perl get_pages.pl $wiki
	if [ $? -eq 0 ]; then
		echo "Joining all data parts into one xml file for $wiki..."
		sh join_xml_parts.sh $wiki
		rm -r data/processed/$wiki/parts
		python3 ../dump_parser/dump_parser.py data/processed/$wiki/full/$wiki.xml
		rm data/processed/$wiki/full/$wiki.xml
	else
		echo "Error when downloading dump for $wiki. Skipping..."
		echo $wiki >> skipped.txt
		rm data/$wiki*.xml
	fi
done

echo "Done with $wiki_index_file"
