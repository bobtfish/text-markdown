#!/usr/bin/env perl
use strict;
use warnings;
use Text::MultiMarkdown qw(markdown);

my $fn = shift(@ARGV);
my $f;
if (defined $fn && length $fn) {
    die("Cannot find file $fn") unless (-r $fn);

    my $fh;
    open($fh, '<', $fn) or die;
    $f = join('', <$fh>);
    close($fh) or die;
}
else { # STDIN
    $f = join('', <>);
}

sub main {
    return markdown($f);
}

print main() unless caller();