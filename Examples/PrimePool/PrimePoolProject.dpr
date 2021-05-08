program PrimePoolProject;

uses
  Forms,
  PrimePoolForm in 'PrimePoolForm.pas' {MainForm},
  ThreadPool in '..\..\ThreadPool.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
