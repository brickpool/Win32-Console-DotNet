use 5.014;
use warnings;

use Test::More;
use Test::Exception;
use Devel::StrictMode;

BEGIN {
  unless ( $^O eq 'MSWin32' ) {
    plan skip_all => 'This is not MSWin32';
  }
  else {
    plan tests => 41;
  }
}

BEGIN {
  use_ok 'Win32::Console';
  use_ok 'Win32::Console::More';
  use_ok 'Win32::Console::DotNet';
}

#-------------------
note 'Constructors';
#-------------------

my $console = System::Console->instance();
isa_ok(
  $console,
  System::Console->FACTORY
);

#----------------
note 'Properties';
#----------------

is(
  $console->BackgroundColor,
  $BG_BLACK,
  'Console->BackgroundColor'
);

cmp_ok(
  $console->BufferHeight, '>', '0',
  'Console->BufferHeight'
);

cmp_ok(
  $console->BufferWidth, '>', '0',
  'Console->BufferWidth'
);

lives_ok(
  sub { $console->CapsLock },
  'Console->CapsLock'
);

cmp_ok(
  $console->CursorLeft, '>=', '0',
  'Console->CursorLeft'
);

ok(
  ($console->CursorSize >= 0 && $console->CursorSize <= 100),
  'Console->CursorSize'
);

cmp_ok(
  $console->CursorTop, '>=', '0',
  'Console->CursorTop'
);

lives_ok(
  sub { $console->CursorVisible(1) },
  'Console->CursorVisible'
);

ok(
  defined($console->Error),
  'Console->Error'
);

is(
  $console->ForegroundColor,
  $FG_LIGHTGRAY,
  'Console->ForegroundColor'
);

ok(
  defined($console->In),
  'Console->In'
);

cmp_ok(
  $console->InputEncoding, '>', '0',
  'Console->InputEncoding'
);

lives_ok(
  sub { $console->IsErrorRedirected },
  'Console->IsErrorRedirected'
);

lives_ok(
  sub { $console->IsInputRedirected },
  'Console->IsInputRedirected'
);

lives_ok(
  sub { $console->IsOutputRedirected },
  'Console->IsOutputRedirected'
);

lives_ok(
  sub { $console->KeyAvailable },
  'Console->KeyAvailable'
);

cmp_ok(
  $console->LargestWindowHeight, '>', '0',
  'Console->LargestWindowHeight'
);

cmp_ok(
  $console->LargestWindowWidth, '>', '0',
  'Console->LargestWindowWidth'
);

lives_ok(
  sub { $console->NumberLock },
  'Console->NumberLock'
);

ok(
  defined($console->Out),
  'Console->Out'
);

cmp_ok(
  $console->OutputEncoding, '>', '0',
  'Console->OutputEncoding'
);

lives_ok(
  sub { $console->Title('Test::More') },
  'Console->Title'
);

lives_ok(
  sub { $console->TreatControlCAsInput(0) },
  'Console->TreatControlCAsInput'
);

subtest 'WindowHeight' => sub {
  plan tests => 3;
  my $height = $console->BufferHeight - 1;
  lives_ok { $height = $console->BufferHeight - 1 } 'Console->BufferHeight';
  lives_ok { $console->WindowHeight($height) } 'Console->WindowHeight';
  is $console->WindowHeight(), $height, '$height';
};

cmp_ok(
  $console->WindowLeft, '>=', '0',
  'Console->WindowLeft'
);

subtest 'WindowWidth' => sub {
  plan tests => 3;
  my $width = $console->BufferWidth - 1;
  lives_ok { $width = $console->BufferWidth - 1 } 'Console->BufferWidth';
  lives_ok { $console->WindowWidth($width) } 'Console->WindowWidth';
  is $console->WindowWidth(), $width, '$width';
};

cmp_ok(
  $console->WindowTop, '>=', '0',
  'Console->WindowTop'
);

#----------------------
note 'System::Console';
#----------------------

lives_ok(
  sub { $console->Clear() },
  'Console->Clear'
);

subtest 'ResetColor' => sub {
  plan tests => 5;
  lives_ok { $console->ForegroundColor($FG_YELLOW) } 'Console->ForegroundColor(14)';
  lives_ok { $console->BackgroundColor($BG_BLUE >> 4) } 'Console->BackgroundColor(1)';
  lives_ok { $console->ResetColor() } 'Console->ResetColor';
  is $console->ForegroundColor, $FG_LIGHTGRAY, 'Console->ForegroundColor';
  is $console->BackgroundColor, ($BG_BLACK >> 4), 'Console->BackgroundColor';
};

subtest 'SetBufferSize' => sub {
  plan tests => 3;
  my $height = $console->BufferHeight;
  my $width = $console->BufferWidth;
  lives_ok { $console->SetBufferSize($width, $height) } 'Console->SetBufferSize';
  is $console->BufferHeight, $height, 'Console->BufferHeight';
  is $console->BufferWidth, $width, 'Console->BufferWidth';
};

subtest 'SetCursorPosition' => sub {
  plan tests => 3;
  my $x = $console->CursorLeft;
  my $y = $console->CursorTop;
  lives_ok { $console->SetCursorPosition($x, $y) } 'Console->SetCursorPosition';
  cmp_ok $console->CursorLeft, '>=', $x, 'Console->CursorLeft';
  cmp_ok $console->CursorTop, '>=', $y, 'Console->CursorTop';
};

subtest 'GetCursorPosition' => sub {
  plan tests => 3;
  my ($x, $y);
  lives_ok { ($x, $y) = @{ $console->GetCursorPosition() } } 'Console->GetCursorPosition';
  ok defined($x), 'Console->CursorLeft';
  ok defined($y), 'Console->CursorTop';
};

lives_ok(
  sub { $console->Beep() },
  'Console->Beep'
);

lives_ok(
  sub { my $key = $console->Read() if STRICT },
  'Console->Read'
);

SKIP: {
  skip 'private method tests', 2 unless STRICT;

  dies_ok { $console->_init };
  dies_ok { $console->_done };

  lives_ok(
    sub {
      $console->_clear_instance();
    },
    'Console->_clear_instance'
  );
}

done_testing;
