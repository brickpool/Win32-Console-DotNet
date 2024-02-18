=pod

=head1 NAME

Win32::Console::More - Win32::Console patches and extensions

=head1 SYNOPSIS

Simply integrate this module into your package or script.

  use Win32::Console;
  use Win32::Console::More;

B<Note>: Loading this module must be done after C<use Win32::Console>, 
otherwise the patches and extensions for L<Win32::Console> will not be 
installed correctly.

=cut

package Win32::Console::More;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

# version '...'
our $version = 'v0.10.0';
our $VERSION = '0.001_001';
$VERSION = eval $VERSION;

# authority '...'
our $authority = 'cpan:JDB';
our $AUTHORITY = 'github:brickpool';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use English qw( -no_match_vars );
use Package::Stash;
use Scalar::Util qw( 
  looks_like_number
  blessed
);
use Win32;
use Win32::API;
use Win32::Console;
use Win32API::File;

# ------------------------------------------------------------------------
# Imports ----------------------------------------------------------------
# ------------------------------------------------------------------------

BEGIN {
  use constant _kernelDll => 'kernel32';

  my (undef, $major) = Win32::GetOSVersion();
  $major //= 0;

  Win32::API::Struct->typedef(
    COORD => qw(
      SHORT X;
      SHORT Y;
    )
  );

  Win32::API::Struct->typedef(
    SMALL_RECT => qw(
      SHORT Left;
      SHORT Top;
      SHORT Right;
      SHORT Bottom;
    )
  );

  Win32::API::Struct->typedef(
    CONSOLE_FONT_INFO => qw(
      DWORD nFont;
      COORD dwFontSize;
    )
  );

  Win32::API::Struct->typedef(
    KEY_EVENT_RECORD => qw(
      WORD  EventType;
      BOOL  bKeyDown;
      WORD  wRepeatCount;
      WORD  wVirtualKeyCode;
      WORD  wVirtualScanCode;
      WCHAR UnicodeChar;
      DWORD dwControlKeyState;
    )
  );

  Win32::API::More->Import(_kernelDll, 
    'BOOL GetCurrentConsoleFont(
      HANDLE              hConsoleOutput,
      BOOL                bMaximumWindow,
      LPCONSOLE_FONT_INFO lpConsoleCurrentFont
    )'
  ) or die "Import GetCurrentConsoleFont: $EXTENDED_OS_ERROR";
  
  Win32::API::More->Import(_kernelDll, 
    'BOOL PeekConsoleInput(
      HANDLE              hConsoleInput,
      LPKEY_EVENT_RECORD  lpBuffer,
      DWORD               nLength,
      LPDWORD             lpNumberOfEventsRead
    )'
  ) or die "Import ReadConsoleInput: $EXTENDED_OS_ERROR";

  Win32::API::More->Import(_kernelDll, 
    'BOOL ReadConsoleInputW(
      HANDLE              hConsoleInput,
      LPKEY_EVENT_RECORD  lpBuffer,
      DWORD               nLength,
      LPDWORD             lpNumberOfEventsRead
    )'
  ) or die "Import ReadConsoleInput: $EXTENDED_OS_ERROR";

  if ( $major >= 6 ) {
    # https://learn.microsoft.com/en-us/windows/win32/gdi/colorref
    # https://stackoverflow.com/a/57231792
    Win32::API::Struct->typedef(
      COLORREF => qw(
        DWORD   rgbBlack;
        DWORD   rgbBlue;
        DWORD   rgbGreen;
        DWORD   rgbCyan;
        DWORD   rgbRed;
        DWORD   rgbMagenta;
        DWORD   rgbBrown;
        DWORD   rgbLightGray;
        DWORD   rgbGray;
        DWORD   rgbLightBlue;
        DWORD   rgbLightGreen;
        DWORD   rgbLightCyan;
        DWORD   rgbLightRed;
        DWORD   rgbLightMagenta;
        DWORD   rgbYellow;
        DWORD   rgbWhite;
      )
    );

    # https://learn.microsoft.com/en-us/windows/console/console-screen-buffer-infoex
    Win32::API::Struct->typedef(
      CONSOLE_SCREEN_BUFFER_INFOEX => qw(
        ULONG      cbSize;
        COORD      dwSize;
        COORD      dwCursorPosition;
        WORD       wAttributes;
        SMALL_RECT srWindow;
        COORD      dwMaximumWindowSize;
        WORD       wPopupAttributes;
        BOOL       bFullscreenSupported;
        COLORREF   ColorTable;
      )
    );

    Win32::API::More->Import(_kernelDll, 
      'BOOL GetConsoleScreenBufferInfoEx(
        HANDLE                         hConsoleOutput,
        LPCONSOLE_SCREEN_BUFFER_INFOEX lpConsoleScreenBufferInfoEx
      )'
    ) or die "Import GetConsoleScreenBufferInfoEx: $EXTENDED_OS_ERROR";

    Win32::API::More->Import(_kernelDll, 
      'BOOL SetConsoleScreenBufferInfoEx(
        HANDLE                         hConsoleOutput,
        LPCONSOLE_SCREEN_BUFFER_INFOEX lpConsoleScreenBufferInfoEx
      )'
    ) or die "Import SetConsoleScreenBufferInfoEx: $EXTENDED_OS_ERROR";
  }

}

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  KEY_EVENT
  MOUSE_EVENT
  WINDOW_BUFFER_SIZE_EVENT

  ENABLE_INSERT_MODE
  ENABLE_QUICK_EDIT_MODE
  ENABLE_EXTENDED_FLAGS
  ENABLE_VIRTUAL_TERMINAL_INPUT

  ENABLE_VIRTUAL_TERMINAL_PROCESSING
  DISABLE_NEWLINE_AUTO_RETURN
  ENABLE_LVB_GRID_WORLDWIDE

