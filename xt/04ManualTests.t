# https://github.com/dotnet/runtime/blob/116f5fd624c6981a66c2a03c5ea5f8fa037ef57f/src/libraries/System.Console/tests/ManualTests/ManualTests.cs
# For verifying console functionality that cannot be run as fully automated.
# To run the suite, enable the manual testing by defining the 'MANUAL_TESTS' environment variable.

use 5.014;
use warnings;

use Test::More;
use Test::Exception;

use POSIX;

BEGIN {
  unless ( $^O eq 'MSWin32' ) {
    plan skip_all => 'This is not MSWin32';
  }
  else {
    plan tests => 26;
  }
}

# Fix STDOUT redirection from prove
POSIX::dup2(fileno(STDERR), fileno(STDOUT));

package ConsoleManualTests {
  use 5.014;
  use warnings;

  require bytes;
  use PerlX::Assert -check;
  use Test::More;
  use Time::HiRes;
  use Win32;
  use Win32::Console;
  use Win32API::File;

  BEGIN {
    use_ok 'Win32::Console::DotNet';
    require_ok 'System';
    require_ok 'ConsoleColor';
    require_ok 'ConsoleKey';
    require_ok 'ConsoleModifiers';
  }

  use Exporter qw( import );
  our @EXPORT = qw( 
    FALSE
    TRUE
    ManualTestsEnabled
    ReadLine
    ReadLineFromOpenStandardInput
    ReadFromOpenStandardInput
    ConsoleReadSupportsBackspace
    ReadLine_BackSpaceCanMoveAcrossWrappedLines
    InPeek
    Beep
    ReadKey
    ReadKeyNoIntercept
    EnterKeyIsEnterAfterKeyAvailableCheck
    ReadKey_KeyChords
    GetKeyChords
    ConsoleOutWriteLine
    KeyAvailable
    Clear
    Colors
    CursorPositionAndArrowKeys
    EncodingTest
    CursorLeftFromLastColumn
    ResizeTest
  );

  use constant ManualTestsEnabled => $ENV{"MANUAL_TESTS"};

  use constant FALSE  => !!'';
  use constant TRUE   => !!1;

  use Class::Struct CONSOLE_SCREEN_BUFFER_INFO => [
    dwSizeX               => '$',
    dwSizeY               => '$',
    dwCursorPositionX     => '$',
    dwCursorPositionY     => '$',
    wAttributes           => '$',
    srWindowLeft          => '$',
    srWindowTop           => '$',
    srWindowRight         => '$',
    srWindowBottom        => '$',
    dwMaximumWindowSizeX  => '$',
    dwMaximumWindowSizeY  => '$',
  ];

  sub ReadLine { # void ($consoleIn)
    my ($consoleIn) = @_;
    my $expectedLine = "This is a test of Console->".($consoleIn ? "In->" : "")."ReadLine.";
    System::Console->WriteLine("Please type the sentence (without the quotes): \"$expectedLine\"");
    my $result = $consoleIn ? System::Console->In->getline() : System::Console->ReadLine();
    assert 'Equal' { index($result, $expectedLine) == 0 };
    AssertUserExpectedResults("the characters you typed properly echoed as you typed");
    return;
  }

  sub ReadLineFromOpenStandardInput { # void ()
    my $expectedLine = "aab";

    # Use Console->ReadLine
    System::Console->WriteLine("Please type 'a' 3 times, press 'Backspace' to erase 1, then type a single 'b' and press 'Enter'.");
    my $result = System::Console->ReadLine();
    assert 'Equal' { index($result, $expectedLine) == 0 };
    AssertUserExpectedResults("the characters you typed properly echoed as you typed");

    # getline from Console->OpenStandardInput
    System::Console->WriteLine("Please type 'a' 3 times, press 'Backspace' to erase 1, then type a single 'b' and press 'Enter'.");
    my $reader = System::Console->OpenStandardInput();
    $result = $reader->getline();
    assert 'Equal' { index($result, $expectedLine) == 0 };
    AssertUserExpectedResults("the characters you typed properly echoed as you typed");
  }

  sub ReadFromOpenStandardInput { # void ()
    # The implementation in StdInReader uses a StringBuilder for caching. We want this builder to use
    # multiple chunks. So the expectedLine is longer than 16 characters (StringBuilder.DefaultCapacity).
    my $expectedLine = "This is a test for ReadFromOpenStandardInput.";
    assert 'True' { length($expectedLine) > 16 };
    System::Console->WriteLine("Please type the sentence (without the quotes): \"$expectedLine\"");
    my $inputStream = System::Console->OpenStandardInput();
    for (my $i = 0; $i < length($expectedLine); $i++) {
      assert 'Equal' { bytes::substr($expectedLine, $i, 1) eq ($inputStream->sysread($_, 1) ? $_ : '') };
    }
    assert 'Equal' { "\n" eq ($inputStream->read($_, 1) ? $_ : '') };
    AssertUserExpectedResults("the characters you typed properly echoed as you typed");
  }

  sub ConsoleReadSupportsBackspace { # void ()
    my $expectedLine = "aab\n";

    System::Console->WriteLine("Please type 'a' 3 times, press 'Backspace' to erase 1, then type a single 'b' and press 'Enter'.");
    foreach my $c ( split //, $expectedLine ) {
      my $ch = System::Console->Read();
      assert 'Equal' { $c eq chr $ch };
    }
    AssertUserExpectedResults("the characters you typed properly echoed as you typed");
  }

  sub ReadLine_BackSpaceCanMoveAcrossWrappedLines { # void ()
    System::Console->WriteLine("Please press 'a' until it wraps to the next terminal line, then press 'Backspace' until the input is erased, and then type a single 'a' and press 'Enter'.");
    System::Console->Write("Input: ");
    System::Console->Out->flush();

    my $result = System::Console->ReadLine();
    assert 'Equal' { "a" eq $result };
    AssertUserExpectedResults("the previous line is 'Input: a'");
  }

  sub InPeek { # void ()
    System::Console->WriteLine("Please type \"peek\" (without the quotes). You should see it as you type:");
    foreach my $c ( 'p', 'e', 'e', 'k' ) {
      assert 'Equal' { $c eq System::Console->In->Peek() };
      assert 'Equal' { $c eq System::Console->In->Peek() };
      assert 'Equal' { $c eq System::Console->In->Peek() };
    }
    System::Console->In->getline(); # enter
    AssertUserExpectedResults("the characters you typed properly echoed as you typed");
  }

  sub Beep { # void ()
    System::Console->Beep();
    AssertUserExpectedResults("hear a beep");
  }

  sub ReadKey { # void ()
    System::Console->WriteLine("Please type \"console\" (without the quotes). You shouldn't see it as you type:");
    foreach my $k ( qw{ C O N S O L E } ) {
      assert 'Equal' { $k eq chr System::Console->ReadKey(TRUE())->{Key} };
    }
    AssertUserExpectedResults("\"console\" correctly not echoed as you typed it");
  }

  sub ReadKeyNoIntercept { # void ()
    System::Console->WriteLine("Please type \"console\" (without the quotes). You should see it as you type:");
    foreach my $k ( qw{ C O N S O L E } ) {
      assert 'Equal' { $k eq chr System::Console->ReadKey(FALSE())->{Key} };
    }
    AssertUserExpectedResults("\"console\" correctly echoed as you typed it");
  }

  sub EnterKeyIsEnterAfterKeyAvailableCheck() { # void ()
    System::Console->WriteLine("Please hold down the 'Enter' key for some time. You shouldn't see new lines appear:");
    my $keysRead = 0;
    while ($keysRead < 50) {
      if (System::Console->KeyAvailable) {
        my $keyInfo = System::Console->ReadKey(FALSE);
        assert 'Equal' { ConsoleKey::Enter == $keyInfo->{Key} };
        $keysRead++;
      }
    }
    while (System::Console->KeyAvailable) {
      my $keyInfo = System::Console->ReadKey(TRUE);
      assert 'Equal' { ConsoleKey::Enter == $keyInfo->{Key} };
    }
    AssertUserExpectedResults("no empty newlines appear");
  }

  sub ReadKey_KeyChords { # void ($requestedKeyChord, \%expected)
    my ($requestedKeyChord, $expected) = @_;
    System::Console->Write("Please type key chord $requestedKeyChord: ");
    my $actual = System::Console->ReadKey(TRUE);
    System::Console->WriteLine();

    assert 'Equal' { $expected->{Key} == $actual->{Key} };
    assert 'Equal' { $expected->{Modifiers} == $actual->{Modifiers} };
    assert 'Equal' { $expected->{KeyChar} eq $actual->{KeyChar} };
  }

  sub GetKeyChords { # \@ ()
    state $MkConsoleKeyInfo = sub { # \% ($requestedKeyChord, $keyChar, $consoleKey, $modifiers)
      my ($requestedKeyChord, $keyChar, $consoleKey, $modifiers) = @_;
      return {
        $requestedKeyChord => {
          Key => $consoleKey,
          KeyChar => $keyChar,
          Modifiers => $modifiers,
        },
      };
    };

    my @yield = (
      $MkConsoleKeyInfo->("Ctrl+B", "\x02", ord('B'), ConsoleModifiers::Control),
      $MkConsoleKeyInfo->("Ctrl+Alt+B", "\x00", ord('B'), ConsoleModifiers::Control | ConsoleModifiers::Alt),
      $MkConsoleKeyInfo->("Enter", "\r", ConsoleKey::Enter, 0),
    );

    if ( $^O eq 'MSWin32' ) {
      push @yield, $MkConsoleKeyInfo->("Ctrl+J", "\n", ord('J'), ConsoleModifiers::Control);
    } else {
      # Ctrl+J is mapped by every Unix Terminal as Ctrl+Enter with new line character
      push @yield, $MkConsoleKeyInfo->("Ctrl+J", "\n", ConsoleKey::Enter, ConsoleModifiers::Control);
    }

    return @yield;
  }

  sub ConsoleOutWriteLine { # void ()
    System::Console->Out->say("abcdefghijklmnopqrstuvwxyz");
    AssertUserExpectedResults("the alphabet above");
  }

  sub KeyAvailable { # void ()
    System::Console->WriteLine("Wait a few seconds, then press any key...");
    while ( System::Console->KeyAvailable ) {
      System::Console->ReadKey();
    }
    while ( !System::Console->KeyAvailable ) {
      Time::HiRes::sleep(500/1000);
      System::Console->WriteLine("\t...waiting...");
    }
    System::Console->ReadKey();
    AssertUserExpectedResults("several wait messages get printed out");
  }

  sub Clear { # void ()
    System::Console->Clear();
    AssertUserExpectedResults("the screen get cleared");
  }

  sub Colors { # void ()
    use constant squareSize => 20;
    my @colors = ( ConsoleColor::Red, ConsoleColor::Green, ConsoleColor::Blue, ConsoleColor::Yellow );
    for (my $row = 0; $row < 2; $row++) {
      for (my $i = 0; $i < int(squareSize / 2); $i++) {
        System::Console->WriteLine();
        System::Console->Write("  ");
        for (my $col = 0; $col < 2; $col++) {
          System::Console->BackgroundColor( $colors[$row * 2 + $col] );
          System::Console->ForegroundColor( $colors[$row * 2 + $col] );
          for (my $j = 0; $j < squareSize; $j++) { 
            System::Console->Write('@');
          }
          System::Console->ResetColor();
        }
      }
    }
    System::Console->WriteLine();

    AssertUserExpectedResults("a Microsoft flag in solid color");
  }

  sub CursorPositionAndArrowKeys { # void ()
    System::Console->WriteLine("Use the up, down, left, and right arrow keys to move around.  When done, press enter.");

    while (TRUE) {
      my $k = System::Console->ReadKey(TRUE);
      if ( $k->{Key} == ConsoleKey::Enter ) {
        last;
      }

      my $left = System::Console->CursorLeft; my $top = System::Console->CursorTop;
      switch: for ($k->{Key}) {
        case: $_ == ConsoleKey::UpArrow and do {
          System::Console->CursorTop( $top - 1 ) if $top > 0;
          last;
        };
        case: $_ == ConsoleKey::LeftArrow and do {
          System::Console->CursorLeft( $left - 1 ) if $left > 0;
          last;
        };
        case: $_ == ConsoleKey::RightArrow and do {
          System::Console->CursorLeft( $left + 1 );
          last;
        };
        case: $_ == ConsoleKey::DownArrow and do {
          System::Console->CursorTop( $top + 1 );
          last;
        };
      }
    }

    AssertUserExpectedResults("the arrow keys move around the screen as expected with no other bad artifacts");
  }

  sub EncodingTest {
    System::Console->WriteLine(System::Console->OutputEncoding);
    System::Console->WriteLine("'\x{03A0}\x{03A3}'.");
    AssertUserExpectedResults("Pi and Sigma or question marks");
  }

  sub CursorLeftFromLastColumn {
    System::Console->WriteLine();
    System::Console->CursorLeft( System::Console->BufferWidth - 1 );
    System::Console->Write("2");
    System::Console->CursorLeft( 0 );
    System::Console->Write("1");
    System::Console->WriteLine();
    AssertUserExpectedResults("single line with '1' at the start and '2' at the end.");
  }

  sub ResizeTest { # void ()
    my $wasResized = FALSE;

    my $widthBefore = System::Console->WindowWidth;
    my $heightBefore = System::Console->WindowHeight;

    assert 'False' { !$wasResized };

    System::Console->SetWindowSize(int($widthBefore / 2), int($heightBefore / 2));

    my $manualResetEvent = eval {
      Time::HiRes::sleep(50/1000);
      my $hConsoleOutput = Win32::Console::_GetStdHandle(STD_OUTPUT_HANDLE) // -1;
      assert { $hConsoleOutput > 0 };
      my $uFileType = Win32API::File::GetFileType($hConsoleOutput) // 0;
      assert { $uFileType == Win32API::File::FILE_TYPE_CHAR };
      my @ir = Win32::Console::_GetConsoleScreenBufferInfo($hConsoleOutput);
      assert { @ir > 1 };
      my $width = $ir[7] - $ir[5] + 1;
      my $height = $ir[8] - $ir[6] + 1;
      $wasResized = $widthBefore != $width || $heightBefore != $height;
      1;
    };
    assert 'True' { $manualResetEvent };
    assert 'True' { $wasResized };
    assert 'Equal' { int($widthBefore / 2) == System::Console->WindowWidth };
    assert 'Equal' { int($heightBefore / 2) == System::Console->WindowHeight };

    System::Console->SetWindowSize($widthBefore, $heightBefore);
    return;
  }

  sub AssertUserExpectedResults { # void ($expected)
    my ($expected) = @_;
    System::Console->Write("Did you see $expected? [y/n] ");
    my $info = System::Console->ReadKey();
    System::Console->WriteLine();
  
    switch: for (chr $info->{Key}) {
      case: /^[YN]$/ and do {
        assert 'Equal' { 'Y' eq chr $info->{Key} };
        last
      };
      default: {
        AssertUserExpectedResults($expected);
        last;
      }
    }
    return;
  }

  $INC{__PACKAGE__ .'.pm'} = 1;
}

