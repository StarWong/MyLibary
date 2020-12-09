unit UIntUtils;
{ A missing RTL function written by Warren Postma. }
{$DEFINE CPUX86}
interface
  function TryStrToUINT64(StrValue:String; var uValue:UInt64 ):Boolean;
  function StrToUINT64(Value:String):UInt64;
  function  InterlockedExchangeAdd64(var Addend: UInt64; Value: UInt64): UInt64;
implementation

uses SysUtils,Character;

function InterlockedCompareExchange64(var Destination:UInt64;ExChange,Comperand:UInt64):UInt64;
stdcall;external 'kernel32.dll' name 'InterlockedCompareExchange64';

{$R-}

function TryStrToUINT64(StrValue:String; var uValue:UInt64 ):Boolean;
var
  Start,Base,Digit:Integer;
  n:Integer;
  Nextvalue:UInt64;
begin
  result := false;
  Base := 10;
  Start := 1;
  StrValue := Trim(UpperCase(StrValue));
  if StrValue='' then
    exit;
  if StrValue[1]='-' then
    exit;
  if StrValue[1]='$' then
  begin
    Base := 16;
    Start := 2;
    if Length(StrValue)>17 then // $+16 hex digits = max hex length.
        exit;
  end;
  uValue := 0;
  for n := Start to Length(StrValue) do
  begin
      if Character.IsDigit(StrValue[n]) then
          Digit := Ord(StrValue[n])-Ord('0')
      else if  (Base=16) and (StrValue[n] >= 'A') and (StrValue[n] <= 'F') then
          Digit := (Ord(StrValue[n])-Ord('A'))+10
      else
          exit;// invalid digit.

      Nextvalue := (uValue*base)+digit;
      if (Nextvalue<uValue) then
          exit;
      uValue := Nextvalue;
  end;
  result := true; // success.
end;

function StrToUINT64(Value:String):UInt64;
begin
  if not TryStrToUINT64(Value,result) then
    raise EConvertError.Create('Invalid uint64 value');

end;

{$R+}

function  InterlockedExchangeAdd64(var Addend: UInt64; Value: UInt64): UInt64;
begin
  repeat
    Result := Addend;
  until (InterlockedCompareExchange64(Addend, Result + Value, Result) = Result);
end;



//{$IFDEF CPUX86}
//function  InterlockedExchangeAdd64(var Addend: Int64; Value: longword): Int64; register;
//asm
//          PUSH    EDI
//          PUSH    ESI
//          PUSH    EBX
//
//          MOV     EDI, EAX
//          MOV     ESI, EDX
//
//          MOV     EAX, [EDI]
//          MOV     EDX, [EDI+4]
//@@1:
//          MOV     ECX, EDX
//          MOV     EBX, EAX
//
//          ADD     EBX, ESI
//          ADC     ECX, 0
//
//LOCK      CMPXCHG8B [EDI]
//          JNZ     @@1
//
//          POP     EBX
//          POP     ESI
//          POP     EDI
//end;
//{$ENDIF}
//
//{$IFDEF CPUX64}
//function  InterlockedExchangeAdd64(var Addend: Int64; Value: longword): Int64; register;
//asm
//          .NOFRAME
//          MOV     RAX, RDX
//          LOCK    XADD [RCX], RAX
//end;
//{$ENDIF}


end.