=cut

use Exporter qw( import );

our @EXPORT_OK = qw(
  KEY_EVENT
  MOUSE_EVENT
  WINDOW_BUFFER_SIZE_EVENT

  ENABLE_INSERT_MODE
  ENABLE_QUICK_EDIT_MODE
  ENABLE_EXTENDED_FLAGS
  ENABLE_VIRTUAL_TERMINAL_INPUT

  ENABLE_VIRTUAL_TERMINAL_PROCESSING
  DISABLE_NEWLINE_AUTO_RETURN
  ENABLE_LVB_GRID_WORLDWIDE
);

# ------------------------------------------------------------------------
# Injected Subs ----------------------------------------------------------
# ------------------------------------------------------------------------

BEGIN {
  my (undef, $major) = Win32::GetOSVersion();
  $major //= 0;

  my $wincon = Package::Stash->new('Win32::Console');

  # Update patched Win32::Console constructor/destructor
  $wincon->add_symbol('&new'
                    , \&new);
  $wincon->add_symbol('&DESTROY'
                    , \&DESTROY);

  # Update patched Win32::Console methods
  $wincon->add_symbol('&Write'
                    , \&Write);
  $wincon->add_symbol('&Input'
                    , \&Input);
  $wincon->add_symbol('&Info'
                    , \&Info) if ( $major >= 6 );

  # Add new Win32::Console methods
  $wincon->add_symbol('&Close'
                    , \&Close);
  $wincon->add_symbol('&is_valid'
                    , \&is_valid);
}

# ------------------------------------------------------------------------
# Constants --------------------------------------------------------------
# ------------------------------------------------------------------------

  use constant {
    KEY_EVENT                 => 0x0001,
    MOUSE_EVENT               => 0x0002,
    WINDOW_BUFFER_SIZE_EVENT  => 0x0004,
  };

  use constant {
    ENABLE_INSERT_MODE                  => 0x0020,
    ENABLE_QUICK_EDIT_MODE              => 0x0040,
    ENABLE_EXTENDED_FLAGS               => 0x0080,
    ENABLE_VIRTUAL_TERMINAL_INPUT       => 0x0200,
  };

  use constant {
    ENABLE_VIRTUAL_TERMINAL_PROCESSING  => 0x0004,
    DISABLE_NEWLINE_AUTO_RETURN         => 0x0008,
    ENABLE_LVB_GRID_WORLDWIDE           => 0x0010,
  };

