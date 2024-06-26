=pod

=head1 NAME

Win32::Console::DotNet - Win32 Console .NET interface

=head1 SYNOPSIS

Simply integrate this module into your package or script.

  use Win32::Console::DotNet;
  System::Console->WriteLine();

  use Win32::Console::DotNet;
  # using the System namespace
  use System;
  Console->WriteLine();

=cut

package Win32::Console::DotNet;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;

use Class::Tiny::Antlers qw( -all );
use namespace::sweep;

# version '...'
our $version = 'v4.6.0';
our $VERSION = '0.002_000';
$VERSION = eval $VERSION;

# authority '...'
our $authority = 'github:microsoft';
our $AUTHORITY = 'github:brickpool';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use Devel::StrictMode;
no if !STRICT, 'warnings', qw( void );

use English qw( -no_match_vars );
use List::Util qw( max );
use PerlX::Assert;
use Win32;
use Win32::Console;
use Win32API::File;

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

  Class::Tiny::Object
    System::Console

=cut

package Win32::Console::DotNet {

  # ------------------------------------------------------------------------
  # Type Constraints -------------------------------------------------------
  # ------------------------------------------------------------------------

=begin private

=cut

  use namespace::sweep -also => [qw(
    is_Object
    is_Bool
    assert_ArrayRef
    assert_CodeRef
    assert_Str
    assert_Object
    assert_Bool
    assert_Int
  )];

=head2 Type Constraints

Basic type constraints

=over

=item <Types::Standard>

This module imports the following type constraints:

  ArrayRef
  CodeRef
  Object
  Str
  Bool
  Int

=cut

  use Type::Nano qw(
    ArrayRef
    CodeRef
    Str
    Object
    Bool
    Int
  );

=item I<is_Object>

  sub is_Object($value) : Bool

Check for a blessed object.

I<param> $value to be checked

I<return> true if $value is blessed

=cut

  sub is_Object($) {
    assert { @ == 1 };
    return Object->check($_[0]);
  }

=item I<is_Bool>

  sub is_Bool($value) : Bool

Check for a reasonable boolean value. Accepts 1, 0, the empty string and undef.

I<param> $value to be checked

I<return> true if operand is boolean

=cut

  sub is_Bool($) {
    assert { @ == 1 };
    return Bool->check($_[0]);
  }

=item I<assert_ArrayRef>

  sub assert_ArrayRef($ref) : ArrayRef

Check the array reference.

I<param> $ref to be checked

I<return> $ref if operand is an array reference

I<throw> IllegalArgumentException if the check fails

=cut

  sub assert_ArrayRef($) {
    assert { @ == 1 };
    unless ( ArrayRef->check($_[0]) ) {
      confess("IllegalArgumentException: %s", ArrayRef->get_message($_[0]));
    }
    return $_[0];
  }

=item I<assert_CodeRef>

  sub assert_CodeRef($ref) : CodeRef

Check the code reference.

I<param> $ref to be checked

I<return> $ref if operand is a code reference

I<throw> IllegalArgumentException if the check fails

=cut

  sub assert_CodeRef($) {
    assert { @ == 1 };
    unless ( CodeRef->check($_[0]) ) {
      confess("IllegalArgumentException: %s", CodeRef->get_message($_[0]));
    }
    return $_[0];
  }

=item I<assert_Str>

  sub assert_Str($value) : Str

Check the string that cannot be stringified.

I<param> $value to be checked

I<return> $value if the value is a string

I<throw> IllegalArgumentException if the check fails

=cut

  sub assert_Str($) {
    assert { @ == 1 };
    unless ( Str->check($_[0]) ) {
      confess("IllegalArgumentException: %s", Str->get_message($_[0]));
    }
    return $_[0];
  }

=item I<assert_Object>

  sub assert_Object($value) : Object

Check for a blessed object.

I<param> $value to be checked

I<return> $value if $value is blessed

I<throw> IllegalArgumentException if the check fails

=cut
  sub assert_Object($) {
    assert { @ == 1 };
    unless ( Object->check($_[0]) ) {
      confess("IllegalArgumentException: %s", Object->get_message($_[0]));
    }
    return $_[0];
  }

=item I<assert_Bool>

  sub assert_Bool($value) : Bool

Check the boolean value. Accepts 1, 0, the empty string and undef.

I<param> $value to be checked

I<return> $value if the value is boolean

I<throw> IllegalArgumentException if the check fails

=cut

  sub assert_Bool($) {
    assert { @ == 1 };
    unless ( Bool->check($_[0]) ) {
      confess("IllegalArgumentException: %s", Bool->get_message($_[0]));
    }
    return $_[0];
  }

=item I<is_Int>

  sub is_Int($value) : Bool

Check for on integer; strict constaint.

I<param> $value to be checked

I<return> true if operand is an integer

I<throw> IllegalArgumentException if the check fails

=cut

  sub assert_Int($) {
    assert { @ == 1 };
    unless ( Int->check($_[0]) ) {
      confess("IllegalArgumentException: %s", Int->get_message($_[0]));
    }
    return $_[0];
  }

=back

=end private

=cut

  # ------------------------------------------------------------------------
  # Constants --------------------------------------------------------------
  # ------------------------------------------------------------------------

=begin private

=cut

  use namespace::sweep -also => [qw(
    TRUE
    FALSE

    AltVKCode
    NumberLockVKCode
    CapsLockVKCode

    VK_CLEAR
    VK_SHIFT
    VK_PRIOR
    VK_NEXT
    VK_INSERT
    VK_NUMPAD0
    VK_NUMPAD9
    VK_SCROLL

    _eventType
    _keyDown
    _repeatCount
    _virtualKeyCode
    _virtualScanCode
    _uChar
    _controlKeyState
  )];

=end private

=head2 Constants

=over

=item <TRUE>

=item <FALSE>

  use constant {
    TRUE  => !! 1,
    FALSE => !! '',
  };

Defines TRUE and FALSE constants.

I<see> constant::boolean

=cut

  use constant {
    TRUE  => !! 1,
    FALSE => !! '',
  };

=item I<WinError.h>

  constant Win32Native::ERROR_INVALID_HANDLE = 0x6;

ERROR_INVALID_HANDLE is a predefined constant that is used to represent a value
that is passed to or returned by one or more built-in functions.

=cut

  sub Win32Native::ERROR_INVALID_HANDLE() { 0x6 };

=begin private

=item I<Winuser.h>

  use constant {
    AltVKCode         => 0x12,
    NumberLockVKCode  => 0x90,
    CapsLockVKCode    => 0x14,
  };

  use constant {
    VK_CLEAR    => 0x0c,
    VK_SHIFT    => 0x10,
    VK_PRIOR    => 0x21,
    VK_NEXT     => 0x22,
    VK_INSERT   => 0x2d,
    VK_NUMPAD0  => 0x60,
    VK_NUMPAD9  => 0x69,
    VK_SCROLL   => 0x91,
  };

Virtual-Key Codes from Winuser.h

=cut

  use constant {
    AltVKCode         => 0x12,
    NumberLockVKCode  => 0x90,  # virtual key code
    CapsLockVKCode    => 0x14,
  };

  use constant {
    VK_CLEAR    => 0x0c,
    VK_SHIFT    => 0x10,
    VK_PRIOR    => 0x21,
    VK_NEXT     => 0x22,
    VK_INSERT   => 0x2d,
    VK_NUMPAD0  => 0x60,
    VK_NUMPAD9  => 0x69,
    VK_SCROLL   => 0x91,
  };

=end private

=item I<WinCon.h>

  use constant Win32Native::KEY_EVENT => 0x0001;

The Event member contains a KEY_EVENT_RECORD structure with information about a
keyboard event.

=cut

  sub Win32Native::KEY_EVENT() { 0x0001 };

=begin private

  use constant {
    _eventType       => 0,
    _keyDown         => 1,
    _repeatCount     => 2,
    _virtualKeyCode  => 3,
    _virtualScanCode => 4,
    _uChar           => 5,
    _controlKeyState => 6,
  };

Constants for accessing the input event array which is used for the console 
input buffer API calls.

I<see> KEY_EVENT_RECORD structure.

=cut

  use constant {
    _eventType       => 0,
    _keyDown         => 1,
    _repeatCount     => 2,
    _virtualKeyCode  => 3,
    _virtualScanCode => 4,
    _uChar           => 5,
    _controlKeyState => 6,
  };

=end private

=back

=cut

  # ------------------------------------------------------------------------
  # Variables --------------------------------------------------------------
  # ------------------------------------------------------------------------

=begin private

=head2 Variables

=over

=item <_INSTANCES>

  my %_INSTANCES ( is => private, type => Hash ) = ();

The instance reference is stored in the %_INSTANCES hash.

I<see> Class::Singelton

=cut

  my %_INSTANCES = ();


=item I<_in>

  my $_in ( is => private, type => Win32::Console );

For L</In>

=item I<_out>

  my $_out ( is => private, type => Win32::Console );

For L</Out>

=item I<_error>

  my $_error ( is => private, type => Win32::Console ):

For L</Error>

=cut

  my $_in;
  my $_out;
  my $_error;

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

=item I<_inputEncoding>

  my $_inputEncoding ( is => private, type => Int );

For L</InputEncoding>

=item I<_outputEncoding>

  my $_outputEncoding ( is => private, type => Int );

For L</OutputEncoding>

=cut

  my $_inputEncoding;
  my $_outputEncoding;

=item I<_stdInRedirectQueried>

  my $_stdInRedirectQueried ( is => private, type => Bool ) = FALSE;

For L</IsInputRedirected>

=item I<_stdOutRedirectQueried>

  my $_stdOutRedirectQueried ( is => private, type => Bool ) = FALSE;

For L</IsOutputRedirected>

=item I<_stdErrRedirectQueried>

  my $_stdErrRedirectQueried ( is => private, type => Bool ) = FALSE;

For L</IsErrorRedirected>

=cut

  my $_stdInRedirectQueried = FALSE;
  my $_stdOutRedirectQueried = FALSE;
  my $_stdErrRedirectQueried = FALSE;

=item I<_isStdInRedirected>

  my $_isStdInRedirected ( is => private, type => Bool );

For L</IsInputRedirected>

=item I<_isStdOutRedirected>

  my $_isStdOutRedirected ( is => private, type => Bool );

For L</IsOutputRedirected>

=item I<_isStdErrRedirected>

  my $_isStdErrRedirected ( is => private, type => Bool );

For L</IsErrorRedirected>

=cut

  my $_isStdInRedirected;
  my $_isStdOutRedirected;
  my $_isStdErrRedirected;

=item I<_consoleInputHandle>

  my $_consoleInputHandle ( is => private, type => Int );

Holds the output handle of the console.

=item I<_consoleStartupHandle>

  my $_consoleStartupHandle ( is => private, type => Int );

Holds the handle of the output or error console at startup.

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
  my $_consoleStartupHandle;
  my $_consoleOutputHandle;

=item I<_ownsConsole>

  my $_ownsConsole ( is => private, type => Bool ) = FALSE;

If a new handle is created when the console is initialized, the variable is 
set to true.

=cut

  my $_ownsConsole = FALSE;

=item I<_owningInputHandle>

  my $_owningInputHandle ( is => private, type => Bool ) = FALSE;

If a new input handle is created when the console is initialized, the variable 
is set to true.

=item I<_owningStartupHandle>

  my $_owningStartupHandle ( is => private, type => Bool ) = FALSE;

If a new startup output handle is created when the console is initialized, the 
variable is set to true.

=item I<_owningOutputHandle>

  my $_owningOutputHandle ( is => private, type => Bool ) = FALSE;

If a new active output handle is created when the console is initialized, the 
variable is set to true.

=cut

  my $_owningInputHandle = FALSE;
  my $_owningStartupHandle = FALSE;
  my $_owningOutputHandle = FALSE;

=item I<_initialized>

  my $_initialized ( is => private, type => Bool ) = FALSE;

If true, the start settings of the console are saved and initialized.

=cut

  my $_initialized = FALSE;

=item I<_startup_input_mode>

  my $_startup_input_mode ( is => private, type => Int );

Saves the start value for the console input mode.

=item I<_startup_output_mode>

  my $_startup_output_mode ( is => private, type => Int );

Saves the start value for the console output mode.

=cut

  q/*
  my $_startup_input_mode;
  my $_startup_output_mode;
  */ if 0;

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
    isa       => Int,
    # init_arg  => undef,
    default   => sub { ($BG_BLACK & 0xf0) >> 4 },
  );

  around 'BackgroundColor' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $succeeded;
      my $csbi = GetBufferInfo(FALSE, $succeeded);

      # For code that may be used from Windows app w/ no console
      if ( !$succeeded ) {
        my $BLACK = ($BG_BLACK & 0xf0) >> 4;
        $self->$orig($BLACK);
        return $BLACK;
      }

      my $c = $csbi->{wAttributes} & 0xf0;
      my $value = ColorAttributeToConsoleColor($c);
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      confess("ArgumentException: InvalidConsoleColor")
        if $value < 0 || $value > 15;
      $self->$orig($value);
      my $c = ConsoleColorToColorAttribute($value, TRUE);

      my $succeeded;
      my $csbi = GetBufferInfo(FALSE, $succeeded);
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
      Win32::Console::_SetConsoleTextAttribute(ConsoleOutputHandle(), $attr);
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
    isa       => Int,
    # init_arg  => undef,
  );

  around 'BufferHeight' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = GetBufferInfo();
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
    isa       => Int,
    # init_arg  => undef,
  );

  around 'BufferWidth' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = GetBufferInfo();
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
    isa       => Bool,
    # init_arg  => undef,
  );

  around 'CapsLock' => sub {
    assert { @_ == 2 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    GET: {
      require Win32Native;
      my $value = (Win32Native::GetKeyState(CapsLockVKCode) & 1) == 1;
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
    isa       => Int,
    # init_arg  => undef,
  );

  around 'CursorLeft' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = GetBufferInfo();
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
    isa       => Int,
    # init_arg  => undef,
  );

  around 'CursorSize' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $hConsole = ConsoleOutputHandle();
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
      my $hConsole = ConsoleOutputHandle();
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
    isa       => Int,
    # init_arg  => undef,
  );

  around 'CursorTop' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = GetBufferInfo();
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
    isa       => Bool,
    # init_arg  => undef,
  );

  around 'CursorVisible' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $hConsole = ConsoleOutputHandle();
      my (undef, $value) = Win32::Console::_GetConsoleCursorInfo($hConsole) 
        or confess("WinIOError: $EXTENDED_OS_ERROR");
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      $self->$orig($value);
      my $hConsole = ConsoleOutputHandle();
      my ($size) = Win32::Console::_GetConsoleCursorInfo($hConsole)
        or confess("WinIOError: $EXTENDED_OS_ERROR");
      Win32::Console::_SetConsoleCursorInfo($hConsole, $size, $value)
        or confess("WinIOError: $EXTENDED_OS_ERROR");
      return;
    }
  };

