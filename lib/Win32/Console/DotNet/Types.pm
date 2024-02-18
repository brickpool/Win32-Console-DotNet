=pod

=head1 NAME

Win32::Console::DotNet::Types - Type Check for Win32::Console::DotNet

=head1 SYNOPSIS

  use Win32::Console::DotNet::Types qw( is_Str :assert );
  ...

=cut

package Win32::Console::DotNet::Types;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

# version '...'
our $version = 'v2.4.0';
our $VERSION = '0.002_001';
$VERSION = eval $VERSION;

# authority '...'
our $authority = 'cpan:TOBYINK';
our $AUTHORITY = 'github:brickpool';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use B;
use Carp qw( confess );
use Data::Dumper;
use Exporter qw( import );
use Module::Runtime qw( 
  is_module_name
  check_module_name
);
use Ref::Util qw(
  is_plain_scalarref
  is_plain_arrayref
  is_plain_hashref
  is_coderef
);
use Scalar::Util qw( 
  looks_like_number
  blessed
);

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  :all
    
    :is
      is_Bool
      is_Str
      is_Num
      is_Int
      is_ScalarRef
      is_ArrayRef
      is_HashRef
      is_CodeRef
      is_Object
      is_ClassName
      is_InstanceOf

    :assert
      assert_Bool
      assert_Str
      assert_Num
      assert_Int
      assert_ScalarRef
      assert_ArrayRef
      assert_HashRef
      assert_CodeRef
      assert_Object
      assert_ClassName
      assert_InstanceOf

=cut

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  is => [qw(
    is_Bool
    is_Str
    is_Num
    is_Int
    is_ScalarRef
    is_ArrayRef
    is_HashRef
    is_CodeRef
    is_Object
    is_ClassName
    is_InstanceOf
  )],

  assert => [qw(
    assert_Bool
    assert_Str
    assert_Num
    assert_Int
    assert_ScalarRef
    assert_ArrayRef
    assert_HashRef
    assert_CodeRef
    assert_Object
    assert_ClassName
    assert_InstanceOf
  )],

);

# add all the other %EXPORT_TAGS ":class" tags to the ":all" class and
# @EXPORT_OK, deleting duplicates
{
  my %seen;
  push
    @EXPORT_OK,
      grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}}
        foreach keys %EXPORT_TAGS;
  push
    @{$EXPORT_TAGS{all}},
      @EXPORT_OK;
}

# ------------------------------------------------------------------------
# Subroutines ------------------------------------------------------------
# ------------------------------------------------------------------------

=head2 Subroutine

=over

=item I<is_Bool>

  sub is_Bool($value) : Bool

Check for a reasonable boolean value. Accepts 1, 0, the empty string and undef.

I<param> $value to be checked

I<return> true if boolean;

I<see> 
L<stackoverflow.com|https://stackoverflow.com/a/5655485>, 
L<Perl API|https://perldoc.perl.org/perlapi#looks_like_number>

=cut

sub is_Bool {
  {
    use if $] >= 5.036, 'builtin', qw( is_bool );
    no if $] >= 5.036, 'warnings', 'experimental:builtin';
    return is_bool($_[0]) if $] >= 5.036;
  }
  return !!1 unless defined($_[0]);
  return !!0 if ref($_[0]);
  if ( looks_like_number($_[0]) ) {
    return $_[0] == 0 || $_[0] == 1;
  }
  return !!1 if $_[0] eq '';
  return !!0;
}

=item I<assert_Bool>

  sub assert_Bool($value) : Bool

Check the boolean value. Accepts 1, 0, the empty string and undef.

I<param> $value to be checked

I<return> $value if the value is a boolean

I<throw> IllegalArgumentException if the check fails

=cut

sub assert_Bool {
  unless ( is_Bool $_[0] ) {
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Varname = '';
    local $Data::Dumper::Maxdepth = 1;
    confess(sprintf("IllegalArgumentException: '%s' must be boolean",
      Dumper($_[0]))
    );
  }
  return $_[0];
}

=item I<is_Str>

  sub is_Str($value) : Bool

Check on a string that cannot be stringified.

I<param> $value to be checked

I<return> true if it is a string

I<see> 
L<stackoverflow.com|https://stackoverflow.com/a/37211404>

=cut

sub is_Str { 
  my $scalar = shift;
  !! (B::svref_2object(\$scalar)->FLAGS & B::SVf_POK);
}

