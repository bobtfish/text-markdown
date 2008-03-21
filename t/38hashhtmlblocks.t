use strict;
use warnings;
use Test::More tests => 7;

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

# If you don't close a tag, we eat the rest of the document. Not great :(
# What did this used to do?
$indoc = qq{before\n<div>foo\n\nafter};
$out = $m->_HashHTMLBlocks($indoc);
is($out, "before\n\n\n$token\n\n", 'unclosed tag (output)');
is($tomd5, "<div>foo\n\nafter",, 'unclosed tag (tomd5)');