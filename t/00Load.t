use 5.014;
use warnings;

use Test::More;

BEGIN {
  unless ( $^O eq 'MSWin32' ) {
    plan skip_all => 'This is not MSWin32';
  }
  else {
    plan tests => 1;
  }
}

use_ok 'Win32::Console::DotNet';

done_testing;
