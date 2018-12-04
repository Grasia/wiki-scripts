use utf8;
use feature 'say';


#~ $filename=$ARGV[0];

#~ my $encoding = ":encoding(UTF-8)";
#~ open (FH, " < $encoding", $filename) or die "Error trying to write on $filename: $!\n";

#~ $aux_fn = "out2";
#~ open (OUT, " > $encoding", $aux_fn) or die "Error trying to write on $aux_fn: $!\n";

foreach $line (<STDIN>)  {
    my ($prev, $value, $after) = $line =~ '(.*wiki_name=")(.*)(" .*)';

    #~ say $prev;
    #~ say $value;
    #~ say $after;
    if (not $prev) {
        print STDOUT "$line";
        next;
    }

    #~ say $value;
    $value =~ s/\"/\&quot;/g;
    #~ say $value;

    print STDOUT "$prev$value$after\n";

    #~ print "$line\n";
}
#~ close(FH);
