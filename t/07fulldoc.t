use strict;
use warnings;
use Test::More tests => 2;

use_ok( 'Text::MultiMarkdown', 'markdown' );

my @data = <DATA>;
my $markdown;
my $expected;
my $inout = 0;
foreach my $l (@data) {
    if ($l =~ /^__END__/) {
        $inout++;
        next;
    }
    if ($inout) {
        $expected .= $l;
        next;
    }
    $markdown .= $l;
} 

my $m = Text::MultiMarkdown->new;
my $out = $m->markdown($markdown);
#$out =~ s/ /&nbsp;/g;
#$expected =~ s/ /&nbsp;/g;
is($out, $expected, 'Output matches expected');

if ($out ne $expected) {
    open(OUT, '>', "/tmp/markdowntest.$$.out");
    open(EXP, '>', "/tmp/markdowntest.$$.exp");
    print OUT $out;
    print EXP $expected;
    close(OUT);
    close(EXP);
    system("diff -u /tmp/markdowntest.$$.exp /tmp/markdowntest.$$.out");
}

__DATA__
# Heading 1
## Heading 2
### Heading 3 ###

Other type of heading (level 2)
-------------------------------

And another one (level 1)
=========================

A paragraph, of *text*. 

  * UL item 1
  * UL item 2

Another paragraph \*Not bold text*.
  
  1. OL, item 1
  2. OL, item 2

A third paragraph

  * Second list, item 1
     * Sub list item 1
     * Sub list item 2
  * Second list, item 2

Within a paragraph `code block`, followed by one which needs ``extra escapeing` `` &copy; t0m.
& note ampersands and > or < are escaped properly in output

__END__
<h1 id="heading1">Heading 1</h1>

<h2 id="heading2">Heading 2</h2>

<h3 id="heading3">Heading 3</h3>

<h2 id="othertypeofheadinglevel2">Other type of heading (level 2)</h2>

<h1 id="andanotheronelevel1">And another one (level 1)</h1>

<p>A paragraph, of <em>text</em>. </p>

<ul>
<li>UL item 1</li>
<li>UL item 2</li>
</ul>

<p>Another paragraph *Not bold text*.</p>

<ol>
<li>OL, item 1</li>
<li>OL, item 2</li>
</ol>

<p>A third paragraph</p>

<ul>
<li>Second list, item 1
<ul>
<li>Sub list item 1</li>
<li>Sub list item 2</li>
</ul></li>
<li>Second list, item 2</li>
</ul>

<p>Within a paragraph <code>code block</code>, followed by one which needs <code>extra escapeing`</code> &#xA9; t0m.
&amp; note ampersands and > or &lt; are escaped properly in output</p>
