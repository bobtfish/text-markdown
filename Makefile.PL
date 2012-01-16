# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Text-Markdown';
author          'Tomas Doran <bobtfish@bobtfish.net>';
license         'bsd';
all_from        'lib/Text/Markdown.pm';

resources bugtracker => 'http://github.com/bobtfish/text-markdown/issues';
resources repository => 'http://github.com/bobtfish/text-markdown/';

# Specific dependencies
perl_version    '5.008';
requires        'Digest::MD5'     => undef;
requires        'Text::Balanced'  => undef;
requires        'Encode'          => undef;
test_requires  'Test::More'      => '0.42';
test_requires  'Test::Exception' => undef;
test_requires  'List::MoreUtils' => undef;
test_requires 'Test::Differences' => undef;
test_requires 'Test::NoWarnings' => undef;
test_requires  'FindBin'         => undef;

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Text/Markdown.pm > README")
        and die $!;
    require Module::Install::CheckConflicts;
}

check_conflicts(
    'Text::MultiMarkdown' => '1.0.27',
);

install_script 'script/Markdown.pl';

WriteAll;

