# users_with_edits scripts

Generate data of edits per user for every wiki in wikia.

You can test this script placing the list of wiki urls you want to extract in a `.txt` file and assing its name to the `$urls_filename` variable.
As an example you can use the `wikiaIndex-test.txt` file given in the repo.

Currently, there are two scripts:

* `get_edits_per_user.pl`: Download a .csv of the form: `url; wiki_name; total_edits; edits_per_user; bots` for every wiki listed in the urls input file.
* `user_with_edits.pl`: Download both, the previous csv and a (bigger) xml file with much more info about every user of every wiki. The shape of that xml matches the `wikia_edits.xsd` schema.

Written in `Perl5`.

## Dependencies
* Bundle::LWP. In debian and derivatives it's included in the `libwww-perl` package. Alternatively, It can be installed using CPAN: `perl -MCPAN -e 'install Bundle::LWP'`
* Perl JSON lib. In debian and derivatives it's included in the `libjson-perl` package, other distros can find it in `perl-JSON`. Alternatively, It can be installed using CPAN:

  ```
  perl -MCPAN -e shell
  install JSON
  ```

* Perl HTML::Strip lib. In debian and derivatives it's included in the `libhtml-strip-perl` package. Alternatively, install it using CPAN: `perl -MCPAN -e HTML::Strip`
* Perl TryCatch module. In debian and Derivatives it's included in the `libtrycatch-perl` package. Alternatively, It can be installed using CPAN:

  ```
  perl -MCPAN -e shell
  install TryCatch
  ```