=item I<assert_Str>

  sub assert_Str($value) : Str

Check the string that cannot be stringified.

I<param> $value to be checked

I<return> $value if the value is a string

I<throw> IllegalArgumentException if the check fails

=cut

sub assert_Str {
  unless ( is_Str $_[0] ) {
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Varname = '';
    local $Data::Dumper::Maxdepth = 1;
    confess(sprintf("IllegalArgumentException: '%s' must be a string",
      Dumper($_[0]))
    );
  }
  return $_[0];
}

=item I<is_Num>

  sub is_Num($value) : Bool

Ckeck for a number; strict constaint.

I<param> $value to be checked

I<return> true if it is a number

I<see> 
L<stackoverflow.com|https://stackoverflow.com/a/3806159>

=cut

sub is_Num {
  !! length(do { 
    no if $] >= 5.022, 'feature', 'bitwise'; 
    no warnings 'numeric';
    ($_[0] // '') & ''
  });
}

=item I<assert_Num>

  sub assert_Num($value) : Num

Ckeck the number; strict constaint.

I<param> $value to be checked

I<return> $value if the value is a number

I<throw> IllegalArgumentException if the check fails

=cut

sub assert_Num {
  unless ( is_Num $_[0] ) {
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Varname = '';
    local $Data::Dumper::Maxdepth = 1;
    confess(sprintf("IllegalArgumentException: '%s' must be a number",
      Dumper($_[0]))
    );
  }
  return $_[0];
}

=item I<is_Int>

  sub is_Int($value) : Bool

Check for on integer; strict constaint.

I<param> $value to be checked

I<return> true if it is an integer

I<see> 
L<stackoverflow.com|https://stackoverflow.com/a/12667>, 
L<perlmonks.org|https://www.perlmonks.org/?node_id=766016>

=cut

sub is_Int {
  is_Num($_[0]) && $_[0] == int($_[0]);
}

=item I<assert_Int>

  sub assert_Int($value) : Int

Ckeck the integer; strict constaint.

I<param> $value to be checked

I<return> $value if the value is an integer

I<throw> IllegalArgumentException if the check fails

=cut

sub assert_Int {
  unless ( is_Int $_[0] ) {
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Varname = '';
    local $Data::Dumper::Maxdepth = 1;
    confess(sprintf("IllegalArgumentException: '%s' must be an integer",
      Dumper($_[0]))
    );
  }
  return $_[0];
}

=item I<is_ArrayRef>

  sub is_ArrayRef($ref) : Bool

Check for an array reference.

I<param> $ref to be checked

I<return> true if it is an array reference

I<see> 
L<is_plain_arrayref|https://metacpan.org/pod/Ref::Util#is_plain_arrayref($ref)>

=cut

sub is_ArrayRef {
  goto &is_plain_arrayref;
}

=item I<assert_ArrayRef>

  sub assert_ArrayRef($ref) : ArrayRef

Check the array reference.

I<param> $ref to be checked

I<return> $ref if it is an array reference

I<throw> IllegalArgumentException if the check fails

=cut

sub assert_ArrayRef {
  unless ( is_plain_arrayref $_[0] ) {
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Varname = '';
    local $Data::Dumper::Maxdepth = 1;
    confess(
      sprintf("IllegalArgumentException: '%s' must be an array reference",
      Dumper($_[0]))
    );
  }
  return $_[0];
}

=item I<is_HashRef>

  sub is_HashRef($ref) : Bool

Check for a hash reference.

I<param> $ref to be checked

I<return> true if it is a hash reference

I<see> 
L<is_plain_hashref|https://metacpan.org/pod/Ref::Util#is_plain_hashref($ref)>

=cut

sub is_HashRef { 
  goto &is_plain_hashref;
}

=item I<assert_HashRef>

  sub assert_HashRef($ref) : HashRef

Check the hash reference.

I<param> $ref to be checked

I<return> $ref if it is a hash reference

I<throw> IllegalArgumentException if the check fails

=cut

sub assert_HashRef {
  unless ( is_plain_hashref $_[0] ) {
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Varname = '';
    local $Data::Dumper::Maxdepth = 1;
    confess(sprintf("IllegalArgumentException: '%s' must be a hash reference",
      Dumper($_[0]))
    );
  }
  return $_[0];
}

=item I<is_ScalarRef>

  sub is_ScalarRef($ref) : Bool

Check for a scalar reference.

I<param> $ref to be checked

