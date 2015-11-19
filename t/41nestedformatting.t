use strict;
use warnings;
use Test::More tests => 43;

use_ok( 'Text::Markdown' );

my $m  = Text::Markdown->new( emphasis_within_words => 1 );
my $md = <<"EOF";
*Em*phasis

_Em_phasis

**Em**phasis

__Em__phasis

***Em*phasis**

___Em_phasis__

***Em**phasis*

___Em__phasis_

__*Em*phasis__

**_Em_phasis**

_**Em**phasis_

*__Em__phasis*

de*em*phasise

de_em_phasise

de**em**phasise

de__em__phasise

de***em*phasise**

de___em_phasise__

de***em**phasise*

de___em__phasise_

de__*em*phasise__

de**_em_phasise**

de_**em**phasise_

de*__em__phasise*

com*plete*

com_plete_

com**plete**

com__plete__

*com**plete***

_com__plete___

**com*plete***

__com_plete___

__com*plete*__

**com_plete_**

_com**plete**_

*com__plete__*

Escape\*

\*Escape

Es\*cape

Escape\_

\_Escape

Es\_cape

EOF

my $want = <<'EOF';
<p><em>Em</em>phasis</p>

<p><em>Em</em>phasis</p>

<p><strong>Em</strong>phasis</p>

<p><strong>Em</strong>phasis</p>

<p><strong><em>Em</em>phasis</strong></p>

<p><strong><em>Em</em>phasis</strong></p>

<p><em><strong>Em</strong>phasis</em></p>

<p><em><strong>Em</strong>phasis</em></p>

<p><strong><em>Em</em>phasis</strong></p>

<p><strong><em>Em</em>phasis</strong></p>

<p><em><strong>Em</strong>phasis</em></p>

<p><em><strong>Em</strong>phasis</em></p>

<p>de<em>em</em>phasise</p>

<p>de<em>em</em>phasise</p>

<p>de<strong>em</strong>phasise</p>

<p>de<strong>em</strong>phasise</p>

<p>de<strong><em>em</em>phasise</strong></p>

<p>de<strong><em>em</em>phasise</strong></p>

<p>de<em><strong>em</strong>phasise</em></p>

<p>de<em><strong>em</strong>phasise</em></p>

<p>de<strong><em>em</em>phasise</strong></p>

<p>de<strong><em>em</em>phasise</strong></p>

<p>de<em><strong>em</strong>phasise</em></p>

<p>de<em><strong>em</strong>phasise</em></p>

<p>com<em>plete</em></p>

<p>com<em>plete</em></p>

<p>com<strong>plete</strong></p>

<p>com<strong>plete</strong></p>

<p><em>com<strong>plete</strong></em></p>

<p><em>com<strong>plete</strong></em></p>

<p><strong>com<em>plete</em></strong></p>

<p><strong>com<em>plete</em></strong></p>

<p><strong>com<em>plete</em></strong></p>

<p><strong>com<em>plete</em></strong></p>

<p><em>com<strong>plete</strong></em></p>

<p><em>com<strong>plete</strong></em></p>

<p>Escape*</p>

<p>*Escape</p>

<p>Es*cape</p>

<p>Escape_</p>

<p>_Escape</p>

<p>Es_cape</p>

EOF

my @html = split "\n\n", $want;
my @md = split "\n\n", $md;

for my $i (0..$#md){ 
    my $got = $m->markdown ($md[$i]);
    chomp $got;
    is($got, $html[$i], "Emphasis within a word works: $md[$i]");
}
