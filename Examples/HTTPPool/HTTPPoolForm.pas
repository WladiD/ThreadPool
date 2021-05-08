unit HTTPPoolForm;

interface

uses
	Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
	Dialogs, Mask, JvExMask, JvSpin, StdCtrls, ExtCtrls, ComCtrls,

	ThreadPool, HTTPThreadPool;

type
	TMainForm = class(TForm)
		Panel1:TPanel;
		LogMemo:TMemo;
		URLMemo:TMemo;
		Label1:TLabel;
		AddTasksButton:TButton;
		CancelTasksButton:TButton;
		ConcurrentWorkersEdit:TJvSpinEdit;
		Label2:TLabel;
		Label3:TLabel;
		SpareWorkersEdit:TJvSpinEdit;
		ProgressBar:TProgressBar;
		procedure FormCreate(Sender:TObject);
		procedure ConcurrentWorkersEditChange(Sender:TObject);
		procedure SpareWorkersEditChange(Sender:TObject);
		procedure AddTasksButtonClick(Sender:TObject);
		procedure CancelTasksButtonClick(Sender:TObject);
		procedure FormDestroy(Sender:TObject);
	private
		procedure TaskStart(Sender:TObject);
		procedure TaskCanceled(Sender:TObject);
		procedure TaskDone(Sender:TObject);
		procedure TaskDownloadStatus(Sender:TObject; Progress, MaxProgress:Int64);
		procedure TasksStatus(Sender:TObject; Progress:Single);
		procedure TasksComplete(Sender:TObject);
	end;

var
	MainForm:TMainForm;

implementation

{$R *.dfm}

procedure DemandInitProc(Manager:TPoolManager);
begin
	if not Assigned(MainForm) then
		Exit;

	Manager.ConcurrentWorkersCount:=Trunc(MainForm.ConcurrentWorkersEdit.Value);
	Manager.SpareWorkersCount:=Trunc(MainForm.SpareWorkersEdit.Value);

	if not Manager.RestoreOwners then
		Manager.RegisterOwner(MainForm, MainForm.TasksStatus, MainForm.TasksComplete);
end;


{** TMainForm **}

procedure TMainForm.AddTasksButtonClick(Sender:TObject);
var
	cc:Integer;
	HTTPTask:THTTPTask;
begin
	LogMemo.Clear;
	{**
	 * Create once, assign needed event handlers and make later only clones with some customizing's
	 *}
	HTTPTask:=THTTPTask.Create(Self);
	HTTPTask.OnDone:=TaskDone;
	HTTPTask.OnStart:=TaskStart;
	HTTPTask.OnCancel:=TaskCanceled;
	HTTPTask.OnDownloadStatus:=TaskDownloadStatus;

	for cc:=0 to URLMemo.Lines.Count - 1 do
	begin
		HTTPTask.URL:=URLMemo.Lines[cc];

		if cc >= (URLMemo.Lines.Count - 3) then
			HTTPTask.Priority:=tpHighest
		else
			HTTPTask.Priority:=tpLowest;

		HTTPManager.AddTask(HTTPTask);

		HTTPTask:=THTTPTask(HTTPTask.Clone);
	end;
end;

procedure TMainForm.CancelTasksButtonClick(Sender:TObject);
begin
	if THTTPManager.HasSingleton then
		HTTPManager.CancelTasksByOwner(Self);
end;

procedure TMainForm.ConcurrentWorkersEditChange(Sender:TObject);
begin
	if THTTPManager.HasSingleton then
		HTTPManager.ConcurrentWorkersCount:=Trunc(ConcurrentWorkersEdit.Value);
end;

procedure TMainForm.FormCreate(Sender:TObject);
begin
	THTTPManager.RegisterSingletonOnDemandProc(DemandInitProc);
end;

procedure TMainForm.FormDestroy(Sender:TObject);
begin
	TPoolManager.TerminateSingletonInstances;
end;

procedure TMainForm.SpareWorkersEditChange(Sender:TObject);
begin
	if THTTPManager.HasSingleton then
		HTTPManager.SpareWorkersCount:=Trunc(SpareWorkersEdit.Value);
end;

procedure TMainForm.TaskCanceled(Sender:TObject);
var
	HTTPTask:THTTPTask;
begin
	if not (Assigned(Sender) and (Sender is THTTPTask)) then
		Exit;
	HTTPTask:=THTTPTask(Sender);

	LogMemo.Lines.Add(Format('Task canceled for "%s"', [HTTPTask.URL]));
end;

procedure TMainForm.TaskDone(Sender:TObject);
var
	HTTPTask:THTTPTask;
	ThreadID:Cardinal;
begin
	if not (Assigned(Sender) and (Sender is THTTPTask)) then
		Exit;
	HTTPTask:=THTTPTask(Sender);

	if Assigned(HTTPTask.Owner) and (HTTPTask.Owner is TPoolWorker) then
		ThreadID:=TPoolWorker(HTTPTask.Owner).ThreadID
	else
		ThreadID:=0;

	LogMemo.Lines.Add(Format('Task done for "%s". [HTTP-Code: %d], [Response-Size: %d Bytes], [ThreadID: %d]',
		[HTTPTask.URL, HTTPTask.ResponseCode, HTTPTask.ResponseSize, ThreadID]));
end;

procedure TMainForm.TaskDownloadStatus(Sender:TObject; Progress, MaxProgress:Int64);
var
	HTTPTask:THTTPTask;
begin
	if not (Assigned(Sender) and (Sender is THTTPTask)) then
		Exit;
	HTTPTask:=THTTPTask(Sender);
	LogMemo.Lines.Add(Format('%d %% (%d of %d Bytes) downloaded of "%s"',
		[Round(Progress / MaxProgress * 100), Progress, MaxProgress, HTTPTask.URL]));
end;

procedure TMainForm.TasksComplete(Sender:TObject);
begin

end;

procedure TMainForm.TasksStatus(Sender:TObject; Progress:Single);
begin
	ProgressBar.Position:=Round(Progress * 100);
end;

procedure TMainForm.TaskStart(Sender:TObject);
begin

end;

end.
