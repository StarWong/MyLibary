unit AES_Stream_Example;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TMainForm = class(TForm)
    Button1: TButton;
    FileOpenDialog1: TFileOpenDialog;
    Label1: TLabel;
    Button2: TButton;
    Button3: TButton;
    dMemo1: TMemo;
    eMemo2: TMemo;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation
uses
BTAES,Logger,Base64;
{$R *.dfm}

const
AES128key:AnsiString ='Œ“∞Æº§’Ω^.^Hello';

procedure TMainForm.Button1Click(Sender: TObject);
begin
if FileOpenDialog1.Execute then
Label1.Caption:=FileOpenDialog1.FileName;
end;

procedure TMainForm.Button2Click(Sender: TObject);
var
F:TMemoryStream;
encoder:TBTAES128;
ret:Cardinal;
cache:array of Byte;
alignedSize:UInt64;
begin
      F:=TMemoryStream.Create;
      encoder:=TBTAES128.Create;
      try
      f.LoadFromFile(Label1.Caption);
    ret:=(f.Size + 8) mod 16;
    if ret = 0 then
     alignedSize:= f.Size + 8
    else
    alignedSize:= f.Size + 8 + 16 -ret;
    SetLength(cache,alignedSize);
      f.Position:=0;
      f.ReadBuffer(cache[0],f.Size);
      PUInt64(@cache[alignedSize - 8])^:=f.Size;
      encoder.encrypt(AES128key,cache,cache);
     // f.Clear;
      f.Position:=0;
      f.WriteBuffer(cache[0],alignedSize);
      SetLength(cache,0);
      f.SaveToFile(Label1.Caption + '.aes128');
      finally
  f.Free;
  encoder.Free;
      end;

end;

procedure TMainForm.Button3Click(Sender: TObject);
var
F:TMemoryStream;
encoder:TBTAES128;
ret:Cardinal;
cache:array of Byte;
vaildSize:UInt64;
begin
      F:=TMemoryStream.Create;
      encoder:=TBTAES128.Create;
      try
      f.LoadFromFile(Label1.Caption);
    ret:=f.Size mod 16;
    //Assert(ret = 0);
      SetLength(cache,f.Size);
      f.Position:=0;
      f.ReadBuffer(cache[0],f.Size);
      encoder.decrypt(AES128key,cache,cache);
      vaildSize:=PUINT64(@cache[f.Size - 8])^;
      f.SetSize(vaildSize);
      f.Position:=0;
      f.WriteBuffer(cache[0],vaildSize);
      SetLength(cache,0);
      f.SaveToFile(Label1.Caption + '.json');
      finally
  f.Free;
  encoder.Free;
      end;

end;

procedure TMainForm.SpeedButton1Click(Sender: TObject);
var
encoder:TBTAES128;
s1,s2:string;
begin
  encoder:=TBTAES128.Create;
  try
  s1:=eMemo2.Lines.Text;

  encoder.encryptStr(AES128key,s1,s2,True);
   dMemo1.Lines.Text:=s2;
   eMemo2.Clear;
  finally
    encoder.Free;
  end;

end;

procedure TMainForm.SpeedButton2Click(Sender: TObject);
var
decoder:TBTAES128;
s1,s2:string;
begin
  decoder:=TBTAES128.Create;
  try
  s1:=dMemo1.Lines.Text;

  decoder.decryptstr(AES128key,s1,s2,True);
   eMemo2.Lines.Text:=s2;
   dMemo1.Clear;
  finally
    decoder.Free;
  end;

end;

end.
