=pod

=head1 NAME

Win32::Native - Windows low level API routines

=cut

package Win32::Native;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

# version '...'
our $version = 'v2.5.0';
our $VERSION = '0.001_001';
$VERSION = eval $VERSION;

# authority '...'
our $authority = 'github:microsoft';
our $AUTHORITY = 'github:brickpool';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use English qw( -no_match_vars );
use Win32::API;

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

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

  Beep
  GetKeyState

=cut

use Exporter qw( import );

our @EXPORT_OK = qw(
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

  Beep
  GetKeyState
);

# ------------------------------------------------------------------------
# Constants --------------------------------------------------------------
# ------------------------------------------------------------------------

=head2 WinError Constants

Error codes from WinError.h

=over

=item I<ERROR_INVALID_HANDLE>

  constant ERROR_INVALID_HANDLE = < Int >;

ERROR_INVALID_HANDLE is a predefined constant that is used to represent a value
that is passed to or returned by one or more built-in functions.

=cut

  use constant ERROR_INVALID_HANDLE => 0x6;

=back

=head2 Winuser Constants

Virtual-Key Codes from Winuser.h

=over

=item I<VK_CLEAR>

  constant VK_CLEAR = < Int >;

CLEAR key.

=cut

  use constant VK_CLEAR => 0x0c;

=item I<VK_SHIFT>

  constant VK_SHIFT = < Int >;

SHIFT key.

=cut

  use constant VK_SHIFT => 0x10;

=item I<VK_MENU>

  constant VK_MENU = < Int >;

ALT key.

=cut

  use constant VK_MENU => 0x12;

=item I<VK_CAPITAL>

  constant VK_CAPITAL = < Int >;

CAPS LOCK key.

=cut

  use constant VK_CAPITAL => 0x14;

=item I<VK_PRIOR>

  constant VK_PRIOR = < Int >;

PAGE UP key

=cut

  use constant VK_PRIOR => 0x21;

=item I<VK_NEXT>

  constant VK_NEXT = < Int >;

PAGE DOWN key

=cut

  use constant VK_NEXT => 0x22;

=item I<VK_INSERT>

  constant VK_INSERT = < Int >;

INSERT key.

=cut

  use constant VK_INSERT => 0x2d;

=item I<VK_NUMPAD0>

  constant VK_NUMPAD0 = < Int >;

Numeric keypad 0 key

=cut

  use constant VK_NUMPAD0 => 0x60;

=item I<VK_NUMPAD9>

  constant VK_NUMPAD9 = < Int >;

Numeric keypad 9 key

=cut

  use constant VK_NUMPAD9 => 0x69;

=item I<VK_NUMLOCK>

  constant VK_NUMLOCK = < Int >;

NUM LOCK key.

=cut

  use constant VK_NUMLOCK => 0x90;

=item I<VK_SCROLL>

  constant VK_SCROLL = < Int >;

SCROLL key.

=cut

  use constant VK_SCROLL => 0x91;

=back

=begin private

=head2 Private Constants

Private Constants.

=over

=item I<_kernelDll>

  constant _kernelDll = < Str >

Name of the kernel library used for the
L<Windows and Messages|https://learn.microsoft.com/en-us/windows/win32/api/_winmsg/>
subs.

=item I<_userDll>

  constant _userDll = < Str >

Name of the user library used for the
L<Windows and Messages|https://learn.microsoft.com/en-us/windows/win32/api/_winmsg/>
subs.

=cut

  use constant {
    _kernelDll  => 'kernel32',
    _userDll    => 'user32',
  };

=back

=end private

=cut

# ------------------------------------------------------------------------
# Subroutines ------------------------------------------------------------
# ------------------------------------------------------------------------

=head2 Subroutines

=over

=item I<Beep>

  sub Beep(Int $dwFreq, Int $dwDuration) : Bool

Generates simple tones on the speaker; for more information consult
the original API documentation.

I<param> $dwFreq the frequency of the sound, in hertz. This parameter must be 
in the range 37 through 32,767 (0x25 through 0x7FFF).

I<param> $dwDuration the duration of the sound, in milliseconds.

I<return> if the function succeeds, the return value is nonzero.

=cut

BEGIN {
  Win32::API::More->Import(_kernelDll, 
    'BOOL Beep(DWORD dwFreq, DWORD dwDuration)'
  ) or die "Import Beep: $EXTENDED_OS_ERROR";
}

=item I<GetKeyState>

  sub GetKeyState(Int $nVirtKey) : Int

Retrieves the status of the specified virtual key; for more information consult
the original API documentation.

I<param> $nVirtKey is a virtual key.

I<return> the return value specifies the status of the specified virtual key.

=cut

BEGIN {
  Win32::API::More->Import(_userDll, 
    'int GetKeyState(int nVirtKey)'
  ) or die "Import GetKeyState: $EXTENDED_OS_ERROR";
}

=back

=cut

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

L<Keyboard and Mouse Input|https://learn.microsoft.com/en-us/windows/win32/api/_inputdev/>
