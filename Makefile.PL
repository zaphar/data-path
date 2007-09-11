use inc::Module::Install;

name            'Data-Path';
perl_version    '5.006';

all_from        'lib/Data/Path.pm';

requires            'Carp'              => '0';
requires            'Scalar::Util'      => '0';

build_requires      'Test::More'        => '0.7';
build_requires      'Test::MockObject'  => '1.08';

WriteAll;
