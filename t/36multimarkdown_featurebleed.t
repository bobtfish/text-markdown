use strict;
use warnings;
use Test::More tests => 2;
use File::Slurp qw(slurp);
use FindBin qw($Bin);

BEGIN: {
    use_ok('Text::Markdown');
}

my $m = Text::Markdown->new();

my $docsdir = "$Bin/docs-multimarkdown";
my $input = q{This is a formatted ![image][] and a [link][] with attributes.

[image]: http://path.to/image "Image title" width=40px height=400px
Some non-link text.
[link]: http://path.to/link.html "Some Link" class=external
        style="border: solid black 1px;"
};
my $output = q{<p>This is a formatted <img src="http://path.to/image" alt="image" title="Image title" width="40px" height="400px" /> and a <a href="http://path.to/link.html" title="Some Link" style="border: solid black 1px;" class="external">link</a> with attributes.</p>

<p>Some non-link text.</p>
};

my $processed = $m->markdown($input);

isnt($processed, $output, 'MultiMarkdown image and link attributes feature bleeds into Text::Markdown');