I<return> true if it is a scalar reference

I<see> 
L<is_plain_scalarref|https://metacpan.org/pod/Ref::Util#is_plain_scalarref($ref)>

=cut

sub is_ScalarRef { 
  goto &is_plain_scalarref;
}

=item I<assert_ScalarRef>

  sub assert_ScalarRef($ref) : ScalarRef

Check the scalar reference.

I<param> $ref to be checked

I<return> $ref if it is a scalar reference

I<throw> IllegalArgumentException if the check fails

=cut

sub assert_ScalarRef {
  unless ( is_plain_scalarref $_[0] ) {
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Varname = '';
    local $Data::Dumper::Maxdepth = 1;
    confess(
      sprintf("IllegalArgumentException: '%s' must be a scalar reference",
      Dumper($_[0]))
    );
  }
  return $_[0];
}

=item I<is_ScalarRef>

  sub is_ScalarRef($ref) : Bool

Check for a code reference.

I<param> $ref to be checked

I<return> true if it is a code reference

I<see> 
L<is_coderef|https://metacpan.org/pod/Ref::Util#is_coderef($ref)>

=cut

sub is_CodeRef {
  goto &is_coderef;
}

=item I<assert_CodeRef>

  sub assert_CodeRef($ref) : CodeRef

Check the code reference.

I<param> $ref to be checked

I<return> $ref if it is a code reference

I<throw> IllegalArgumentException if the check fails

=cut

sub assert_CodeRef {
  unless ( is_coderef $_[0] ) {
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Varname = '';
    local $Data::Dumper::Maxdepth = 1;
    confess(sprintf("IllegalArgumentException: '%s' must be a code reference",
      Dumper($_[0]))
    );
  }
  return $_[0];
}

=item I<is_Object>

  sub is_Object($value) : Bool

Check for a blessed object.

I<param> $value to be checked

I<return> true if $value is blessed

I<see> 
L<Scalar::Util|https://perldoc.perl.org/Scalar::Util>, 
L<builtin|https://perldoc.perl.org/builtin#blessed>

=cut

sub is_Object { 
  goto &blessed;
}

=item I<assert_Object>

  sub assert_Object($value) : Object

Check for a blessed object.

I<param> $value to be checked

I<return> $value if $value is blessed

I<throw> IllegalArgumentException if the check fails

=cut

sub assert_Object {
  unless ( blessed $_[0] ) {
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Varname = '';
    local $Data::Dumper::Maxdepth = 1;
    confess(sprintf("IllegalArgumentException: '%s' must be a blessed object",
      Dumper($_[0]))
    );
  }
  return $_[0];
}

=item I<is_ClassName>

  sub is_ClassName($value) : Bool

The function can be used to return true or false if the argument can not be 
validated.

I<param> $value to be checked

I<return> true if $value is a valid class name

=cut

sub is_ClassName {
  goto &is_module_name;
}

=item I<assert_ClassName>

  sub assert_ClassName($value) : ClassName

This function can be used to throw an exception if the argument can not be 
validated.

I<param> $value to be checked

I<return> $value if $value is a valid class name

I<throw> IllegalArgumentException if the check fails

=cut

sub assert_ClassName {
  goto &check_module_name;
}

=item I<is_InstanceOf>

  sub is_InstanceOf(Object $object, ClassName $class) : Bool

Check if an object is an instance of a given class.

I<param> $object to be checked

I<param> $class name

I<return> true if object is instance of the given class

=cut

sub is_InstanceOf {
  return (@_ == 2)
    && defined($_[0]) && ref($_[0])
    && blessed($_[0]) && $_[0]->isa($_[1]);
}

=item I<assert_InstanceOf>

  sub assert_InstanceOf(Object $object, ClassName $class) : Object

Check the object instance of a given class.

I<param> $object to be checked

I<param> $class name

I<return> object if it is instance of the fiven class

I<throw> IllegalArgumentException if the check fails

=cut

sub assert_InstanceOf {
  unless ( is_InstanceOf(@_) ) {
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Varname = '';
    local $Data::Dumper::Maxdepth = 1;
    confess(sprintf("IllegalArgumentException: '%s' must be object type '%s'",
      Dumper($_[0]), $_[1])
    );
  }
  return $_[0];
}

=back

=cut

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the Windows Console DotNet library.

 Copyright (C) 2024 by J. Schneider

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

L<Exporter>, L<Ref::Util>, L<Scalar::Util>
