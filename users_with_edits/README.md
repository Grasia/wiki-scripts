# users_with_edits script

Generate data of edits per user for every wiki in wikia.

You can test this script placing in line 32 the list of wiki urls you want to extract the edits per user from (variable `$urls_filename`).
As an example you can use the `wikiaIndex-test.txt` file given in the repo.

Written in `Perl5`.

## Dependencies
* Bundle::LWP. In debian and derivatives it's included in the `libwww-perl` package. Alternatively, It can be installed using CPAN: `perl -MCPAN -e 'install Bundle::LWP'`
* Perl JSON lib. In debian and derivatives it's included in the `libjson-perl` package, other distros can find it in `perl-JSON`. Alternatively, It can be installed using CPAN: `perl -MCPAN -e 'install JSON'`
* Perl HTML::Strip lib. In debian and derivatives it's included in the `libhtml-strip-perl` package. Alternatively, install it using CPAN: `perl -cpan HTML::Strip`
* Perl TryCatch module. In debian and Derivatives it's included in the `libtrycatch-perl` package. Alternatively, It can be installed using CPAN: `perl -MCPAN -e 'install TryCatch'`
