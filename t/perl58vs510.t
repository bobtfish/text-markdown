use strict;
use warnings;
use Test::More tests => 1;

my $str = "\n\n\n\n";
$str =~ s{.*}{
    s/^/MOO/g;
    $_;
}egmx;
my $exp = "MOO\nMOO\nMOO\nMOO\n";

is($str, $exp);
