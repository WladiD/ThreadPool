unit PrimePoolForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.Math,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,

  ThreadPool,
  {**
   * This is the example pool
   *}
  PrimePool;

type
  TMainForm = class(TForm)
    LogMemo: TMemo;
    Panel1: TPanel;
    AddPrimeTasksButton: TButton;
    TerminatePrimeManagerButton: TButton;
    ConcurrentWorkersEdit: TEdit;
    Label1: TLabel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Label2: TLabel;
    StartNumberEdit: TEdit;
    Label3: TLabel;
    TaskRangeEdit: TEdit;
    Label4: TLabel;
    TaskCountEdit: TEdit;
    Label5: TLabel;
    SpareWorkersEdit: TEdit;
    CancelTasksButton: TButton;
    PrimeProgressBar: TProgressBar;
    procedure FormDestroy(Sender: TObject);
    procedure AddPrimeTasksButtonClick(Sender: TObject);
    procedure TerminatePrimeManagerButtonClick(Sender: TObject);
    procedure ConcurrentWorkersEditChange(Sender: TObject);
    procedure SpareWorkersEditChange(Sender: TObject);
    procedure CancelTasksButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure TaskStart(Sender: TObject);
    procedure TaskCanceled(Sender: TObject);
    procedure TaskDone(Sender: TObject);
    procedure TasksStatus(Sender: TObject; Progress: Single);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

{ TMainForm }

procedure TMainForm.CancelTasksButtonClick(Sender: TObject);
begin
  TPrimeManager.Singleton.CancelTasksByOwner(Self);
end;

procedure TMainForm.ConcurrentWorkersEditChange(Sender: TObject);
begin
  if TPrimeManager.HasSingleton then
    TPrimeManager.Singleton.ConcurrentWorkersCount := StrToInt(ConcurrentWorkersEdit.Text);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Activate the "Demand Mode" of the manager
  TPrimeManager.RegisterSingletonOnDemandProc(
    procedure(Manager: TPoolManager)
    begin
      Manager.ConcurrentWorkersCount := StrToInt(ConcurrentWorkersEdit.Text);
      Manager.SpareWorkersCount := StrToInt(SpareWorkersEdit.Text);
      if not Manager.RestoreOwners then
        Manager.RegisterOwner(Self, TasksStatus, TaskDone);
    end);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  TPoolManager.DispatchOwnerDestroyed(Self);
  TPrimeManager.UnregisterSingletonOnDemandProc;
  TPoolManager.TerminateSingletonInstances;
end;

procedure TMainForm.SpareWorkersEditChange(Sender: TObject);
begin
  if TPrimeManager.HasSingleton then
    TPrimeManager.Singleton.SpareWorkersCount := StrToInt(SpareWorkersEdit.Text);
end;

procedure TMainForm.AddPrimeTasksButtonClick(Sender: TObject);
var
  PrimeTask: TPrimeTask;
  cc, Range, Steps, Start: Cardinal;
begin
  LogMemo.Clear;

  Start := StrToInt(StartNumberEdit.Text);
  Steps := StrToInt(TaskCountEdit.Text);
  Range := StrToInt(TaskRangeEdit.Text);

  PrimeTask := TPrimeTask.Create(Self);
  PrimeTask.OnStart := TaskStart;
  PrimeTask.OnCancel := TaskCanceled;
  PrimeTask.OnDone := TaskDone;

  for cc := 0 to Steps - 1 do
  begin
    Primetask.FromNumber := (cc * Range) + Start;
    PrimeTask.ToNumber := (((cc + 1) * Range) - 1) + Start;

    TPrimeManager.Singleton.AddTask(PrimeTask);

    PrimeTask := TPrimeTask(PrimeTask.Clone);
  end;
end;

procedure TMainForm.TaskStart(Sender: TObject);
var
  Task: TPrimeTask;
  ThreadID: Cardinal;
begin
  if not (Assigned(Sender) and (Sender is TPrimeTask)) then
    Exit;
  Task := TPrimeTask(Sender);
  if Assigned(Task.Owner) and (Task.Owner is TPoolWorker) then
    ThreadID := TPoolWorker(Task.Owner).ThreadID
  else
    ThreadID := 0;
  LogMemo.Lines.Add(Format('Task started for range %d - %d with thread #%d...',
    [Task.FromNumber, Task.ToNumber, ThreadID]));
  LogMemo.Lines.Add('----');
end;

procedure TMainForm.TaskCanceled(Sender: TObject);
var
  Task: TPrimeTask;
begin
  if not (Assigned(Sender) and (Sender is TPrimeTask)) then
    Exit;
  Task := TPrimeTask(Sender);
  LogMemo.Lines.Add(Format('Task canceled for range %d - %d.',
    [Task.FromNumber, Task.ToNumber]));
end;

procedure TMainForm.TaskDone(Sender:TObject);
var
  Task: TPrimeTask;
  ThreadID: Cardinal;
  PrimeNumbers: string;
  cc: Integer;
  MaxInList: Integer;
  CutList: Boolean;
begin
  if not (Assigned(Sender) and (Sender is TPrimeTask)) then
    Exit;
  Task := TPrimeTask(Sender);
  if Assigned(Task.Owner) and (Task.Owner is TPoolWorker) then
    ThreadID := TPoolWorker(Task.Owner).ThreadID
  else
    ThreadID := 0;

  LogMemo.Lines.Add(Format('Task done for range %d - %d by thread #%d and %d prime numbers found:',
    [Task.FromNumber, Task.ToNumber, ThreadID, Length(Task.PrimesOutput)]));

  PrimeNumbers := '';

  MaxInList := Length(Task.PrimesOutput) - 1;
  CutList := MaxInList > 10;
  if CutList then
    MaxInList := 10;

  for cc := 0 to MaxInList do
    PrimeNumbers := Format('%s, %d', [PrimeNumbers, Task.PrimesOutput[cc]]);

  if PrimeNumbers <> '' then
  begin
    PrimeNumbers := Copy(PrimeNumbers, 3, Length(PrimeNumbers));
    if CutList then
      PrimeNumbers := PrimeNumbers + ' ...'
  end;

  LogMemo.Lines.Add(PrimeNumbers);
  LogMemo.Lines.Add('----');
end;

procedure TMainForm.TasksStatus(Sender: TObject; Progress: Single);
begin
  PrimeProgressBar.Max := 100;
  PrimeProgressBar.Position := Round(Progress * 100);
end;

procedure TMainForm.TerminatePrimeManagerButtonClick(Sender: TObject);
begin
  if TPrimeManager.HasSingleton then
    TPrimeManager.Singleton.Terminate;
end;

end.