=item I<Error>

  field Error ( is => rwp, type => Object, lazy => 1, builder => 1 );

A Windows::Console object that represents the standard error stream.

=cut

  has Error => (
    is        => 'rwp',
    isa       => Object,
    # init_arg  => undef,
    lazy      => 1,
    default   => &_build_Error,
    # builder   => 1,
  );

  sub _build_Error {
    unless ( defined $_error ) {
      $_error = __PACKAGE__->OpenStandardError();
      assert "Didn't set Console::_error appropriately!" { $_error };
    }
    return $_error;
  }

=item I<ForegroundColor>

  field ForegroundColor ( is => rw, type => Int ) = $FG_LIGHTGRAY;

Color that specifies the foreground color of the console; that is, the color
of each character that is displayed.  The default is gray.

I<throws> ArgumentException if the color specified in a set operation is not 
valid.

=cut

  has ForegroundColor => (
    is        => 'rw',
    isa       => Int,
    # init_arg  => undef,
    default   => sub { $FG_LIGHTGRAY },
  );

  around 'ForegroundColor' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $succeeded;
      my $csbi = GetBufferInfo(FALSE, $succeeded);

      # For code that may be used from Windows app w/ no console
      if ( !$succeeded ) {
        $self->$orig($FG_LIGHTGRAY);
        return $FG_LIGHTGRAY;
      }

      my $c = $csbi->{wAttributes} & 0x0f;
      my $value = ColorAttributeToConsoleColor($c);
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      confess("ArgumentException: InvalidConsoleColor")
        if $value < 0 || $value > 15;
      $self->$orig($value);
      my $c = ConsoleColorToColorAttribute($value, FALSE);

      my $succeeded;
      my $csbi = GetBufferInfo(FALSE, $succeeded);
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
      Win32::Console::_SetConsoleTextAttribute(ConsoleOutputHandle(), $attr);
      return;
    }
  };

