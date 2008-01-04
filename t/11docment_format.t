use strict;
use warnings;
use Test::More tests => 5;

#1
use_ok( 'Text::MultiMarkdown');

my $instr = q{A trivial block of text};
my $m = Text::MultiMarkdown->new();
my $outstr = qq{<p>A trivial block of text</p>\n};

is( #2
    $m->markdown($instr) => $outstr, 
    'Markdown'
);

$m = Text::MultiMarkdown->new();
$outstr = qq{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>\n\t<head>\n\t</head>\n<body>\n<p>A trivial block of text</p>\n</body>\n</html>};

is( #3
    $m->markdown($instr, {document_format => 'Complete'}) => $outstr, 
    'Markdown with complete xhtml doc'
);

$instr = q{title: A page title
css: somestyle.css
other: some metadata

A trivial block of text};

$outstr = qq{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>\n\t<head>\n\t\t<link type="text/css" rel="stylesheet" href="somestyle.css" />
\t\t<meta name="other" content="some metadata" />
\t\t<title>A page title</title>\n\t</head>\n<body>\n<p>A trivial block of text</p>\n</body>\n</html>};

is( #4
    $m->markdown($instr, {document_format => 'complete'}) => $outstr, 
    'Markdown with complete xhtml doc (and metadata)'
);

$outstr = qq{css: somestyle.css<br />\nother: some metadata<br />\ntitle: A page title<br />\n
<p>A trivial block of text</p>\n};

is( #5 
    $m->markdown($instr) => $outstr, 
    'Markdown withmetadata, but no complete doc'
);
