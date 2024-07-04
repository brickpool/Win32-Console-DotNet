# https://learn.microsoft.com/en-us/dotnet/api/system.console.write?view=net-8.0
# This example demonstrates the System::Console->Write() method.

use 5.014;
use warnings;
use Win32::Console::DotNet;

sub main {
  my $console = System::Console->instance();

  $console->Clear();
  # Format a integer or floating-point number in various ways.
  $console->WriteLine("Standard Numeric Format Specifiers");
  $console->Write("%08d\n", 123);
  $console->Write("%.3f\n", -123.45);
  $console->Write("%d = %f\n", 123, 123);
  $console->WriteLine();

  # Format a value in various ways.
  $console->WriteLine("Standard Format Specifiers");
  $console->WriteLine(123);
  $console->WriteLine(-123.45);
  $console->Write("\tTAB");
  $console->WriteLine(undef);

  $console->Write("--end--");
  return 0;
}

exit main();
