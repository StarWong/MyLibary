unit Unit_Example;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,ZipForge;

type
  TMainForm = class(TForm)
    Button1: TButton;
    Edit1: TEdit;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
  end;

var
  MainForm: TMainForm;
implementation
{$R *.dfm}

type
TFileUnZiper = class(TZipForge)
strict private
FFailure:LongBool;
public
procedure OnError(Sender: TObject; FileName: TZFString;
    Operation: TZFProcessOperation; NativeError: integer;
    ErrorCode: integer; ErrorMessage: TZFString; var Action: TZFAction);
public
property IsError:LongBool  read FFailure write FFailure;
end;



function UnZipFile(const fileToExtra:string;aes256Key:ansistring ='';extraName:string ='';extraDir:string =''):LongBool;
var
zipProcesser:TFileUnZiper;
begin
   Result:=False;
   zipProcesser:=TFileUnZiper.Create(nil);
   try
   try
       with zipProcesser do
       begin
          FileName:=fileToExtra;
          OpenArchive(fmOpenRead);
          EncryptionMethod:=caAES_256;
          Password:=aes256Key;
          if extraDir = '' then
          extraDir :=ExtractFilePath(ParamStr(0));
          BaseDir:=extraDir;
          if extraName = '' then
          extraName :='*.*';
          OnProcessFileFailure:=OnError;
          IsError:=False;
         ExtractFiles(extraName);
         CloseArchive;
       end;
       Result:=Not zipProcesser.IsError;
   except

   end;
   finally
       zipProcesser.Free;
   end;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin

if not   UnZipFile('123.zip','123456') then ShowMessage('failedx');

end;

{ TFileUnZiper }

procedure TFileUnZiper.OnError(Sender: TObject; FileName: TZFString;
  Operation: TZFProcessOperation; NativeError, ErrorCode: integer;
  ErrorMessage: TZFString; var Action: TZFAction);
begin
FFailure:=True;
Action:=fxaIgnore;
end;

end.
