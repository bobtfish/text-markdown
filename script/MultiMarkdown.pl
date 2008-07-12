#!/usr/bin/env perl
use strict;
use warnings;
use Text::MultiMarkdown qw(markdown);

=head1 NAME

MultiMarkdown.pl - Convert MultiMarkdown syntax to (X)HTML

=head1 DESCRIPTION

This program is distributed as part of Perl's Text::MultiMarkdown module,
illustrating sample usage.

MultiMarkdown.pl can be invoked on any file containing MultiMarkdown-syntax, and
will produce the corresponding (X)HTML on STDOUT:

    $ cat file.txt
    [MultiMarkdown][] *extends* the very well-known [Markdown][] syntax.

    [MultiMarkdown]: http://fletcherpenney.net/What_is_MultiMarkdown
    [Markdown]: http://daringfireball.net/projects/markdown/

    $ multimarkdown file.txt
    <p><a href="http://fletcherpenney.net/What_is_MultiMarkdown">MultiMarkdown</a> <em>extends</em> the very well-known <a href="http://daringfireball.net/projects/markdown/">Markdown</a> syntax.</p>


If no file is specified, it will expect its input from STDIN:

    $ echo "A **simple** test" | multimarkdown
    <p>A <strong>simple</strong> test</p>

=head1 OPTIONS

=over

=item version

Shows the full information for this version

=item shortversion

Shows only the version number

=item html4tags

Produce HTML 4-style tags instead of XHTML - XHTML requires elements
that do not wrap a block (i.e. the C<hr> tag) to state they will not
be closed, by closing with C</E<gt>>. HTML 4-style will plainly output
the tag as it comes:

    $ echo '---' | multimarkdown
    <hr />
    $ echo '---' | multimarkdown --html4tags
    <hr>

=item help

Shows this documentation

=back

=head1 AUTHOR

Copyright 2004 John Gruber

Copyright 2006 Fletcher Penny

Copyright 2008 Tomas Doran

The manpage was written by Gunnar Wolf <gwolf@debian.org> for its use
in Debian systems, but can be freely used elsewhere.

For full licensing information, please refer to
Text::MultiMarkdown.pm's full documentation.

=head1 SEE ALSO

L<Text::MultiMarkdown>, L<http://fletcherpenney.net/What_is_MultiMarkdown>

=cut

#### Check for command-line switches: #################
my %cli_opts;
use Getopt::Long;
Getopt::Long::Configure('pass_through');
GetOptions(\%cli_opts,
    'version',
    'shortversion',
    'html4tags',
    'help'
);
if ($cli_opts{'version'}) {     # Version info
    print "\nThis is MultiMarkdown, version $Text::MultiMarkdown::VERSION.\n";
    print "Copyright 2004 John Gruber\n";
    print "Copyright 2006 Fletcher Penny\n";
    print "Copyright 2008 Tomas Doran\n";
    print "Parts contributed by several other people.";
    print "http://fletcherpenney.net/MultiMarkdown/\n\n";
    exit 0;
}
if ($cli_opts{'shortversion'}) {        # Just the version number string.
    print $Text::MultiMarkdown::VERSION;
    exit 0;
}
if ($cli_opts{'help'}) {
    for my $dir (split m/:/, $ENV{PATH}) {
	my $cmd = "$dir/perldoc";
	exec($cmd, $0) if (-f $cmd and -x $cmd);
    }
    die "perldoc could not be found in your path - Cannot show help, sorry\n";
}
my $m;
if ($cli_opts{'html4tags'}) {           # Use HTML tag style instead of XHTML
    $m = Text::MultiMarkdown->new(empty_element_suffix => '>');
}
else {
    $m = Text::MultiMarkdown->new;
}

sub main {
    my (@fns) = @_;
    
    my $f;
    if (scalar @fns) {
        foreach my $fn (@fns) {
            die("Cannot find file $fn") unless (-r $fn);

            my $fh;
            open($fh, '<', $fn) or die;
            $f = join('', <$fh>);
            close($fh) or die;
        }
    }
    else { # STDIN
        local $/;               # Slurp the whole file
        $f = <>;
    }
    
    return $m->markdown($f);
}

print main(@ARGV) unless caller();
