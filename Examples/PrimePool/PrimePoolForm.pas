unit PrimePoolForm;

interface

uses
	Windows, Messages, SysUtils, Variants, ThreadPool, Classes, Graphics, Controls, Forms,
	Dialogs, StdCtrls, Math, ExtCtrls, ComCtrls,
	{**
	 * This is the example pool
	 *}
	PrimePool;

type
	TForm1 = class(TForm)
		LogMemo:TMemo;
		Panel1:TPanel;
		AddPrimeTasksButton:TButton;
		TerminatePrimeManagerButton:TButton;
		ConcurrentWorkersEdit:TEdit;
		Label1:TLabel;
		PageControl1:TPageControl;
		TabSheet1:TTabSheet;
		Label2:TLabel;
		StartNumberEdit:TEdit;
		Label3:TLabel;
		TaskRangeEdit:TEdit;
		Label4:TLabel;
		TaskCountEdit:TEdit;
		Label5:TLabel;
		SpareWorkersEdit:TEdit;
		CancelTasksButton:TButton;
		PrimeProgressBar:TProgressBar;
		procedure FormDestroy(Sender:TObject);
		procedure AddPrimeTasksButtonClick(Sender:TObject);
		procedure TerminatePrimeManagerButtonClick(Sender:TObject);
		procedure ConcurrentWorkersEditChange(Sender:TObject);
		procedure SpareWorkersEditChange(Sender:TObject);
		procedure CancelTasksButtonClick(Sender:TObject);
    	procedure FormCreate(Sender:TObject);
	private
		procedure TaskStart(Sender:TObject);
		procedure TaskCanceled(Sender:TObject);
		procedure TaskDone(Sender:TObject);
		procedure TasksStatus(Sender:TObject; Progress:Single);
	end;

var
	Form1: TForm1;

implementation

{$R *.dfm}

{** TForm1 **}

procedure PrimePoolInit(Manager:TPoolManager);
begin
	if Assigned(Form1) then
	begin
		Manager.ConcurrentWorkersCount:=StrToInt(Form1.ConcurrentWorkersEdit.Text);
		Manager.SpareWorkersCount:=StrToInt(Form1.SpareWorkersEdit.Text);
		if not Manager.RestoreOwners then
			Manager.RegisterOwner(Form1, Form1.TasksStatus, Form1.TaskDone);
	end;
end;

procedure TForm1.CancelTasksButtonClick(Sender: TObject);
begin
	TPrimeManager.Singleton.CancelTasksByOwner(Self);
end;

procedure TForm1.ConcurrentWorkersEditChange(Sender:TObject);
begin
	if TPrimeManager.HasSingleton then
		TPrimeManager.Singleton.ConcurrentWorkersCount:=StrToInt(ConcurrentWorkersEdit.Text);
end;

procedure TForm1.FormCreate(Sender:TObject);
begin
	{**
	 * Activate the "Demand Mode" of the manager
	 *}
	TPrimeManager.RegisterSingletonOnDemandProc(PrimePoolInit);
end;

procedure TForm1.FormDestroy(Sender:TObject);
begin
	TPoolManager.DispatchOwnerDestroyed(Self);
	TPrimeManager.UnregisterSingletonOnDemandProc;
	TPoolManager.TerminateSingletonInstances;
end;

procedure TForm1.SpareWorkersEditChange(Sender:TObject);
begin
	if TPrimeManager.HasSingleton then
		TPrimeManager.Singleton.SpareWorkersCount:=StrToInt(SpareWorkersEdit.Text);
end;

procedure TForm1.AddPrimeTasksButtonClick(Sender:TObject);
var
	PrimeTask:TPrimeTask;
	cc, Range, Steps, Start:Cardinal;
begin
	LogMemo.Clear;

	Start:=StrToInt(StartNumberEdit.Text);
	Steps:=StrToInt(TaskCountEdit.Text);
	Range:=StrToInt(TaskRangeEdit.Text);

	PrimeTask:=TPrimeTask.Create(Self);
	PrimeTask.OnStart:=Form1.TaskStart;
	PrimeTask.OnCancel:=Form1.TaskCanceled;
	PrimeTask.OnDone:=Form1.TaskDone;

	for cc:=0 to Steps - 1 do
	begin
		Primetask.FromNumber:=(cc * Range) + Start;
		PrimeTask.ToNumber:=(((cc + 1) * Range) - 1) + Start;

		TPrimeManager.Singleton.AddTask(PrimeTask);

		PrimeTask:=TPrimeTask(PrimeTask.Clone);
	end;
end;

procedure TForm1.TaskStart(Sender:TObject);
var
	Task:TPrimeTask;
	ThreadID:Cardinal;
begin
	if not (Assigned(Sender) and (Sender is TPrimeTask)) then
		Exit;
	Task:=TPrimeTask(Sender);
	if Assigned(Task.Owner) and (Task.Owner is TPoolWorker) then
		ThreadID:=TPoolWorker(Task.Owner).ThreadID
	else
		ThreadID:=0;
	LogMemo.Lines.Add(Format('Task started for range %d - %d with thread #%d...',
		[Task.FromNumber, Task.ToNumber, ThreadID]));
	LogMemo.Lines.Add('----');
end;

procedure TForm1.TaskCanceled(Sender: TObject);
var
	Task:TPrimeTask;
begin
	if not (Assigned(Sender) and (Sender is TPrimeTask)) then
		Exit;
	Task:=TPrimeTask(Sender);
	LogMemo.Lines.Add(Format('Task canceled for range %d - %d.',
		[Task.FromNumber, Task.ToNumber]));
end;

procedure TForm1.TaskDone(Sender:TObject);
var
	Task:TPrimeTask;
	ThreadID:Cardinal;
	PrimeNumbers:String;
	cc:Integer;
	MaxInList:Integer;
	CutList:Boolean;
begin
	if not (Assigned(Sender) and (Sender is TPrimeTask)) then
		Exit;
	Task:=TPrimeTask(Sender);
	if Assigned(Task.Owner) and (Task.Owner is TPoolWorker) then
		ThreadID:=TPoolWorker(Task.Owner).ThreadID
	else
		ThreadID:=0;

	LogMemo.Lines.Add(Format('Task done for range %d - %d by thread #%d and %d prime numbers found:',
		[Task.FromNumber, Task.ToNumber, ThreadID, Length(Task.PrimesOutput)]));

	PrimeNumbers:='';

	MaxInList:=Length(Task.PrimesOutput) - 1;
	CutList:=MaxInList > 10;
	if CutList then
		MaxInList:=10;

	for cc:=0 to MaxInList do
		PrimeNumbers:=Format('%s, %d', [PrimeNumbers, Task.PrimesOutput[cc]]);

	if PrimeNumbers <> '' then
	begin
		PrimeNumbers:=Copy(PrimeNumbers, 3, Length(PrimeNumbers));
		if CutList then
			PrimeNumbers:=PrimeNumbers + ' ...'
	end;

	LogMemo.Lines.Add(PrimeNumbers);

	LogMemo.Lines.Add('----');
end;

procedure TForm1.TasksStatus(Sender:TObject; Progress:Single);
begin
	PrimeProgressBar.Max:=100;
	PrimeProgressBar.Position:=Round(Progress * 100);
end;

procedure TForm1.TerminatePrimeManagerButtonClick(Sender:TObject);
begin
	if TPrimeManager.HasSingleton then
		TPrimeManager.Singleton.Terminate;
end;

end.
