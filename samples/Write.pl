# https://learn.microsoft.com/en-us/dotnet/api/system.console.write?view=net-8.0
# This example demonstrates the System::Console->Write() method.

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

sub main {
  Console->Clear();
  # Format a integer or floating-point number in various ways.
  Console->WriteLine("Standard Numeric Format Specifiers");
  Console->Write("%08d\n", 123);
  Console->Write("%.3f\n", -123.45);
  Console->Write("%d = %f\n", 123, 123);
  Console->WriteLine();

  # Format a value in various ways.
  Console->WriteLine("Standard Format Specifiers");
  Console->WriteLine(123);
  Console->WriteLine(-123.45);
  Console->Write("\tTAB");
  Console->WriteLine(undef);

  Console->Write("--end--");
  return 0;
}

exit main();
