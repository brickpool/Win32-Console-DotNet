=head1 NAME

System::Console - Win32 Console .NET interface

=cut

package System::Console;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;

use constant::boolean;
use Moo;
use namespace::autoclean 0.16;

# version '...'
our $version = 'v4.8.0';
our $VERSION = '0.001_001';
$VERSION = eval $VERSION;

# authority '...'
our $authority = 'github:microsoft';
our $AUTHORITY = 'github:brickpool';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use Devel::StrictMode;
no if !STRICT, 'warnings', 'void';

use Carp qw(
  confess 
  croak
);
use English qw( -no_match_vars );
use PerlX::Assert;
use Scalar::Util qw( isdual );
use Sub::Private;
use Win32;
use Win32::Console;
use Win32API::File qw( 
  :FILE_TYPE_
  :Misc
);

use Win32::Console::DotNet::Types qw( :all );
use Win32::Console::More qw( KEY_EVENT );
use Win32::Native qw(
  ERROR_INVALID_HANDLE

  VK_CLEAR
  VK_SHIFT
  VK_MENU
  VK_CAPITAL
  VK_PRIOR
  VK_NEXT
  VK_INSERT
  VK_NUMPAD0
  VK_NUMPAD9
  VK_NUMLOCK
  VK_SCROLL
);

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

The console is a window in which users interact with a text-based console
application by entering text input via the computer keyboard and reading text 
output from the computer terminal. 

The I<System::Console> class provides basic support for applications that read 
characters from and write characters to the console.

B<Note>: I<System::Console> is singleton a class that has represents the 
standard input, output, and error streams for console applications.

=head2 Class

public class I<< System::Console >>

Object Hierarchy

  Moo::Object
    System::Console

All Implemented Roles:

  MooX::Singleton

=cut

package System::Console {

  with 'MooX::Singleton';

  # ------------------------------------------------------------------------
  # Constants --------------------------------------------------------------
  # ------------------------------------------------------------------------

=begin private

=head2 Constants

=over

=item I<_eventType>

=item I<_keyDown>

=item I<_repeatCount>

=item I<_virtualKeyCode>

=item I<_uChar>

=item I<_controlKeyState>

=cut

  use constant _eventType       => 0;
  use constant _keyDown         => 1;
  use constant _repeatCount     => 2;
  use constant _virtualKeyCode  => 3;
  use constant _uChar           => 5;
  use constant _controlKeyState => 6;

=back

=end private

=cut

  # ------------------------------------------------------------------------
  # Variables --------------------------------------------------------------
  # ------------------------------------------------------------------------

=begin private

=head2 Variables

=over

=item I<_initialized>

  my $_initialized ( is => private, type => Bool ) = FALSE;

If true, the start settings of the console are saved and initialized.

=cut

  my $_initialized = FALSE;

=item I<_startup_input_mode>

  my $_startup_input_mode ( is => private, type => Int );

Saves the start value for the console input mode.

=cut

  my $_startup_input_mode;

=item I<_startup_output_mode>

  my $_startup_output_mode ( is => private, type => Int );

Saves the start value for the console output mode.

=cut

  my $_startup_output_mode;

=item I<_startup_info>

  my $_startup_info ( is => private, type => ArrayRef[Int] );

Saves the values of GetConsoleScreenBufferInfoEx, which are read when the 
console is started.

=cut

  my $_startup_info;

=item I<_cachedInputRecord>

  my $_cachedInputRecord ( is => private, type => ArrayRef ) = [(-1)];

For L</ReadKey>

=cut

  # ReadLine & Read can't use this because they need to use ReadFile
  # to be able to handle redirected input.  We have to accept that
  # we will lose repeated keystrokes when someone switches from
  # calling ReadKey to calling Read or ReadLine.  Those methods should 
  # ideally flush this cache as well.
  my $_cachedInputRecord = [(-1)];

=item I<_haveReadDefaultColors>

  my $_haveReadDefaultColors ( is => private, type => Bool );

For L</ResetColor>

=cut

  my $_haveReadDefaultColors;

=item I<_consoleInputHandle>

  my $_consoleInputHandle ( is => private, type => Int );

Holds the output handle of the console.

=item I<_consoleOutputHandle>

  my $_consoleOutputHandle ( is => private, type => Int );

Holds the input handle of the console.

=cut

  # About reliability: I'm not using SafeHandle here.  We don't 
  # need to close these handles, and we don't allow the user to close
  # them so we don't have many of the security problems inherent in
  # something like file handles.  Additionally, in a host like SQL 
  # Server, we won't have a console.
  my $_consoleInputHandle;
  my $_consoleOutputHandle;

=back

=end private

=cut

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Attributes

=over

=item I<BackgroundColor>

  field BackgroundColor ( is => rw, type => Int ) = 0;

A Color that specifies the background color of the console; that is, the color 
that appears behind each character.  The default is black.

I<throws> ArgumentException if the color specified in a set operation is not
valid.

=cut

  has BackgroundColor => (
    is        => 'rw',
    isa       => sub { 
      assert_Int $_[0];
      confess("ArgumentException: InvalidConsoleColor")
        if $_[0] < 0 || $_[0] > 15;
    },
    init_arg  => undef,
    default   => sub { ($BG_BLACK & 0xf0) >> 4 },
  );

  around 'BackgroundColor' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $succeeded;
      my $csbi = _GetBufferInfo(FALSE, $succeeded);

      # For code that may be used from Windows app w/ no console
      if ( !$succeeded ) {
        my $BLACK = ($BG_BLACK & 0xf0) >> 4;
        $self->$orig($BLACK);
        return $BLACK;
      }

      my $c = $csbi->{wAttributes} & 0xf0;
      my $value = _ColorAttributeToConsoleColor($c);
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      $self->$orig($value);
      my $c = _ConsoleColorToColorAttribute($value, TRUE);

      my $succeeded;
      my $csbi = _GetBufferInfo(FALSE, $succeeded);
      # For code that may be used from Windows app w/ no console
      return if !$succeeded;

      assert "Setting the background color before we've read the default background color!"
        { $_haveReadDefaultColors };

      my $attr = $csbi->{wAttributes};
      $attr &= ~0xf0;
      # Perl#'s bitwise-or.
      $attr = $attr | $c;
      # Ignore errors here - there are some scenarios for running code that 
      # wants to print in colors to the console in a Windows application.
      Win32::Console::_SetConsoleTextAttribute(_ConsoleOutputHandle(), $attr);
      return;
    }
  };

=item I<BufferHeight>

  field BufferHeight ( is => rw, type => Int );

The current height, in rows, of the buffer area.

I<throws> ArgumentOutOfRangeException if the value in a set operation is less 
than or equal to zero or greater than or equal to 0x7fff or less than 
L</WindowTop> + L</WindowHeight>.

I<throws> An I/O error occurred.

=cut

  has BufferHeight => (
    is        => 'rw',
    isa       => sub { assert_Int $_[0] },
    init_arg  => undef,
  );

  around 'BufferHeight' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = _GetBufferInfo();
      my $value = $csbi->{dwSize}->{Y};
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      $self->SetBufferSize($self->BufferWidth, $value);
      return;
    }
  };

=item I<BufferWidth>

  field BufferWidth ( is => rw, type => Int );

The current width, in columns, of the buffer area.

I<throws> ArgumentOutOfRangeException if the value in a set operation is less 
than or equal to zero or greater than or equal to 0x7fff or less than 
L</WindowLeft> + L</WindowWidth>.

=cut

  has BufferWidth => (
    is        => 'rw',
    isa       => sub { assert_Int $_[0] },
    init_arg  => undef,
  );

  around 'BufferWidth' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = _GetBufferInfo();
      my $value = $csbi->{dwSize}->{X};
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      $self->SetBufferSize($value, $self->BufferHeight);
      return;
    }
  };

=item I<CapsLock>

  field CapsLock ( is => rw, type => Bool );

Gets a value indicating whether the CAPS LOCK keyboard toggle is turned on or 
turned off.

=cut

  has CapsLock => (
    is        => 'rwp',
    isa       => sub { assert_Bool $_[0] },
    init_arg  => undef,
  );

  around 'CapsLock' => sub {
    assert { @_ == 2 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    GET: {
      my $value = (Win32::Native::GetKeyState(VK_CAPITAL) & 1) == 1;
      $self->_set_CapsLock($value);
      return $value;
    }
  };

=item I<CursorLeft>

  field CursorLeft ( is => rw, type => Int );

The column position of the cursor within the buffer area.

I<throws> ArgumentOutOfRangeException if the value in a set operation is less 
than zero or greater than or equal to L</BufferWidth>.

=cut

  has CursorLeft => (
    is        => 'rw',
    isa       => sub { assert_Int $_[0] },
    init_arg  => undef,
  );

  around 'CursorLeft' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = _GetBufferInfo();
      my $value = $csbi->{dwCursorPosition}->{X};
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      $self->SetCursorPosition($value, $self->CursorTop);
      return;
    }
  };

=item I<CursorSize>

  field CursorSize ( is => rw, type => Int );

The height of the cursor within a character cell.

The size of the cursor expressed as a percentage of the height of a character 
cell.  The property value ranges from 1 to 100.

I<throws> ArgumentOutOfRangeException if the value specified in a set operation
is less than 1 or greater than 100.