use_ok 'ConsoleManualTests';

SKIP: {
  skip 'Manual test not enabled', 20 unless ManualTestsEnabled();

  lives_ok { ReadLine(FALSE()) } 'ReadLine(FALSE)';
  lives_ok { ReadLine(TRUE()) } 'ReadLine(TRUE)';
  lives_ok { ReadLineFromOpenStandardInput() } 'ReadLineFromOpenStandardInput';
  lives_ok { ReadFromOpenStandardInput() } 'ReadFromOpenStandardInput';
  lives_ok { ConsoleReadSupportsBackspace() } 'ConsoleReadSupportsBackspace';
  lives_ok { ReadLine_BackSpaceCanMoveAcrossWrappedLines() } 'ReadLine_BackSpaceCanMoveAcrossWrappedLines';
  TODO: {
    local $TODO = "Peek() must be implemented.";
    lives_ok { InPeek() } 'InPeek';
  };
  lives_ok { Beep() } 'Beep';
  lives_ok { ReadKey() } 'ReadKey';
  lives_ok { ReadKeyNoIntercept() } 'ReadKeyNoIntercept';
  lives_ok { EnterKeyIsEnterAfterKeyAvailableCheck() } 'EnterKeyIsEnterAfterKeyAvailableCheck';
  lives_ok { ReadKey_KeyChords(each %$_) for GetKeyChords() } 'ReadKey_KeyChords';
  lives_ok { ConsoleOutWriteLine() } 'ConsoleOutWriteLine';
  lives_ok { KeyAvailable() } 'KeyAvailable';
  lives_ok { diag ''; Clear() } 'Clear';
  lives_ok { diag ''; Colors() } 'Colors';
  lives_ok { CursorPositionAndArrowKeys() } 'CursorPositionAndArrowKeys';
  lives_ok { EncodingTest() } 'EncodingTest';
  lives_ok { CursorLeftFromLastColumn() } 'CursorLeftFromLastColumn';
  lives_ok { ResizeTest() } 'ResizeTest';
};

done_testing;
