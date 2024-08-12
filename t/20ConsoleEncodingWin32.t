# https://github.com/dotnet/runtime/blob/116f5fd624c6981a66c2a03c5ea5f8fa037ef57f/src/libraries/System.Console/tests/ConsoleEncoding.Windows.cs
# Licensed to the .NET Foundation under one or more agreements.
# The .NET Foundation licenses this file to you under the MIT license.
use 5.014;
use warnings;

use Test::More;
use Test::Exception;
use Config;

BEGIN {
  unless ( $^O eq 'MSWin32' ) {
    plan skip_all => 'This is not MSWin32';
  }
  else {
    plan tests => 10;
  }
}

BEGIN {
  use_ok 'Win32';
  use_ok 'Win32::Console';
  use_ok 'Win32::Console::DotNet';
  use_ok 'System';
}

sub Encoding::Latin1::CodePage  (){ 28591 }
sub Encoding::ASCII::CodePage   (){ 20127 }
sub Encoding::Unicode::CodePage (){ $Config{byteorder} =~ /1234/ ? 1200 : 1201 }

sub OnLeaveScope::DESTROY { ${$_[0]}->() }

subtest 'InputEncoding_SetDefaultEncoding_Success' => sub {
  plan tests => 3;
  lives_ok {
    my $encoding = Win32::GetConsoleCP();
    Console->InputEncoding($encoding);
    is Console->InputEncoding, $encoding;
    is Win32::GetConsoleCP(), $encoding;
  };
};

subtest 'InputEncoding_SetUnicodeEncoding_SilentlyIgnoredInternally' => sub {
  plan tests => 4;
  lives_ok {
    my $unicodeEncoding = Encoding::Unicode->CodePage;
    my $oldEncoding = Console->InputEncoding;
    isnt $oldEncoding, $unicodeEncoding;

    Console->InputEncoding($unicodeEncoding);
    is Console->InputEncoding, $unicodeEncoding;
    is Win32::GetConsoleCP(), $oldEncoding;
  };
};

subtest 'InputEncoding_SetEncodingWhenDetached_ErrorIsSilentlyIgnored' => sub {
  plan tests => 4;
  my $oldEncoding = Win32::GetConsoleCP();
  lives_ok {
    my $dispose = bless \sub {
      # Restore the console
      Win32::Console::Alloc();
      Win32::SetConsoleCP($oldEncoding);
    }, 'OnLeaveScope';
    my $encoding = Console->InputEncoding != Encoding::ASCII->CodePage
                  ? Encoding::ASCII->CodePage
                  : Encoding::Latin1->CodePage;
    
    # use FreeConsole to detach the current console - simulating a process 
    # started with the "DETACHED_PROCESS" flag
    Win32::Console::Free();

    # Setting the input encoding should not throw an exception
    Console->InputEncoding($encoding);
    # The internal state of Console should have updated, despite the failure 
    # to change the console's input encoding
    is Console->InputEncoding, $encoding;
    # Operations on the console are no longer valid - GetConsoleCP fails.
    is Win32::GetConsoleCP(), 0;
  };
  is Win32::GetConsoleCP(), $oldEncoding;
};

subtest 'OutputEncoding_SetDefaultEncoding_Success' => sub {
  plan tests => 3;
  lives_ok {
    my $encoding = Win32::GetConsoleOutputCP();
    Console->OutputEncoding($encoding);
    is Console->OutputEncoding, $encoding;
    is Win32::GetConsoleOutputCP(), $encoding;
  };
};

subtest 'OutputEncoding_SetUnicodeEncoding_SilentlyIgnoredInternally' => sub {
  plan tests => 4;
  lives_ok {
    my $unicodeEncoding = Encoding::Unicode->CodePage;
    my $oldEncoding = Console->OutputEncoding;
    isnt $oldEncoding, $unicodeEncoding;

    Console->OutputEncoding($unicodeEncoding);
    is Console->OutputEncoding, $unicodeEncoding;
    is Win32::GetConsoleOutputCP(), $oldEncoding;
  };
};

subtest 'OutputEncoding_SetEncodingWhenDetached_ErrorIsSilentlyIgnored' => sub {
  plan tests => 4;
  my $oldEncoding = Win32::GetConsoleOutputCP();
  lives_ok {
    my $dispose = bless \sub {
      # Restore the console
      Win32::Console::Alloc();
      Win32::SetConsoleOutputCP($oldEncoding);
    }, 'OnLeaveScope';
    my $encoding = Console->OutputEncoding != Encoding::ASCII->CodePage
                  ? Encoding::ASCII->CodePage
                  : Encoding::Latin1->CodePage;
    
    # use FreeConsole to detach the current console - simulating a process 
    # started with the "DETACHED_PROCESS" flag
    Win32::Console::Free();

    # Setting the output encoding should not throw an exception
    Console->OutputEncoding($encoding);
    # The internal state of Console should have updated, despite the failure 
    # to change the console's output encoding
    is Console->OutputEncoding, $encoding;
    # Operations on the console are no longer valid - GetConsoleOutputCP fails.
    is Win32::GetConsoleOutputCP(), 0;
  };
  is Win32::GetConsoleOutputCP(), $oldEncoding;
};

done_testing;