=item I<In>

  field In ( is => rwp, type => Object, lazy => 1, builder => 1 );

A Windows::Console object that represents the standard input stream.

=cut

  has In => (
    is        => 'rwp',
    isa       => Object,
    # init_arg  => undef,
    lazy      => 1,
    default   => &_build_In,
    # builder   => 1,
  );

  sub _build_In {
    unless ( defined $_in ) {
      $_in = __PACKAGE__->OpenStandardInput();
    }
    return $_in;
  }

=item I<InputEncoding>

  field InputEncoding ( is => rw, type => Int );

Gets or sets the encoding the console uses to write input.

I<note> A get operation may return a cached value instead of the console's 
current input encoding.

=cut

  has InputEncoding => (
    is        => 'rw',
    isa       => Int,
    # init_arg  => undef,
    default   => sub { Win32::GetConsoleCP() },
  );

  around 'InputEncoding' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      return $_inputEncoding
        if $_inputEncoding;

      {
        my $cp = Win32::GetConsoleCP();
        $self->$orig($_inputEncoding = $cp);
        return $_inputEncoding;
      }
    }
    SET: {
      my $value = shift;
      if ( !defined $value ) {
        confess("ArgumentNullException: value");
      }
      $self->$orig($value);

      {
        if ( !IsStandardConsoleUnicodeEncoding($value) ) {
          my $cp = $value;
          my $r = Win32::SetConsoleCP($cp);
          if (!$r) {
            confess("WinIOError: $EXTENDED_OS_ERROR");
          }
        }

        $_inputEncoding = $value;

        # We need to reinitialize Console->In in the next call to _in
        # This will discard the current StreamReader, potentially 
        # losing buffered data
        $self->_set_In($self->OpenStandardInput());
        return;
      }
    }
  };

=item I<IsErrorRedirected>

  field IsErrorRedirected ( is => rwp, type => Bool, lazy => 1, builder => 1 );

Gets a value that indicates whether error has been redirected from the 
standard error stream.  True if error is redirected; otherwise, false.

=cut

  has IsErrorRedirected => (
    is        => 'rwp',
    isa       => Bool,
    # init_arg  => undef,
    lazy      => 1,
    default   => &_build_IsErrorRedirected,
    # builder   => 1,
  );

  sub _build_IsErrorRedirected {
    if ( !$_stdErrRedirectQueried ) {
      my $errHndle = Win32::Console::_GetStdHandle(STD_ERROR_HANDLE);
      my $_isStdErrRedirected = IsHandleRedirected($errHndle);
      $_stdErrRedirectQueried = TRUE;
    }
    return $_isStdErrRedirected;
  }

=item I<IsInputRedirected>

  field IsInputRedirected ( is => rwp, type => Bool, lazy => 1, builder => 1 );

Gets a value that indicates whether input has been redirected from the 
standard input stream.  True if input is redirected; otherwise, false.

=cut

  has IsInputRedirected => (
    is        => 'rwp',
    isa       => Bool,
    # init_arg  => undef,
    lazy      => 1,
    default   => &_build_IsInputRedirected,
    # builder   => 1,
  );

  sub _build_IsInputRedirected {
    if ( !$_stdInRedirectQueried ) {
      $_isStdInRedirected = IsHandleRedirected(ConsoleInputHandle());
      $_stdInRedirectQueried = TRUE;
    }
    return $_isStdInRedirected;
  }

=item I<IsOutputRedirected>

  field IsOutputRedirected ( is => rwp, type => Bool, lazy => 1, 
    builder => 1 );

Gets a value that indicates whether output has been redirected from the 
standard output stream.  True if output is redirected; otherwise, false.

=cut

  has IsOutputRedirected => (
    is        => 'rwp',
    isa       => Bool,
    # init_arg  => undef,
    lazy      => 1,
    default   => &_build_IsOutputRedirected,
    # builder   => 1,
  );

  sub _build_IsOutputRedirected {
    if ( !$_stdOutRedirectQueried ) {
      $_isStdOutRedirected = IsHandleRedirected(ConsoleOutputHandle());
      $_stdOutRedirectQueried = TRUE;
    }
    return $_isStdOutRedirected;
  }

=item I<KeyAvailable>

  field KeyAvailable ( is => rwp, type => Bool );

Gets a value indicating whether a key press is available in the input stream.

