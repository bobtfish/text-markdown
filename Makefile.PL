# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Text-MultiMarkdown';
author          'Darren M. Kulp <kulp@cpan.org>';
license			'bsd';
all_from        'lib/Text/MultiMarkdown.pm';

# Specific dependencies
requires        'MIME::Base64'    => undef;
requires        'List::Util'      => undef;
requires        'Digest::MD5'     => undef;
requires        'Scalar::Util'    => undef;
build_requires  'Test::More'      => '0.42';
build_requires  'Test::Exception' => undef;
build_requires  'List::MoreUtils' => undef;
build_requires  'File::Slurp'     => undef;

auto_install;
WriteAll;