=cut

  has CursorSize => (
    is        => 'rw',
    isa       => sub { assert_Int $_[0] },
    init_arg  => undef,
  );

  around 'CursorSize' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $hConsole = _ConsoleOutputHandle();
      my ($value) = Win32::Console::_GetConsoleCursorInfo($hConsole) 
        or confess("WinIOError: $EXTENDED_OS_ERROR");
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      $self->$orig($value);
      if ( $value < 1 || $value > 100 ) {
        confess("ArgumentOutOfRangeException: value $value CursorSize");
      }
      my $hConsole = _ConsoleOutputHandle();
      my (undef, $visible) = Win32::Console::_GetConsoleCursorInfo($hConsole)
        or confess("WinIOError: $EXTENDED_OS_ERROR");
      Win32::Console::_SetConsoleCursorInfo($hConsole, $value, $visible)
        or confess("WinIOError: $EXTENDED_OS_ERROR");
      return;
    }
  };

=item I<CursorTop>

  field CursorTop ( is => rw, type => Int );

The row position of the cursor within the buffer area.

I<throws> ArgumentOutOfRangeException if the value in a set operation is less 
than zero or greater than or equal to L</BufferHeight>.

=cut

  has CursorTop => (
    is        => 'rw',
    isa       => sub { assert_Int $_[0] },
    init_arg  => undef,
  );

  around 'CursorTop' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = _GetBufferInfo();
      my $value = $csbi->{dwCursorPosition}->{Y};
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      $self->SetCursorPosition($self->CursorLeft, $value);
      return;
    }
  };

=item I<CursorVisible>

  field CursorVisible ( is => rw, type => Bool );

The attribute indicating whether the cursor is visible.

True if the cursor is visible; otherwise, false.

=cut

  has CursorVisible => (
    is        => 'rw',
    isa       => sub { assert_Bool $_[0] },
    init_arg  => undef,
  );

  around 'CursorVisible' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $hConsole = _ConsoleOutputHandle();
      my (undef, $value) = Win32::Console::_GetConsoleCursorInfo($hConsole) 
        or confess("WinIOError: $EXTENDED_OS_ERROR");
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      $self->$orig($value);
      my $hConsole = _ConsoleOutputHandle();
      my ($size) = Win32::Console::_GetConsoleCursorInfo($hConsole)
        or confess("WinIOError: $EXTENDED_OS_ERROR");
      Win32::Console::_SetConsoleCursorInfo($hConsole, $size, $value)
        or confess("WinIOError: $EXTENDED_OS_ERROR");
      return;
    }
  };

=item I<Error>

  field Error ( is => rwp, type => Win32::Console, lazy => 1, builder => 1 );

A Windows::Console object that represents the standard error stream.

=cut

  has Error => (
    is        => 'rwp',
    isa       => sub { assert_InstanceOf $_[0], 'Win32::Console'; },
    init_arg  => undef,
    lazy      => 1,
    builder   => sub {
      my $self = shift;
      my $_error = $self->OpenStandardError();
      assert "Didn't set Console::_error appropriately!" { $_error };
      return $_error;
    },
  );

=item I<ForegroundColor>

  field ForegroundColor ( is => rw, type => Int ) = $FG_LIGHTGRAY;

Color that specifies the foreground color of the console; that is, the color
of each character that is displayed.  The default is gray.

I<throws> ArgumentException if the color specified in a set operation is not 
valid.

=cut

  has ForegroundColor => (
    is        => 'rw',
    isa       => sub {
      assert_Int $_[0];
      confess("ArgumentException: InvalidConsoleColor")
        if $_[0] < 0 || $_[0] > 15;
    },
    init_arg  => undef,
    default   => sub { $FG_LIGHTGRAY },
  );

  around 'ForegroundColor' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $succeeded;
      my $csbi = _GetBufferInfo(FALSE, $succeeded);

      # For code that may be used from Windows app w/ no console
      if ( !$succeeded ) {
        $self->$orig($FG_LIGHTGRAY);
        return $FG_LIGHTGRAY;
      }

      my $c = $csbi->{wAttributes} & 0x0f;
      my $value = _ColorAttributeToConsoleColor($c);
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      $self->$orig($value);
      my $c = _ConsoleColorToColorAttribute($value, FALSE);

      my $succeeded;
      my $csbi = _GetBufferInfo(FALSE, $succeeded);
      # For code that may be used from Windows app w/ no console
      return if !$succeeded;

      assert "Setting the foreground color before we've read the default foreground color!"
        { $_haveReadDefaultColors };

      my $attr = $csbi->{wAttributes};
      $attr &= ~0x0f;
      # Perl's bitwise-or.
      $attr = $attr | $c;
      # Ignore errors here - there are some scenarios for running code that 
      # wants to print in colors to the console in a Windows application.
      Win32::Console::_SetConsoleTextAttribute(_ConsoleOutputHandle(), $attr);
      return;
    }
  };

=item I<In>

  field In ( is => rwp, type => Win32::Console, lazy => 1, builder => 1 );

A Windows::Console object that represents the standard input stream.

=cut

  has In => (
    is        => 'rwp',
    isa       => sub { assert_InstanceOf $_[0], 'Win32::Console'; },
    init_arg  => undef,
    lazy      => 1,
    builder   => sub { 
      my $self = shift;
      my $_in = $self->OpenStandardInput();
      return $_in;
    },
  );

=item I<InputEncoding>

  field InputEncoding ( is => rw, type => Int );

Gets or sets the encoding the console uses to write input.

I<note> A get operation may return a cached value instead of the console's 
current input encoding.

=cut

  has InputEncoding => (
    is        => 'rw',
    isa       => sub { assert_Int $_[0] },
    init_arg  => undef,
    default   => sub { Win32::Console::_GetConsoleCP() },
  );

  around 'InputEncoding' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      return $self->$orig();
    }
    SET: {
      my $value = shift;
      if ( !defined $value ) {
        confess("ArgumentNullException $value");
      }
      Win32::Console::_SetConsoleCP($value)
        or confess("WinIOError: $EXTENDED_OS_ERROR");
      $self->$orig($value);
      return;
    }
  };

=item I<IsErrorRedirected>

  field IsErrorRedirected ( is => rwp, type => Bool, lazy => 1, builder => 1 );

Gets a value that indicates whether error has been redirected from the 
standard error stream.  True if error is redirected; otherwise, false.

=cut

  has IsErrorRedirected => (
    is        => 'rwp',
    isa       => sub { assert_Bool $_[0] },
    init_arg  => undef,
    lazy      => 1,
    builder   => sub {
      my $errHndle = Win32::Console::_GetStdHandle(STD_ERROR_HANDLE);
      return _IsHandleRedirected($errHndle);
    },
  );

=item I<IsInputRedirected>

  field IsInputRedirected ( is => rwp, type => Bool, lazy => 1, builder => 1 );

Gets a value that indicates whether input has been redirected from the 
standard input stream.  True if input is redirected; otherwise, false.

=cut

  has IsInputRedirected => (
    is        => 'rwp',
    isa       => sub { assert_Bool $_[0] },
    init_arg  => undef,
    lazy      => 1,
    builder   => sub {
      return _IsHandleRedirected(_ConsoleInputHandle());
    },
  );

=item I<IsOutputRedirected>

  field IsOutputRedirected ( is => rwp, type => Bool, lazy => 1, 
    builder => 1 );

Gets a value that indicates whether output has been redirected from the 
standard output stream.  True if output is redirected; otherwise, false.

=cut

  has IsOutputRedirected => (
    is        => 'rwp',
    isa       => sub { assert_Bool $_[0] },
    init_arg  => undef,
    lazy      => 1,
    builder   => sub {
      return _IsHandleRedirected(_ConsoleOutputHandle());
    },
  );

=item I<KeyAvailable>

  field KeyAvailable ( is => rwp, type => Bool );

Gets a value indicating whether a key press is available in the input stream.

