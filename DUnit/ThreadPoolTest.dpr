program ThreadPoolTest;
{

  Delphi DUnit-Testprojekt
  -------------------------
  Dieses Projekt enthlt das DUnit-Test-Framework und die GUI/Konsolen-Test-Runner.
  Zum Verwenden des Konsolen-Test-Runners fgen Sie den konditinalen Definitionen
  in den Projektoptionen "CONSOLE_TESTRUNNER" hinzu. Ansonsten wird standardmig
  der GUI-Test-Runner verwendet.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  Forms,
  TestFramework,
  GUITestRunner,
  TextTestRunner,
  TestThreadPool in 'TestThreadPool.pas',
  ThreadPool in '..\ThreadPool.pas';

{$R *.RES}

begin
	Application.Initialize;
	if IsConsole then
		with TextTestRunner.RunRegisteredTests(rxbPause) do
			Free
	else
		GUITestRunner.RunRegisteredTests;
end.

