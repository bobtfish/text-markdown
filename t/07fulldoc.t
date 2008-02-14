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

my $out = Text::MultiMarkdown::markdown($markdown);
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
> block quoted text
>
> in multiple paragraphs
> and across multiple lines
>
> > and at
>> multiple levels.
__END__
<blockquote>
  <p>block quoted text</p>
  
  <p>in multiple paragraphs
  and across multiple lines</p>
  
  <blockquote>
    <p>and at
    multiple levels.</p>
  </blockquote>
</blockquote>
