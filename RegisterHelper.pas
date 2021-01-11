unit RegisterHelper;

interface

function IsVCRTL140Installed:LongBool;

implementation
uses
Registry,Windows,SysUtils;

type
TIsWow64Process = function(hProcess:THandle;var Wow64Process:LongBool):LongBool;stdcall;


function Is32BitProcessUnderWOW64:LongBool;
var
IsWow64Process:TIsWow64Process;
hmod:THandle;
begin
 Result:=False;
 hmod:= LoadLibraryW('kernel32.dll');
 if hmod = 0 then RaiseLastOSError;
 IsWow64Process:=nil;
 IsWow64Process:=GetProcAddress(hmod, 'IsWow64Process');
 if Assigned(IsWow64Process) then
 begin
   IsWow64Process(GetCurrentProcess,Result);
 end;
end;

function IsVCRTL140Installed:LongBool;
var
 reg:TRegistry;
begin
  reg := TRegistry.Create(KEY_READ);
  try
  reg.RootKey := HKEY_LOCAL_MACHINE;
  if Is32BitProcessUnderWOW64 then
  Result:=reg.KeyExists('SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x86')
  else
  Result:=reg.KeyExists('SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86');
  finally
    reg.Free;
  end;
end;



end.