# ------------------------------------------------------------------------
# Subroutines ------------------------------------------------------------
# ------------------------------------------------------------------------

  # Retrieves information about the current console font
  #===========================
  sub _GetCurrentConsoleFont {
  #===========================
    my ($handle, $maxWindow) = @_;
    $maxWindow = $maxWindow ? 1 : 0;
    return () unless @_ == 2;
    return () unless defined $handle;
    return () unless looks_like_number $handle;
    return () unless looks_like_number $maxWindow;

    my $fontInfo = Win32::API::Struct->new('CONSOLE_FONT_INFO');
    $fontInfo->{dwFontSize} = Win32::API::Struct->new('COORD');
      $fontInfo->{nFont}
    = $fontInfo->{dwFontSize}->{X}
    = $fontInfo->{dwFontSize}->{Y}
    = 0;
    return GetCurrentConsoleFont( $handle, $maxWindow, $fontInfo )
      ? (
          $fontInfo->{nFont},
          $fontInfo->{dwFontSize}->{X},
          $fontInfo->{dwFontSize}->{Y},
        )
      : ()
  }

  # Retrieves extended information about the specified console screen buffer.
  #==================================
  sub _GetConsoleScreenBufferInfoEx {
  #==================================
    my ($handle) = @_;
    return () unless @_ == 1;
    return () unless defined $handle;
    return () unless looks_like_number $handle;

    my $infoEx = Win32::API::Struct->new('CONSOLE_SCREEN_BUFFER_INFOEX');
    return () unless blessed $infoEx;
    $infoEx->{dwSize} = Win32::API::Struct->new('COORD');
    return () unless blessed $infoEx->{dwSize};
    $infoEx->{dwCursorPosition} = Win32::API::Struct->new('COORD');
    return () unless blessed $infoEx->{dwCursorPosition};
    $infoEx->{srWindow} = Win32::API::Struct->new('SMALL_RECT');
    return () unless blessed $infoEx->{srWindow};
    $infoEx->{dwMaximumWindowSize} = Win32::API::Struct->new('COORD');
    return () unless blessed $infoEx->{dwMaximumWindowSize};
    $infoEx->{ColorTable} = Win32::API::Struct->new('COLORREF');
    return () unless blessed $infoEx->{ColorTable};
    # https://stackoverflow.com/a/9222394
    $infoEx->{cbSize} = $infoEx->sizeof;
    return () unless $infoEx->{cbSize} == 96;
      $infoEx->{dwSize}->{X}
    = $infoEx->{dwSize}->{Y}
    = $infoEx->{dwCursorPosition}->{X}
    = $infoEx->{dwCursorPosition}->{Y}
    = $infoEx->{wAttributes}
    = $infoEx->{srWindow}->{Left}
    = $infoEx->{srWindow}->{Top}
    = $infoEx->{srWindow}->{Right}
    = $infoEx->{srWindow}->{Bottom}
    = $infoEx->{dwMaximumWindowSize}->{X}
    = $infoEx->{dwMaximumWindowSize}->{Y}
    = $infoEx->{wPopupAttributes}
    = $infoEx->{bFullscreenSupported}
    = $infoEx->{ColorTable}->{rgbBlack}
    = $infoEx->{ColorTable}->{rgbBlue}
    = $infoEx->{ColorTable}->{rgbGreen}
    = $infoEx->{ColorTable}->{rgbCyan}
    = $infoEx->{ColorTable}->{rgbRed}
    = $infoEx->{ColorTable}->{rgbMagenta}
    = $infoEx->{ColorTable}->{rgbBrown}
    = $infoEx->{ColorTable}->{rgbLightGray}
    = $infoEx->{ColorTable}->{rgbGray}
    = $infoEx->{ColorTable}->{rgbLightBlue}
    = $infoEx->{ColorTable}->{rgbLightGreen}
    = $infoEx->{ColorTable}->{rgbLightCyan}
    = $infoEx->{ColorTable}->{rgbLightRed}
    = $infoEx->{ColorTable}->{rgbLightMagenta}
    = $infoEx->{ColorTable}->{rgbYellow}
    = $infoEx->{ColorTable}->{rgbWhite}
    = 0;

    return GetConsoleScreenBufferInfoEx($handle, $infoEx) 
      ? (
          $infoEx->{dwSize}->{X},
          $infoEx->{dwSize}->{Y},
          $infoEx->{dwCursorPosition}->{X},
          $infoEx->{dwCursorPosition}->{Y},
          $infoEx->{wAttributes},
          $infoEx->{srWindow}->{Left},
          $infoEx->{srWindow}->{Top},
          $infoEx->{srWindow}->{Right},
          $infoEx->{srWindow}->{Bottom},
          $infoEx->{dwMaximumWindowSize}->{X},
          $infoEx->{dwMaximumWindowSize}->{Y},
          $infoEx->{wPopupAttributes},
          $infoEx->{bFullscreenSupported},
          $infoEx->{ColorTable}->{rgbBlack},
          $infoEx->{ColorTable}->{rgbBlue},
          $infoEx->{ColorTable}->{rgbGreen},
          $infoEx->{ColorTable}->{rgbCyan},
          $infoEx->{ColorTable}->{rgbRed},
          $infoEx->{ColorTable}->{rgbMagenta},
          $infoEx->{ColorTable}->{rgbBrown},
          $infoEx->{ColorTable}->{rgbLightGray},
          $infoEx->{ColorTable}->{rgbGray},
          $infoEx->{ColorTable}->{rgbLightBlue},
          $infoEx->{ColorTable}->{rgbLightGreen},
          $infoEx->{ColorTable}->{rgbLightCyan},
          $infoEx->{ColorTable}->{rgbLightRed},
          $infoEx->{ColorTable}->{rgbLightMagenta},
          $infoEx->{ColorTable}->{rgbYellow},
          $infoEx->{ColorTable}->{rgbWhite},
        )
      : ()
  }

  # Sets extended information about the specified console screen buffer.
  #==================================
  sub _SetConsoleScreenBufferInfoEx {
  #==================================
    return undef unless @_ == 30;
    for ( @_[0..12,14..29] ) {
      return undef unless defined($_) && looks_like_number($_);
    }
    
    my $handle;
    my $infoEx = Win32::API::Struct->new('CONSOLE_SCREEN_BUFFER_INFOEX');
    return undef unless blessed $infoEx;
    $infoEx->{dwSize} = Win32::API::Struct->new('COORD');
    return undef unless blessed $infoEx->{dwSize};
    $infoEx->{dwCursorPosition} = Win32::API::Struct->new('COORD');
    return undef unless blessed $infoEx->{dwCursorPosition};
    $infoEx->{srWindow} = Win32::API::Struct->new('SMALL_RECT');
    return undef unless blessed $infoEx->{srWindow};
    $infoEx->{dwMaximumWindowSize} = Win32::API::Struct->new('COORD');
    return undef unless blessed $infoEx->{dwMaximumWindowSize};
    $infoEx->{ColorTable} = Win32::API::Struct->new('COLORREF');
    return undef unless blessed $infoEx->{ColorTable};
    # https://stackoverflow.com/a/9222394
    $infoEx->{cbSize} = $infoEx->sizeof;
    return undef unless $infoEx->{cbSize} == 96;
    (
      $handle,
      $infoEx->{dwSize}->{X},
      $infoEx->{dwSize}->{Y},
      $infoEx->{dwCursorPosition}->{X},
      $infoEx->{dwCursorPosition}->{Y},
      $infoEx->{wAttributes},
      $infoEx->{srWindow}->{Left},
      $infoEx->{srWindow}->{Top},
      $infoEx->{srWindow}->{Right},
      $infoEx->{srWindow}->{Bottom},
      $infoEx->{dwMaximumWindowSize}->{X},
      $infoEx->{dwMaximumWindowSize}->{Y},
      $infoEx->{wPopupAttributes},
      $infoEx->{bFullscreenSupported},
      $infoEx->{ColorTable}->{rgbBlack},
      $infoEx->{ColorTable}->{rgbBlue},
      $infoEx->{ColorTable}->{rgbGreen},
      $infoEx->{ColorTable}->{rgbCyan},
      $infoEx->{ColorTable}->{rgbRed},
      $infoEx->{ColorTable}->{rgbMagenta},
      $infoEx->{ColorTable}->{rgbBrown},
      $infoEx->{ColorTable}->{rgbLightGray},
      $infoEx->{ColorTable}->{rgbGray},
      $infoEx->{ColorTable}->{rgbLightBlue},
      $infoEx->{ColorTable}->{rgbLightGreen},
      $infoEx->{ColorTable}->{rgbLightCyan},
      $infoEx->{ColorTable}->{rgbLightRed},
      $infoEx->{ColorTable}->{rgbLightMagenta},
      $infoEx->{ColorTable}->{rgbYellow},
      $infoEx->{ColorTable}->{rgbWhite},
    ) = @_;
    $infoEx->{bFullscreenSupported} = $_[13] ? 1 : 0;

    return SetConsoleScreenBufferInfoEx($handle, $infoEx);
  }

  # _ReadConsoleInputW with Unicode (and WindowBufferSizeEvent) support
  #=======================
  sub _ReadConsoleInputW {
  #=======================
    my ($handle) = @_;
    return undef unless @_ == 1;
    return undef unless defined $handle;
    return undef unless looks_like_number $handle;
    
    my ($event_type) = Win32::Console::_PeekConsoleInput($handle) // (0);
    SWITCH: for ($event_type) {

      $_ == KEY_EVENT and do {
        my @event = do {
          # Win32::Console::Input() may not support Unicode, so the native
          # Windows API 'ReadConsoleInputW' call is used instead.
          my $ir = Win32::API::Struct->new('KEY_EVENT_RECORD');
          my $ok
            = $ir->{EventType}
            = $ir->{bKeyDown}
            = $ir->{wRepeatCount}
            = $ir->{wVirtualKeyCode}
            = $ir->{wVirtualScanCode}
            = $ir->{UnicodeChar}
            = $ir->{dwControlKeyState}
            = 0
            ;
          ReadConsoleInputW( $handle, $ir, 1, $ok ) && $ok
            ? ( $ir->{EventType},
                $ir->{bKeyDown},
                $ir->{wRepeatCount},
                $ir->{wVirtualKeyCode},
                $ir->{wVirtualScanCode},
                $ir->{UnicodeChar},
                $ir->{dwControlKeyState} )
            : ()
            ;
        };
        return  @event
              ? @event
              : undef
              ;
      };

      # Win32::Console::Input() does not support 'WindowBufferSizeEvent',
      $_ == WINDOW_BUFFER_SIZE_EVENT and do {
        # Consume event from the Windows event queue
        return undef 
          unless (Win32::Console::_ReadConsoleInput($handle) // 0) 
            == WINDOW_BUFFER_SIZE_EVENT;
        # Get Window buffer size
        my ( $size_x, $size_y ) =
          Win32::Console::_GetConsoleScreenBufferInfo($handle) 
            || return undef;
        return (
          $event_type,
          $size_x,
          $size_y
        );
      };

      DEFAULT: {
        return Win32::Console::_ReadConsoleInput($handle);
      };
    }
  }

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

  ------------------------------------------------------------------------
  Fix Module Win32::Console version 0.10
  ------------------------------------------------------------------------
  
  1. Since you didn't open those handles (that's not what GetStdHandle does),
     you don't need to close them.
  2. The parameter 'dwShareMode' can be 0 (zero), indicating that the buffer
     cannot be shared
  3. Note that standard I/O handles should be INVALID_HANDLE_VALUE instead
     of 0 (NULL).
  4. Close shortcut is not implemented.
  5. Writing 0 bytes causes the cursor to become invisible for a short time
     in old versions of the Windows console.
  
  https://rt.cpan.org/Public/Bug/Display.html?id=33513
  https://docs.microsoft.com/en-us/windows/console/createconsolescreenbuffer
  https://stackoverflow.com/a/14730120/12342329
  https://rt.cpan.org/Public/Bug/Display.html?id=64676
  
  ------------------------------------------------------------------------

