unit ProcessCreator;

interface
type
{$IFDEF UNICODE}
PChar = PWideChar;
{$ELSE}
PChar = PAnsiChar;
{$ENDIF}

function CreateProcessOnParentProcess(CommandLine: PChar): Boolean;
function CreateProcessAsAdmin(const path,args,workdir:WideString;mask:Cardinal = 256):LongBool;

function InstallSoft(const fileName,args:string;waitTime:Cardinal=INFINITE):LongBool;

function IsRunningAsAdmin:LongBool;

procedure RestartAsAdminWithSameArgs;

function GetOsVer:Cardinal;{0:unknow;1:xp,2003;2:vista,w7,w2008;3:win8,win8,win8.1,win10}

implementation
uses
  SysUtils,ShellAPI,ActiveX,
  TlHelp32,
  Windows,Logger;
type
   _CLIENT_ID = record
       UniqueProcess: tHANDLE;
       UniqueThread: tHANDLE;
     end;
     CLIENT_ID = _CLIENT_ID;
     PCLIENT_ID = ^CLIENT_ID;
     TClientID = CLIENT_ID;
     PClientID = ^TClientID;
     PUNICODE_STRING = ^UNICODE_STRING;

  UNICODE_STRING = record
    Length: Word;
    MaximumLength: Word;
    Buffer: pwidechar;
  end;
  {$MINENUMSIZE 4}
  TSecurityImpersonationLevel = (SecurityAnonymous,
  SecurityIdentification, SecurityImpersonation, SecurityDelegation);
  {$MINENUMSIZE 1}
  PSecurityQualityOfService = ^TSecurityQualityOfService;
  SECURITY_CONTEXT_TRACKING_MODE = Boolean;
  _SECURITY_QUALITY_OF_SERVICE = record
    Length: Cardinal;
    ImpersonationLevel: TSecurityImpersonationLevel;
    ContextTrackingMode: SECURITY_CONTEXT_TRACKING_MODE;
    EffectiveOnly: Boolean;
  end;

  TSecurityQualityOfService = _SECURITY_QUALITY_OF_SERVICE;
  SECURITY_QUALITY_OF_SERVICE = _SECURITY_QUALITY_OF_SERVICE;
  PSecurityDescriptor = Pointer;

    _OBJECT_ATTRIBUTES = record
    Length: Cardinal;
    RootDirectory: THandle;
    ObjectName: PUNICODE_STRING;
    Attributes: Cardinal;
    SecurityDescriptor: PSecurityDescriptor;
    SecurityQualityOfService: PSecurityQualityOfService;
  end;

  OBJECT_ATTRIBUTES = _OBJECT_ATTRIBUTES;
  POBJECT_ATTRIBUTES = ^OBJECT_ATTRIBUTES;

  PPROC_THREAD_ATTRIBUTE_LIST = Pointer;

  STARTUPINFOEX = packed record
    StartupInfoX: StartupInfo;
    lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST;
  end;

  STARTUPINFOEXA = packed record
    StartupInfoX: StartupInfoA;
    lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST;
  end;
const
  SE_SECURITY_NAME = 'SeSecurityPrivilege';
  PROC_THREAD_ATTRIBUTE_PARENT_PROCESS = $00020000;
  EXTENDED_STARTUPINFO_PRESENT = $00080000;

function InitializeProcThreadAttributeList(lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST; dwAttributeCount, dwFlags: DWORD; var lpSize: Cardinal): Boolean; stdcall; external 'kernel32.dll';
function CreateEnvironmentBlock(lpEnvironment: PPoint; hToken: THandle; bInherit: Boolean): Boolean; stdcall; external 'Userenv.dll' name 'CreateEnvironmentBlock';
procedure UpdateProcThreadAttribute(lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST; dwFlags, Attribute: DWORD; var pValue: Pointer; cbSize: Cardinal; pPreviousValue: Pointer; pReturnSize: PCardinal); stdcall;
external 'kernel32.dll' delayed;
function DestroyEnvironmentBlock(pEnvironment: Pointer): Boolean; stdcall; external 'Userenv.dll' name 'DestroyEnvironmentBlock';
procedure DeleteProcThreadAttributeList(lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST); stdcall; external 'Kernel32.dll';
function NtOpenProcessToken(ProcessHandle: THandle; DesiredAccess: Cardinal;
  TokenHandle: PCardinal): Integer; stdcall;external 'ntdll.dll' name 'NtOpenProcessToken';
