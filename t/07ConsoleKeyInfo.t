use 5.014;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  unless ( $^O eq 'MSWin32' ) {
    plan skip_all => 'This is not MSWin32';
  }
  else {
    plan tests => 14;
  }
}

BEGIN {
  use_ok 'Win32::Console::DotNet';
}

require_ok 'ConsoleKeyInfo';

#-------------------
note 'Constructors';
#-------------------

my $cki1 = ConsoleKeyInfo->new({ Key => 1, KeyChar => "\2", Modifiers => 3 });
my $cki2 = ConsoleKeyInfo->new(1, "\2", !!1, !!1, !!0);

isa_ok $cki1, 'ConsoleKeyInfo';
isa_ok $cki2, 'ConsoleKeyInfo';
dies_ok { ConsoleKeyInfo->new() // die } 'Invalid Argument';

#----------------
note 'Properties';
#----------------

is $cki1->Key(), 1, 'ConsoleKeyInfo->Key';
is $cki1->KeyChar(), "\2", 'ConsoleKeyInfo->KeyChar';
is $cki1->Modifiers(), 3, 'ConsoleKeyInfo->Modifiers';
dies_ok { $cki1->Key(2) // die } 'Invalid Set';

#--------------
note 'Methods';
#--------------

ok $cki1->Equals($cki2), 'ConsoleKeyInfo->Equals';
lives_ok { $cki1->ToString } 'ConsoleKeyInfo->ToString';

#----------------
note 'Operators';
#----------------

ok !!($cki1 eq $cki2), 'eq';
ok  !($cki1 ne $cki2), 'ne';
like "$cki1", qr/Key/, '""';

done_testing;
