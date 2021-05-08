program HTTPPoolProject;

uses
  Forms,
  HTTPPoolForm in 'HTTPPoolForm.pas' {MainForm},
  HTTPThreadPool in '..\..\HTTPThreadPool.pas',
  ThreadPool in '..\..\ThreadPool.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