function NtOpenProcess(var ProcessHandle: THandle;DesiredAccess: Cardinal;
ObjectAttributes:Pointer;ClientId:Pointer
):Integer;stdcall;external 'ntdll.dll' name 'NtOpenProcess';
function LookupPrivilegeValueW(lpSystemName: PWideChar; lpName: PWideChar;
  lpLuid: PLUID): LongBool; stdcall;
external 'Advapi32.dll' name 'LookupPrivilegeValueW';
function AdjustTokenPrivileges(TokenHandle: THandle;
  DisableAllPrivileges: LongBool; NewState: PTokenPrivileges;
  BufferLength: Cardinal; PreviousState: PTokenPrivileges;
  ReturnLength: PCardinal): LongBool; stdcall;
external 'Advapi32.dll' name 'AdjustTokenPrivileges';

function CheckTokenMembership(TokenHandle: THandle; SidToCheck: Pointer; var IsMember: LongBool): LongBool;
stdcall; external advapi32 name 'CheckTokenMembership';




procedure GetOSVersionInfo(var Info: TOSVersionInfoEx);
begin
  FillChar(Info, SizeOf(TOSVersionInfoEx), 0);
  Info.dwOSVersionInfoSize := SizeOf(TOSVersionInfoEx);
  if not GetVersionEx(TOSVersionInfo(Addr(Info)^)) then RaiseLastOSError;
end;

function GetOsVer:Cardinal;
var
info: TOSVersionInfoEx;
sysInfo: Tsysteminfo;
begin
    windows.GetSystemInfo(sysInfo);
    GetOSVersionInfo(info);
    case info.dwMajorVersion of
    0,1,2,3,4,5:begin
      Result:=1;
    end;
    6:begin
      case info.dwMinorVersion of
       0,1:begin
          Result:=2;
         end;
         2,3:begin
             Result:=3;
         end;
      end;
    end;
    10:begin
      Result:=3;
    end;
    else
    Result:=0;
    end;
end;

function EnableDebug(out hToken: THandle): Boolean;
Const
  SE_DEBUG_NAME = 'SeDebugPrivilege';
var
  _Luit: LUID;
  TP: TOKEN_PRIVILEGES;
  RetLen: Cardinal;
begin
  Result := False;
  hToken := 0;
  if NtOpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES, @hToken)
    <> 0 then
    Exit;
  if not LookupPrivilegeValueW(nil, SE_DEBUG_NAME, @_Luit) then
  begin
    Exit;
  end;
  TP.PrivilegeCount := 1;
  TP.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
  TP.Privileges[0].LUID := Int64(_Luit);
  RetLen := 0;
  Result := AdjustTokenPrivileges(hToken, False, @TP, SizeOf(TP), nil, @RetLen);
end;

function GetIdByName(szName: PChar): DWORD;
var
  hProcessSnap: THANDLE;
  pe32: TProcessEntry32;
begin
  Result:=0;
  hProcessSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  try
  if (hProcessSnap = INVALID_HANDLE_VALUE) then Exit;
  pe32.dwSize := sizeof(TProcessEntry32);
  if Process32First(hProcessSnap, pe32) then
  begin
    repeat
      if UpperCase(strpas(szName)) = UpperCase(pe32.szExeFile) then
      begin
        Result := pe32.th32ProcessID;
        break;
      end;
    until (Process32Next(hProcessSnap, pe32) = FALSE);
  end;
  finally
   CloseHandle(hProcessSnap);
  end;
end;

function CreateProcessOnParentProcess(CommandLine: PChar): Boolean;
var
  pi: Process_Information;
  si: STARTUPINFOEX;
  cbAListSize, IsErr: Cardinal;
  pAList: PPROC_THREAD_ATTRIBUTE_LIST;
  hParent, hToken, Explorerhandle: THandle;
  UserNameATM:{$IFDEF UNICODE} array[0..255] of WideChar{$ELSE}array[0..255] of ANSIChar{$ENDIF};
  BuffSize: DWORD;
  lpEnvironment: Pointer;
  DbHandle:THandle;
  OA:OBJECT_ATTRIBUTES;
  cid:TClientID;