=cut

  has KeyAvailable => (
    is        => 'rwp',
    isa       => sub { assert_Bool $_[0] },
    init_arg  => undef,
  );
  
  around 'KeyAvailable' => sub {
    assert { @_ == 2 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    GET: {
      if ( $_cachedInputRecord->[_eventType] == KEY_EVENT ) {
        $self->_set_KeyAvailable(TRUE);
        return TRUE;
      }

      my @ir;
      my $numEventsRead = 0;
      while (TRUE) {
        my $r = do {
          @ir = Win32::Console::_PeekConsoleInput(_ConsoleInputHandle());
          $numEventsRead = 1 if @ir > 1;
          @ir > 1;
        };
        if ( !$r ) {
          my $errorCode = Win32::GetLastError();
          if ( $errorCode == ERROR_INVALID_HANDLE ) {
            confess("InvalidOperationException: ConsoleKeyAvailableOnFile");
          }
          confess("WinIOError stdin: $EXTENDED_OS_ERROR");
        }

        if ( $numEventsRead == 0 ) {
          $self->_set_KeyAvailable(FALSE);
          return FALSE;
        }

        # Skip non key-down && mod key events.
        if ( !_IsKeyDownEvent(\@ir) || _IsModKey(\@ir) ) {
          #

          $r = do {
            @ir = Win32::Console::_ReadConsoleInput(_ConsoleInputHandle());
            $numEventsRead = 1 if @ir > 1;
            @ir > 1;
          };

          if ( !$r ) {
            confess("WinIOError: $EXTENDED_OS_ERROR");
          }
        } 
        else {
          $self->_set_KeyAvailable(TRUE);
          return TRUE;
        }
      }
    }
  };

=item I<LargestWindowHeight>

  field LargestWindowHeight ( is => rwp, type => Int );

Gets the largest possible number of console window rows, based on the current 
font and screen resolution.

=cut

  has LargestWindowHeight => (
    is        => 'rwp',
    isa       => sub { assert_Int $_[0] },
    init_arg  => undef,
  );

  around 'LargestWindowHeight' => sub {
    assert { @_ == 2 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    GET: {
      my $height;
      if ( $self->Out ) {
        assert { $self->Out->is_valid };
        (undef, $height) = $self->Out->MaxWindow()
          or warn $EXTENDED_OS_ERROR;
        $self->_set_LargestWindowHeight($height);
      } elsif ( $self->In ) {
        assert { $self->In->is_valid };
        (undef, $height) = $self->In->MaxWindow()
          or warn $EXTENDED_OS_ERROR;
        $self->_set_LargestWindowHeight($height);
      } else {
        $height = $self->$orig();
      }
      return $height;
    }
  };

=item I<LargestWindowWidth>

  field LargestWindowWidth ( is => rwp, type => Int );

Gets the largest possible number of console window columns, based on the 
current font and screen resolution.

=cut

  has LargestWindowWidth => (
    is        => 'rwp',
    isa       => sub { assert_Int $_[0] },
    init_arg  => undef,
  );

  around 'LargestWindowWidth' => sub {
    assert { @_ == 2 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    GET: {
      my $width;
      if ( $self->Out ) {
        assert { $self->Out->is_valid };
        ($width) = $self->Out->MaxWindow()
          or warn $EXTENDED_OS_ERROR;
        $self->_set_LargestWindowWidth($width);
      } elsif ( $self->In ) {
        assert { $self->In->is_valid };
        ($width) = $self->In->MaxWindow()
          or warn $EXTENDED_OS_ERROR;
        $self->_set_LargestWindowWidth($width);
      } else {
        $width = $self->$orig();
      }
      return $width;
    }
  };

=item I<NumberLock>

  field NumberLock ( is => rw, type => Bool );

Gets a value indicating whether the NUM LOCK keyboard toggle is turned on or 
turned off.

=cut

  has NumberLock => (
    is        => 'rwp',
    isa       => sub { assert_Bool $_[0] },
    init_arg  => undef,
  );

  around 'NumberLock' => sub {
    assert { @_ == 2 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    GET: {
      my $value = (Win32::Native::GetKeyState(VK_NUMLOCK) & 1) 
        == 1;
      $self->_set_NumberLock($value);
      return $value;
    }
  };

=item I<Out>

  field Out ( is => rwp, type => Win32::Console, lazy => 1, builder => 1 );

A Windows::Console object that represents the standard output stream.

=cut

  has Out => (
    is        => 'rwp',
    isa       => sub { assert_InstanceOf $_[0], 'Win32::Console'; },
    init_arg  => undef,
    lazy      => 1,
    builder   => sub {
      my $self = shift;
      my $_out = $self->OpenStandardOutput();
      assert "Didn't set Console::_out appropriately!" { $_out };
      return $_out;
    },
  );

=item I<OutputEncoding>

  field OutputEncoding ( is => rw, type => Int );

Gets or sets the encoding the console uses to write output.

I<note> A get operation may return a cached value instead of the console's 
current output encoding.

=cut

  has OutputEncoding => (
    is        => 'rw',
    isa       => sub { assert_Int $_[0] },
    init_arg  => undef,
    default   => sub { Win32::Console->_GetConsoleOutputCP() },
  );

  around 'OutputEncoding' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      return $self->$orig();
    }
    SET: {
      my $value = shift;
      if ( !defined $value ) {
        confess("ArgumentNullException $value");
      }
      if ( $self->Out && !$self->IsOutputRedirected ) {
        # Flush works also for stdout
        # https://stackoverflow.com/a/18389182
        $self->Out->Flush(); 
      }
      if ( $self->Error && !$self->IsErrorRedirected ) {
        $self->Error->Flush(); 
      }
      Win32::Console::_SetConsoleOutputCP($value)
        or confess("WinIOError: $EXTENDED_OS_ERROR");
      $self->$orig($value);
      return;
    }
  };

=item I<Title>

  field Title ( is => rw, type => Str ) = '';

The string to be displayed in the title bar of the console.  The maximum length
of the title string is 24500 characters.

I<throws> ArgumentOutOfRangeException if in a set operation, the specified 
title is longer than 24500 characters.

I<throws> Exception if in a set operation, the specified title is not a string.

=cut

  has Title => (
    is        => 'rw',
    isa       => sub { assert_Str $_[0] },
    init_arg  => undef,
    default   => sub { '' },
  );

  around 'Title' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $title = Win32::Console::_GetConsoleTitle()
        or confess("WinIOError string empty: $EXTENDED_OS_ERROR");
      $self->$orig($title);
      if ( length($title) > 24500 ) {
        confess("InvalidOperationException: ConsoleTitleTooLong");
      }
      return $title;
    }
    SET: {
      my $value = shift;
      $self->$orig($value);
      if ( length($value) > 24500 ) {
        confess("InvalidOperationException: ConsoleTitleTooLong");
      }
      Win32::Console::_SetConsoleTitle($value)
        or confess("WinIOError: $EXTENDED_OS_ERROR");
      return;
    }
  };

=item I<TreatControlCAsInput>

  field TreatControlCAsInput ( is => rw, type => Bool ) = FALSE;

Indicating whether the combination of the Control modifier key and C console 
key (Ctrl+C) is treated as ordinary input or as an interruption that is handled
by the operating system.

The attribute is true if Ctrl+C is treated as ordinary input; otherwise, false.

I<throws> Exception if unable to get or set the input mode of the console input
buffer.

=cut

  has TreatControlCAsInput => (
    is        => 'rw',
    isa       => sub { assert_Bool $_[0] },
    init_arg  => undef,
    default   => sub { FALSE },
  );

  around 'TreatControlCAsInput' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $handle = _ConsoleInputHandle();
      if ( $handle == INVALID_HANDLE_VALUE ) {
        confess("IOException: NoConsole");
      }
      my $mode = 0;
      my $r = do {
        local $_ = Win32::Console::_GetConsoleMode($handle);
        $mode = $_ || 0;
        !isdual($_);
      };
      if (!$r) {
        confess("WinIOError: $EXTENDED_OS_ERROR");
      }
      my $value = ($mode & ENABLE_PROCESSED_INPUT) == 0;
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      my $handle = _ConsoleInputHandle();
      if ( $handle == INVALID_HANDLE_VALUE ) {
        confess("IOException: NoConsole");
      }
      my $mode = 0;
      my $r = do {
        local $_ = Win32::Console::_GetConsoleMode($handle);
        $mode = $_ || 0;
        !isdual($_);
      };
      if ( $value ) {
        $mode &= ~ENABLE_PROCESSED_INPUT;
      } else {
        $mode |= ENABLE_PROCESSED_INPUT;
      }
      $r = Win32::Console::_SetConsoleMode($handle, $mode);
      if ( !$r ) {
        confess("WinIOError: $EXTENDED_OS_ERROR");
      }
      $self->$orig($value);
      return;
    }
  };

=item I<WindowHeight>

  field WindowHeight ( is => rw, type => Int );

The height of the console window measured in rows.

I<throws> ArgumentOutOfRangeException if the value is less than or equal to 0 
or the value plus L</WindowTop> is greater than or equal to 0x7fff or the 
value greater than the largest possible window height for the current screen 
resolution and console font.

I<throws> Exception if an error occurs when reading or writing information.

=cut

  has WindowHeight => (
    is        => 'rw',
    isa       => sub { assert_Int $_[0] },
    init_arg  => undef,
  );

  around 'WindowHeight' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = _GetBufferInfo();
      my $value = $csbi->{srWindow}->{Bottom} - $csbi->{srWindow}->{Top} + 1;
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      $self->SetWindowSize($self->WindowWidth, $value);
      return;
    }
  };

=item I<WindowLeft>

  field WindowLeft ( is => rw, type => Int );

The leftmost console window position measured in columns.

I<throws> ArgumentOutOfRangeException if the value is less than 0 or
as a result of the assignment, WindowLeft plus L</WindowWidth> would exceed 
L</BufferWidth>.

I<throws> Exception if an error occurs when reading or writing information.

=cut

  has WindowLeft => (
    is        => 'rw',
    isa       => sub { 
      assert_Int $_[0];
      confess('ArgumentOutOfRangeException: ' . $_[0])
        if STRICT && $_[0] < 0;
    },
    init_arg  => undef,
  );

  around 'WindowLeft' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = _GetBufferInfo();
      my $value = $csbi->{srWindow}->{Left};
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      $self->SetWindowPosition($value, $self->WindowTop);
      return;
    }
  };

=item I<WindowTop>

  field WindowTop ( is => rw, type => Int );

The uppermost console window position measured in rows.

I<throws> ArgumentOutOfRangeException if the value is less than  0 or
as a result of the assignment, WindowTop plus L</WindowHeight> would exceed 
L</BufferHeight>.

I<throws> Exception if an error occurs when reading or writing information.

=cut

  has WindowTop => (
    is        => 'rw',
    isa       => sub { assert_Int $_[0] },
    init_arg  => undef,
  );

  around 'WindowTop' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = _GetBufferInfo();
      my $value = $csbi->{srWindow}->{Top};
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      $self->SetWindowPosition($self->WindowLeft, $value);
      return;
    }
  };

=item I<WindowWidth>

  field WindowWidth ( is => rw, type => Int );

The width of the console window measured in columns.

I<throws> ArgumentOutOfRangeException if the value is less than or equal to 0 
or the value plus L</WindowLeft> is greater than or equal to 0x7fff or the 
value greater than the largest possible window width for the current screen 
resolution and console font.

I<throws> Exception if an error occurs when reading or writing information.

=cut

  has WindowWidth => (
    is        => 'rw',
    isa       => sub { assert_Int $_[0] },
    init_arg  => undef,
  );

  around 'WindowWidth' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = _GetBufferInfo();
      my $value = $csbi->{srWindow}->{Right} - $csbi->{srWindow}->{Left} + 1;
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      $self->SetWindowSize($value, $self->WindowHeight);
      return;
    }
  };

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => __PACKAGE__;

