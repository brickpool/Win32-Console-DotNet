# https://learn.microsoft.com/en-us/dotnet/api/system.console.read?view=net-8.0
# This example demonstrates the System::Console->read() method.

use 5.014;
use Win32::Console::DotNet;
use Try::Tiny;

sub main() {
  my $m1 = "\nType a string of text then press Enter. " .
           "Type '+' anywhere in the text to quit:\n";
  my $m2 = "Character '%s' is hexadecimal %#.4x.";
  my $m3 = "Character     is hexadecimal %#.4x.";
  my $ch;
  my $x;
   
  #
  my $console = System::Console->instance();
  say($m1);
  do {
    $x = $console->Read();
    try {
      $ch = $x < 0 ? die "Invalid value" : chr( $x );
      if ( $ch =~ /^\s+$/ ) {
        printf($m3 . "\n", $x);
        if ( $ch == 0x0a ) {
          say($m1);
        }
      }
      else {
        printf($m2 . "\n", $ch, $x);
      }
    }
    catch {
      printf("%s Value read = %d.\n", $_, $x);
      $ch = "\0";
      say($m1);
    }

  }
  while ( $ch ne '+' );
}

exit main();

__END__

=pod

=begin comment

This example produces the following results:

Type a string of text then press Enter. Type '+' anywhere in the text to quit:

The quick brown fox.
Character 'T' is hexadecimal 0x0054.
Character 'h' is hexadecimal 0x0068.
Character 'e' is hexadecimal 0x0065.
Character     is hexadecimal 0x0020.
Character 'q' is hexadecimal 0x0071.
Character 'u' is hexadecimal 0x0075.
Character 'i' is hexadecimal 0x0069.
Character 'c' is hexadecimal 0x0063.
Character 'k' is hexadecimal 0x006b.
Character     is hexadecimal 0x0020.
Character 'b' is hexadecimal 0x0062.
Character 'r' is hexadecimal 0x0072.
Character 'o' is hexadecimal 0x006f.
Character 'w' is hexadecimal 0x0077.
Character 'n' is hexadecimal 0x006e.
Character     is hexadecimal 0x0020.
Character 'f' is hexadecimal 0x0066.
Character 'o' is hexadecimal 0x006f.
Character 'x' is hexadecimal 0x0078.
Character '.' is hexadecimal 0x002e.
Character     is hexadecimal 0x000d.
Character     is hexadecimal 0x000a.

Type a string of text then press Enter. Type '+' anywhere in the text to quit:

^Z
Value was either too large or too small for a character. Value read = -1.

Type a string of text then press Enter. Type '+' anywhere in the text to quit:

+
Character '+' is hexadecimal 0x002b.

=end comment