begin
  Result := False;
  { 提升权限 }
  Result := EnableDebug(DbHandle);
  if not Result then Exit;

  UserNameATM := '';

  while (UserNameATM = '') or (UpperCase(UserNameATM) = 'SYSTEM') do
  begin

    Sleep(50);
    Explorerhandle := GetIdByName('EXPLORER.EXE');
    if Explorerhandle <> 0 then
    begin
        FillChar(OA,SizeOf(OBJECT_ATTRIBUTES),#0);
        OA.Length:=SizeOf(OBJECT_ATTRIBUTES);
        cid.UniqueProcess:=Explorerhandle;
        cid.UniqueThread:=0;
      IF   NtOpenProcess(hParent, $1F0FFF, @OA, @cid) = 0 THEN
      begin
       // if NtOpenProcessToken(hParent, TOKEN_ALL_ACCESS, hToken) then
       if NtOpenProcessToken(hParent, TOKEN_ALL_ACCESS, @hToken) = 0 then
          ImpersonateLoggedOnUser(hToken);
        BuffSize := SizeOf(UserNameATM);
        GetUserName(UserNameATM, BuffSize);
        RevertToSelf;
      end;
    end;
  end;
  lpEnvironment := nil;

  if not CreateEnvironmentBlock(@lpEnvironment, hToken, False) then
  begin
    //Printf(GetLastError,'CreateEnvironmentBlock:');
    CloseHandle(hParent);
    CloseHandle(hToken);

    Exit;
  end;

  try
    ZeroMemory(@si, SizeOf(STARTUPINFOEX));
    si.StartupInfox.cb := SizeOf(si);
    si.StartupInfox.lpDesktop := PChar('Winsta0\Default');
    si.StartupInfox.wShowWindow := SW_MINIMIZE;
    ZeroMemory(@pi, SizeOf(Process_Information));
    cbAListSize := 0;
    InitializeProcThreadAttributeList(nil, 1, 0, cbAListSize);

    pAList := HeapAlloc(GetProcessHeap(), 0, cbAListSize);

    if not InitializeProcThreadAttributeList(pAList, 1, 0, cbAListSize) then
    begin
    //Printf(GetLastError,'InitializeProcThreadAttributeList:');
      Exit;
    end;
    SetLastError(0);
    UpdateProcThreadAttribute(pAList, 0, PROC_THREAD_ATTRIBUTE_PARENT_PROCESS, Pointer(hParent), 4, nil, nil);
    IsErr := GetLastError;
    if IsErr > 0 then
    begin
    //Printf(GetLastError,'UpdateProcThreadAttribute:');
      Exit;
    end;
    si.lpAttributeList := pAList;

    if not CreateProcessAsUser(hToken, nil, CommandLine, nil, nil, false, EXTENDED_STARTUPINFO_PRESENT or CREATE_UNICODE_ENVIRONMENT, lpEnvironment, nil, si.StartupInfoX, pi) then
    begin
    //Printf(GetLastError,'CreateProcessAsUser:');
      Exit;
    end;
    Result := True;
  finally
  IF pi.hProcess <> 0 THEN  CloseHandle(pi.hProcess);
  IF pi.hThread <> 0 THEN  CloseHandle(pi.hThread);
  IF hParent <> 0 THEN CloseHandle(hParent);
  IF hToken <> 0 THEN  CloseHandle(hToken);
  IF lpEnvironment <> nil THEN
  BEGIN  DestroyEnvironmentBlock(lpEnvironment);
    lpEnvironment := nil;
  END;
  if pAList <> NIL then
  begin
    DeleteProcThreadAttributeList(pAList);
    HeapFree(GetProcessHeap(), 0, pAList);
  end;
  end;

end;

function CreateProcessAsAdmin(const path,args,workdir:WideString;mask:Cardinal = 256):LongBool;
var
command_line:WideString;
n_path,n_args:Cardinal;
exeCInfo:SHELLEXECUTEINFOW;
ret:Cardinal;
begin
FillChar(exeCInfo,SizeOf(SHELLEXECUTEINFOW),#0);
    ExecInfo.cbSize := sizeof(SHELLEXECUTEINFOW);
    ExecInfo.fMask := mask;
    ExecInfo.lpVerb := 'runas';
    ExecInfo.lpFile := PWideChar(path);
    ExecInfo.lpParameters := PWideChar(args);
    ExecInfo.lpDirectory := PWideChar(workdir);
    ExecInfo.nShow := 1;
    CoInitializeEx(nil,COINIT_APARTMENTTHREADED or COINIT_DISABLE_OLE1DDE);
    try
    Result:=ShellExecuteExW(@exeCInfo);
    if not Result then RaiseLastOSError;
    finally
      CoUninitialize;
    end;
end;

function InstallSoft(const fileName,args:string;waitTime:Cardinal=INFINITE):LongBool;
var
exeCInfo:SHELLEXECUTEINFOW;
ret:Cardinal;
begin
FillChar(exeCInfo,SizeOf(SHELLEXECUTEINFOW),#0);
    ExecInfo.cbSize := sizeof(SHELLEXECUTEINFOW);
    ExecInfo.fMask := 64;
    ExecInfo.lpVerb := nil;
    ExecInfo.lpFile := PWideChar(@fileName[1]);
    ExecInfo.lpParameters := PWideChar(@args[1]);
    ExecInfo.lpDirectory := nil;
    ExecInfo.nShow := 1;
    CoInitializeEx(nil,COINIT_APARTMENTTHREADED or COINIT_DISABLE_OLE1DDE);
    try
    Result:=ShellExecuteExW(@exeCInfo);
    if not Result then RaiseLastOSError;
    WaitForSingleObject(exeCInfo.hProcess,waitTime);
    finally
      CoUninitialize;
    end;
end;

function IsRunningAsAdmin:LongBool;
const
SECURITY_BUILTIN_DOMAIN_RID :LongInt = $00000020;
DOMAIN_ALIAS_RID_ADMINS:LongInt = $00000220;
var
NtAuthority:SID_IDENTIFIER_AUTHORITY;
AdministratorsGroup:PSID;
IsRunAsAdmin:LongBool;
begin
  AdministratorsGroup:=nil;
  FillChar(NtAuthority,SizeOf(SID_IDENTIFIER_AUTHORITY),#0);
  NtAuthority.Value[5]:=5;
 Result:=AllocateAndInitializeSid(
  NtAuthority,
  2,
  SECURITY_BUILTIN_DOMAIN_RID,
  DOMAIN_ALIAS_RID_ADMINS,
  0,0,0,0,0,0,
  AdministratorsGroup
  );
  if not Result then RaiseLastOSError;
 IsRunAsAdmin:=False;
 try
 Result:=CheckTokenMembership(0,AdministratorsGroup,IsRunAsAdmin);
 if not Result then RaiseLastOSError;
 Result:= IsRunAsAdmin <> False;
 finally
  IF AdministratorsGroup <> NIL then FreeSid(AdministratorsGroup);
 end;
end;

function ConsumeSpaces(const str:PWideChar):PWideChar;
var
pWChar:PWideChar;
I:Cardinal;
begin
     pWChar:=str;
     for I := 0 to 1023 do
       begin
          if pWChar^ <> WideChar(#32) then Exit(pWCHar)
          else
          Inc(pWChar);
       end;
       Exception.Create('1024');
end;

function ConsumeArg(const pCmdLine:PWideChar):PWideChar;
var
Quotes:LongBool;
I:Cardinal;
pWChar:PWideChar;
begin
   Quotes:=False;
   pWChar:=pCmdLine;
   for I := 0 to 1023 do
     begin
        if pWChar^ = WideChar(#0) then Exit(pCmdLine);
        if pWChar^ = WideChar(#34){'"'} then
        begin
          if Quotes then
          begin
            Inc(pWChar);
            Exit(ConsumeSpaces(pWChar));
          end;
          Quotes:=True;
        end
        else
        if (pWChar^ <> WideChar(#32){' '}) and (not Quotes) then
        begin
           Exit(ConsumeSpaces(pWChar));
        end;
        Inc(pWChar);
     end;
     Exception.Create('1024');
end;

function GetCommandLineWithoutProgram:WideString;
var
pCommandLineW:PWideChar;
begin
      pCommandLineW:=GetCommandLineW;
      Result:=ConsumeArg(pCommandLineW);
end;

function RestartAsAdmin(const args:WideString):LongBool;
var
path,workdir:array[0..1023] of WideChar;
begin
    FillChar(path[0],1024*2,#0);
    Result:= GetModuleFileNameW(GetModuleHandleW(nil),PWideChar(@path[0]),1024) <> 0;
    if not Result then RaiseLastOSError;
    FillChar(workdir[0],1024*2,#0);
    Result:=GetCurrentDirectoryW(1024,PWideChar(@workdir[0])) <> 0;
    if not Result then RaiseLastOSError;

    Result:=CreateProcessAsAdmin(path, args, workdir);
end;

procedure RestartAsAdminWithSameArgs;
begin
   RestartAsAdmin(GetCommandLineWithoutProgram);
   ExitProcess(0);
end;




end.


