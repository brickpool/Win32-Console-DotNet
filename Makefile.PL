use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

die "OS unsupported\n" if $^O ne 'MSWin32';

WriteMakefile(
  MIN_PERL_VERSION  => '5.014',
  PL_FILES          => {},
  LICENSE           => 'mit',
  META_MERGE  => {
    'meta-spec' => { version => 2 },
    resources   => {
      bugtracker  => {
        web => 'https://github.com/brickpool/Console/issues',
      },
      repository  => {
        type => 'git',
        url  => 'https://github.com/brickpool/Console.git',
        web  => 'https://github.com/brickpool/Console',
      },
      homepage    => 'http://brickpool.de',
    },
  },
  AUTHOR            => 'J. Schneider',
  NAME              => 'Win32::Console::DotNet',
  VERSION_FROM      => 'lib/Win32/Console/DotNet.pm',
  ABSTRACT_FROM     => 'lib/Win32/Console/DotNet.pm',
  EXE_FILES         => [],
  PREREQ_PM => {
    'B'                     => '1.42_02',
    'Carp'                  => '1.3301',
    'constant'              => '1.27',
    'constant::boolean'     => '0.02',
    'Data::Dumper'          => '2.154',
    'Devel::StrictMode'     => '0.003',
    'English'               => '1.06_01',
    'Exporter'              => '5.70',
    'Module::Runtime'       => '0.014',
    'Moo'                   => '2.004',
    'MooX::Singleton'       => '1.20',
    'namespace::autoclean'  => '0.16',
    'Package::Stash'        => '0.37',
    'PerlX::Assert'         => '0.905',
    'Ref::Util'             => '0.204',
    'Scalar::Util'          => '1.55',
    'Sub::Private'          => '0.02',
    'version'               => '0.77',
    'Win32'                 => '0.54',
    'Win32::API'            => '0.79',
    'Win32::Console'        => '0.10',
    'Win32API::File'        => '0.1201',
  },
  TEST_REQUIRES => {
    'Test::Exception' => '0.43',
    'Test::More'      => '1.001006',
  },
  dist  => {
    COMPRESS  => 'gzip',
    SUFFIX    => 'gz',
    TARFLAGS  => '--format=gnu -cvf',
  },
  clean => {
    FILES => 'Win32-Console-*',
  },
  test  => {
    TESTS => 't/*.t t/*/*.t'
  },
);
