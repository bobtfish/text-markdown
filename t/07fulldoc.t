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
    eval {
        require Text::Diff;
    };
    if (!$@) {
        print "=" x 80 . "\nDIFFERENCES:\n";
        print Text::Diff::diff(\$expected => \$out,{ STYLE => "Unified" });
    }
    else {
        warn("Install Text::Diff for more helpful failure message! ($@)");
    }
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
& note **ampersands** and > or < _are_ escaped __properly__ in output

[testlink]: http://www.test.com/ "Test dot Com website"

[testlink2]: http://www.test2.com/

This paragraph has [a link] [testlink] and [another link] [testlink2].. This is [an example](http://example.com/ "Title") inline link.

[Google]: http://google.com/

Or, we could use <http://wuto-links.com/>. Or shortcut links like this: [Google][]

> block quoted text
>
> in multiple paragraphs
> and across multiple lines
>
> > and at
>> multiple levels.

    This is a code block here...
    
* * *

*****

- - -

un*fucking*believable - \*this text is surrounded by literal asterisks\*, but the text before that should be bold according to the docs, but isn't FIXME!

![Alt text](/path/to/img.jpg)

![Alt text2](/path/to/img2.jpg "Optional title")

[img]: url/to/image  "Optional title attribute"

![Alt text for ref mode][img]

---------------------------------------
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
&amp; note <strong>ampersands</strong> and > or &lt; <em>are</em> escaped <strong>properly</strong> in output</p>

<p>This paragraph has <a href="http://www.test.com/" title="Test dot Com website">a link</a> and <a href="http://www.test2.com/">another link</a>.. This is <a href="http://example.com/" title="Title">an example</a> inline link.</p>

<p>Or, we could use <a href="http://wuto-links.com/">http://wuto-links.com/</a>. Or shortcut links like this: <a href="http://google.com/">Google</a></p>

<blockquote>
  <p>block quoted text</p>
  
  <p>in multiple paragraphs
  and across multiple lines</p>
  
  <blockquote>
    <p>and at
    multiple levels.</p>
  </blockquote>
</blockquote>

<pre><code>This is a code block here...
</code></pre>

<hr />

<hr />

<hr />

<p>un*fucking*believable - *this text is surrounded by literal asterisks*, but the text before that should be bold according to the docs, but isn't FIXME!</p>

<p><img src="/path/to/img.jpg" alt="Alt text" id="alttext" /></p>

<p><img src="/path/to/img2.jpg" alt="Alt text2" title="Optional title" id="alttext2" /></p>

<p><img src="url/to/image" alt="Alt text for ref mode" title="Optional title attribute" id="alttextforrefmode" /></p>

<hr />