=head2 Constructors

=over

=item I<new>

  factory new() : System::Console

Public constructor.

=item I<instance>

  factory instance() : System::Console

This constructor instantiates an object instance if none exists, otherwise it
returns an existing instance.

It is used to initialize the default I/O console.

=cut

  sub BUILD {
    assert { @_ >= 2 };
    assert { is_Object $_[0] };

    _init();
    return;
  }

=back

=cut

  # ------------------------------------------------------------------------
  # Destructors ------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Destructors

=over

=item I<DEMOLISH>

  method DEMOLISH()

Restore the console before destroying the instance/object.

=cut

  sub DEMOLISH {
    assert { @_ >= 1 };
    assert { is_Object $_[0] };

    _done();
    return;
  }

=back

=cut

  # ------------------------------------------------------------------------
  # Methods ----------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Methods

=over

=item I<Beep>

  method Beep()

Plays the sound of a beep through the console speaker.

  method Beep(Int frequency, Int duration)

Plays the sound of a beep of a specified frequency and duration through the 
console speaker.

I<param> $frequency of the beep, ranging from 37 to 32767 hertz.

I<param> $duration of the beep measured in milliseconds.

I<throws> ArgumentOutOfRangeException if $frequency is less than 37 or more 
than 32767 hertz or $duration is less than or equal to zero.

=cut

  sub Beep {
    assert { @_ == 1 || @_ == 3 };
    my $self = assert_Object shift;
    my $frequency = 800;
    my $duration = 200;
    $frequency = assert_Int shift if @_ == 3;
    $duration = assert_Int shift if @_ == 3;

    if ($frequency < 0x25 || $frequency > 0x7fff) {
      confess("ArgumentOutOfRangeException: frequency $frequency BeepFrequency");
    }
    if ($duration <= 0) {
      confess("ArgumentOutOfRangeException: duration $duration NeedPosNum");
    }

    # Note that Beep over Remote Desktop connections does not currently
    # work.  Ignore any failures here.
    Win32::Native::Beep($frequency, $duration);
    return;
  }

=item I<Clear>

  method Clear()

Clears the console buffer and corresponding console window of display 
information.

I<throws> IOException if an I/O error occurred.

=cut

  sub Clear {
    assert { @_ == 1 };
    my $self = assert_Object shift;

    my $coordScreen = { X => 0, Y => 0 };
    my $csbi;
    my $conSize;
    my $success;

    my $hConsole = _ConsoleOutputHandle();
    if ( $hConsole == INVALID_HANDLE_VALUE ) {
      confess("IOException: NoConsole");
    }

    # get the number of character cells in the current buffer
    # Go through my helper method for fetching a screen buffer info
    # to correctly handle default console colors.
    $csbi = _GetBufferInfo();
    $conSize = $csbi->{dwSize}->{X} * $csbi->{dwSize}->{Y};

    # fill the entire screen with blanks

    my $numCellsWritten = 0;
    $success = do {
      $numCellsWritten = Win32::Console::_FillConsoleOutputCharacter($hConsole,
        ' ', $conSize, $coordScreen->{X}, $coordScreen->{Y});
      $numCellsWritten > 0;
    };
    if (!$success) {
      confess("WinIOError: $EXTENDED_OS_ERROR");
    }

    # now set the buffer's attributes accordingly

    $numCellsWritten = 0;
    $success = do {
      $numCellsWritten = Win32::Console::_FillConsoleOutputAttribute($hConsole,
        $csbi->{wAttributes}, $conSize, $coordScreen->{X}, $coordScreen->{Y});
      $numCellsWritten > 0;
    };
    if (!$success) {
      confess("WinIOError: $EXTENDED_OS_ERROR");
    }

    # put the cursor at (0, 0)

    $success = Win32::Console::_SetConsoleCursorPosition($hConsole, 
      $coordScreen->{X}, $coordScreen->{Y});
    if (!$success) {
      confess("WinIOError: $EXTENDED_OS_ERROR");
    }
    return;
  }

=item I<GetCursorPosition>

  method GetCursorPosition() : ArrayRef[Int]

Gets the position of the cursor.

I<return> the column and row position of the cursor as array reference.

=cut

  sub GetCursorPosition {
    assert { @_ == 1 };
    my $self = assert_Object shift;

    return [
      $self->CursorLeft, 
      $self->CursorTop,
    ]
  }

=item I<MoveBufferArea>

  method MoveBufferArea(Int $sourceLeft, Int $sourceTop, Int $sourceWidth, 
    Int $sourceHeight, Int $targetLeft, Int $targetTop);

Copies a specified source area of the screen buffer to a specified destination 
area.

I<param> $sourceLeft is the leftmost column of the source area.

I<param> $sourceTop is the topmost row of the source area.

I<param> $sourceWidth is the number of columns in the source area.

I<param> $sourceHeight is the number of rows in the source area.

I<param> $targetLeft is the leftmost column of the destination area.

I<param> $targetTop is the topmost row of the destination area.

I<throws> ArgumentOutOfRangeException if one or more of the parameters is less 
than zero or $sourceLeft or $targetLeft is greater than or equal to 
L</BufferWidth> or $sourceTop or $targetTop is greater than or equal to 
L</BufferHeight> or $sourceTop + $sourceHeight is greater than or equal to 
L</BufferHeight> or $sourceLeft + $sourceWidth is greater than or equal to 
L</BufferWidth>.

I<throws> IOException if an I/O error occurred.

I<note> If the destination and source parameters specify a position located 
outside the boundaries of the current screen buffer, only the portion of the 
source area that fits within the destination area is copied. That is, the 
source area is clipped to fit the current screen buffer.

The MoveBufferArea method copies the source area to the destination area. If 
the destination area does not intersect the source area, the source area is 
filled with blanks using the current foreground and background colors. 
Otherwise, the intersected portion of the source area is not filled.

  method MoveBufferArea(Int $sourceLeft, Int $sourceTop, Int $sourceWidth, 
    Int $sourceHeight, Int $targetLeft, Int $targetTop, Str $sourceChar, 
    Int $sourceForeColor, Int $sourceBackColor);

Copies a specified source area of the screen buffer to a specified destination 
area.

I<param> $sourceLeft is the leftmost column of the source area.

I<param> $sourceTop is the topmost row of the source area.

I<param> $sourceWidth is the number of columns in the source area.

I<param> $sourceHeight is the number of rows in the source area.

I<param> $targetLeft is the leftmost column of the destination area.

I<param> $targetTop is the topmost row of the destination area.

I<param> $sourceChar is the character used to fill the source area.

I<param> $sourceForeColor is the foreground color used to fill the source area.

I<param> $sourceBackColor is the background color used to fill the source area.

I<throws> ArgumentOutOfRangeException if one or more of the parameters is less 
than zero or $sourceLeft or $targetLeft is greater than or equal to 
L</BufferWidth> or $sourceTop or $targetTop is greater than or equal to 
L</BufferHeight> or $sourceTop + $sourceHeight is greater than or equal to 
L</BufferHeight> or $sourceLeft + $sourceWidth is greater than or equal to 
L</BufferWidth>.

I<throws> ArgumentException if one or both of the color parameters is not 
valid.

I<throws> IOException if an I/O error occurred.

I<note> If the destination and source parameters specify a position located 
outside the boundaries of the current screen buffer, only the portion of the 
source area that fits within the destination area is copied. That is, the 
source area is clipped to fit the current screen buffer.

The MoveBufferArea method copies the source area to the destination area. If 
the destination area does not intersect the source area, the source area is 
filled with the character specified by sourceChar, using the colors specified 
by $sourceForeColor and $sourceBackColor. Otherwise, the intersected portion of
the source area is not filled.

The MoveBufferArea method performs no operation if $sourceWidth or 
$sourceHeight is zero.

