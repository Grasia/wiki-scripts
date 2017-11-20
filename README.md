# wikia_dump_downloader
Download the current revisions of a repository from a Mediawiki site via Special:Export and the API.

# Dependencies
* perl 5
* Bundle::LWP. In debian and derivatives it's included in the `libwww-perl` package. Alternatively, It can be installed using CPAN: `perl -MCPAN -e 'install Bundle::LWP'`
* Perl JSOn lib. In debian and derivatives it's included in the `libjson-perl` package, other distros can find it in `perl-JSON`. Alternatively, It can be installed using CPAN: `perl -MCPAN -e 'install JSON'`

# Usage
Run the script with the canonical url (without http) for the wiki you want to download:
`perl get_pages.pl <wiki_url>`

For example: `perl get_pages.pl strikewitches.wikia.com`

The generated dump will be stored in the data/ directory in parts of 5000 pages each.

To join the parts in a single xml file use the shell script `join_xml_parts.sh` as showed below:
`sh join_xml_parts.sh <wiki_prefix>`

For example: `sh join_xml_parts.sh strikewitches.wikia.com`

A new directory will be created in the data/proccesed/ dir with the name you just supplied. Inside you will find two directories:

- full/: a single xml file with all the history as a whole. (Most likely what you want)
- parts/: the previously downloaded xml parts of 5000 pages history each.
