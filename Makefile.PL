# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Text-MultiMarkdown';
author          'Darren M. Kulp <kulp@cpan.org>';
license			'bsd';
all_from        'lib/Text/MultiMarkdown.pm';

# Specific dependencies
requires        'MIME::Base64'  => '3.07';
requires        'List::Util'    => '1.18';
requires        'Digest::MD5'   => '2.36';
requires        'Scalar::Util'  => '1.18';
build_requires  'Test::More'    => '0.42';

auto_install;
WriteAll;