=cut

  sub MoveBufferArea {
    assert { @_ == 7 || @_ == 10 };
    my $self            = assert_Object shift;
    my $sourceLeft      = assert_Int shift;
    my $sourceTop       = assert_Int shift;
    my $sourceWidth     = assert_Int shift;
    my $sourceHeight    = assert_Int shift;
    my $targetLeft      = assert_Int shift;
    my $targetTop       = assert_Int shift;
    my $sourceChar      = @_ ? assert_Str(shift) : ' ';
    my $sourceForeColor = @_ ? assert_Int(shift) : $FG_BLACK;
    my $sourceBackColor = @_ ? assert_Int(shift) : $self->BackgroundColor;

    if ($sourceForeColor < 0 || $sourceForeColor > 15 ) {
      confess("ArgumentException: InvalidConsoleColor sourceForeColor " . 
        $sourceForeColor);
    }
    if ( $sourceBackColor < 0 || $sourceBackColor > 15 ) {
      confess("ArgumentException: InvalidConsoleColor sourceBackColor " . 
        $sourceBackColor);
    }

    my $csbi = _GetBufferInfo();
    my $bufferSize = $csbi->{dwSize};
    if ($sourceLeft < 0 || $sourceLeft > $bufferSize->{X}) {
      confess("ArgumentOutOfRangeException: sourceLeft $sourceLeft " . 
        "ConsoleBufferBoundaries");
    }
    if ($sourceTop < 0 || $sourceTop > $bufferSize->{Y}) {
      confess("ArgumentOutOfRangeException: sourceTop $sourceTop " . 
        "ConsoleBufferBoundaries");
    }
    if ($sourceWidth < 0 || $sourceWidth > $bufferSize->{X} - $sourceLeft) {
      confess("ArgumentOutOfRangeException: sourceWidth $sourceWidth " . 
        "ConsoleBufferBoundaries");
    }
    if ($sourceHeight < 0 || $sourceTop > $bufferSize->{Y} - $sourceHeight) {
      confess("ArgumentOutOfRangeException: sourceHeight $sourceHeight " . 
        "ConsoleBufferBoundaries");
    }

    # Note: if the target range is partially in and partially out
    # of the buffer, then we let the OS clip it for us.
    if ($targetLeft < 0 || $targetLeft > $bufferSize->{X}) {
      confess("ArgumentOutOfRangeException: targetLeft $targetLeft " . 
        "ConsoleBufferBoundaries");
    }
    if ($targetTop < 0 || $targetTop > $bufferSize->{Y}) {
      confess("ArgumentOutOfRangeException: targetTop $targetTop " . 
        "ConsoleBufferBoundaries");
    }

    # If we're not doing any work, bail out now (Windows will return
    # an error otherwise)
    return if $sourceWidth == 0 || $sourceHeight == 0;

    # Read data from the original location, blank it out, then write
    # it to the new location.  This will handle overlapping source and
    # destination regions correctly.

    # See the "Reading and Writing Blocks of Characters and Attributes" 
    # sample for help

    # Read the old data
    my $data = (" " x ($sourceWidth * $sourceHeight * 4));
    $bufferSize->{X} = $sourceWidth;
    $bufferSize->{Y} = $sourceHeight;
    my $bufferCoord = { X => 0, Y => 0 };
    my $readRegion = {};
    $readRegion->{Left} = $sourceLeft;
    $readRegion->{Right} = $sourceLeft + $sourceWidth - 1;
    $readRegion->{Top} = $sourceTop;
    $readRegion->{Bottom} = $sourceTop + $sourceHeight - 1;

    my $r;
    $r = Win32::Console::_ReadConsoleOutput(_ConsoleOutputHandle(), $data,
      $bufferSize->{X}, $bufferSize->{Y}, 
      $bufferCoord->{X}, $bufferCoord->{Y}, 
      $readRegion->{Left}, $readRegion->{Top}, 
      $readRegion->{Right}, $readRegion->{Bottom}
    );
    if (!$r) {
      confess("WinIOError: $EXTENDED_OS_ERROR");
    }

    # Overwrite old section
    # I don't have a good function to blank out a rectangle.
    my $writeCoord = { X => 0, Y => 0 };
    $writeCoord->{X} = $sourceLeft;
    my $c = _ConsoleColorToColorAttribute($sourceBackColor, TRUE);
    $c |= _ConsoleColorToColorAttribute($sourceForeColor, FALSE);
    my $attr = $c;
    my $numWritten;
    for (my $i = $sourceTop; $i < $sourceTop + $sourceHeight; $i++) {
      $writeCoord->{Y} = $i;
      $r = do {
        local $_ = Win32::Console::_FillConsoleOutputCharacter(
          _ConsoleOutputHandle(), $sourceChar, $sourceWidth,
          $writeCoord->{X}, $writeCoord->{Y}
        );
        $numWritten = $_ || 0;
        !isdual($_);
      };
      assert "FillConsoleOutputCharacter wrote the wrong number of chars!"
        { $numWritten == $sourceWidth };
      if (!$r) {
        confess("WinIOError: $EXTENDED_OS_ERROR");
      }
      $r = do {
        local $_ = Win32::Console::_FillConsoleOutputAttribute(
          ConsoleOutputHandle(), $attr, $sourceWidth,
          $writeCoord->{X}, $writeCoord->{Y}
        );
        $numWritten = $_ || 0;
        !isdual($_);
      };
      if (!$r) {
        confess("WinIOError: $EXTENDED_OS_ERROR");
      }
    }

    # Write text to new location
    my $writeRegion = {};
    $writeRegion->{Left} = $targetLeft;
    $writeRegion->{Right} = $targetLeft + $sourceWidth;
    $writeRegion->{Top} = $targetTop;
    $writeRegion->{Bottom} = $targetTop + $sourceHeight;

    $r = Win32::Console::_WriteConsoleOutput(
      _ConsoleOutputHandle(), $data, 
      $bufferSize->{X}, $bufferSize->{Y}, 
      $bufferCoord->{X}, $bufferCoord->{Y}, 
      $writeRegion->{Left}, $writeRegion->{Top}, 
      $writeRegion->{Right}, $writeRegion->{Bottom}
    );
    return;
  }

=item I<OpenStandardError>

  method OpenStandardError() : Win32::Console

Acquires the standard error object.

I<return> the standard error object.

=cut

  sub OpenStandardError {
    assert { @_ == 1 };
    assert { is_ClassName($_[0]) || is_Object($_[0]) };
    return Win32::Console->new(STD_ERROR_HANDLE);
  }

=item I<OpenStandardInput>

  method OpenStandardInput() : Win32::Console

Acquires the standard input object.

I<return> the standard input object.

=cut

  sub OpenStandardInput {
    assert { @_ == 1 };
    assert { is_ClassName($_[0]) || is_Object($_[0]) };
    return Win32::Console->new(STD_INPUT_HANDLE);
  }

=item I<OpenStandardOutput>

  method OpenStandardOutput() : Win32::Console

Acquires the standard output object.

I<return> the standard output object.

=cut

  sub OpenStandardOutput {
    assert { @_ == 1 };
    assert { is_ClassName($_[0]) || is_Object($_[0]) };
    return Win32::Console->new(STD_OUTPUT_HANDLE);
  }

=item I<Read>

  method Read() : Int

Reads the next character from the standard input stream.

I<return> the next character from the input stream, or negative one (-1) if 
there are currently no more characters to be read.

=cut

  sub Read {
    assert { @_ == 1 };
    my $self = assert_Object shift;
    assert { is_Object $self->In };

    my $ch = $self->In->InputChar();
    return defined($ch) ? ord($ch) : -1;
  }

=item I<ResetColor>

  method ResetColor()

Sets the foreground and background console colors to their defaults.

I<throws> IOException if an I/O error occurred.

=cut

  sub ResetColor {
    assert { @_ == 1 };
    my $self = assert_Object shift;

    my $succeeded;
    my $csbi = _GetBufferInfo(FALSE, $succeeded);
    return if !$succeeded;

    assert "Setting the color attributes before we've read the default color attributes!"
      { $_haveReadDefaultColors };
 
    my $attr = $ATTR_NORMAL;
    # Ignore errors here - there are some scenarios for running code that wants
    # to print in colors to the console in a Windows application.
    Win32::Console::_SetConsoleTextAttribute(_ConsoleOutputHandle(), $attr);
    return;
  }

=item I<ReadKey>

  method ReadKey(Bool $intercept=FALSE) : HashRef

Obtains the next character or function key pressed by the user. 
The pressed key is optionally displayed in the console window.

I<param> $intercept determines whether to display the pressed key in the 
console window. true to not display the pressed key; otherwise, false.

I<return> an HashRef that describes the console key and unicode character, if 
any, that correspond to the pressed console key.  The HashRef also describes, 
in a bitwise combination of values, whether one or more Shift, Alt, or Ctrl 
modifier keys was pressed simultaneously with the console key.

=cut

  sub ReadKey {
    assert { @_ == 1 || @_ == 2 };
    my $self = assert_Object shift;
    my $intercept = FALSE;
    $intercept = assert_Bool shift if @_ == 2;

    my @ir;
    my $numEventsRead = -1;
    my $r;

    if ( $_cachedInputRecord->[_eventType] == KEY_EVENT ) {
      # We had a previous keystroke with repeated characters.
      @ir = @$_cachedInputRecord;
      if ( $_cachedInputRecord->[_repeatCount] == 0 ) {
        $_cachedInputRecord->[_eventType] = -1;
      } else {
        $_cachedInputRecord->[_repeatCount]--; 
      }
      # We will return one key from this method, so we decrement the
      # repeatCount here, leaving the cachedInputRecord in the "queue".

    } else { # We did NOT have a previous keystroke with repeated characters:

      while (TRUE) {
        $r = do {
          @ir = Win32::Console::_ReadConsoleInput(_ConsoleInputHandle());
          $numEventsRead = 1 if @ir > 1;
          @ir > 1;
        };
        if ( !$r || $numEventsRead == 0 ) {
          # This will fail when stdin is redirected from a file or pipe.
          confess("InvalidOperationException: ConsoleReadKeyOnFile");
        }

        my $keyCode = $ir[_virtualKeyCode];

        # First check for non-keyboard events & discard them. Generally we tap 
        # into only KeyDown events and ignore the KeyUp events but it is 
        # possible that we are dealing with a Alt+NumPad unicode key sequence, 
        # the final  unicode char is revealed only when the Alt key is released
        # (i.e when  the sequence is complete). To avoid noise, when the Alt 
        # key is down, we should eat up any intermediate key strokes (from 
        # NumPad) that collectively forms the Unicode character.  

        if ( _IsKeyDownEvent(\@ir) ) {
          #
          next if $keyCode != VK_MENU;
        }

        my $ch = $ir[_uChar];

        # In a Alt+NumPad unicode sequence, when the alt key is released uChar 
        # will represent the final unicode character, we need to surface this. 
        # VirtualKeyCode for this event will be Alt from the Alt-Up key event. 
        # This is probably not the right code, especially when we don't expose 
        # ConsoleKey.Alt, so this will end up being the hex value (0x12). 
        # VK_PACKET comes very close to being useful and something that we 
        # could look into using for this purpose... 

        if ( $ch == 0 ) {
          # Skip mod keys.
          next if _IsModKey(\@ir);
        }

        # When Alt is down, it is possible that we are in the middle of a 
        # Alt+NumPad unicode sequence. Escape any intermediate NumPad keys 
        # whether NumLock is on or not (notepad behavior)
        my $key = $keyCode;
        if (_IsAltKeyDown(\@ir) && (($key >= VK_NUMPAD0 && $key <= VK_NUMPAD9)
                                || ($key == VK_CLEAR) || ($key == VK_INSERT)
                                || ($key >= VK_PRIOR && $key <= VK_NEXT))
        ) {
          next;
        }

        if ( $ir[_repeatCount] > 1 ) {
          $ir[_repeatCount]--;
          $_cachedInputRecord = \@ir;
        }
        last;
      }
    } # we did NOT have a previous keystroke with repeated characters.

    my $state = $ir[_controlKeyState];
    my $shift = ($state & SHIFT_PRESSED) != 0;
    my $alt = ($state & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED)) != 0;
    my $control = ($state & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED)) != 0;

    my $info = {
      keyChar   => chr($ir[_uChar]),
      key       => $ir[_virtualKeyCode],
      modifiers => ($shift ? 2 : 0) + ($alt ? 1 : 0) + ($control ? 4 : 0),
    };

    if ( $intercept ) {
      $self->write($ir[_uChar]);
    }
    return $info;
  }

