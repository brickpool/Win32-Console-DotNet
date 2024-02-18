use 5.014;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  unless ( $^O eq 'MSWin32' ) {
    plan skip_all => 'This is not MSWin32';
  }
  else {
    plan tests => 6;
  }
}

BEGIN {
  use_ok 'Win32::Native', qw(
    ERROR_INVALID_HANDLE
    VK_CAPITAL
    VK_NUMLOCK
    GetKeyState
  );
};

#----------------
note 'Constants';
#----------------

is(
  ERROR_INVALID_HANDLE,
  0x6,
  'ERROR_INVALID_HANDLE'
);

is(
  VK_CAPITAL,
  0x14,
  'VK_CAPITAL'
);

is(
  VK_NUMLOCK,
  0x90,
  'VK_NUMLOCK'
);

#----------------
note 'API calls';
#----------------

lives_ok(
  sub {
    my $lock = GetKeyState(VK_CAPITAL) & 1;
    diag sprintf("CapsLock: %s", $lock ? 'enabled' : 'disabled');
  },
  'GetKeyState(VK_CAPITAL)'
);

lives_ok(
  sub {
    my $lock = GetKeyState(VK_NUMLOCK) & 1;
    diag sprintf("NumberLock: %s", $lock ? 'enabled' : 'disabled');
  },
  'GetKeyState(VK_NUMLOCK)'
);

done_testing;
