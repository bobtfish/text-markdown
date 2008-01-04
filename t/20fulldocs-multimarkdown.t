use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use List::MoreUtils qw(uniq);
use File::Slurp qw(slurp);

### Generate difftest subroutine, pretty prints diffs if you have Text::Diff, use uses
### Test::More::is otherwise.

eval {
    require Text::Diff;
};
if (!$@) {
    *difftest = sub {
        my ($got, $expected, $testname) = @_;
        if ($got eq $expected) {
            pass($testname);
            return;
        }
        print "=" x 80 . "\nDIFFERENCES: + = processed version from .text, - = template from .html\n";
        print Text::Diff::diff(\$expected => \$got, { STYLE => "Unified" }) . "\n";
        fail($testname);
    };
}
else {
    warn("Install Text::Diff for more helpful failure message! ($@)");
    *difftest = \&Test::More::is;
}

### Actual code for this test - unless(caller) stops it
### being run when this file is required by other tests

unless (caller) {
    my $docsdir = "$Bin/docs-multimarkdown";
    my @files = get_files($docsdir);

    plan tests => scalar(@files) + 2;

    use_ok('Text::MultiMarkdown');

    my $m = Text::MultiMarkdown->new(
        use_metadata  => 1,
    );
    {
        my $has_warned = 0;
        local $SIG{__WARN__} = sub {
            $has_warned++;
            warn(@_);
        };
        run_tests($m, $docsdir, @files);
        is($has_warned, 0, 'No warnings expected');
    };
}

sub get_files {
    my ($docsdir) = @_;
    my $DH;
    opendir($DH, $docsdir) or die("Could not open $docsdir");
    my @files = uniq map { s/\.(html|text)$// ? $_ : (); } readdir($DH);
    closedir($DH);
    return @files;
}

sub run_tests {
    my ($m, $docsdir, @files) = @_;
    foreach my $test (@files) {
        my ($input, $output);
        eval {
            $output = slurp("$docsdir/$test.html");
            $input  = slurp("$docsdir/$test.text");
        };
        $input .= "\n\n";
        $output .= "\n\n";
        if ($@) {
            fail("1 part of test file not found: $@");
            next;
        }
        $output =~ s/\s+\z//; # trim trailing whitespace
        my $processed = $m->markdown($input);
        $processed =~ s/\s+\z//; # trim trailing whitespace
    
        # Un-comment for debugging if you have space diffs you can't see..
        #$output =~ s/ /&nbsp;/g;
        #$output =~ s/\t/&tab;/g;
        #$processed =~ s/ /&nbsp;/g;
        #$processed =~ s/\t/&tab;/g;
        
        difftest($processed, $output, "Docs test: $test");
    }
}

1;