=cut

  has KeyAvailable => (
    is        => 'rwp',
    isa       => Bool,
    # init_arg  => undef,
  );
  
  around 'KeyAvailable' => sub {
    assert { @_ == 2 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    GET: {
      if ( $_cachedInputRecord->[_eventType] == Win32Native::KEY_EVENT ) {
        $self->_set_KeyAvailable(TRUE);
        return TRUE;
      }

      my @ir;
      my $numEventsRead = 0;
      while (TRUE) {
        my $r = do {
          Win32::SetLastError(0);
          @ir = Win32::Console::_PeekConsoleInput(ConsoleInputHandle());
          $numEventsRead = 0 + (@ir > 1);
          Win32::GetLastError() == 0;
        };
        if ( !$r ) {
          my $errorCode = Win32::GetLastError();
          if ( $errorCode == Win32Native::ERROR_INVALID_HANDLE ) {
            confess("InvalidOperationException: ConsoleKeyAvailableOnFile");
          }
          confess("WinIOError stdin: $EXTENDED_OS_ERROR");
        }

        if ( $numEventsRead == 0 ) {
          $self->_set_KeyAvailable(FALSE);
          return FALSE;
        }

        # Skip non key-down && mod key events.
        if ( !IsKeyDownEvent(\@ir) || IsModKey(\@ir) ) {
          #

          $r = do {
            Win32::SetLastError(0);
            @ir = Win32::Console::_ReadConsoleInput(ConsoleInputHandle());
            $numEventsRead = 0 + (@ir > 1);
            Win32::GetLastError() == 0;
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
    isa       => Int,
    # init_arg  => undef,
  );

  around 'LargestWindowHeight' => sub {
    assert { @_ == 2 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    GET: {
      # Note this varies based on current screen resolution and 
      # current console font.  Do not cache this value.
      my (undef, $bounds_Y) = Win32::Console::_GetLargestConsoleWindowSize(
        ConsoleOutputHandle());
      $self->_set_LargestWindowHeight($bounds_Y);
      return $bounds_Y;
    }
  };

=item I<LargestWindowWidth>

  field LargestWindowWidth ( is => rwp, type => Int );

Gets the largest possible number of console window columns, based on the 
current font and screen resolution.

=cut

  has LargestWindowWidth => (
    is        => 'rwp',
    isa       => Int,
    # init_arg  => undef,
  );

  around 'LargestWindowWidth' => sub {
    assert { @_ == 2 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    GET: {
      # Note this varies based on current screen resolution and 
      # current console font.  Do not cache this value.
      my ($bounds_X) = Win32::Console::_GetLargestConsoleWindowSize(
        ConsoleOutputHandle());
      $self->_set_LargestWindowWidth($bounds_X);
      return $bounds_X;
    }
  };

=item I<NumberLock>

  field NumberLock ( is => rw, type => Bool );

Gets a value indicating whether the NUM LOCK keyboard toggle is turned on or 
turned off.

=cut

  has NumberLock => (
    is        => 'rwp',
    isa       => Bool,
    # init_arg  => undef,
  );

  around 'NumberLock' => sub {
    assert { @_ == 2 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    GET: {
      require Win32Native;
      my $value = (Win32Native::GetKeyState(NumberLockVKCode) & 1) == 1;
      $self->_set_NumberLock($value);
      return $value;
    }
  };

=item I<Out>

  field Out ( is => rwp, type => Object, lazy => 1, builder => 1 );

A Windows::Console object that represents the standard output stream.

=cut

  has Out => (
    is        => 'rwp',
    isa       => Object,
    # init_arg  => undef,
    lazy      => 1,
    default   => &_build_Out,
    # builder   => 1,
  );

  sub _build_Out {
    unless ( defined $_out ) {
      $_out = __PACKAGE__->OpenStandardOutput();
      assert "Didn't set Console::_out appropriately!" { $_out };
    }
    return $_out;
  }

=item I<OutputEncoding>

  field OutputEncoding ( is => rw, type => Int );

Gets or sets the encoding the console uses to write output.

I<note> A get operation may return a cached value instead of the console's 
current output encoding.

=cut

  has OutputEncoding => (
    is        => 'rw',
    isa       => Int,
    # init_arg  => undef,
    default   => sub { Win32::Console->_GetConsoleOutputCP() },
  );

  around 'OutputEncoding' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      return $_outputEncoding
        if $_outputEncoding;

      {
        my $cp = Win32::GetConsoleOutputCP();
        $self->$orig($_outputEncoding = $cp);
        return $_outputEncoding;
      }
    }
    SET: {
      my $value = shift;
      if ( !defined $value ) {
        confess("ArgumentNullException: value");
      }
      $self->$orig($value);

      {
        # Before changing the code page we need to flush the data 
        # if Out hasn't been redirected. Also, have the next call to  
        # _out reinitialize the console code page.

        if ( $self->Out && !$self->IsOutputRedirected ) {
          # Flush (_FlushConsoleInputBuffer) works also for stdout
          # https://stackoverflow.com/a/18389182
          $self->Out->Flush(); 
          $self->_set_Out($self->OpenStandardOutput());
        }
        if ( $self->Error && !$self->IsErrorRedirected ) {
          $self->Error->Flush(); 
          $self->_set_Error($self->OpenStandardError());
        }

        if ( !IsStandardConsoleUnicodeEncoding($value) ) {
          my $cp = $value;
          my $r = Win32::SetConsoleOutputCP($cp);
          if (!$r) {
            confess("WinIOError: $EXTENDED_OS_ERROR");
          }
        }

        $_outputEncoding = $value;
        return;
      }
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
    isa       => Str,
    # init_arg  => undef,
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
    isa       => Bool,
    # init_arg  => undef,
    default   => sub { FALSE },
  );

  around 'TreatControlCAsInput' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $handle = ConsoleInputHandle();
      if ( $handle == Win32API::File::INVALID_HANDLE_VALUE ) {
        confess("IOException: NoConsole");
      }
      my $mode = 0;
      my $r = do {
        Win32::SetLastError(0);
        $mode = Win32::Console::_GetConsoleMode($handle) || 0;
        Win32::GetLastError() == 0;
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
      my $handle = ConsoleInputHandle();
      if ( $handle == Win32API::File::INVALID_HANDLE_VALUE ) {
        confess("IOException: NoConsole");
      }
      my $mode = 0;
      my $r = do {
        Win32::SetLastError(0);
        $mode = Win32::Console::_GetConsoleMode($handle) || 0;
        Win32::GetLastError() == 0;
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
    isa       => Int,
    # init_arg  => undef,
  );

  around 'WindowHeight' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = GetBufferInfo();
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
    isa       => Int,
    # init_arg  => undef,
  );

  around 'WindowLeft' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = GetBufferInfo();
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
    isa       => Int,
    # init_arg  => undef,
  );

  around 'WindowTop' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = GetBufferInfo();
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
    isa       => Int,
    # init_arg  => undef,
  );

  around 'WindowWidth' => sub {
    assert { @_ >= 2 && @_ <= 3 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = GetBufferInfo();
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

=cut

  sub BUILD {
    assert { @_ >= 2 };
    assert { is_Object($_[0]) };

    # _init();
    return;
  }

=item I<instance>

  factory instance() : System::Console

This constructor instantiates an object instance if none exists, otherwise it
returns an existing instance.

It is used to initialize the default I/O console.

=cut

  sub instance {
    assert { @_ == 1 };
    my $class = shift;
    # already got an object
    return $class if ref $class;
    # store the instance against the $class key of %_INSTANCES
    my $instance = $_INSTANCES{$class};
    unless (defined $instance) {
      $_INSTANCES{$class} = $instance = $class->new();
    }
    return $instance;
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
    assert { is_Object($_[0]) };

    # _done();
    return;
  }

  #
  # END block to explicitly destroy all Singleton objects since
  # destruction order at program exit is not predictable.
  # see CPAN RT #23568 and #68526 for examples
  #
  END {
    # dereferences and causes orderly destruction of all instances
    undef(%_INSTANCES);
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
    require Win32Native;
    Win32Native::Beep($frequency, $duration);
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

    my $hConsole = ConsoleOutputHandle();
    if ( $hConsole == Win32API::File::INVALID_HANDLE_VALUE ) {
      confess("IOException: NoConsole");
    }

    # get the number of character cells in the current buffer
    # Go through my helper method for fetching a screen buffer info
    # to correctly handle default console colors.
    $csbi = GetBufferInfo();
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
      confess("ArgumentException: InvalidConsoleColor sourceForeColor %d",
        $sourceForeColor);
    }
    if ( $sourceBackColor < 0 || $sourceBackColor > 15 ) {
      confess("ArgumentException: InvalidConsoleColor sourceBackColor %d",
        $sourceBackColor);
    }

    my $csbi = GetBufferInfo();
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
    $r = Win32::Console::_ReadConsoleOutput(ConsoleOutputHandle(), $data,
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
    my $c = ConsoleColorToColorAttribute($sourceBackColor, TRUE);
    $c |= ConsoleColorToColorAttribute($sourceForeColor, FALSE);
    my $attr = $c;
    my $numWritten;
    for (my $i = $sourceTop; $i < $sourceTop + $sourceHeight; $i++) {
      $writeCoord->{Y} = $i;
      $r = do {
        Win32::SetLastError(0);
        $numWritten = Win32::Console::_FillConsoleOutputCharacter(
          ConsoleOutputHandle(), $sourceChar, $sourceWidth,
          $writeCoord->{X}, $writeCoord->{Y}
        ) || 0;
        Win32::GetLastError() == 0;
      };
      assert "FillConsoleOutputCharacter wrote the wrong number of chars!"
        { $numWritten == $sourceWidth };
      if (!$r) {
        confess("WinIOError: $EXTENDED_OS_ERROR");
      }
      $r = do {
        Win32::SetLastError(0);
        $numWritten = Win32::Console::_FillConsoleOutputAttribute(
          ConsoleOutputHandle(), $attr, $sourceWidth,
          $writeCoord->{X}, $writeCoord->{Y}
        ) || 0;
        Win32::GetLastError() == 0;
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
      ConsoleOutputHandle(), $data, 
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
    assert { $_[0] eq __PACKAGE__ || is_Object($_[0]) };
    return Win32::Console->new(STD_ERROR_HANDLE);
  }

=item I<OpenStandardInput>

  method OpenStandardInput() : Win32::Console

Acquires the standard input object.

I<return> the standard input object.

=cut

  sub OpenStandardInput {
    assert { @_ == 1 };
    assert { $_[0] eq __PACKAGE__ || is_Object($_[0]) };
    return Win32::Console->new(STD_INPUT_HANDLE);
  }

=item I<OpenStandardOutput>

  method OpenStandardOutput() : Win32::Console

Acquires the standard output object.

I<return> the standard output object.

=cut

  sub OpenStandardOutput {
    assert { @_ == 1 };
    assert { $_[0] eq __PACKAGE__ || is_Object($_[0]) };
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
    assert { is_Object($self->In) };

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
    my $csbi = GetBufferInfo(FALSE, $succeeded);
    return if !$succeeded;

    assert "Setting the color attributes before we've read the default color attributes!"
      { $_haveReadDefaultColors };
 
    my $attr = $ATTR_NORMAL;
    # Ignore errors here - there are some scenarios for running code that wants
    # to print in colors to the console in a Windows application.
    Win32::Console::_SetConsoleTextAttribute(ConsoleOutputHandle(), $attr);
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

    if ( $_cachedInputRecord->[_eventType] == Win32Native::KEY_EVENT ) {
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
          Win32::SetLastError(0);
          @ir = Win32::Console::_ReadConsoleInput(ConsoleInputHandle());
          $numEventsRead = 0 + (@ir > 1);
          Win32::GetLastError() == 0;
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

        if ( IsKeyDownEvent(\@ir) ) {
          #
          next if $keyCode != AltVKCode;
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
          next if IsModKey(\@ir);
        }

        # When Alt is down, it is possible that we are in the middle of a 
        # Alt+NumPad unicode sequence. Escape any intermediate NumPad keys 
        # whether NumLock is on or not (notepad behavior)
        my $key = $keyCode;
        if (IsAltKeyDown(\@ir)  && (($key >= VK_NUMPAD0 && $key <= VK_NUMPAD9)
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
    assert { is_Object($self->In) };

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

    my $csbi = GetBufferInfo();
    my $srWindow = $csbi->{srWindow};
    if ( $width < $srWindow->{Right} + 1 || $width >= 0x7fff ) {
      confess("ArgumentOutOfRangeException: width $width " . 
        "ConsoleBufferLessThanWindowSize");
    }
    if ( $height < $srWindow->{Bottom} + 1 || $height >= 0x7fff ) {
      confess("ArgumentOutOfRangeException: height $height " . 
        "ConsoleBufferLessThanWindowSize");
    }
    Win32::Console::_SetConsoleScreenBufferSize(ConsoleOutputHandle(), 
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

    my $hConsole = ConsoleOutputHandle();
    my $r = Win32::Console::_SetConsoleCursorPosition($hConsole, $left, $top);
    if ( !$r ) {
      # Give a nice error message for out of range sizes
      my $errorCode = Win32::GetLastError();
      my $csbi = GetBufferInfo();
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
    my $csbi = GetBufferInfo();
    my $r;

    # If the buffer is smaller than this new window size, resize the
    # buffer to be large enough.  Include window position.
    my $resizeBuffer = FALSE;
    my $size = {
      X => $csbi->{dwSize}->{X},
      Y => $csbi->{dwSize}->{Y},
    };
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
      $r = Win32::Console::_SetConsoleScreenBufferSize(ConsoleOutputHandle(), 
        $size->{X}, $size->{Y});
      if (!$r) {
        confess("WinIOError: $EXTENDED_OS_ERROR");
      }
    }

    my $srWindow = $csbi->{srWindow};
    # Preserve the position, but change the size.
    $srWindow->{Bottom} = $srWindow->{Top} + $height - 1;
    $srWindow->{Right} = $srWindow->{Left} + $width - 1;

    $r = Win32::Console::_SetConsoleWindowInfo(ConsoleOutputHandle(), TRUE, 
      $srWindow->{Left}, $srWindow->{Top}, 
      $srWindow->{Right}, $srWindow->{Bottom}
    );
    if ( !$r ) {
      my $errorCode = Win32::GetLastError();

      # If we resized the buffer, un-resize it.
      if ( $resizeBuffer ) {
        Win32::Console::_SetConsoleScreenBufferSize(ConsoleOutputHandle(), 
          $csbi->{dwSize}->{X}, $csbi->{dwSize}->{Y});
      }

      # Try to give a better error message here
      my $bounds = { X => 0, Y => 0 };
      ($bounds->{X}, $bounds->{Y}) = 
        Win32::Console::_GetLargestConsoleWindowSize(ConsoleOutputHandle());
      if ( $width > $bounds->{X} ) {
        confess("ArgumentOutOfRangeException: width $width " . 
          "ConsoleWindowSize size %d", $bounds->{X});
      }
      if ( $height > $bounds->{Y} ) {
        confess("ArgumentOutOfRangeException: height $height " . 
          "ConsoleWindowSize size %d", $bounds->{Y});
      }

      confess("WinIOError: %s", Win32::FormatMessage($errorCode));
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
    my $csbi = GetBufferInfo();

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

=cut

  use namespace::sweep -also => [qw(
    ColorAttributeToConsoleColor
    ConsoleColorToColorAttribute
    ConsoleInputHandle
    ConsoleOutputHandle
    GetBufferInfo
    IsAltKeyDown
    IsKeyDownEvent
    IsHandleRedirected
    IsModKey
    IsStandardConsoleUnicodeEncoding
    _init
    _done
  )];

=item I<ColorAttributeToConsoleColor>

  sub ColorAttributeToConsoleColor(Int $c) : Int

Converts the standard color index to the Wiondows color attribute.

=cut

  sub ColorAttributeToConsoleColor {
    assert { @_ == 1 };
    my $c = assert_Int shift;

    # Turn background colors into foreground colors.
    if (($c & 0xf0) != 0) {
      $c = $c >> 4;
    }

    return $c;
  }

=item I<ColorAttributeToConsoleColor>

  sub ConsoleColorToColorAttribute(Int $color, Bool $isBackground) : Int

Converts the Windows color attribute to the standard color index.

=cut

  sub ConsoleColorToColorAttribute {
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

=item I<ConsoleInputHandle>

  sub ConsoleInputHandle() : Int

Simplifies the use of GetStdHandle(STD_INPUT_HANDLE).

=cut

  sub ConsoleInputHandle {
    assert { @_ == 0 };
    $_consoleInputHandle = Win32::Console::_GetStdHandle(STD_INPUT_HANDLE) 
      unless defined $_consoleInputHandle;
    return $_consoleInputHandle;
  }

=item I<ConsoleOutputHandle>

  sub ConsoleOutputHandle() : Int

Simplifies the use of GetStdHandle(STD_OUTPUT_HANDLE).

=cut

  sub ConsoleOutputHandle {
    assert { @_ == 0 };
    $_consoleOutputHandle = Win32::Console::_GetStdHandle(STD_OUTPUT_HANDLE)
      unless defined $_consoleOutputHandle;
    return $_consoleOutputHandle;
  }

=item I<GetBufferInfo>

  sub GetBufferInfo() : HashRef
  sub GetBufferInfo(Bool $throwOnNoConsole, Bool $succeeded) : HashRef

Simplifies the use of GetConsoleScreenBufferInfo().

=cut

  sub GetBufferInfo {
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
      assert { is_Bool($_[0]) };
      assert { is_Bool($_[1]) };
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
    my $success;

    my $hConsole = ConsoleOutputHandle();
    if ( $hConsole == Win32API::File::INVALID_HANDLE_VALUE ) {
      if ( !$throwOnNoConsole ) {
        return { %$CONSOLE_SCREEN_BUFFER_INFO };
      }
      else {
        confess("IOException: NoConsole");
      }
    }

    # Note that if stdout is redirected to a file, the console handle
    # may be a file.  If this fails, try stderr and stdin.
    $success = do {
      @csbi = Win32::Console::_GetConsoleScreenBufferInfo($hConsole);
      @csbi > 1;
    };
    if ( !$success ) {
      $success = do {
        @csbi = Win32::Console::_GetConsoleScreenBufferInfo(
          Win32::Console::_GetStdHandle(STD_ERROR_HANDLE)
        );
        @csbi > 1;
      };
      if ( !$success ) {
        $success = do {
          @csbi = Win32::Console::_GetConsoleScreenBufferInfo(
            Win32::Console::_GetStdHandle(STD_INPUT_HANDLE)
          );
          @csbi > 1;
        };
      }

      if ( !$success ) {
        my $errorCode = Win32::GetLastError();
        if ( $errorCode == Win32Native::ERROR_INVALID_HANDLE
          && !$throwOnNoConsole
        ) {
          return { %$CONSOLE_SCREEN_BUFFER_INFO };
        }
        confess("WinIOError: $EXTENDED_OS_ERROR");
      }
    }

    if ( !$_haveReadDefaultColors ) {
      # Fetch the default foreground and background color for the
      # ResetColor method.
      $ATTR_NORMAL = $csbi[4] & 0xff;
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

=item I<IsAltKeyDown>

  sub IsAltKeyDown(ArrayRef $ir) : Bool

For tracking Alt+NumPad unicode key sequence.

=cut

  # For tracking Alt+NumPad unicode key sequence. When you press Alt key down 
  # and press a numpad unicode decimal sequence and then release Alt key, the
  # desired effect is to translate the sequence into one Unicode KeyPress. 
  # We need to keep track of the Alt+NumPad sequence and surface the final
  # unicode char alone when the Alt key is released. 
  sub IsAltKeyDown { 
    assert { @_ == 1 };
    my $ir = assert_ArrayRef shift;

    return ($ir->[_controlKeyState] 
      & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED)) != 0;
  }

=item I<IsKeyDownEvent>

  sub IsKeyDownEvent(ArrayRef $ir) : Bool

To detect pure KeyDown events.

=cut

  # Skip non key events. Generally we want to surface only KeyDown event 
  # and suppress KeyUp event from the same Key press but there are cases
  # where the assumption of KeyDown-KeyUp pairing for a given key press 
  # is invalid. For example in IME Unicode keyboard input, we often see
  # only KeyUp until the key is released.  
  sub IsKeyDownEvent {
    assert { @_ == 1 };
    my $ir = assert_ArrayRef shift;

    return $ir->[_eventType] == Win32Native::KEY_EVENT && $ir->[_keyDown];
  }

=item I<IsHandleRedirected>

  sub IsHandleRedirected(Int $ioHandle) : Bool

Detects if a console handle has been redirected.

=cut

  sub IsHandleRedirected {
    assert { @_ == 1 };
    my $ioHandle = assert_Int shift;

    assert { $ioHandle };
    assert { $ioHandle != Win32API::File::INVALID_HANDLE_VALUE };

    # If handle is not to a character device, we must be redirected:
    my $fileType = Win32API::File::GetFileType($ioHandle) // 0;
    if ( ($fileType & Win32API::File::FILE_TYPE_CHAR) 
      != Win32API::File::FILE_TYPE_CHAR 
    ) {
      return TRUE;
    }

    # We are on a char device.
    # If GetConsoleMode succeeds, we are NOT redirected.
    my $mode;
    my $success = do {
      Win32::SetLastError(0);
      $mode = Win32::Console::_GetConsoleMode($ioHandle) || 0;
      Win32::GetLastError() == 0;
    };
    return !$success;
  };

=item I<IsModKey>

  sub IsModKey(ArrayRef $ir) : Bool

Detects if the KeyEvent uses a mod key.

=cut

  sub IsModKey {
    assert { @_ == 1 };
    my $ir = assert_ArrayRef shift;

    # We should also skip over Shift, Control, and Alt, as well as caps lock.
    # Apparently we don't need to check for 0xA0 through 0xA5, which are keys 
    # like Left Control & Right Control. See the Microsoft 'ConsoleKey' for 
    # these values.
    my $keyCode = $ir->[_virtualKeyCode];
    return  ($keyCode >= VK_SHIFT && $keyCode <= AltVKCode) 
          || $keyCode == CapsLockVKCode 
          || $keyCode == NumberLockVKCode 
          || $keyCode == VK_SCROLL
  }

=item I<IsStandardConsoleUnicodeEncoding>

  sub IsStandardConsoleUnicodeEncoding(Int $encoding) : Bool

We cannot simply compare the encoding to Unicode because it incorporates BOM 
and we do not care about BOM. Instead, we compare the codepage only.

=cut

  sub IsStandardConsoleUnicodeEncoding {
    assert { @_ == 1 };
    my $encoding = assert_Int shift;

    my $enc = $encoding;
    return FALSE if !$enc;

    return 65000 == $enc;
  }

=item I<_init>

  sub _init()

Initializes the native screen resources and saves the settings that may be 
changed by this console.

=cut

  #
  # The console can be accessed in two ways: through GetStdHandle() or through
  # CreateFile(). GetStdHandle() will be unable to return a console handle
  # if standard handles have been redirected.
  #
  # Additionally, we want to spawn a new console when none is visible to the user.
  # This might happen under two circumstances:
  #
  # 1. The console crashed. This is easy to detect because all console operations
  #    fail on the console handles.
  # 2. The console exists somehow but cannot be made visible, not even by doing
  #    GetConsoleWindow() and then ShowWindow(SW_SHOW). This is what happens
  #    under Git Bash without pseudoconsole support. In this case, none of the
  #    standard handles is a console, yet the handles returned by CreateFile()
  #    still work.
  #
  # So, in order to find out if a console needs to be allocated, we
  # check whether at least of the standard handles is a console. If none
  # of them is, we allocate a new console. Yes, this will always spawn a
  # console if all three standard handles are redirected, but this is not
  # a common use case.
  #
  # Then comes the question of whether to access the console through GetStdHandle()
  # or through CreateFile(). CreateFile() has the advantage of not being affected
  # by standard handle redirection. However, I have found that some terminal
  # emulators (i.e. ConEmu) behave unexpectedly when using screen buffers
  # opened with CreateFile(). So we will use the standard handles whenever possible.
  #
  # It is worth mentioning that the handles returned by CreateFile() have to be
  # closed, but the ones returned by GetStdHandle() must not. So we have to remember
  # this information for each console handle.
  #
  # We also need to remember whether we allocated a console or not, so that
  # we can free it when tearing down. If we don't, weird things may happen.
  #
  sub _init {
    assert { @_ == 0 };

    return if $_initialized;

    my $isValid = sub {
      my ($handle) = @_;
      return $handle
          && $handle != Win32API::File::INVALID_HANDLE_VALUE;
    };
    my $isConsole = sub {
      my ($handle) = @_;
      return !!Win32::Console::_GetConsoleMode($handle);
    };

    my $handle;
    my $haveConsole = FALSE;

    $handle = ConsoleInputHandle();
    if ( $isConsole->($handle) ) {
      $haveConsole = TRUE;
    }

    $handle = ConsoleOutputHandle();
    if ( $isConsole->($handle) ) {
      $haveConsole = TRUE;
      if ( !$isValid->($_consoleStartupHandle) ) {
        $_consoleStartupHandle = $handle;
      }
    }

    $handle = Win32::Console::_GetStdHandle(STD_ERROR_HANDLE);
    if ( $isConsole->($handle) ) {
      $haveConsole = TRUE;
      if ( !$isValid->($_consoleStartupHandle) ) {
        $_consoleStartupHandle = $handle;
      }
    }

    if ( !$haveConsole ) {
      Win32::Console::Free();
      Win32::Console::Alloc();
      $_ownsConsole = TRUE;
    }

    if ( !$isValid->($_consoleInputHandle) ) {
      $_consoleInputHandle = Win32API::File::createFile(
        'CONIN$',
        {
          Access => GENERIC_READ | GENERIC_WRITE,
          Share  => FILE_SHARE_READ,
          Create => Win32API::File::OPEN_EXISTING,
        }
      );
      $_owningInputHandle = TRUE;
    }

    if ( !$isValid->($_consoleStartupHandle) ) {
      $_consoleStartupHandle = Win32API::File::createFile(
        'CONOUT$',
        {
          Access => GENERIC_READ | GENERIC_WRITE,
          Share  => FILE_SHARE_WRITE,
          Create => Win32API::File::OPEN_EXISTING,
        }
      );
      $_owningStartupHandle = TRUE;
    }

    $_consoleOutputHandle = Win32::Console::_CreateConsoleScreenBuffer(
      GENERIC_READ | GENERIC_WRITE,
      0,
      CONSOLE_TEXTMODE_BUFFER
    );
    $_owningOutputHandle = TRUE;

    {
      my @sbInfo = Win32::Console::_GetConsoleScreenBufferInfo(
        $_consoleStartupHandle);
      # Force the screen buffer size to match the window size.
      # The Console API guarantees this, but some implementations
      # are not compliant (e.g. Wine).
      my ($left, $top, $right, $bottom) = @sbInfo[5..8];
      my $dwSize = {
        X => $right - $left + 1, 
        Y => $bottom - $top + 1,
      };
      Win32::Console::_SetConsoleScreenBufferSize($_consoleOutputHandle, 
        $dwSize->{X}, $dwSize->{Y});
    }
    Win32::Console::_SetConsoleActiveScreenBuffer($_consoleOutputHandle);

    if ( !$isValid->($_consoleInputHandle) 
      || !$isValid->($_consoleStartupHandle) 
      || !$isValid->($_consoleOutputHandle) 
    ) {
      confess("Error: cannot get a console.\n");
    }

    eval {
      q/*
      my $CONSOLE = Win32::Console->new(STD_INPUT_HANDLE);
      assert { $CONSOLE };
      assert { !!$CONSOLE->Mode() };
      $_startup_input_mode = $CONSOLE->Mode();

      $CONSOLE = Win32::Console->new(STD_OUTPUT_HANDLE);
      assert { $CONSOLE };
      assert { !!$CONSOLE->Mode() };
      $_startup_output_mode = $CONSOLE->Mode();
      */ if 0;

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

  sub _done {
    assert { @_ == 0 };

    return unless $_initialized;

    my @activeSbInfo = Win32::Console::_GetConsoleScreenBufferInfo(
      $_consoleOutputHandle);
    my @startupSbInfo = Win32::Console::_GetConsoleScreenBufferInfo(
      $_consoleStartupHandle);

    my ($left, $top, $right, $bottom) = @activeSbInfo[5..8];
    my $activeWindowSize = { 
      X => $right - $left + 1, 
      Y => $bottom - $top + 1,
    };
    ($left, $top, $right, $bottom) = @startupSbInfo[5..8];
    my $startupWindowSize = { 
      X => $right - $left + 1, 
      Y => $bottom - $top + 1,
    };

    # Preserve the current window size.
    if ( $activeWindowSize->{X} != $startupWindowSize->{X} 
      || $activeWindowSize->{Y} != $startupWindowSize->{Y} 
    ) {
      # The buffer is not allowed to be smaller than the window, so enlarge
      # it if necessary. But do not shrink it in the opposite case, to avoid
      # loss of data.
      my $dwSize = {
        X => $startupSbInfo[0],
        Y => $startupSbInfo[1],
      };
      $dwSize->{X} = $activeWindowSize->{X}
        if $dwSize->{X} < $activeWindowSize->{X};
      $dwSize->{Y} = $activeWindowSize->{Y}
        if $dwSize->{Y} < $activeWindowSize->{Y};
      Win32::Console::_SetConsoleScreenBufferSize($_consoleStartupHandle, 
        $dwSize->{X}, $dwSize->{Y});
      # Get the updated cursor position, in case it changed after the resize.
      @startupSbInfo = Win32::Console::_GetConsoleScreenBufferInfo(
        $_consoleStartupHandle);
      # Make sure the cursor is visible. If possible, show it in the bottom 
      # row.
      my $srWindow = {};
      my $dwCursorPosition = {
        X => $startupSbInfo[2],
        Y => $startupSbInfo[3],
      };
      $srWindow->{Right} = max($dwCursorPosition->{X}, $activeWindowSize->{X} - 1);
      $srWindow->{Left} = $srWindow->{Right} - ($activeWindowSize->{X} - 1);
      $srWindow->{Bottom} = max($dwCursorPosition->{Y}, $activeWindowSize->{Y} - 1);
      $srWindow->{Top} = $srWindow->{Bottom} - ($activeWindowSize->{Y} - 1);
      Win32::Console::_SetConsoleWindowInfo($_consoleStartupHandle, TRUE,
        $srWindow->{Left}, $srWindow->{Top}, 
        $srWindow->{Right}, $srWindow->{Bottom});
    }

    Win32::Console::_SetConsoleActiveScreenBuffer($_consoleStartupHandle);
    Win32::Console::_CloseHandle($_consoleInputHandle) 
      if $_owningInputHandle;
    Win32::Console::_CloseHandle($_consoleStartupHandle) 
      if $_consoleStartupHandle;
    Win32::Console::_CloseHandle($_consoleOutputHandle) 
      if $_consoleOutputHandle;
    Win32::Console::Free() 
      if $_ownsConsole;

    eval {
      q/*
      my $CONSOLE = Win32::Console->new(STD_INPUT_HANDLE);
      assert { $CONSOLE };
      assert { !!$CONSOLE->Mode() };
      $CONSOLE->Mode($_startup_input_mode);

      $CONSOLE = Win32::Console->new(STD_OUTPUT_HANDLE);
      assert { $CONSOLE };
      assert { !!$CONSOLE->Mode() };
      $CONSOLE->Mode($_startup_output_mode);
      */ if 0;

      $_initialized = FALSE;
    } or do {
      warn($@ =~ /(.+?)$/m ? "$1\n" : $@);
    };
  
    return;
  }

=end private

=back

=head2 Inheritance

Methods inherited from class L<Class::Tiny::Object|Class::Tiny>

  new, DESTROY

Methods inherited from class L<UNIVERSAL>

  can, DOES, isa, VERSION

=cut

}

1;

# ------------------------------------------------------------------------
# Injections -------------------------------------------------------------
# ------------------------------------------------------------------------

# see RT64675 https://rt.cpan.org/Public/Bug/Display.html?id=64675
#----------------------------------------
package Win32::Console::PatchForRT64675 {
#----------------------------------------
  use Win32::Console qw();
  my $old_InputChar = Win32::Console->can('InputChar');
  my $new_InputChar = sub {
    my ($self, $number) = @_;
    return undef unless ref($self);
    $number = 1 unless defined($number);
 
    my $buffer = (" " x $number);
    $number = Win32::Console::_ReadConsole($self->{'handle'}, 
      $buffer, $number);
    return undef unless $number;
    substr($buffer, $number) = '';
    return $buffer;
  };
  no warnings qw( redefine );
  *Win32::Console::InputChar = $new_InputChar;
  1;
}

# see RT64676 https://rt.cpan.org/Public/Bug/Display.html?id=64676
#----------------------------------------
package Win32::Console::PatchForRT64676 {
#----------------------------------------
  use Win32::Console qw();
  my $Close = sub {
    my ($self) = @_;
    return undef unless ref($self);
    return Win32::Console::_CloseHandle($self->{'handle'});
  };
  no warnings qw( once redefine );
  *Win32::Console::Close = $Close unless Win32::Console->can('Close');
  1;
}

# Writing 0 bytes causes the cursor to become invisible for a short time in old
# versions of the Windows console.
#--------------------------------------
package Win32::Console::PatchForWrite {
#--------------------------------------
  use Win32::Console qw();
  my $old_Write = Win32::Console->can('Write');
  my $new_Write = sub {
    my ($self, $string) = @_;
    return undef unless ref($self);
    return undef unless length($string);
    return Win32::Console::_WriteConsole($self->{'handle'}, $string);
  };
  no warnings qw( redefine );
  *Win32::Console::Write = $new_Write;
  1;
}

# see SYNOPSIS using this code
#---------------
package System {
#---------------
  use Exporter qw( import );
  our @EXPORT = qw( Console );
  sub Console() {
    require Win32::Console::DotNet;
    state $instance = Win32::Console::DotNet->instance();
  }
  $INC{'System.pm'} = 1;
}

# see Utilapiset.h and Winuser.h documentation for Beep() and GetKeyState()
#--------------------
package Win32Native {
#--------------------
  use English qw( -no_match_vars );
  use Win32::API;
  use constant {
    KERNEL32  => 'kernel32',
    USER32    => 'user32',
  };
  BEGIN {
    Win32::API::More->Import(KERNEL32, 
      'BOOL Beep(DWORD dwFreq, DWORD dwDuration)'
    ) or die "Import Beep: $EXTENDED_OS_ERROR";
    Win32::API::More->Import(USER32, 
      'int GetKeyState(int nVirtKey)'
    ) or die "Import GetKeyState: $EXTENDED_OS_ERROR";
  }
  $INC{'Win32Native.pm'} = 1;
}

__END__

=head1 COPYRIGHT AND LICENCE

 This class provides access to the standard input, standard output
 and standard error streams

 Copyright (c) 2015 by Microsoft Corporation.

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

=head1 CONTRIBUTORS

=over

=item *

1998-2008 by Andy Wardley E<lt>abw@wardley.orgE<gt> (Code snippet from 
L<Class:Singleton>)

=item *

2014, 2020 by Steve Hay (Code snippet from 
L<Class:Singleton>)

=item *

2008, 2009 by Piotr Roszatycki E<lt>dexter@cpan.orgE<gt> (Code snippet from 
L<constant:boolean>)

=item *

2011 by Joe Vornehm E<lt>joejr@vornehm.comE<gt> (Code snippet from I<RT64675>)

=item *

2019-2021 by magiblot E<lt>magiblot@hotmail.comE<gt> (Code snippet from 
I<stdioctl.cpp>)

=back

=head1 SEE ALSO

L<Win32::Console>, 
L<console.cs|https://github.com/microsoft/referencesource/blob/51cf7850defa8a17d815b4700b67116e3fa283c2/mscorlib/system/console.cs>