=cut
 
  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  # fix 1..3 - see below
  #========
  sub new {
  #========
    my ($class, $param1, $param2) = @_;
    my $self = { 'handle_is_std' => 0 };

    if ( defined( $param1 )
    && (
             $param1 == Win32::Console::constant("STD_INPUT_HANDLE",  0)
          || $param1 == Win32::Console::constant("STD_OUTPUT_HANDLE", 0)
          || $param1 == Win32::Console::constant("STD_ERROR_HANDLE",  0)
        )
    ) {
      $self->{'handle'} = Win32::Console::_GetStdHandle( $param1 );
      # fix 1 - Close only non standard handle
      $self->{'handle_is_std'} = 1;
    }
    else {
      if ( !$param1 ) {
        $param1 = Win32::Console::constant("GENERIC_READ", 0)
                | Win32::Console::constant("GENERIC_WRITE", 0)
                ;
      }
      # fix 2 - The value 0 (zero) is also a permitted value
      if ( !defined( $param2 ) ) {
        $param2 = Win32::Console::constant("FILE_SHARE_READ", 0)
                | Win32::Console::constant("FILE_SHARE_WRITE", 0)
                ;
      }
      $self->{'handle'} = Win32::Console::_CreateConsoleScreenBuffer(
          $param1
        , $param2
        , Win32::Console::constant("CONSOLE_TEXTMODE_BUFFER", 0)
      );
    }
    # fix 3 - If handle is undefined, 0 or -1 then the handle is invalid.
    if (
         $self->{'handle'}
      && $self->{'handle'} != Win32API::File::INVALID_HANDLE_VALUE
    ) {
      bless $self, $class;
      return $self;
    }
    return;
  }

  # ------------------------------------------------------------------------
  # Destructors ------------------------------------------------------------
  # ------------------------------------------------------------------------

  # fix 1 - Close only non standard handle
  #============
  sub DESTROY {
  #============
    my ($self) = @_;
    return unless blessed($self);
    $self->Close() unless $self->{'handle_is_std'};
    return;
  }

  # ------------------------------------------------------------------------
  # Win32::Console ---------------------------------------------------------
  # ------------------------------------------------------------------------

  # fix 4 - Implement Close
  #==========
  sub Close {
  #==========
    my ($self) = @_;
    return undef unless ref($self);
    return Win32::Console::_CloseHandle($self->{'handle'});
  }

  # GetConsoleScreenBufferInfoEx support
  #=========
  sub Info {
  #=========
    my($self) = @_;
    return undef unless ref($self);
    return _GetConsoleScreenBufferInfoEx($self->{'handle'});
  }

  # Unicode and WindowBufferSizeEvent support
  #==========
  sub Input {
  #==========
    my($self) = @_;
    return undef unless ref($self);
    return _ReadConsoleInputW($self->{'handle'});
  }

  # fix 5 - Writing 0 bytes
  #==========
  sub Write {
  #==========
    my ($self, $string) = @_;
    return undef unless ref($self);
    return undef unless length($string);
    return Win32::Console::_WriteConsole($self->{'handle'}, $string);
  }

  # Ok, this is an extension
  #==============
  sub is_valid {
  #==============
    my ($self) = @_;
    return undef unless ref($self);
    return !! $self->Mode();
  }

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the Windows Console DotNet library.

 Copyright (C) 2024 by J. Schneider

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

2023,2024 by J. Schneider L<https://github.com/brickpool/>

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
L<Console Functions|https://learn.microsoft.com/en-us/windows/console/console-functions>
