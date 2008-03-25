#!/usr/bin/env perl
use strict;
use warnings;
use Text::Markdown qw(markdown);

#### Check for command-line switches: #################
my %cli_opts;
use Getopt::Long;
Getopt::Long::Configure('pass_through');
GetOptions(\%cli_opts,
    'version',
    'shortversion',
    'html4tags',
    'help',
);
if ($cli_opts{'version'}) {     # Version info
    print "\nThis is Markdown, version $Text::Markdown::VERSION.\n";
    print "Copyright 2004 John Gruber\n";
    print "Copyright 2008 Tomas Doran\n";
    print "Parts contributed by several other people.";
    print "http://daringfireball.net/projects/markdown/\n\n";
    exit 0;
}
if ($cli_opts{'shortversion'}) {        # Just the version number string.
    print $Text::Markdown::VERSION;
    exit 0;
}
if ($cli_opts{'help'})

my $m;
if ($cli_opts{'html4tags'}) {           # Use HTML tag style instead of XHTML
    $m = Text::Markdown->new(empty_element_suffix => '>');
}
else {
    $m = Text::Markdown->new;
}

sub main {
    my ($fn) = @_;
    
    my $f;
    if (defined $fn && length $fn) {
        die("Cannot find file $fn") unless (-r $fn);

        my $fh;
        open($fh, '<', $fn) or die;
        $f = join('', <$fh>);
        close($fh) or die;
    }
    else { # STDIN
        local $/;               # Slurp the whole file
        $f = <>;
    }

    return markdown($f);
}

print main(shift(@ARGV)) unless caller();


