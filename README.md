# wikia_dump_downloader
Download the current revisions of a repository from a Mediawiki site via Special:Export and the API.

# Dependencies
* perl 5
* Bundle::LWP. In debian and derivatives it's included in the `libwww-perl` package. Alternatively, It can be installed using CPAN: `perl -MCPAN -e 'install Bundle::LWP'`
* Perl JSOn lib. In debian and derivatives it's included in the `libjson-perl` package, other distros can find it in `perl-JSON`. Alternatively, It can be installed using CPAN: `perl -MCPAN -e 'install JSON'`