=item I<ReadLine>

  method ReadLine() : Str

Reads the next line of characters from the standard input stream.

I<return> the next line of characters from the input stream, or undef if no 
more lines are available.

I<throws> ArgumentOutOfRangeException if number of characters in the next line 
is greater than 0x7fff.

=cut

  sub ReadLine {
    assert { @_ == 1 };
    my $self = assert_Object shift;
    assert { is_Object $self->In };

    my $str = '';
    while (TRUE) {
      my $ch = $self->In->InputChar();
      return undef unless defined $ch;
      last if $ch =~ /[\r\n]/;
      $str .= $ch;
      if (length($str) > 0x7fff) {
        confess(sprintf("ArgumentOutOfRangeException: length %d", 
          length($str)));
      }
    }
    return $str;
  }

=item I<SetBufferSize>

  method SetBufferSize(Int $width, Int $height)

Sets the height and width of the screen buffer area to the specified values.

I<param> $width of the buffer area measured in columns.

I<param> $height of the buffer area measured in rows.

=cut

  sub SetBufferSize {
    assert { @_ == 3 };
    my $self = assert_Object shift;
    my $width = assert_Int shift;
    my $height = assert_Int shift;

    my $csbi = _GetBufferInfo();
    my $srWindow = $csbi->{srWindow};
    if ( $width < $srWindow->{Right} + 1 || $width >= 0x7fff ) {
      confess("ArgumentOutOfRangeException: width $width " . 
        "ConsoleBufferLessThanWindowSize");
    }
    if ( $height < $srWindow->{Bottom} + 1 || $height >= 0x7fff ) {
      confess("ArgumentOutOfRangeException: height $height " . 
        "ConsoleBufferLessThanWindowSize");
    }
    Win32::Console::_SetConsoleScreenBufferSize(_ConsoleOutputHandle(), 
      $width, $height) or confess("WinIOError: $EXTENDED_OS_ERROR");

    $self->{BufferHeight} = $height;
    $self->{BufferWidth} = $width;
    return;
  }

=item I<SetCursorPosition>

  method SetCursorPosition(Int $left, Int $top)

Sets the position of the cursor.

I<param> $left column position of the cursor. Columns are numbered from left to
right starting at 0.

I<param> $top row position of the cursor. Rows are numbered from top to bottom 
starting at 0.

=cut

  sub SetCursorPosition {
    assert { @_ == 3 };
    my $self = assert_Object shift;
    my $left = assert_Int shift;
    my $top = assert_Int shift;

    # Note on argument checking - the upper bounds are NOT correct 
    # here!  But it looks slightly expensive to compute them.  Let
    # Windows calculate them, then we'll give a nice error message.
    if ( $left < 0 || $left >= 0x7fff ) {
      confess("ArgumentOutOfRangeException: left $left " . 
        "ConsoleBufferBoundaries");
    }
    if ( $top < 0 || $top >= 0x7fff ) {
      confess("ArgumentOutOfRangeException: top $top " . 
        "ConsoleBufferBoundaries");
    }

    my $hConsole = _ConsoleOutputHandle();
    my $r = Win32::Console::_SetConsoleCursorPosition($hConsole, $left, $top);
    if ( !$r ) {
      # Give a nice error message for out of range sizes
      my $errorCode = Win32::GetLastError();
      my $csbi = _GetBufferInfo();
      if ( $left < 0 || $left >= $csbi->{dwSize}->{X} ) {
        confess("ArgumentOutOfRangeException: left $left " . 
          "ConsoleBufferBoundaries");
      }
      if ( $top < 0 || $top >= $csbi->{dwSize}->{Y} ) {
        confess("ArgumentOutOfRangeException: top $top " . 
          "ConsoleBufferBoundaries");
      }

      confess("WinIOError: $EXTENDED_OS_ERROR");
    }

    $self->{CursorLeft} = $left;
    $self->{CursorTop} = $top;
    return;
  }

=item I<SetError>

  method SetError(Win32::Console $newError)

Sets the L</Error> attribute to the specified error L<Win32::Console> object.

I<param> $newError is an console object that was created using the 
L<Win32::Console> module.

=cut

  sub SetError {
    assert { @_ == 2 };
    my $self = assert_Object shift;
    my $newError = shift;

    if ( !defined $newError ) {
      confess("ArgumentNullException: newError");
    }
    $self->_set_Error($newError);
    return;
  }

=item I<SetIn>

  method SetIn(Win32::Console $newIn)

Sets the L</In> attribute to the specified input L<Win32::Console> object.

I<param> $newIn is an console object that was created using the 
L<Win32::Console> module.

=cut

  sub SetIn {
    assert { @_ == 2 };
    my $self = assert_Object shift;
    my $newIn = shift;

    if ( !defined $newIn ) {
      confess("ArgumentNullException: newIn");
    }
    $self->_set_In($newIn);
    return;
  }

=item I<SetOut>

  method SetOut(Win32::Console $newOut)

Sets the L</Out> attribute to the specified output L<Win32::Console> object.

I<param> $newOut is an console object that was created using the 
L<Win32::Console> module.

=cut

  sub SetOut {
    assert { @_ == 2 };
    my $self = assert_Object shift;
    my $newOut = shift;

    if ( !defined $newOut ) {
      confess("ArgumentNullException: newOut");
    }
    $self->_set_Out($newOut);
    return;
  }

=item I<SetWindowSize>

  method SetWindowSize(Int $width, Int $height)

Sets the height and width of the console window to the specified values.

I<param> $width of the console window measured in columns.

I<param> $height of the console window measured in rows.

=cut

  sub SetWindowSize {
    assert { @_ == 3 };
    my $self = assert_Object shift;
    my $width = assert_Int shift;
    my $height = assert_Int shift;

    if ( $width <= 0 ) {
      confess("ArgumentOutOfRangeException: width $width NeedPosNum");
    }
    if ( $height <= 0 ) {
      confess("ArgumentOutOfRangeException: height $height NeedPosNum");
    }
    
    # Get the position of the current console window
    my $csbi = _GetBufferInfo();
    my $r;

    # If the buffer is smaller than this new window size, resize the
    # buffer to be large enough.  Include window position.
    my $resizeBuffer = FALSE;
    my $size = {};
    $size->{X} = $csbi->{dwSize}->{X};
    $size->{Y} = $csbi->{dwSize}->{Y};
    if ( $csbi->{dwSize}->{X} < $csbi->{srWindow}->{Left} + $width ) {
      if ( $csbi->{srWindow}->{Left} >= 0x7fff - $width ) {
        confess("ArgumentOutOfRangeException: width $width " . 
          "ConsoleWindowBufferSize");
      }
      $size->{X} = $csbi->{srWindow}->{Left} + $width;
      $resizeBuffer = TRUE;
    }
    if ( $csbi->{dwSize}->{Y} < $csbi->{srWindow}->{Top} + $height ) {
      if ( $csbi->{srWindow}->{Top} >= 0x7fff - $height ) {
        confess("ArgumentOutOfRangeException: height $height " . 
          "ConsoleWindowBufferSize");
      }
      $size->{Y} = $csbi->{srWindow}->{Top} + $height;
      $resizeBuffer = TRUE;
    }
    if ( $resizeBuffer ) {
      $r = Win32::Console::_SetConsoleScreenBufferSize(_ConsoleOutputHandle(), 
        $size->{X}, $size->{Y});
      if (!$r) {
        confess("WinIOError: $EXTENDED_OS_ERROR");
      }
    }

    my $srWindow = $csbi->{srWindow};
    # Preserve the position, but change the size.
    $srWindow->{Bottom} = $srWindow->{Top} + $height - 1;
    $srWindow->{Right} = $srWindow->{Left} + $width - 1;

    $r = Win32::Console::_SetConsoleWindowInfo(_ConsoleOutputHandle(), TRUE, 
      $srWindow->{Left}, $srWindow->{Top}, 
      $srWindow->{Right}, $srWindow->{Bottom}
    );
    if ( !$r ) {
      my $errorCode = Win32::GetLastError();

      # If we resized the buffer, un-resize it.
      if ( $resizeBuffer ) {
        Win32::Console::_SetConsoleScreenBufferSize(_ConsoleOutputHandle(), 
          $csbi->{dwSize}->{X}, $csbi->{dwSize}->{Y});
      }

      # Try to give a better error message here
      my $bounds = { X => 0, Y => 0 };
      ($bounds->{X}, $bounds->{Y}) = 
        Win32::Console::_GetLargestConsoleWindowSize(_ConsoleOutputHandle());
      if ( $width > $bounds->{X} ) {
        confess("ArgumentOutOfRangeException: width $width " . 
          "ConsoleWindowSize size " . $bounds->{X});
      }
      if ( $height > $bounds->{Y} ) {
        confess("ArgumentOutOfRangeException: height $height " . 
          "ConsoleWindowSize size ", $bounds->{Y});
      }

      confess("WinIOError: " . Win32::FormatMessage($errorCode));
    }

    if ( $resizeBuffer ) {
      $self->{BufferHeight} = $size->{X};
      $self->{BufferWidth} = $size->{Y};
    }
    $self->{WindowLeft} = $srWindow->{Left};
    $self->{WindowTop} = $srWindow->{Top};
    $self->{windowRight} = $srWindow->{Right};
    $self->{windowBottom} = $srWindow->{Bottom};

    return;
  }

