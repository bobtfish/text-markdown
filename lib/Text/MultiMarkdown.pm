package Text::MultiMarkdown;
require 5.006_000;
use strict;
use warnings;

sub _DoBlockQuotes {
    my ($text) = @_;

    $text =~ s{
          (                             # Wrap whole match in $1
            (
              ^[ \t]*>[ \t]?            # '>' at the start of a line
                .+\n                    # rest of the first line
              (.+\n)*                   # subsequent consecutive lines
              \n*                       # blanks
            )+
          )
        }{
            my $bq = $1;
            $bq =~ s/^[ \t]*>[ \t]?//gm;    # trim one level of quoting
            
            $bq = _DoBlockQuotes($bq);      # recurse

            #print "STRING IS {$bq}\n";
            $bq =~ s/^/  MOO/g;
            #print "OUT STRING IS {$bq}\n";

            "<blockquote>\n$bq\n</blockquote>\n\n";
        }egmx;


    return $text;
}

1;
