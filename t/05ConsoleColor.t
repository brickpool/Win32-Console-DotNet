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

require_ok 'ConsoleColor';

lives_ok {
  no warnings 'void';
  ConsoleColor::elements();
  ConsoleColor->elements();
  (ConsoleColor->elements)[0]; 
} 'elements';

lives_ok {
  no warnings 'void';
  ConsoleColor::values();
  ConsoleColor->values();
  (ConsoleColor->values)[0]; 
} 'values';

lives_ok {
  no warnings 'void';
  ConsoleColor::count();
  ConsoleColor->count();
} 'count';

lives_ok {
  no warnings 'void';
  ConsoleColor::get(0);
  ConsoleColor->get(0);
} 'get';

is_deeply (
  [ConsoleColor->values], 
  [0..15], 
  'deeply'
);

is  ( ConsoleColor->Blue, 9, 'Blue'             );
is  ( ConsoleColor->count, 16, 'count'          );
like( ConsoleColor->get(0), qr/Black/, 'first'  );
like( ConsoleColor->get(-1), qr/White/, 'last'  );

done_testing;