=item I<SetWindowPosition>

  method SetWindowPosition(Int $left, Int $top)

Sets the position of the console window relative to the screen buffer.

I<param> $left corner of the console window.

I<param> $top corner of the console window.

=cut

  sub SetWindowPosition {
    assert { @_ == 3 };
    my $self = assert_Object shift;
    my $left = assert_Int shift;
    my $top = assert_Int shift;

    # Get the size of the current console window
    my $csbi = _GetBufferInfo();

    my $srWindow = $csbi->{srWindow};

    # Check for arithmetic underflows & overflows.
    my $newRight = $left + $srWindow->{Right} - $srWindow->{Left} + 1;
    if ( $left < 0 || $newRight > $csbi->{dwSize}->{X} || $newRight < 0 ) {
      confess("ArgumentOutOfRangeException: left $left ConsoleWindowPos");
    }
    my $newBottom = $top + $srWindow->{Bottom} - $srWindow->{Top} + 1;
    if ( $top < 0 || $newBottom > $csbi->{dwSize}->{Y} || $newBottom < 0 ) {
      confess("ArgumentOutOfRangeException: top $top ConsoleWindowPos");
    }

    # Preserve the size, but move the position.
    $srWindow->{Bottom} -= $srWindow->{Top} - $top;
    $srWindow->{Right} -= $srWindow->{Left} - $left;
    $srWindow->{Left} = $left;
    $srWindow->{Top} = $top;

    my $r = Win32::Console::_SetConsoleWindowInfo(ConsoleOutputHandle(), TRUE, 
      $srWindow->{Left}, $srWindow->{Top}, 
      $srWindow->{Right}, $srWindow->{Bottom}
    );
    if (!$r) {
      confess("WinIOError: $EXTENDED_OS_ERROR");
    }

    $self->{WindowLeft} = $srWindow->{Left};
    $self->{WindowTop} = $srWindow->{Top};
    $self->{windowRight} = $srWindow->{Right};
    $self->{windowBottom} = $srWindow->{Bottom};

    return;
  }

=item I<Write>

  method Write(Str $format, Item $arg0, Item $arg1, ...)

Writes the text representation of the specified arguments to the standard 
output stream using the specified format information.

I<param> $format is a composite format string.

I<param> $arg0 is the first item to write using format.

I<param> $arg1 is the second item to write using format.

I<param> ...

I<throws> IOException if an I/O error occurred.

I<throws> ArgumentNullException if $format is undef.

I<note> thismethod does not perform any formatting of its own: It uses the 
Perl function I<sprintf>.

  method Write(Int $value)

Writes the text representation of the specified integer value to the standard 
output stream.

I<param> $value is the value to write.

I<throws> IOException if an I/O error occurred.

  method Write(String $value)

Writes the specified string value to the standard output stream.

I<param> $value is the value to write.

I<throws> IOException if an I/O error occurred.

  method Write(Object $value)

Writes the text representation of the specified object to the standard output 
stream.

I<param> $value is the value to write or undef.

I<throws> IOException if an I/O error occurred.

I<note> If $value is undef, nothing is written and no exception is thrown. 
Otherwise, the stringification method of $value is called to produce its string
representation, and the resulting string is written to the standard output 
stream.

  method Write(Num $value)

Writes the text representation of the specified floating-point value to the 
standard output stream.

I<param> $value is the value to write.

I<throws> IOException if an I/O error occurred.

  method Write(Bool $value)

Writes the text representation of the specified Boolean value to the standard 
output stream.

I<param> $value is the value to write.

I<throws> IOException if an I/O error occurred.

=cut

  sub Write {
    assert { @_ > 1 };
    my $self = assert_Object shift;

    my $str = '';
    if ( @_ > 1 ) {
      my $format = assert_Str shift;
      $str = sprintf($format, @_);
    } else {
      my $value = $_[0];
      if ( defined $value ) {
        use autodie;
        eval {
          open(my $fh, '>', \$str);
          print $fh $value;
          close $fh;
        } or do {
          confess $@;
        };
      }
    }
    $self->Out->Write($str) if $str;
    return;
  }

=item I<WriteLine>

  method WriteLine(Str $format, Item $arg0, Item $arg1, ...)

Writes the text representation of the specified objects, followed by the 
current line terminator, to the standard output stream using the specified 
format information.

I<param> $format is a composite format string.

I<param> $arg0 is the first item to write using format.

I<param> $arg1 is the second item to write using format.

I<param> ...

I<throws> IOException if an I/O error occurred.

I<throws> ArgumentNullException if $format is undef.

I<note> thismethod does not perform any formatting of its own: It uses the 
Perl function I<sprintf>.

  method WriteLine(String $value)

Writes the specified string value, followed by the current line terminator, to 
the standard output stream.

I<param> $value is the value to write.

I<throws> IOException if an I/O error occurred.

  method WriteLine(Int $value)

Writes the text representation of the specified integer value, followed by the 
current line terminator, to the standard output stream.

I<param> $value is the value to write.

I<throws> IOException if an I/O error occurred.

  method WriteLine(Num $value)

Writes the text representation of the specified floating-point value, followed 
by the current line terminator, to the standard output stream.

I<param> $value is the value to write.

I<throws> IOException if an I/O error occurred.

  method WriteLine(Bool $value)

Writes the text representation of the specified Boolean value, followed by the 
current line terminator, to the standard output stream.

I<param> $value is the value to write.

I<throws> IOException if an I/O error occurred.

  method WriteLine()

Writes the current line terminator to the standard output stream.

I<throws> IOException if an I/O error occurred.

  method WriteLine(Object $value)

Writes the text representation of the specified object, followed by the current
line terminator, to the standard output stream.

I<param> $value is the value to write or undef.

I<throws> IOException if an I/O error occurred.

I<note> If $value is undef only the line terminator is written. Otherwise, the 
stringification method of $value is called to produce its string 
representation, and the resulting string is written to the standard output 
stream.

=cut

  sub WriteLine {
    assert { @_ > 0 };
    my $self = assert_Object shift;

    $self->Write(@_) if @_;
    $self->Write("\n");
    return;
  }

  # ------------------------------------------------------------------------
  # Subroutines ------------------------------------------------------------
  # ------------------------------------------------------------------------

=begin private

=item I<_ColorAttributeToConsoleColor>

  sub _ColorAttributeToConsoleColor(Int $c) : Int

Converts the standard color index to the Wiondows color attribute.

=cut

  sub _ColorAttributeToConsoleColor($) :Private {
    assert { @_ == 1 };
    my $c = assert_Int shift;

    # Turn background colors into foreground colors.
    if (($c & 0xf0) != 0) {
      $c = $c >> 4;
    }

    return $c;
  }

=item I<_ColorAttributeToConsoleColor>

  sub _ConsoleColorToColorAttribute(Int $color, Bool $isBackground) : Int

Converts the Windows color attribute to the standard color index.

=cut

  sub _ConsoleColorToColorAttribute($$) :Private {
    assert { @_ == 2 };
    my $color = assert_Int shift;
    my $isBackground = assert_Bool shift;

    if (($color & ~0xf) != 0) {
      confess("ArgumentException: InvalidConsoleColor");
    }

    my $c = $color;

    # Make these background colors instead of foreground
    if ($isBackground) {
      $c = $c * 16;
    }
    return $c;
  }

=item I<_ConsoleInputHandle>

  sub _ConsoleInputHandle() : Int

Simplifies the use of GetStdHandle(STD_INPUT_HANDLE).

=cut

  sub _ConsoleInputHandle() :Private {
    assert { @_ == 0 };
    $_consoleInputHandle = Win32::Console::_GetStdHandle(STD_INPUT_HANDLE) 
      unless defined $_consoleInputHandle;
    return $_consoleInputHandle;
  }

=item I<_ConsoleOutputHandle>

  sub _ConsoleOutputHandle() : Int

Simplifies the use of GetStdHandle(STD_OUTPUT_HANDLE).

=cut

  sub _ConsoleOutputHandle() :Private {
    assert { @_ == 0 };
    $_consoleOutputHandle = Win32::Console::_GetStdHandle(STD_OUTPUT_HANDLE)
      unless defined $_consoleOutputHandle;
    return $_consoleOutputHandle;
  }

=item I<_GetBufferInfo>

  sub _GetBufferInfo() : HashRef
  sub _GetBufferInfo(Bool $throwOnNoConsole, Bool $succeeded) : HashRef

Simplifies the use of GetConsoleScreenBufferInfo().

