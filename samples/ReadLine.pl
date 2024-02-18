# https://learn.microsoft.com/en-us/dotnet/api/system.console.readline?view=net-8.0
# This example demonstrates the System::Console->read() method.

use 5.014;
use Win32::Console::DotNet;
use DateTime;

sub main() {
  #
  my $console = System::Console->instance();
  $console->Clear();

  my $dat = DateTime->now();

  $console->Out->Write(sprintf("\nToday is %s at %s.", $dat->dmy('/'), $dat->hms));
  $console->Out->Write("\nPress Enter key to continue... ");
  $console->ReadLine();
}

exit main();

__END__

=pod

=begin comment

The example displays output like the following:
     Today is 10/26/2015 at 12:22:22 PM.

     Press Enter key to continue...

=end comment
