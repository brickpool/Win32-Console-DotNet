use 5.014;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  unless ( $^O eq 'MSWin32' ) {
    plan skip_all => 'This is not MSWin32';
  }
  else {
    plan tests => 11;
  }
}

BEGIN {
  use_ok 'Win32::Console::DotNet';
}

require_ok 'ConsoleModifiers';

lives_ok {
  no warnings 'void';
  ConsoleModifiers::elements();
  ConsoleModifiers->elements();
  (ConsoleModifiers->elements)[0]; 
} 'elements';

lives_ok {
  no warnings 'void';
  ConsoleModifiers::values();
  ConsoleModifiers->values();
  (ConsoleModifiers->values)[0]; 
} 'values';

lives_ok {
  no warnings 'void';
  ConsoleModifiers::count();
  ConsoleModifiers->count();
} 'count';

lives_ok {
  no warnings 'void';
  ConsoleModifiers::get(0);
  ConsoleModifiers->get(0);
} 'get';

is_deeply (
  [ConsoleModifiers->values], 
  [0..2,4], 
  'deeply'
);

is  ( ConsoleModifiers->Alt, 1, 'Alt'                 );
is  ( ConsoleModifiers->count, 4, 'count'             );
like( ConsoleModifiers->get(0), qr/None/, 'first'     );
like( ConsoleModifiers->get(-1), qr/Control/, 'last'  );

done_testing;
