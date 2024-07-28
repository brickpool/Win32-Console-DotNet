use 5.014;
use warnings;

use Test::More;

BEGIN {
  unless ( $^O eq 'MSWin32' ) {
    plan skip_all => 'This is not MSWin32';
  }
  else {
    plan tests => 8;
  }
}

use_ok 'Win32::Console::DotNet';
use_ok 'System';
use_ok 'Win32Native';
use_ok 'IO::DebugOutputTextWriter';
use_ok 'ConsoleColor';
use_ok 'ConsoleKey';
use_ok 'ConsoleKeyInfo';
use_ok 'ConsoleModifiers';

done_testing;
