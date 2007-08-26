use inc::Module::Install;

name            'Data-Path';
perl_version    '5.006';

all_from        'lib/Data/Path';

build_requires  'Test::More' => '0.7';

WriteAl;
