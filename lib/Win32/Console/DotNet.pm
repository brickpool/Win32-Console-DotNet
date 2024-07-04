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
our $VERSION = '0.003_000';
$VERSION = eval $VERSION;

# authority '...'
our $authority = 'github:microsoft';
our $AUTHORITY = 'github:brickpool';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use Devel::StrictMode;
no if !STRICT, 'warnings', qw( void );

use Config;
use English qw( -no_match_vars );
use IO::File;
use IO::Null;
use List::Util qw( max );
use PerlX::Assert;
use Symbol;
use threads;
use threads::shared;
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

  Defined
  ArrayRef
  CodeRef
  Object
  Str
  Bool
  Int

=cut

  use Type::Nano qw(
    Defined
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
    assert { @_ == 1 };
    return Object->check($_[0]);
  }

=item I<is_Bool>

  sub is_Bool($value) : Bool

Check for a reasonable boolean value. Accepts 1, 0, the empty string and undef.

I<param> $value to be checked

I<return> true if operand is boolean

=cut

  sub is_Bool($) {
    assert { @_ == 1 };
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
    assert { @_ == 1 };
    unless ( ArrayRef->check($_[0]) ) {
      confess("IllegalArgumentException: %s\n", ArrayRef->get_message($_[0]));
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
    assert { @_ == 1 };
    unless ( CodeRef->check($_[0]) ) {
      confess("IllegalArgumentException: %s\n", CodeRef->get_message($_[0]));
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
    assert { @_ == 1 };
    unless ( Str->check($_[0]) ) {
      confess("IllegalArgumentException: %s\n", Str->get_message($_[0]));
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
    assert { @_ == 1 };
    unless ( Object->check($_[0]) ) {
      confess("IllegalArgumentException: %s\n", Object->get_message($_[0]));
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
    assert { @_ == 1 };
    unless ( Bool->check($_[0]) ) {
      confess("IllegalArgumentException: %s\n", Bool->get_message($_[0]));
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
    assert { @_ == 1 };
    unless ( Int->check($_[0]) ) {
      confess("IllegalArgumentException: %s\n", Int->get_message($_[0]));
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
    _DEBUG
    TRUE
    FALSE
    DefaultConsoleBufferSize
    MinBeepFrequency
    MaxBeepFrequency
    MaxConsoleTitleLength
    StdConUnicodeEncoding

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

    eventType
    keyDown
    repeatCount
    virtualKeyCode
    virtualScanCode
    uChar
    controlKeyState
  )];

=end private

=head2 Constants

=over

=item I<_DEBUG>

  use constant _DEBUG => 1|undef;

I<_DEBUG> is defined as 1 if the environment variable C<NDEBUG> or 
C<PERL_NDEBUG> is not defined as true and any of the following environment 
variables have been set to true, otherwise undefined.

  PERL_STRICT
  EXTENDED_TESTING
  AUTHOR_TESTING
  RELEASE_TESTING

I<see> L<Devel::StrictMode>

=cut

  use constant _DEBUG => (STRICT and !$ENV{NDEBUG} || !$ENV{PERL_NDEBUG}) 
                          ? 1 : undef;

=item I<TRUE>

=item I<FALSE>

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

=item I<DefaultConsoleBufferSize>

  use constant DefaultConsoleBufferSize => 256;

Defines the standard console buffer size.

=cut

  use constant DefaultConsoleBufferSize => 256;

=item I<MinBeepFrequency>

=item I<MaxBeepFrequency>

  use constant {
    MinBeepFrequency  => 0x25,
    MaxBeepFrequency  => 0x7fff,
  };

Beep range - see MSDN.

=cut

  use constant {
    MinBeepFrequency  => 0x25,
    MaxBeepFrequency  => 0x7fff,
  };

=item I<MaxConsoleTitleLength>

  use constant MaxConsoleTitleLength => 24500;

MSDN says console titles can be up to 64 KB in length.
But I get an exception if I use buffer lengths longer than
~24500 Unicode characters.  Oh well.

=cut

  use constant MaxConsoleTitleLength => 24500;

=item I<StdConUnicodeEncoding>

  use constant StdConUnicodeEncoding => { CodePage => Int, bigEndian => Int };

The value corresponds to the Windows code pages 1200 (little endian byte 
order) or 1201 (big endian byte order).

=cut

  use constant StdConUnicodeEncoding => {
    CodePage  => $Config{byteorder} == 1234 ? 1200 : 1201,
    bigEndian => $Config{byteorder} == 4321 ? 1 : 0,
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
    eventType       => 0,
    keyDown         => 1,
    repeatCount     => 2,
    virtualKeyCode  => 3,
    virtualScanCode => 4,
    uChar           => 5,
    controlKeyState => 6,
  };

Constants for accessing the input event array which is used for the console 
input buffer API calls.

I<see> KEY_EVENT_RECORD structure.

=cut

  use constant {
    eventType       => 0,
    keyDown         => 1,
    repeatCount     => 2,
    virtualKeyCode  => 3,
    virtualScanCode => 4,
    uChar           => 5,
    controlKeyState => 6,
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

=item I<_defaultColors>

  my $_defaultColors ( is => private, type => Ref[Int] );

Reference value of L<$ATTR_NORMAL|Win32::Console>, used for L</ResetColor>. 

=cut

  my $_defaultColors = \$ATTR_NORMAL;

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

=item I<InternalSyncObject>

  my $InternalSyncObject ( is => private, type => Any );

Private variable for locking instead of locking on a public type for SQL 
reliability work.

Use this for internal synchronization during initialization, wiring up events, 
or for short, non-blocking OS calls.

=item I<ReadKeySyncObject>

  my $ReadKeySyncObject ( is => private, type => Any );

Use this for blocking in Console->ReadKey, which needs to protect itself in 
case multiple threads call it simultaneously.

Use a ReadKey-specific lock though, to allow other fields to be initialized on 
this type.

=cut

  my $InternalSyncObject :shared;
  my $ReadKeySyncObject :shared;

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

=item I<_leaveOpen>

  my $_leaveOpen ( is => private, type => HashRef ) = {};

If a file handle needs to be protected against automatic closing (when leaving 
the scope), the associated parameter I<$ownsHandle> is set to false when 
L</SafeFileHandle> is called.

To leave the file handle open, we save the IO:Handle object in this hash 
so that the REFCNT is > 0. 

=cut

  my $_leaveOpen = {};

=item I<ResourceString>

  my %ResourceString ( is => private, type => Hash ) = (...);

This hash variable contains all resource strings that are used here in this 
package.

=cut

  my %ResourceString = (
    ArgumentNullException =>
      "Value cannot be null. Parameter name: %s",
    Arg_InvalidConsoleColor =>
      "The ConsoleColor enum value was not defined on that enum. Please ".
      "use a defined color from the enum.",
    ArgumentOutOfRange_BeepFrequency =>
      "Console->Beep's frequency must be between between %d and %d.",
    ArgumentOutOfRange_ConsoleBufferBoundaries =>
      "The value must be greater than or equal to zero and less than the ".
      "console's buffer size in that dimension.",
    ArgumentOutOfRange_ConsoleBufferLessThanWindowSize =>
      "The console buffer size must not be less than the current size and ".
      "position of the console window, nor greater than or equal to 32767.",
    ArgumentOutOfRange_CursorSize =>
      "The cursor size is invalid. It must be a percentage between 1 and 100.",
    ArgumentOutOfRange_ConsoleTitleTooLong
      => "The console title is too long.",
    ArgumentOutOfRange_ConsoleWindowBufferSize =>
      "The new console window size would force the console buffer size to be "
      ."too large.",
    ArgumentOutOfRange_ConsoleWindowPos =>
      "The window position must be set such that the current window size fits".
      "within the console's buffer, and the numbers must not be negative.",
    ArgumentOutOfRange_ConsoleWindowSize_Size =>
      "The value must be less than the console's current maximum window size ".
      "of %d in that dimension. Note that this value depends on screen ".
      "resolution and the console font.",
    ArgumentOutOfRange_NeedPosNum =>
      "Positive number required.",
    ArgumentOutOfRange_NeedNonNegNum =>
      "Non-negative number required.",
    InvalidOperation_ConsoleKeyAvailableOnFile =>
      "Cannot see if a key has been pressed when either application does not ".
      "have a console or when console input has been redirected from a file.",
    InvalidOperation_ConsoleReadKeyOnFile =>
      "Cannot read keys when either application does not have a console or ".
      "when console input has been redirected. Try Console->Read.",
    IO_NoConsole =>
      "There is no console.",
  );

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
      if ( $value < 0 || $value > 15 ) {
        confess("ArgumentException:\n".
          "$ResourceString{Arg_InvalidConsoleColor}\n");
      }
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

  field CapsLock ( is => rwp, type => Bool );

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
        or confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      $self->$orig($value);
      if ( $value < 1 || $value > 100 ) {
        confess("ArgumentOutOfRangeException: value $value\n". 
          "$ResourceString{ArgumentOutOfRange_CursorSize}\n");
      }
      my $hConsole = ConsoleOutputHandle();
      my (undef, $visible) = Win32::Console::_GetConsoleCursorInfo($hConsole)
        or confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
      Win32::Console::_SetConsoleCursorInfo($hConsole, $value, $visible)
        or confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
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
        or confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      $self->$orig($value);
      my $hConsole = ConsoleOutputHandle();
      my ($size) = Win32::Console::_GetConsoleCursorInfo($hConsole)
        or confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
      Win32::Console::_SetConsoleCursorInfo($hConsole, $size, $value)
        or confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
      return;
    }
  };

=item I<Error>

  field Error ( is => rwp, type => Defined );

A IO::Handle that represents the standard error stream.

=cut

  has Error => (
    is        => 'rwp',
    isa       => Defined,
    # init_arg  => undef,
  );

  around 'Error' => sub {
    assert { @_ == 2 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    GET: {
      unless ( defined $_error ) {
        InitializeStdOutError(FALSE);
        $self->$orig($_error);
      }
      return $_error;
    }
  };

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
      if ( $value < 0 || $value > 15 ) {
        confess("ArgumentException:\n".
          "$ResourceString{Arg_InvalidConsoleColor}\n");
      }
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

  field In ( is => rwp, type => Defined );

A IO::Handle that represents the standard input stream.

=cut

  has In => (
    is        => 'rwp',
    isa       => Defined,
    # init_arg  => undef,
  );

  around 'In' => sub {
    assert { @_ == 2 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    GET: {
      # Because most applications don't use stdin, we can delay 
      # initialize it slightly better startup performance.
      unless ( defined $_in ) {
        lock($InternalSyncObject);
        # Set up Console->In
        my $s = __PACKAGE__->OpenStandardInput();
        my $reader;
        if ( !$s ) {
          $reader = IO::Null->new();
        } else {
          my $enc = $_inputEncoding // Win32::GetConsoleCP();
          $reader = IO::Handle->new_from_fd(fileno($s), 'r');
          $reader->binmode(':encoding(UTF-8)') if $enc == 65001;
        }
        $self->$orig($_in = $reader);
      }
      return $_in;
    }
  };

=item I<InputEncoding>

  field InputEncoding ( is => rw, type => Int ) = GetConsoleCP();

Gets or sets the encoding the console uses to write input.

I<note> A get operation may return a cached value instead of the console's 
current input encoding.

=cut

  has InputEncoding => (
    is        => 'rw',
    isa       => Int,
    # init_arg  => undef,
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
        lock($InternalSyncObject);

        my $cp = Win32::GetConsoleCP();
        $self->$orig($_inputEncoding = $cp);
        return $_inputEncoding;
      }
    }
    SET: {
      my $value = shift;
      if ( !defined $value ) {
        confess("ArgumentNullException:\n". 
          sprintf("$ResourceString{ArgumentNullException}\n", "value"));
      }
      $self->$orig($value);

      {
        lock($InternalSyncObject);

        if ( !IsStandardConsoleUnicodeEncoding($value) ) {
          my $cp = $value;
          my $r = Win32::SetConsoleCP($cp);
          if ( !$r ) {
            confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
          }
        }

        $_inputEncoding = $value;

        # We need to reinitialize Console->In in the next call to _in
        # This will discard the current IO::Handle, potentially 
        # losing buffered data
        $_in = undef;
        return;
      }
    }
  };

=item I<IsErrorRedirected>

  field IsErrorRedirected ( is => ro, type => Bool );

Gets a value that indicates whether error has been redirected from the 
standard error stream.  True if error is redirected; otherwise, false.

=cut

  has IsErrorRedirected => (
    is        => 'ro',
    isa       => Bool,
    # init_arg  => undef,
  );

  around 'IsErrorRedirected' => sub {
    assert { @_ == 2 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    GET: {
      unless ( $_stdErrRedirectQueried ) {
        lock($InternalSyncObject);
        my $errHndle = Win32::Console::_GetStdHandle(STD_ERROR_HANDLE);
        $_isStdErrRedirected = IsHandleRedirected($errHndle);
        $_stdErrRedirectQueried = TRUE;
        $self->$orig($_isStdErrRedirected);
      }
      return $_isStdErrRedirected;
    }
  };

=item I<IsInputRedirected>

  field IsInputRedirected ( is => ro, type => Bool );

Gets a value that indicates whether input has been redirected from the 
standard input stream.  True if input is redirected; otherwise, false.

=cut

  has IsInputRedirected => (
    is        => 'ro',
    isa       => Bool,
    # init_arg  => undef,
  );

  around 'IsInputRedirected' => sub {
    assert { @_ == 2 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    GET: {
      unless ( $_stdInRedirectQueried ) {
        lock($InternalSyncObject);
        $_isStdInRedirected = IsHandleRedirected(ConsoleInputHandle());
        $_stdInRedirectQueried = TRUE;
        $self->$orig($_isStdInRedirected);
      }
      return $_isStdInRedirected;
    }
  };

=item I<IsOutputRedirected>

  field IsOutputRedirected ( is => ro, type => Bool );

Gets a value that indicates whether output has been redirected from the 
standard output stream.  True if output is redirected; otherwise, false.

=cut

  has IsOutputRedirected => (
    is        => 'ro',
    isa       => Bool,
    # init_arg  => undef,
  );

  around 'IsOutputRedirected' => sub {
    assert { @_ == 2 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    GET: {
      if ( !$_stdOutRedirectQueried ) {
        lock($InternalSyncObject);
        $_isStdOutRedirected = IsHandleRedirected(ConsoleOutputHandle());
        $_stdOutRedirectQueried = TRUE;
        $self->$orig($_isStdOutRedirected);
      }
      return $_isStdOutRedirected;
    }
  };

=item I<KeyAvailable>

  field KeyAvailable ( is => ro, type => Bool );

Gets a value indicating whether a key press is available in the input stream.

=cut

  has KeyAvailable => (
    is        => 'ro',
    isa       => Bool,
    # init_arg  => undef,
  );
  
  around 'KeyAvailable' => sub {
    assert { @_ == 2 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    GET: {
      if ( $_cachedInputRecord->[eventType] == Win32Native::KEY_EVENT ) {
        $self->$orig(TRUE);
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
            confess("InvalidOperationException:\n". 
              "$ResourceString{InvalidOperation_ConsoleKeyAvailableOnFile}". 
              "\n");
          }
          confess("WinIOError: stdin\n$EXTENDED_OS_ERROR\n");
        }

        if ( $numEventsRead == 0 ) {
          $self->$orig(FALSE);
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
            confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
          }
        } 
        else {
          $self->$orig(TRUE);
          return TRUE;
        }
      }
    }
  };

=item I<LargestWindowHeight>

  field LargestWindowHeight ( is => ro, type => Int );

Gets the largest possible number of console window rows, based on the current 
font and screen resolution.

=cut

  has LargestWindowHeight => (
    is        => 'ro',
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
      $self->$orig($bounds_Y);
      return $bounds_Y;
    }
  };

=item I<LargestWindowWidth>

  field LargestWindowWidth ( is => ro, type => Int );

Gets the largest possible number of console window columns, based on the 
current font and screen resolution.

=cut

  has LargestWindowWidth => (
    is        => 'ro',
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
      $self->$orig($bounds_X);
      return $bounds_X;
    }
  };

=item I<NumberLock>

  field NumberLock ( is => ro, type => Bool );

Gets a value indicating whether the NUM LOCK keyboard toggle is turned on or 
turned off.

=cut

  has NumberLock => (
    is        => 'ro',
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
      $self->$orig($value);
      return $value;
    }
  };

=item I<Out>

  field Out ( is => rwp, type => Defined );

A IO::Handle that represents the standard output stream.

=cut

  has Out => (
    is        => 'rwp',
    isa       => Defined,
    # init_arg  => undef,
  );

  around 'Out' => sub {
    assert { @_ == 2 };
    my $orig = assert_CodeRef shift;
    my $self = assert_Object shift;
    GET: {
      unless ( defined $_out ) {
        InitializeStdOutError(TRUE);
        $self->$orig($_out);
      }
      return $_out;
    }
  };

=item I<OutputEncoding>

  field OutputEncoding ( is => rw, type => Int ) = GetConsoleOutputCP();

Gets or sets the encoding the console uses to write output.

I<note> A get operation may return a cached value instead of the console's 
current output encoding.

=cut

  has OutputEncoding => (
    is        => 'rw',
    isa       => Int,
    # init_arg  => undef,
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
        lock($InternalSyncObject);

        return $_outputEncoding
          if $_outputEncoding;

        my $cp = Win32::GetConsoleOutputCP();
        $self->$orig($_outputEncoding = $cp);
        return $_outputEncoding;
      }
    }
    SET: {
      my $value = shift;
      if ( !defined $value ) {
        confess("ArgumentNullException:\n". 
          sprintf("$ResourceString{ArgumentNullException}\n", "value"));
      }
      $self->$orig($value);

      {
        lock($InternalSyncObject);
        # Before changing the code page we need to flush the data 
        # if Out hasn't been redirected. Also, have the next call to  
        # $_out reinitialize the console code page.

        if ( $self->Out && !$self->IsOutputRedirected ) {
          $self->Out->flush();
          $_out = undef;
        }
        if ( $self->Error && !$self->IsErrorRedirected ) {
          $self->Error->flush();
          $_error = undef;
        }

        if ( !IsStandardConsoleUnicodeEncoding($value) ) {
          my $cp = $value;
          my $r = Win32::SetConsoleOutputCP($cp);
          if ( !$r ) {
            confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
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
        or confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
      $self->$orig($title);
      if ( length($title) > MaxConsoleTitleLength ) {
        confess("InvalidOperationException:\n".
          "$ResourceString{ArgumentOutOfRange_ConsoleTitleTooLong}\n");
      }
      return $title;
    }
    SET: {
      my $value = shift;
      $self->$orig($value);
      if ( length($value) > MaxConsoleTitleLength ) {
        confess("InvalidOperationException:\n".
          "$ResourceString{ArgumentOutOfRange_ConsoleTitleTooLong}\n");
      }
      Win32::Console::_SetConsoleTitle($value)
        or confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
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
        confess("IOException:\n$ResourceString{IO_NoConsole}\n");
      }
      my $mode = 0;
      my $r = do {
        Win32::SetLastError(0);
        $mode = Win32::Console::_GetConsoleMode($handle) || 0;
        Win32::GetLastError() == 0;
      };
      if ( !$r ) {
        confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
      }
      my $value = ($mode & ENABLE_PROCESSED_INPUT) == 0;
      $self->$orig($value);
      return $value;
    }
    SET: {
      my $value = shift;
      my $handle = ConsoleInputHandle();
      if ( $handle == Win32API::File::INVALID_HANDLE_VALUE ) {
        confess("IOException:\n$ResourceString{IO_NoConsole}\n");
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
        confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
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
    if ( !defined $instance ) {
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

    if ( $frequency < MinBeepFrequency || $frequency > MaxBeepFrequency ) {
      confess("ArgumentOutOfRangeException: frequency $frequency\n". 
        sprintf("$ResourceString{ArgumentOutOfRange_BeepFrequency}\n", 
          MinBeepFrequency, MaxBeepFrequency));
    }
    if ( $duration <= 0 ) {
      confess("ArgumentOutOfRangeException: duration $duration\n". 
        "$ResourceString{ArgumentOutOfRange_NeedPosNum}\n");
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
      confess("IOException:\n$ResourceString{IO_NoConsole}\n");
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
    if ( !$success ) {
      confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
    }

    # now set the buffer's attributes accordingly

    $numCellsWritten = 0;
    $success = do {
      $numCellsWritten = Win32::Console::_FillConsoleOutputAttribute($hConsole,
        $csbi->{wAttributes}, $conSize, $coordScreen->{X}, $coordScreen->{Y});
      $numCellsWritten > 0;
    };
    if ( !$success ) {
      confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
    }

    # put the cursor at (0, 0)

    $success = Win32::Console::_SetConsoleCursorPosition($hConsole, 
      $coordScreen->{X}, $coordScreen->{Y});
    if ( !$success ) {
      confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
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

    if ( $sourceForeColor < 0 || $sourceForeColor > 15 ) {
      confess("ArgumentException: sourceForeColor\n".
        "$ResourceString{Arg_InvalidConsoleColor}\n");
    }
    if ( $sourceBackColor < 0 || $sourceBackColor > 15 ) {
      confess("ArgumentException: sourceBackColor\n".
        "$ResourceString{Arg_InvalidConsoleColor}\n");
    }

    my $csbi = GetBufferInfo();
    my $bufferSize = $csbi->{dwSize};
    if ( $sourceLeft < 0 || $sourceLeft > $bufferSize->{X} ) {
      confess("ArgumentOutOfRangeException: sourceLeft $sourceLeft\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
    }
    if ( $sourceTop < 0 || $sourceTop > $bufferSize->{Y} ) {
      confess("ArgumentOutOfRangeException: sourceTop $sourceTop\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
    }
    if ( $sourceWidth < 0 || $sourceWidth > $bufferSize->{X} - $sourceLeft ) {
      confess("ArgumentOutOfRangeException: sourceWidth $sourceWidth\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
    }
    if ( $sourceHeight < 0 || $sourceTop > $bufferSize->{Y} - $sourceHeight ) {
      confess("ArgumentOutOfRangeException: sourceHeight $sourceHeight\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
    }

    # Note: if the target range is partially in and partially out
    # of the buffer, then we let the OS clip it for us.
    if ( $targetLeft < 0 || $targetLeft > $bufferSize->{X} ) {
      confess("ArgumentOutOfRangeException: targetLeft $targetLeft\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
    }
    if ( $targetTop < 0 || $targetTop > $bufferSize->{Y} ) {
      confess("ArgumentOutOfRangeException: targetTop $targetTop\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
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
    if ( !$r ) {
      confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
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
      if ( !$r ) {
        confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
      }
      $r = do {
        Win32::SetLastError(0);
        $numWritten = Win32::Console::_FillConsoleOutputAttribute(
          ConsoleOutputHandle(), $attr, $sourceWidth,
          $writeCoord->{X}, $writeCoord->{Y}
        ) || 0;
        Win32::GetLastError() == 0;
      };
      if ( !$r ) {
        confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
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

  method OpenStandardError(Int $bufferSize=DefaultConsoleBufferSize) 
    : FileHandle

Acquires the standard error object.

I<return> the standard error object.

=cut

  sub OpenStandardError {
    assert { @_ == 1 || @_ == 2 };
    my $caller = shift;
    my $bufferSize = @_ ? assert_Int(shift) : DefaultConsoleBufferSize;

    assert { $caller };
    assert { is_Object($caller) || !ref($caller) && $caller eq __PACKAGE__ };

    if ( $bufferSize < 0 ) {
      confess("ArgumentOutOfRangeException: bufferSize\n". 
        "$ResourceString{ArgumentOutOfRange_NeedNonNegNum}\n");
    }
    return GetStandardFile(STD_ERROR_HANDLE, 'w', $bufferSize);
  }

=item I<OpenStandardInput>

  method OpenStandardInput(Int $bufferSizeDefaultConsoleBufferSize) 
    : FileHandle

Acquires the standard input object.

I<return> the standard input object.

=cut

  sub OpenStandardInput {
    assert { @_ == 1 || @_ == 2 };
    my $caller = shift;
    my $bufferSize = @_ ? assert_Int(shift) : DefaultConsoleBufferSize;

    assert { $caller };
    assert { is_Object($caller) || !ref($caller) && $caller eq __PACKAGE__ };

    if ( $bufferSize < 0 ) {
      confess("ArgumentOutOfRangeException: bufferSize\n". 
        "$ResourceString{ArgumentOutOfRange_NeedNonNegNum}\n");
    }
    return GetStandardFile(STD_INPUT_HANDLE, 'r', $bufferSize);
  }

=item I<OpenStandardOutput>

  method OpenStandardOutput(Int $bufferSize=DefaultConsoleBufferSize) 
    : FileHandle

Acquires the standard output object.

I<return> the standard output object.

=cut

  sub OpenStandardOutput {
    assert { @_ == 1 || @_ == 2 };
    my $caller = shift;
    my $bufferSize = @_ ? assert_Int(shift) : DefaultConsoleBufferSize;

    assert { $caller };
    assert { is_Object($caller) || !ref($caller) && $caller eq __PACKAGE__ };

    if ( $bufferSize < 0 ) {
      confess("ArgumentOutOfRangeException: bufferSize\n". 
        "$ResourceString{ArgumentOutOfRange_NeedNonNegNum}\n");
    }
    return GetStandardFile(STD_OUTPUT_HANDLE, 'w', $bufferSize);
  }

=item I<Read>

  method Read() : Int

Reads the next character from the standard input stream.

I<return> the next character from the input stream, or negative one (-1) if 
there are currently no more characters to be read.

I<throws> IOException if an I/O error occurred.

=cut

  sub Read {
    assert { @_ == 1 };
    my $self = assert_Object shift;

    assert { $self->In };
    $! = undef;
    $self->In->sysread(my $ch, 1);
    confess("IOException:\n$OS_ERROR\n") if $!;
    return $ch ? ord($ch) : -1;
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
    my $intercept = @_ ? assert_Bool(shift) : FALSE;

    my @ir;
    my $numEventsRead = -1;
    my $r;

    { 
      lock($ReadKeySyncObject);

      if ( $_cachedInputRecord->[eventType] == Win32Native::KEY_EVENT ) {
        # We had a previous keystroke with repeated characters.
        @ir = @$_cachedInputRecord;
        if ( $_cachedInputRecord->[repeatCount] == 0 ) {
          $_cachedInputRecord->[eventType] = -1;
        } else {
          $_cachedInputRecord->[repeatCount]--; 
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
            # We could theoretically call Console->Read here, but I 
            # think we might do some things incorrectly then.
            confess("InvalidOperationException:\n".
              "$ResourceString{InvalidOperation_ConsoleReadKeyOnFile}\n");
          }

          my $keyCode = $ir[virtualKeyCode];

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

          my $ch = $ir[uChar];

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

          if ( $ir[repeatCount] > 1 ) {
            $ir[repeatCount]--;
            $_cachedInputRecord = \@ir;
          }
          last;
        }
      } # we did NOT have a previous keystroke with repeated characters.
    } # lock($ReadKeySyncObject)

    my $state = $ir[controlKeyState];
    my $shift = ($state & SHIFT_PRESSED) != 0;
    my $alt = ($state & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED)) != 0;
    my $control = ($state & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED)) != 0;

    my $info = {
      keyChar   => chr($ir[uChar]),
      key       => $ir[virtualKeyCode],
      modifiers => ($shift ? 2 : 0) + ($alt ? 1 : 0) + ($control ? 4 : 0),
    };

    if ( $intercept ) {
      $self->write($ir[uChar]);
    }
    return $info;
  }

=item I<ReadLine>

  method ReadLine() : Str

Reads the next line of characters from the standard input stream.

I<return> the next line of characters from the input stream, or C<undef> if no 
more lines are available.

I<throws> IOException if an I/O error occurred.

=cut

  sub ReadLine {
    assert { @_ == 1 };
    my $self = assert_Object shift;

    assert { $self->In };
    $! = undef;
    my $str = $self->In->getline() // '';
    confess("IOException:\n$OS_ERROR\n") if $!;
    return $str;
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
 
    my $defaultAttrs = $$_defaultColors & 0xff;
    # Ignore errors here - there are some scenarios for running code that wants
    # to print in colors to the console in a Windows application.
    Win32::Console::_SetConsoleTextAttribute(ConsoleOutputHandle(), 
      $defaultAttrs);
    return;
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
      confess("ArgumentOutOfRangeException: width $width\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferLessThanWindowSize}",
        "\n");
    }
    if ( $height < $srWindow->{Bottom} + 1 || $height >= 0x7fff ) {
      confess("ArgumentOutOfRangeException: height $height\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferLessThanWindowSize}",
        "\n");
    }
    Win32::Console::_SetConsoleScreenBufferSize(ConsoleOutputHandle(), 
      $width, $height) or confess("WinIOError:\n$EXTENDED_OS_ERROR\n");

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
      confess("ArgumentOutOfRangeException: left $left\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
    }
    if ( $top < 0 || $top >= 0x7fff ) {
      confess("ArgumentOutOfRangeException: top $top\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
    }

    my $hConsole = ConsoleOutputHandle();
    my $r = Win32::Console::_SetConsoleCursorPosition($hConsole, $left, $top);
    if ( !$r ) {
      # Give a nice error message for out of range sizes
      my $errorCode = Win32::GetLastError();
      my $csbi = GetBufferInfo();
      if ( $left < 0 || $left >= $csbi->{dwSize}->{X} ) {
        confess("ArgumentOutOfRangeException: left $left\n". 
          "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
      }
      if ( $top < 0 || $top >= $csbi->{dwSize}->{Y} ) {
        confess("ArgumentOutOfRangeException: top $top\n". 
          "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
      }

      confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
    }

    $self->{CursorLeft} = $left;
    $self->{CursorTop} = $top;
    return;
  }

=item I<SetError>

  method SetError(IO::Handle $newError)

Sets the L</Error> attribute to the specified error IO::Handle.

I<param> $newError represents a IO::Handle that is the new standard error.

=cut

  sub SetError {
    assert { @_ == 2 };
    my $self = assert_Object shift;
    my $newError = shift;

    if ( !defined $newError ) {
      confess("ArgumentNullException:\n". 
        sprintf("$ResourceString{ArgumentNullException}\n", "newError"));
    }
    {
      lock($InternalSyncObject);
      $self->_set_Error($_error = $newError);
    }
    return;
  }

=item I<SetIn>

  method SetIn(IO::Handle $newIn)

Sets the L</In> attribute to the specified input IO::Handle.

I<param> $newIn represents a io handle that is the new standard input.

=cut

  sub SetIn {
    assert { @_ == 2 };
    my $self = assert_Object shift;
    my $newIn = shift;

    if ( !defined $newIn ) {
      confess("ArgumentNullException:\n". 
        sprintf("$ResourceString{ArgumentNullException}\n", "newIn"));
    }
    {
      lock($InternalSyncObject);
      $self->_set_In($_in = $newIn);
    }
    return;
  }

=item I<SetOut>

  method SetOut(IO::Handle $newOut)

Sets the L</Out> attribute to the specified output IO::Handle.

I<param> $newOut represents a io handle that is the new standard output.

=cut

  sub SetOut {
    assert { @_ == 2 };
    my $self = assert_Object shift;
    my $newOut = shift;

    if ( !defined $newOut ) {
      confess("ArgumentNullException:\n". 
        sprintf("$ResourceString{ArgumentNullException}\n", "newOut"));
    }
    {
      lock($InternalSyncObject);
      $self->_set_Out($_out = $newOut);
    }
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
      confess("ArgumentOutOfRangeException: width $width\n". 
        "$ResourceString{ArgumentOutOfRange_NeedPosNum}\n");
    }
    if ( $height <= 0 ) {
      confess("ArgumentOutOfRangeException: height $height\n". 
        "$ResourceString{ArgumentOutOfRange_NeedPosNum}\n");
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
        confess("ArgumentOutOfRangeException: width $width\n". 
          "$ResourceString{ArgumentOutOfRange_ConsoleWindowBufferSize}\n");
      }
      $size->{X} = $csbi->{srWindow}->{Left} + $width;
      $resizeBuffer = TRUE;
    }
    if ( $csbi->{dwSize}->{Y} < $csbi->{srWindow}->{Top} + $height ) {
      if ( $csbi->{srWindow}->{Top} >= 0x7fff - $height ) {
        confess("ArgumentOutOfRangeException: height $height\n". 
          "$ResourceString{ArgumentOutOfRange_ConsoleWindowBufferSize}\n");
      }
      $size->{Y} = $csbi->{srWindow}->{Top} + $height;
      $resizeBuffer = TRUE;
    }
    if ( $resizeBuffer ) {
      $r = Win32::Console::_SetConsoleScreenBufferSize(ConsoleOutputHandle(), 
        $size->{X}, $size->{Y});
      if ( !$r ) {
        confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
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
        confess("ArgumentOutOfRangeException: width $width\n". 
          sprintf("$ResourceString{ArgumentOutOfRange_ConsoleWindowSize_Size}".
            "\n", $bounds->{X}));
      }
      if ( $height > $bounds->{Y} ) {
        confess("ArgumentOutOfRangeException: height $height\n". 
          sprintf("$ResourceString{ArgumentOutOfRange_ConsoleWindowSize_Size}".
            "\n", $bounds->{Y}));
      }

      confess(sprintf("WinIOError:\n%s\n", Win32::FormatMessage($errorCode)));
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
      confess("ArgumentOutOfRangeException: left $left\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleWindowPos}\n");
    }
    my $newBottom = $top + $srWindow->{Bottom} - $srWindow->{Top} + 1;
    if ( $top < 0 || $newBottom > $csbi->{dwSize}->{Y} || $newBottom < 0 ) {
      confess("ArgumentOutOfRangeException: top $top\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleWindowPos}\n");
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
    if ( !$r ) {
      confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
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

I<note> this method does not perform any formatting of its own: It uses the 
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

    assert { $self->Out };
    $! = undef;
    if ( @_ > 1 ) {
      $self->Out->printf(shift, @_);
    } elsif ( @_ > 0 ) {
      $self->Out->print(shift);
    }
    confess("IOException:\n$OS_ERROR\n") if $!;
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

I<note> this method does not perform any formatting of its own: It uses the 
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

    assert { $self->Out };
    $! = undef;
    if ( @_ > 1 ) {
      $self->Out->say(sprintf(shift, @_));
    } elsif ( @_ > 0 ) {
      $self->Out->say(shift);
    } else {
      $self->Out->say();
    }
    confess("IOException:\n$OS_ERROR\n") if $!;
    return;
  }

  # ------------------------------------------------------------------------
  # Subroutines ------------------------------------------------------------
  # ------------------------------------------------------------------------

=begin private

=cut

  use namespace::sweep -also => [qw(
    CheckOutputDebug
    ColorAttributeToConsoleColor
    ConsoleColorToColorAttribute
    ConsoleHandleIsWritable
    ConsoleInputHandle
    ConsoleOutputHandle
    GetBufferInfo
    GetStandardFile
    GetUseFileAPIs
    InitializeStdOutError
    IsAltKeyDown
    IsHandleRedirected
    IsKeyDownEvent
    IsModKey
    IsStandardConsoleUnicodeEncoding
    MakeDebugOutputTextWriter
    SafeFileHandle
  )];

=item I<CheckOutputDebug>

  sub CheckOutputDebug() : Bool

Checks whether the developer mode is currently activated

I<return> true if the developer mode is currently enabled. It always returns 
false on Windows versions older than Windows 10.

=cut

  # This is ONLY used in debug builds.  If you have a registry key set,
  # it will redirect Console->Out & Error on console-less applications to
  # your debugger's output window.
  sub CheckOutputDebug {
    return exists(&Win32::IsDeveloperModeEnabled)
        && Win32::IsDeveloperModeEnabled();
  }

=item I<ColorAttributeToConsoleColor>

  sub ColorAttributeToConsoleColor(Int $c) : Int

Converts the color attribute of the Windows console into a color constant.

I<param> $c is a color attribute of the Windows Console. 

I<return> a console color constant.

=cut

  sub ColorAttributeToConsoleColor {
    assert { @_ == 1 };
    my $c = assert_Int shift;

    # Turn background colors into foreground colors.
    if ( ($c & 0xf0) != 0 ) {
      $c = $c >> 4;
    }

    return $c;
  }

=item I<ConsoleColorToColorAttribute>

  sub ConsoleColorToColorAttribute(Int $color, Bool $isBackground) : Int

Converts a color constant into the color attribute of the Windows Console.

I<param> $color specifies a color constant that defines the foreground or 
background color.

I<param> $isBackground specifies whether the specified color constant is a 
foreground or background color.

I<return> a color attribute of the Windows Console.

=cut

  sub ConsoleColorToColorAttribute {
    assert { @_ == 2 };
    my $color = assert_Int shift;
    my $isBackground = assert_Bool shift;

    if ( ($color & ~0xf) != 0 ) {
      confess("ArgumentException:\n".
        "$ResourceString{Arg_InvalidConsoleColor}\n");
    }

    my $c = $color;

    # Make these background colors instead of foreground
    if ( $isBackground ) {
      $c *= 16;
    }
    return $c;
  }

=item I<ConsoleHandleIsWritable>

  sub ConsoleHandleIsWritable(Int $outErrHandle) : Bool

Checks whether stdout or stderr are writable.  Do NOT pass
stdin here.

I<param> $outErrHandle is a handle to a file or I/O device (for example file, 
console buffer or pipe). The parameter should be created with write access.

I<return> true if the specified handle is writable, otherwise false. 

=cut

  sub ConsoleHandleIsWritable {
    assert { @_ == 1 };
    my $outErrHandle = assert_Int shift;

    # Do NOT call this method on stdin!

    # Windows apps may have non-null valid looking handle values for 
    # stdin, stdout and stderr, but they may not be readable or 
    # writable.  Verify this by calling WriteFile in the 
    # appropriate modes.
    # This must handle console-less Windows apps.

    my $bytesWritten;
    my $junkByte = chr 0x41;
    # We use our own Win32::API call for WriteFile because the Win32API::File 
    # version provides a different implementation for the use of the third 
    # parameter (nNumberOfBytesToWrite). 
    # According to the Windows API, it is intended that the value 0 performs a 
    # NULL write!
    my $r = Win32Native::WriteFile($outErrHandle, $junkByte, 0, $bytesWritten, 
      undef);
    # In Win32 apps w/ no console, bResult should be false for failure.
    return !!$r;
  }

=item I<ConsoleInputHandle>

  sub ConsoleInputHandle() : Int

Simplifies the use of GetStdHandle(STD_INPUT_HANDLE).

I<return> the standard input handle to the standard input device.

=cut

  sub ConsoleInputHandle {
    assert { @_ == 0 };
    $_consoleInputHandle //= Win32::Console::_GetStdHandle(STD_INPUT_HANDLE);
    return $_consoleInputHandle;
  }

=item I<ConsoleOutputHandle>

  sub ConsoleOutputHandle() : Int

Simplifies the use of GetStdHandle(STD_OUTPUT_HANDLE).

I<return> the standard output handle to the standard output device.

=cut

  sub ConsoleOutputHandle {
    assert { @_ == 0 };
    $_consoleOutputHandle //= Win32::Console::_GetStdHandle(STD_OUTPUT_HANDLE);
    return $_consoleOutputHandle;
  }

=item I<GetBufferInfo>

  sub GetBufferInfo() : HashRef
  sub GetBufferInfo(Bool $throwOnNoConsole, Bool $succeeded) : HashRef

Simplifies the use of GetConsoleScreenBufferInfo().

I<param> $throwOnNoConsole must be set to true if an exception is to be 
generated in the event of an error and false if an empty input record is to be 
returned instead. 

I<param> $succeeded [out] is true if no error occurred and false if an error 
occurred.

I<return> an hash reference with informations about the console.

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
        confess("IOException:\n$ResourceString{IO_NoConsole}\n");
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
        confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
      }
    }

    if ( !$_haveReadDefaultColors ) {
      # Fetch the default foreground and background color for the
      # ResetColor method.
      $$_defaultColors = $csbi[4] & 0xff;
      $_haveReadDefaultColors = TRUE;
    }

    $$succeeded = TRUE;
    return {
      dwSize => {
        X => $csbi[0],
        Y => $csbi[1],
      },
      dwCursorPosition => {
        X => $csbi[2],
        Y => $csbi[3],
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

=item I<GetStandardFile>

  sub GetStandardFile(Int $stdHandleName, Str $access, 
    Int $bufferSize) : IO::Handle

This subroutine is only exposed via methods to get at the console.
We won't use any security checks here.

I<param> $stdHandleName specified the standard device (STD_INPUT_HANDLE, 
STD_OUTPUT_HANDLE or STD_ERROR_HANDLE).

I<param> $access: the possible values of the $access parameter are 
system-dependent. See the documentation of L<Win32API::File/"OsFHandleOpen"> 
to see which values are available.

I<param> $bufferSize buffer size.

I<return> a FileHandle of the specified standard device (STD_INPUT_HANDLE, 
STD_OUTPUT_HANDLE or STD_ERROR_HANDLE) or IO::Null in the event of an error.

=cut

  sub GetStandardFile {
    assert { @_ == 3 };
    my $stdHandleName = assert_Int shift;
    my $access = assert_Str shift;
    my $bufferSize = assert_Int shift;

    # We shouldn't close the handle for stdout, etc, or we'll break
    # unmanaged code in the process that will print to console.
    # We should have a better way of marking this on SafeHandle.
    my $handle = Win32::Console::_GetStdHandle($stdHandleName);

    # If someone launches a managed process via CreateProcess, stdout
    # stderr, & stdin could independently be set to INVALID_HANDLE_VALUE.
    # Additionally they might use 0 as an invalid handle.
    if ( !$handle || $handle == Win32API::File::INVALID_HANDLE_VALUE ) {
      return IO::Null->new();
    }

    # Check whether we can read or write to this handle.
    if ( $stdHandleName != STD_INPUT_HANDLE 
      && !ConsoleHandleIsWritable($handle)
    ) {
      # Win32::OutputDebugString(sprintf("Console::ConsoleHandleIsValid for ".
      #   "std handle %ld failed, setting it to a null stream", 
      #   $stdHandleName)) if _DEBUG;
      return IO::Null->new();
    }

    my $useFileAPIs = GetUseFileAPIs($stdHandleName);

    # Win32::OutputDebugString(sprintf("Console::GetStandardFile for std ".
    #   "handle %ld succeeded, returning handle number %d", 
    #   $stdHandleName, $handle)) if _DEBUG;
    my $console = Symbol::gensym();
    my $sh = SafeFileHandle($console, FALSE);
    if ( !Win32API::File::OsFHandleOpen($sh, $handle, $access) ) {
      return IO::Null->new();
    }
    # Do not buffer console streams, or we can get into situations where
    # we end up blocking waiting for you to hit enter twice.  It was
    # redundant.
    return $console;
  }

=item I<GetUseFileAPIs>

  sub GetUseFileAPIs(Int $handleType) : Bool

This subroutine checks whether the file API should be used.

I<param> $handleType specified the standard device (STD_INPUT_HANDLE, 
STD_OUTPUT_HANDLE or STD_ERROR_HANDLE).

I<return> true if the specified handle should use the Window File API for 
console access, or false if the Windows Console API should rather be used. 

=cut

  sub GetUseFileAPIs {
    assert { @_ == 1 };
    my $handleType = assert_Int shift;

    switch: for ($handleType) {

      case: $_ == STD_INPUT_HANDLE and
        return !IsStandardConsoleUnicodeEncoding(Win32::GetConsoleCP()) 
            || 
          ($_isStdInRedirected // IsHandleRedirected(ConsoleInputHandle()));

      case: $_ == STD_OUTPUT_HANDLE and
        return !IsStandardConsoleUnicodeEncoding(Win32::GetConsoleOutputCP()) 
            || 
          ($_isStdOutRedirected // IsHandleRedirected(ConsoleOutputHandle()));

      case: $_ == STD_ERROR_HANDLE and
        return !IsStandardConsoleUnicodeEncoding(Win32::GetConsoleOutputCP()) 
            || 
          ($_isStdErrRedirected // IsHandleRedirected(
            Win32::Console::_GetStdHandle(STD_ERROR_HANDLE)));

      default: {
        # This can never happen.
        confess("Unexpected handleType value ($handleType)") if STRICT;
        return TRUE;
      }
    }
  }

=item I<InitializeStdOutError>

  sub InitializeStdOutError(Bool $stdout)

Initialization of standard output or standard error handle.

I<param> $stdout is true if a standard output handle is to be initialized and 
false if a standard error handle is to be initialized.

=cut

  # For console apps, the console handles are set to values like 3, 7, 
  # and 11 OR if you've been created via CreateProcess, possibly -1
  # or 0.  -1 is definitely invalid, while 0 is probably invalid.
  # Also note each handle can independently be invalid or good.
  # For Windows apps, the console handles are set to values like 3, 7, 
  # and 11 but are invalid handles - you may not write to them.  However,
  # you can still spawn a Windows app via CreateProcess and read stdout
  # and stderr.
  # So, we always need to check each handle independently for validity
  # by trying to write or read to it, unless it is -1.

  # We do not do a security check here, under the assumption that this
  # cannot create a security hole, but only waste a user's time or 
  # cause a possible denial of service attack.
  sub InitializeStdOutError {
    assert { @_ == 1 };
    my $stdout = assert_Bool shift;

    # Set up Console->Out or Console->Error.
    { 
      lock($InternalSyncObject);
      if ( $stdout && $_out ) {
        return;
      } elsif ( !$stdout && $_error ) {
        return;
      }

      my $writer;
      my $s;
      if ( $stdout ) {
        $s = __PACKAGE__->OpenStandardOutput(DefaultConsoleBufferSize);
      } else {
        $s = __PACKAGE__->OpenStandardError(DefaultConsoleBufferSize);
      }

      if ( !$s ) {
        if ( _DEBUG && CheckOutputDebug() ) {
          $writer = MakeDebugOutputTextWriter($stdout ? "Console->Out: " : "Console->Error: ");
        } else {
          $writer = IO::Null->new();
        }
      }
      else {
        my $encoding = $_outputEncoding // Win32::GetConsoleOutputCP();
        my $stdxxx = IO::File->new_from_fd(fileno($s), 'w');
        $stdxxx->binmode(':encoding(UTF-8)') if $encoding == 65001;
        $stdxxx->autoflush(TRUE);
        $writer = $stdxxx;
      }
      if ( $stdout ) {
        $_out = $writer;
      } else {
        $_error = $writer;
      }
      assert "Didn't set Console::_out or _error appropriately!"
        { $stdout && $_out || !$stdout && $_error };
    }
    return;
  }

=item I<IsAltKeyDown>

  sub IsAltKeyDown(ArrayRef $ir) : Bool

For tracking Alt+NumPad unicode key sequence.

I<param> $ir is an array reference to a KeyEvent input record.

I<return> true if Alt key is pressed, otherwise false.

=cut

  # For tracking Alt+NumPad unicode key sequence. When you press Alt key down 
  # and press a numpad unicode decimal sequence and then release Alt key, the
  # desired effect is to translate the sequence into one Unicode KeyPress. 
  # We need to keep track of the Alt+NumPad sequence and surface the final
  # unicode char alone when the Alt key is released. 
  sub IsAltKeyDown { 
    assert { @_ == 1 };
    my $ir = assert_ArrayRef shift;

    return ($ir->[controlKeyState] 
      & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED)) != 0;
  }

=item I<IsHandleRedirected>

  sub IsHandleRedirected(Int $ioHandle) : Bool

Detects if a console handle has been redirected.

I<param> $ioHandle is a Windows IO handle (for example a handle of a file, a 
console or a pipe).

I<return> true if the specified handle is redirected, otherwise false.

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

=item I<IsKeyDownEvent>

  sub IsKeyDownEvent(ArrayRef $ir) : Bool

To detect pure KeyDown events.

I<param> $ir is an array reference to a KeyEvent input record.

I<return> true on a KeyDown event, otherwise false.

=cut

  # Skip non key events. Generally we want to surface only KeyDown event 
  # and suppress KeyUp event from the same Key press but there are cases
  # where the assumption of KeyDown-KeyUp pairing for a given key press 
  # is invalid. For example in IME Unicode keyboard input, we often see
  # only KeyUp until the key is released.  
  sub IsKeyDownEvent {
    assert { @_ == 1 };
    my $ir = assert_ArrayRef shift;

    return $ir->[eventType] == Win32Native::KEY_EVENT && $ir->[keyDown];
  }

=item I<IsModKey>

  sub IsModKey(ArrayRef $ir) : Bool

Detects if the KeyEvent uses a mod key.

I<param> $ir is an array reference to a KeyEvent input record.

I<return> true if the KeyEvent uses a mod key, otherwise false.

=cut

  sub IsModKey {
    assert { @_ == 1 };
    my $ir = assert_ArrayRef shift;

    # We should also skip over Shift, Control, and Alt, as well as caps lock.
    # Apparently we don't need to check for 0xA0 through 0xA5, which are keys 
    # like Left Control & Right Control. See the Microsoft 'ConsoleKey' for 
    # these values.
    my $keyCode = $ir->[virtualKeyCode];
    return  ($keyCode >= VK_SHIFT && $keyCode <= AltVKCode) 
          || $keyCode == CapsLockVKCode 
          || $keyCode == NumberLockVKCode 
          || $keyCode == VK_SCROLL
  }

=item I<IsStandardConsoleUnicodeEncoding>

  sub IsStandardConsoleUnicodeEncoding(Int $encoding) : Bool

Test if standard console Unicode encoding is activated.

I<param> $encoding contains the code page identifier.

I<return> true if the encoding uses a Windows Unicode encoding or false if not.

=cut

  # We cannot simply compare the encoding to Encoding.Unicode bacasue it 
  # incorporates BOM and we do not care about BOM. Instead, we compare by 
  # class, codepage and little-endianess only:
  sub IsStandardConsoleUnicodeEncoding {
    assert { @_ == 1 };
    my $encoding = assert_Int shift;

    my $enc = {
      CodePage  => $encoding,
      bigEndian => $Config{byteorder} & 0b1,
    };
    return FALSE if !$enc;

    return StdConUnicodeEncoding->{CodePage} == $enc->{CodePage}
        && StdConUnicodeEncoding->{bigEndian} == $enc->{bigEndian};
  }

=item I<MakeDebugOutputTextWriter>

  sub MakeDebugOutputTextWriter(Str $streamLabel) : IO::Handle

Creates an I<DebugOutputTextWriter> IO::Handle and returns it.

I<param> $streamLabel contains a string which is prefixed to each output.

I<return> of an IO::Handle of type I<DebugOutputTextWriter>.

=cut

  sub MakeDebugOutputTextWriter {
    require DebugOutputTextWriter;
    assert { @_ == 1 };
    my $streamLabel = assert_Str shift;
    my $output = DebugOutputTextWriter->new($streamLabel);
    $output->print("Output redirected to debugger from a bit bucket.");
    return $output;
  }

=item I<SafeFileHandle>

  sub SafeFileHandle(FileHandle $preexistingHandle, 
    Bool $ownsHandle) : FileHandle;

Create a reference to safe an existing file handle.

I<param> $preexistingHandle is an C<GLOB> or L<IO::Handle> object that 
represents the pre-existing file handle to use.

I<param> $ownsHandle should be set to true to reliably release the file handle 
during the closing phase; false to prevent release.

I<return> of the specified FileHandle.

=cut

  sub SafeFileHandle {
    assert { @_ == 2 };
    my $preexistingHandle = shift;
    my $ownsHandle = assert_Bool shift;

    assert { $preexistingHandle };
    assert { # is_FileHandle
      ref($preexistingHandle) eq 'GLOB' 
        or 
      tied($preexistingHandle) && tied($preexistingHandle)->can('TIEHANDLE')
        or 
      is_Object($preexistingHandle) && $preexistingHandle->isa('IO::Handle')
        or 
      is_Object($preexistingHandle) && $preexistingHandle->isa('Tie::Handle')
    };

    my $hNativeHandle = Win32API::File::GetOsFHandle($preexistingHandle);
    if ( $hNativeHandle 
      && $hNativeHandle != Win32API::File::INVALID_HANDLE_VALUE
    ) {
      my $ouFlags = 0;
      if ( Win32API::File::GetHandleInformation($hNativeHandle, $ouFlags)
        && $ouFlags & Win32API::File::HANDLE_FLAG_PROTECT_FROM_CLOSE
      ) {
        $ownsHandle = FALSE;
      }
    }
    if ( !$ownsHandle ) {
      $_leaveOpen->{$preexistingHandle} = $preexistingHandle;
    } else {
      delete $_leaveOpen->{$preexistingHandle};
    }
    return $preexistingHandle;
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
# Additional Packages ----------------------------------------------------
# ------------------------------------------------------------------------

# see SYNOPSIS using this code
#---------------
package System {
#---------------
  use 5.014; 
  use warnings;
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
  use 5.014; 
  use warnings;
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
    Win32::API::More->Import(KERNEL32,
      'BOOL WriteFile(
        HANDLE    hFile,
        LPCSTR    lpBuffer,
        DWORD     nNumberOfBytesToWrite,
        LPDWORD   lpNumberOfBytesWritten,
        LPVOID    lpOverlapped
      )'
    ) or die "Import WriteFile: $EXTENDED_OS_ERROR";
  }
  $INC{'Win32Native.pm'} = 1;
}

# Most of the content was taken from L</IO::Null>, L</IO::String> and 
# I<system.io.__debugoutputtextwriter.cs>
#------------------------------
package DebugOutputTextWriter {
#------------------------------
  use 5.014; 
  use warnings;
  use Symbol ();
  use IO::Handle ();
  use Win32;
  our @ISA = qw(IO::Handle);
 
  *CLOSE = *WRITE =
  *close = *write =
  *opened = *eof = *syswrite = *ungetc = *clearerr = *flush =
  *binmode = sub { 1 };

  *TELL = *FILENO =
  *tell = *fileno = sub { -1 };

  *GETC = *READ =
  *getc = *read = *sysread = *error = *getline = sub { '' };

  sub readline {
    return () if wantarray;
    return '';
  }
  *READLINE = \&readline;

  sub getlines { return () }
  sub DESTROY { 1 }

  sub new { # $handle ($class, | $consoleType)
    my $class = shift;
    my $self = bless Symbol::gensym(), ref($class) || $class;
    tie *$self, $self;
    $self->open(@_);
    return $self;
  }
  *nem_from_fd = *fdopen = \&new;

  sub open { # $handle ($handle, | $consoleType)
    my $self = shift;
    return $self->new(@_) unless ref($self);
    my $consoleType = shift // '';
    *$self->{_consoleType} = "$consoleType";
    return $self;
  }
  *OPEN = \&open;
 
  sub print { # $success ($handle, @list)
    return undef unless ref(shift);
    Win32::OutputDebugString(join $,//'', @_);
    return 1;
  }
  *PRINT = \&print;

  sub printf { # $success ($handle, $format, @list)
    return undef unless ref(shift);
    Win32::OutputDebugString(sprintf(shift, @_));
    return 1;
  }
  *PRINTF = \&printf;

  sub say { # $success ($handle, @list)
    my $self = shift;
    return undef unless ref($self);
    if ( defined $_[0] ) {
      my $consoleType = *$self->{_consoleType} // '';
      Win32::OutputDebugString(join $,//'', $consoleType, @_);
    } else {
      Win32::OutputDebugString('<null>');
    }
    Win32::OutputDebugString("\n");
    return 1;
  }

  sub TIEHANDLE {
    return $_[0] if ref($_[0]);
    my $class = shift;
    my $self = bless Symbol::gensym(), $class;
    $self->open(@_);
    return $self;
  }

  $INC{'DebugOutputTextWriter.pm'} = 1;
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

=cut
