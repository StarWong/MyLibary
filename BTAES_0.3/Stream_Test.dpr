program Stream_Test;

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Forms,
  AES_Stream_Example in 'AES_Stream_Example.pas' {MainForm},
  BTAES in 'src\BTAES.pas',
  BTAESBox in 'src\BTAESBox.pas',
  BTAESUtil in 'src\BTAESUtil.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
