#!/usr/bin/env perl
use strict;
use warnings;
use Text::MultiMarkdown qw(markdown);

#### Check for command-line switches: #################
my %cli_opts;
use Getopt::Long;
Getopt::Long::Configure('pass_through');
GetOptions(\%cli_opts,
    'version',
    'shortversion',
    'html4tags',
);
if ($cli_opts{'version'}) {     # Version info
    print "\nThis is Markdown, version $Text::MultiMarkdown::VERSION.\n";
    print "Copyright 2004 John Gruber\n";
    print "Copyright 2006 Fletcher Penny\n";
    print "Copyright 2008 Tomas Doran\n";
    print "Parts contributed by several other people."
    print "http://fletcherpenney.net/MultiMarkdown/\n\n";
    exit 0;
}
if ($cli_opts{'shortversion'}) {        # Just the version number string.
    print $Text::MultiMarkdown::VERSION;
    exit 0;
}

my $m;
if ($cli_opts{'html4tags'}) {           # Use HTML tag style instead of XHTML
    $m = Text::MultiMarkdown->new(empty_element_suffix => '>');
}
else {
    $m = Text::MultiMarkdown->new;
}

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