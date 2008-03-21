use strict;
use warnings;
use Test::More tests => 15;

BEGIN: {
    use_ok('Text::Markdown');
};

my $tomd5;
my $token="flibble";
my $old_md5_sub = \&Text::Markdown::_md5_utf8;
my $new_md5_sub = sub {
    $tomd5 = shift;
    return $token;
};
{
    no warnings 'redefine';
    *Text::Markdown::_md5_utf8 = $new_md5_sub;
}

my $m = Text::Markdown->new;

# Check basic case works.
my $indoc = qq{<div>\nfoo\n</div>\n};
my $out = $m->_HashHTMLBlocks($indoc);
is($out, "\n\n$token\n\n\n", 'basic case (output)');
is($tomd5, "<div>\nfoo\n</div>", 'basic case (tomd5)');

# Check leading space on the line is stripped.
$indoc = qq{before\n  <div>\nfoo\n  </div>\n};
$out = $m->_HashHTMLBlocks($indoc);
is($out, "before\n\n\n$token\n\n\n", 'leading space on line stripped (output)');
is($tomd5, "<div>\nfoo\n  </div>", 'leading space on line (tomd5)');

# If you don't close a tag, it's output verbatim.. Not great :(
$tomd5 = 'foobarbaz';
$indoc = qq{before\n<div>foo\n\nafter};
$out = $m->_HashHTMLBlocks($indoc);
is($out, $indoc, 'unclosed tag (output verbatim)');
is($tomd5, 'foobarbaz', 'unclosed tag (tomd5 not called)');

# Check however that a non-closed tag doesn't stop us working for the rest of the document
$indoc = qq{<div id='1'>\nbefore\n<div id='2'>foo\n\nafter</div>};
$out = $m->_HashHTMLBlocks($indoc);
is($out, "<div id='1'>\nbefore\n\n\n$token\n\n", 'unclosed tag followed by normal (unclosed output verbatim, rest fine)');
is($tomd5, "<div id='2'>foo\n\nafter</div>", 'unclosed tag (tomd5 called for 2nd tag pair)');

# Test a self closing tag, these are output verbatim (crap..)
$indoc = qq{<div />};
$tomd5 = 'quux';
$out = $m->_HashHTMLBlocks($indoc);
is($out, $indoc, 'self closed tag');
is($tomd5, "quux", 'self closed tag never gets md5d');

# This is what I think should happen
{
    local $TODO = 'This would be better behavior';
    $out = $m->_HashHTMLBlocks($indoc);
    is($out, "\n\n$token\n\n", 'self closed tag');
    is($tomd5, "<div />", 'self closed tag never gets md5d');
}

# Check what happens when you have 2 runs back to back.
my $callcounter = 0;
{
    no warnings 'redefine'; 
    *Text::Markdown::_md5_utf8 = sub {
        $callcounter++;
        $new_md5_sub->(@_);
    };
}
$indoc = qq{<div>bazquux</div><div>\nfoobar\n</div>\n};
$out = $m->_HashHTMLBlocks($indoc);
is($callcounter, 2, 'md5 called twice for 2 tag blocks');
is($out, "\n\n$token\n\n\n\n$token\n\n\n", 'run together HTML blocks output');
