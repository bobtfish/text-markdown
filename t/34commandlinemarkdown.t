use strict;
use warnings;
use FindBin qw($Bin);
use Test::More tests => 2;
use Test::Exception;

my $filename = "$Bin/Markdown-from-MDTest1.1.mdtest/Markdown_Documentation_-_Syntax";
unshift(@ARGV, "$filename.text");
open my $file, '<', "$filename.xhtml" or die "Couldn't open $filename: $!";
my $expected = do { local $/; <$file> };

lives_ok {
    require "$Bin/../script/Markdown.pl";
} 'require Markdown.pl works';
my $out = main();
is($out, $expected, 'Markdown.pl does the right thing with the syntax guide');
