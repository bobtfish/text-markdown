# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Text-Markdown';
author          'Tomas Doran <bobtfish@bobtfish.net>';
license         'bsd';
all_from        'lib/Text/Markdown.pm';
resources repository => 'http://svn.kulp.ch/cpan/text_multimarkdown';

# Specific dependencies
perl_version    '5.008';
requires        'Digest::MD5'     => undef;
requires        'Text::Balanced'  => undef;
requires        'Encode'          => undef;
build_requires  'Test::More'      => '0.42';
build_requires  'Test::Exception' => undef;
build_requires  'List::MoreUtils' => undef;
build_requires  'File::Slurp'     => '9999.08';
build_requires  'FindBin'         => undef;

# Scripts I install
prompt_script('script/Markdown.pl');
prompt_script('script/MultiMarkdown.pl');

WriteAll;
