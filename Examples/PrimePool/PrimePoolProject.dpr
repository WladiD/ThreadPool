program PrimePoolProject;

uses
  Forms,
  PrimePoolForm in 'PrimePoolForm.pas' {Form1},
  ThreadPool in '..\..\ThreadPool.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
