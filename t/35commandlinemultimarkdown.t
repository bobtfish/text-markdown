use strict;
use warnings;
use FindBin qw($Bin);
use File::Slurp qw(slurp);
use Test::More tests => 2;
use Test::Exception;

unshift(@ARGV, "$Bin/Text-MultiMarkdown.mdtest/Markdown_Documentation_-_Syntax.text");
my $expected = slurp("$Bin/Text-MultiMarkdown.mdtest/Markdown_Documentation_-_Syntax.xhtml");

lives_ok {
    require "$Bin/../script/MultiMarkdown.pl";
} 'require MultiMarkdown.pl works';
my $out = main();
is($out, $expected, 'MultiMarkdown.pl does the right thing with the syntax guide');