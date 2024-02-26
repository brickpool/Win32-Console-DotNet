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
    'Class::Method::Modifiers'  => '2.11',
    'Class::Tiny'               => '1.000',
    'Class::Tiny::Antlers'      => '0.024',
    'constant'                  => '1.27',
    'Devel::StrictMode'         => '0.003',
    'English'                   => '1.06_01',
    'List::Util'                => '0.204',
    'namespace::sweep'          => '0.006',
    'PerlX::Assert'             => '0.905',
    'Type::Nano'                => '0.014',
    'Win32'                     => '0.54',
    'Win32::API'                => '0.79',
    'Win32::Console'            => '0.10',
    'Win32API::File'            => '0.1201',
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
