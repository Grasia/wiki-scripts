# wiki_dump_downloader
Download all the revisions history of a Mediawiki wiki via the API and the Special:Export endpoint.

Note that large wikis can take a lot of time to get all the pages and download its whole history.

# Dependencies
* perl 5
* Bundle::LWP. In debian and derivatives it's included in the `libwww-perl` package. Alternatively, It can be installed using CPAN: `perl -MCPAN -e 'install Bundle::LWP'`
* Perl JSOn lib. In debian and derivatives it's included in the `libjson-perl` package, other distros can find it in `perl-JSON`. Alternatively, It can be installed using CPAN: `perl -MCPAN -e 'install JSON'`

# Usage
Run the script with the canonical url (without http) for the wiki you want to download:
`perl get_pages.pl <wiki_url>`

For example: `perl get_pages.pl strikewitches.wikia.com`

The generated dump will be stored in the data/ directory splitted in parts of 5000 pages each.

To join these parts in a single xml file use the shell script `join_xml_parts.sh` as showed below:
`sh join_xml_parts.sh <wiki_prefix>`

For example: `sh join_xml_parts.sh strikewitches.wikia.com`

A new directory will be created in the data/proccesed/ dir with the name you just supplied. Inside you will find two directories:

- full/: a single xml file with all the history as a whole. (Most likely what you want)
- parts/: the previously downloaded xml parts of 5000 pages history each

## Download and process many wikis at once with `bulk_download.sh`
To download, join parts and process the wiki dump with the [dump_parser.py script](https://github.com/Grasia/wiki-scripts/blob/master/dump_parser/dump_parser.py), you can use the `bulk_download.sh` shell script.

It needs an input text file listing, one per line, all the canonical urls of the wikis you want to work with. One example of this file would be this:

`wikis_to_download.txt file:`
```
lab-rats.wikia.com
dragcave.wikia.com
es.clubpenguin.wikia.com
es.thewalkingdead.wikia.com
althistory.wikia.com
nerf.wikia.com
fr.lgdc.wikia.com
familyguy.wikia.com
```
Following the example above, you'd run the script with: `sh bulk_download.sh wikis_to_download.txt`

As a result, it will leave the processed history csv file in the full/ directory of every wiki. It will also remove the parts and full xml files in order to not fill up all your disk space. Finally, if any error arises at any step when collecting and processsing wiki data, the script will add its url to the skipped.txt file and go on to the next one.

The script is pretty simple, so feel free to modify it to suit your needs.

# Domains tested
Domains tested so far:
- *.wikia.com :heavy_check_mark:
- *.gamepedia.com :heavy_check_mark: -> Although it sometimes can return a `504 Gateway Time-out` error from Cloudfront
- *.wiktionary.org :heavy_check_mark:
- nomadwiki.org/lang/ :heavy_check_mark:
