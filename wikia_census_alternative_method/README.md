# census

## Note
*This was an alternative method to retrieve all the wikis hosted in Wikia using the MediaWiki api.php endpoint.
However this method takes too long to complete and has to face many errors, so we finally decided to use another approach using the [Wikia's Sitemap](http://www.wikia.com/Sitemap) which is the one hosted in: https://github.com/Grasia/wiki-scripts/tree/master/wikia_census*

Generate a 'census' or corpus of wikia hosted wikis, based on number of users, editions, pages, etcetera.

## Dependencies
* perl 5
* Bundle::LWP. In debian and derivatives it's included in the `libwww-perl` package. Alternatively, It can be installed using CPAN: `perl -MCPAN -e 'install Bundle::LWP'`
* Perl JSOn lib. In debian and derivatives it's included in the `libjson-perl` package, other distros can find it in `perl-JSON`. Alternatively, It can be installed using CPAN: `perl -MCPAN -e 'install JSON'`
