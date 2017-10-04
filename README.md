# wikia_dump_downloader
Download the current revisions of a repository from a Mediawiki site via Special:Export and the API.

# census

Generate a 'census' or corpus of wikia hosted wikis, based on number of users, editions, pages, etcetera.

TODO: Generate alternative census of 'Deleted' wikias.

# Dependencies
* perl 5
* Bundle::LWP. In debian and derivatives it's included in the `libwww-perl` package. Alternatively, It can be installed using CPAN: `perl -MCPAN -e 'install Bundle::LWP'`
