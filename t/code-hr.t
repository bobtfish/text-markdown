use strict;
use warnings;
use Text::Markdown 'markdown';
use Test::More tests => 1;

my $txt =  markdown(<<'END_MARKDOWN', { tab_width => 2 });
This is a para.

  This is code.
  ---
  This is code.

This is a para.
END_MARKDOWN

unlike($txt, qr{<hr}, "no HR elements when the hr is in a code block");