=cut

  sub _GetBufferInfo(;$$) :Private {
    state $CONSOLE_SCREEN_BUFFER_INFO = {
      dwSize => {
        X => 0,
        Y => 0,
      },
      dwCursorPosition => {
        X => 0,
        Y => 0,
      },
      wAttributes => 0,
      srWindow => {
        Left    => 0,
        Top     => 0,
        Right   => 0,
        Bottom  => 0,
      },
      dwMaximumWindowSize => {
        X => 0,
        Y => 0,
      },
    };

    my ( $throwOnNoConsole, $succeeded );
    if ( @_ ) {
      assert { @_ == 2 };
      assert { is_Bool $_[0] };
      assert { is_Bool $_[1] };
      $throwOnNoConsole = $_[0];
      $succeeded = \$_[1];
    }
    else {
      assert { @_ == 0 };
      $throwOnNoConsole = TRUE;
      my $junk;
      $succeeded = \$junk;
    }

    $$succeeded = FALSE;
    my @csbi;

    my $hConsole = _ConsoleOutputHandle();
    if ( $hConsole == INVALID_HANDLE_VALUE ) {
      if ( !$throwOnNoConsole ) {
        return { %$CONSOLE_SCREEN_BUFFER_INFO };
      }
      else {
        confess("IOException: NoConsole");
      }
    }
    @csbi = Win32::Console::_GetConsoleScreenBufferInfo($hConsole);
    if ( @csbi == 0 ) {
      @csbi = Win32::Console::_GetConsoleScreenBufferInfo(
        Win32::Console::_GetStdHandle(STD_ERROR_HANDLE)
      );
      if ( @csbi == 0 ) {
        @csbi = Win32::Console::_GetConsoleScreenBufferInfo(
          Win32::Console::_GetStdHandle(STD_INPUT_HANDLE)
        );
      }
    }
    if ( @csbi == 0 ) {
      my $errorCode = Win32::GetLastError();
      if ( $errorCode == ERROR_INVALID_HANDLE && !$throwOnNoConsole) {
        return { %$CONSOLE_SCREEN_BUFFER_INFO };
      }
      confess("WinIOError: $EXTENDED_OS_ERROR");
    }

    if ( !$_haveReadDefaultColors ) {
      $ATTR_NORMAL = $csbi[4]; # wAttributes
      $_haveReadDefaultColors = TRUE;
    }

    $$succeeded = TRUE;
    return {
      dwSize => {
        X => $csbi[0],
        Y => $csbi[1],
      },
      dwCursorPosition => {
        X => $csbi[1],
        Y => $csbi[2],
      },
      wAttributes => $csbi[4],
      srWindow => {
        Left    => $csbi[5],
        Top     => $csbi[6],
        Right   => $csbi[7],
        Bottom  => $csbi[8],
      },
      dwMaximumWindowSize => {
        X => $csbi[9],
        Y => $csbi[10],
      },
    }
  }

=item I<_IsAltKeyDown>

  sub _IsAltKeyDown(ArrayRef $ir) : Bool

For tracking Alt+NumPad unicode key sequence.

=cut

  # For tracking Alt+NumPad unicode key sequence. When you press Alt key down 
  # and press a numpad unicode decimal sequence and then release Alt key, the
  # desired effect is to translate the sequence into one Unicode KeyPress. 
  # We need to keep track of the Alt+NumPad sequence and surface the final
  # unicode char alone when the Alt key is released. 
  sub _IsAltKeyDown($) :Private { 
    assert { @_ == 1 };
    my $ir = assert_ArrayRef shift;

    return ($ir->[_controlKeyState] 
      & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED)) != 0;
  }

=item I<_IsKeyDownEvent>

  sub _IsKeyDownEvent(ArrayRef $ir) : Bool

To detect pure KeyDown events.

=cut

  # Skip non key events. Generally we want to surface only KeyDown event 
  # and suppress KeyUp event from the same Key press but there are cases
  # where the assumption of KeyDown-KeyUp pairing for a given key press 
  # is invalid. For example in IME Unicode keyboard input, we often see
  # only KeyUp until the key is released.  
  sub _IsKeyDownEvent($) :Private {
    assert { @_ == 1 };
    my $ir = assert_ArrayRef shift;

    return $ir->[_eventType] == KEY_EVENT && $ir->[_keyDown];
  }

=item I<_IsHandleRedirected>

  sub _IsHandleRedirected(Int $ioHandle) : Bool

Detects if a console handle has been redirected.

=cut

  sub _IsHandleRedirected($) :Private {
    assert { @_ == 1 };
    my $ioHandle = assert_Int shift;

    assert { $ioHandle };
    assert { $ioHandle != INVALID_HANDLE_VALUE };

    # If handle is not to a character device, we must be redirected:
    my $fileType = Win32API::File::GetFileType($ioHandle) // 0;
    if ( ($fileType & FILE_TYPE_CHAR) != FILE_TYPE_CHAR ) {
      return TRUE;
    }

    # We are on a char device.
    # If GetConsoleMode succeeds, we are NOT redirected.
    my $mode;
    my $success = do {
      $mode = Win32::Console::_GetConsoleMode($ioHandle);
      !(isdual($mode) && $mode eq '');
    };
    return !$success;
  };

=item I<_IsModKey>

  sub _IsModKey(ArrayRef $ir) : Bool

Detects if the KeyEvent uses a mod key.

=cut

  sub _IsModKey($) :Private {
    assert { @_ == 1 };
    my $ir = assert_ArrayRef shift;

    # We should also skip over Shift, Control, and Alt, as well as caps lock.
    # Apparently we don't need to check for 0xA0 through 0xA5, which are keys 
    # like Left Control & Right Control. See the Microsoft 'ConsoleKey' for 
    # these values.
    my $keyCode = $ir->[_virtualKeyCode];
    return  ($keyCode >= VK_SHIFT && $keyCode <= VK_MENU) 
          || $keyCode == VK_CAPITAL 
          || $keyCode == VK_NUMLOCK 
          || $keyCode == VK_SCROLL
  }

=item I<_init>

  sub _init()

Initializes the native screen resources and saves the settings that may be 
changed by this console.

=cut

  sub _init() :Private {
    assert { @_ == 0 };

    return if $_initialized;
    eval {
      my $CONSOLE = Win32::Console->new(STD_INPUT_HANDLE);
      assert { $CONSOLE };
      assert { $CONSOLE->is_valid };
      $_startup_input_mode = $CONSOLE->Mode();

      $CONSOLE = Win32::Console->new(STD_OUTPUT_HANDLE);
      assert { $CONSOLE };
      assert { $CONSOLE->is_valid };
      $_startup_output_mode = $CONSOLE->Mode();

      my $major = (Win32::GetOSVersion())[1] // 0;
      my @info;
      if ( $major < 6 ) {
        my $hConsoleOutput = $CONSOLE->{'handle'};
        assert { $hConsoleOutput };
        assert { $hConsoleOutput != INVALID_HANDLE_VALUE };
        @info =
          Win32::Console::More::_GetConsoleScreenBufferInfoEx(
            $hConsoleOutput) 
              or confess(sprintf('Win32 API error: %s', $EXTENDED_OS_ERROR));
        assert { scalar(@info) >= 29 };
      } 
      else {
        # GetConsoleScreenBufferInfoEx is not supported
        @info = Win32::Console::_GetConsoleScreenBufferInfo($CONSOLE->{'handle'});
        assert { scalar(@info) };
      } 
      $_startup_info = \@info;

      $_initialized = TRUE;
    } or do {
      warn("$1\n") if $@ =~ /(.+?)$/m 
    };
    return;
  }

=item I<_done>

  sub _done()

Releases all native screen resources and resets the settings used by this 
console.

=cut

  sub _done() :Private {
    assert { @_ == 0 };

    return unless $_initialized;
    eval {
      my $CONSOLE = Win32::Console->new(STD_INPUT_HANDLE);
      assert { $CONSOLE };
      assert { $CONSOLE->is_valid };
      $CONSOLE->Mode($_startup_input_mode);

      $CONSOLE = Win32::Console->new(STD_OUTPUT_HANDLE);
      assert { $CONSOLE };
      assert { $CONSOLE->is_valid };
      $CONSOLE->Mode($_startup_output_mode);

      my @info = @{ $_startup_info };
      assert { scalar(@info) };
      my $major = (Win32::GetOSVersion())[1] // 0;
      if ( $major >= 6 && scalar(@info) >= 29 ) {
        my $hConsoleOutput = $CONSOLE->{'handle'};
        assert { $hConsoleOutput };
        assert { $hConsoleOutput != INVALID_HANDLE_VALUE };
        # https://stackoverflow.com/a/52227764
        $info[8] += 1;
        $info[9] += 1;
        Win32::Console::More::_SetConsoleScreenBufferInfoEx(
          $hConsoleOutput, @info)
            or confess(sprintf('Win32 API error: %s', $EXTENDED_OS_ERROR));
      }
      else {
        # SetConsoleScreenBufferInfoEx is not supported
      }

      $_initialized = FALSE;
    } or do {
      warn("$1\n") if $@ =~ /(.+?)$/m;
    };
    return;
  }

=end private

=back

=head2 Inheritance

Methods inherited from class L<Moo::Object|Moo>

  new, does, DOES, meta, BUILDARGS, FOREIGNBUILDARGS, BUILD, DEMOLISH

=cut

}

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This class provides access to the standard input, standard output
 and standard error streams

 Copyright (c) Microsoft Corporation.

 The library files are licensed under MIT licence.

 Permission is hereby granted, free of charge, to any person obtaining a
 copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

=head1 AUTHORS

=over

=item *

2024 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 DISCLAIMER OF WARRANTIES

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

L<Win32::Console>, 
L<console.cs|https://github.com/microsoft/referencesource/blob/51cf7850defa8a17d815b4700b67116e3fa283c2/mscorlib/system/console.cs>
