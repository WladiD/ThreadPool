unit TestThreadPool;

interface

uses
	TestFramework, Generics.Defaults, Forms, Generics.Collections, Classes,
	Contnrs, SysUtils, Windows, SyncObjs, ThreadPool;

type

	TTestThreadPool= class(TTestCase)
	public
//		procedure SetUp; override;
		procedure TearDown; override;

		procedure StressAddTaskTest(TasksCount, ConcurrentWorkers:Integer);
		procedure StressAddOwnerTaskTest(OwnersCount, TasksPerOwnerCount,
			ConcurrentWorkers:Integer);
	published
		procedure Singleton;
		procedure DemandProc;
		procedure ValidatePerCPUWorkersCount;
		procedure TasksCountByOwner;

		procedure StressAddTask_1000Tasks_2Workers;
		procedure StressAddTask_1000Tasks_4Workers;
		procedure StressAddTask_1000Tasks_8Workers;
		procedure StressAddTask_1000Tasks_16Workers;

		procedure StressAddTask_10000Tasks_2Workers;
		procedure StressAddTask_10000Tasks_4Workers;
		procedure StressAddTask_10000Tasks_8Workers;
		procedure StressAddTask_10000Tasks_16Workers;

		procedure StressAddOwnerTask_10Owner_1000Tasks_2Worker;
		procedure StressAddOwnerTask_20Owner_1000Tasks_4Worker;
		procedure StressAddOwnerTask_30Owner_1000Tasks_8Worker;
		procedure StressAddOwnerTask_40Owner_1000Tasks_16Worker;
	end;


{** Some thread pools for testing purposes **}

{**
 * Simply does nothing, but implement all needed methods
 *}
{$REGION 'Null thread pool'}
	TNULLTask = class(TPoolTask);

	TNULLWorker = class(TPoolWorker)
	protected
		procedure ExecuteTask; override;
	end;

	TNULLManager = class(TPoolManager)
	protected
		class function WorkerClass:TPoolWorkerClass; override;
	public
		class function Singleton:TNULLManager; reintroduce;
	end;
{$ENDREGION}

{**
 * Next useless thread pool, which can sleep
 *}
{$REGION 'Sleeping thread pool'}
	TSLEEPTask = class(TPoolTask)
	protected
		FSleepDuration:Integer;
	public
		property SleepDuration:Integer read FSleepDuration write FSleepDuration;
	end;

	TSLEEPWorker = class(TPoolWorker)
	protected
		procedure ExecuteTask; override;
	end;

	TSLEEPManager = class(TPoolManager)
	protected
		class function WorkerClass:TPoolWorkerClass; override;
	public
		class function Singleton:TSLEEPManager; reintroduce;
	end;
{$ENDREGION}


implementation


{** TThreadPoolTest **}

procedure TTestThreadPool.DemandProc;
var
	DemandProc:TManagerProc;
	DemandProcCalledTimes:Integer;

	procedure CheckHasDemandProc(ShouldExist:Boolean);
	begin
		Check(TNULLManager.HasSingletonOnDemandProc = ShouldExist);
		Check(TSLEEPManager.HasSingletonOnDemandProc = ShouldExist);
	end;

begin
	DemandProcCalledTimes:=0;
	DemandProc:=procedure(Manager:TPoolManager)
	begin
		Inc(DemandProcCalledTimes);
	end;
	{**
	 * At start no demand init proc should be exists
	 *}
	CheckHasDemandProc(FALSE);
	{**
	 * Register...
	 *}
	TNULLManager.RegisterSingletonOnDemandProc(DemandProc);
	TSLEEPManager.RegisterSingletonOnDemandProc(DemandProc);
	CheckHasDemandProc(TRUE);
	{**
	 * ...make some single instances (the demand init proc should be called here)...
	 *}
	TNULLManager.Singleton;
	TSLEEPManager.Singleton;
	Check(DemandProcCalledTimes = 2);
	{**
	 * ...unregister again.
	 *}
	TNULLManager.UnregisterSingletonOnDemandProc;
	TSLEEPManager.UnregisterSingletonOnDemandProc;
	CheckHasDemandProc(FALSE);
end;

procedure TTestThreadPool.StressAddOwnerTaskTest(OwnersCount, TasksPerOwnerCount,
	ConcurrentWorkers:Integer);
var
	cc, ccc:Integer;
	Owner:TObject;
	TasksCompleteEventHandler:TAnonymousNotifyEvent;
	CompleteOwners:TBits;
	SleepTask:TSLEEPTask;
	NullTask:TNULLTask;

	function GetTasksCompleteEventHandler(Owner:TObject):TAnonymousNotifyEvent;
	begin
		Result:=procedure(Sender:TObject)
		begin
			CompleteOwners[Integer(Owner) - 1]:=TRUE;
		end;
	end;
begin
	CompleteOwners:=TBits.Create;
	CompleteOwners.Size:=OwnersCount;

	TNULLManager.Singleton.ConcurrentWorkersCount:=ConcurrentWorkers;
	TSLEEPManager.Singleton.ConcurrentWorkersCount:=ConcurrentWorkers;

	for cc:=0 to OwnersCount - 1 do
	begin
		Owner:=TObject(cc + 1);
		TasksCompleteEventHandler:=GetTasksCompleteEventHandler(Owner);
		TNULLManager.Singleton.RegisterOwner(Owner, nil, TasksCompleteEventHandler);
		TSLEEPManager.Singleton.RegisterOwner(Owner, nil, TasksCompleteEventHandler);

		for ccc:=0 to TasksPerOwnerCount - 1 do
		begin
			SleepTask:=TSLEEPTask.Create(Owner);
			NullTask:=TNULLTask.Create(Owner);
			SleepTask.SleepDuration:=20;

			TNULLManager.Singleton.AddTask(NullTask);
			TSLEEPManager.Singleton.AddTask(SleepTask);
		end;
	end;

	while CompleteOwners.OpenBit < OwnersCount do
		Application.HandleMessage;

	Check(TRUE);

	CompleteOwners.Free;
end;

procedure TTestThreadPool.StressAddOwnerTask_40Owner_1000Tasks_16Worker;
begin
	StressAddOwnerTaskTest(40, 1000, 16);
end;

procedure TTestThreadPool.StressAddOwnerTask_30Owner_1000Tasks_8Worker;
begin
	StressAddOwnerTaskTest(30, 1000, 8);
end;

procedure TTestThreadPool.StressAddOwnerTask_20Owner_1000Tasks_4Worker;
begin
	StressAddOwnerTaskTest(20, 1000, 4);
end;

procedure TTestThreadPool.StressAddOwnerTask_10Owner_1000Tasks_2Worker;
begin
	StressAddOwnerTaskTest(10, 1000, 2);
end;

procedure TTestThreadPool.StressAddTaskTest(TasksCount, ConcurrentWorkers:Integer);
var
	SleepTask:TSLEEPTask;
	NullTask:TNULLTask;
	SleepTasksDone, NullTasksDone:Integer;
	DoneProc:TAnonymousNotifyEvent;
	cc:Integer;
begin
	SleepTasksDone:=0;
	NullTasksDone:=0;

	DoneProc:=procedure(Sender:TObject)
	begin
		if Sender is TSLEEPTask then
			Inc(SleepTasksDone)
		else if Sender is TNULLTask then
			Inc(NullTasksDone);
	end;

	TNULLManager.Singleton.ConcurrentWorkersCount:=ConcurrentWorkers;
	TSLEEPManager.Singleton.ConcurrentWorkersCount:=ConcurrentWorkers;

	NullTask:=TNULLTask.Create(nil);
	NullTask.OnDone:=DoneProc;
	for cc:=0 to TasksCount - 1 do
	begin
		TNULLManager.Singleton.AddTask(NullTask);
		NullTask:=TNULLTask(NullTask.Clone);
	end;

	SleepTask:=TSLEEPTask.Create(nil);
	SleepTask.OnDone:=DoneProc;
	for cc:=0 to TasksCount - 1 do
	begin
		TSLEEPManager.Singleton.AddTask(SleepTask);
		SleepTask:=TSLEEPTask(SleepTask.Clone);
		SleepTask.SleepDuration:=10;
	end;

	while not ((SleepTasksDone = TasksCount) and (NullTasksDone = TasksCount)) do
		Application.HandleMessage;

	Check(TRUE);
end;

procedure TTestThreadPool.StressAddTask_1000Tasks_2Workers;
begin
	StressAddTaskTest(1000, 2);
end;

procedure TTestThreadPool.StressAddTask_1000Tasks_4Workers;
begin
	StressAddTaskTest(1000, 4);
end;

procedure TTestThreadPool.StressAddTask_1000Tasks_8Workers;
begin
	StressAddTaskTest(1000, 8);
end;

procedure TTestThreadPool.StressAddTask_1000Tasks_16Workers;
begin
	StressAddTaskTest(1000, 16);
end;

procedure TTestThreadPool.StressAddTask_10000Tasks_2Workers;
begin
	StressAddTaskTest(10000, 2);
end;

procedure TTestThreadPool.StressAddTask_10000Tasks_4Workers;
begin
	StressAddTaskTest(10000, 4);
end;

procedure TTestThreadPool.StressAddTask_10000Tasks_8Workers;
begin
	StressAddTaskTest(10000, 8);
end;

procedure TTestThreadPool.StressAddTask_10000Tasks_16Workers;
begin
	StressAddTaskTest(10000, 16);
end;

procedure TTestThreadPool.Singleton;

	procedure CheckHasSingleton;
	begin
		CheckFalse(TNULLManager.HasSingleton);
		CheckFalse(TSLEEPManager.HasSingleton);
	end;

begin
	{**
	 * As we start, there shouldn't be any single instances
	 *}
	CheckHasSingleton;
	{**
	 * Check consistency of Singleton
	 *}
	Check(TNULLManager.Singleton <> nil);
	Check(TNULLManager.Singleton = TNULLManager.Singleton);
	Check(TSLEEPManager.Singleton <> nil);
	Check(TSLEEPManager.Singleton = TSLEEPManager.Singleton);
	{**
	 * Check for correct mapping of the class and the single instance
	 *}
	Check(Integer(TNULLManager.Singleton) <> Integer(TSLEEPManager.Singleton));
	{**
	 * Terminate the single instances
	 *}
	TNULLManager.Singleton.Terminate;
	TSLEEPManager.Singleton.Terminate;
	TPoolManager.TerminateSingletonInstances;

	CheckHasSingleton;
end;


procedure TTestThreadPool.TasksCountByOwner;
const
	OwnersCount = 10;
	TasksCount = 69;
var
	cc, ccc:Integer;
	SleepTask:TSLEEPTask;
	NullTask:TNULLTask;
	Owner:TObject;
begin
	TNULLManager.Singleton.ConcurrentWorkersCount:=0;
	TSLEEPManager.Singleton.ConcurrentWorkersCount:=0;

	for cc:=1 to OwnersCount do
	begin
		Owner:=TObject(cc);
		for ccc:=1 to TasksCount do
		begin
			SleepTask:=TSLEEPTask.Create(Owner);
			NullTask:=TNULLTask.Create(Owner);
			TSLEEPManager.Singleton.AddTask(SleepTask);
			TNULLManager.Singleton.AddTask(NullTask);
		end;
	end;

	for cc:=1 to OwnersCount do
	begin
		Owner:=TObject(cc);

		repeat
			Sleep(10);
		until (TSLEEPManager.Singleton.TasksCountByOwner(Owner) = TasksCount) and
			(TNULLManager.Singleton.TasksCountByOwner(Owner) = TasksCount);

		TSLEEPManager.Singleton.CancelTasksByOwner(Owner);
		TNULLManager.Singleton.CancelTasksByOwner(Owner);

		repeat
			Sleep(10);
		until (TSLEEPManager.Singleton.TasksCountByOwner(Owner) = 0) and
			(TNULLManager.Singleton.TasksCountByOwner(Owner) = 0);
	end;
	{**
	 * Through the async working way of threads, there is nothing to check, but if it's arrived here
	 * the test is passed, otherwise it never reach this point.
	 *}
	Check(TRUE);
end;

procedure TTestThreadPool.TearDown;
begin
	TPoolManager.TerminateSingletonInstances;
end;

procedure TTestThreadPool.ValidatePerCPUWorkersCount;
begin
	TNULLManager.Singleton.ConcurrentWorkersCountPerCPU:=1;
	Check(TNULLManager.Singleton.ConcurrentWorkersCount = System.CPUCount);

	TNULLManager.Singleton.ConcurrentWorkersCountPerCPU:=2;
	Check(TNULLManager.Singleton.ConcurrentWorkersCount = (System.CPUCount * 2));

	TNULLManager.Singleton.ConcurrentWorkersCountPerCPU:=8;
	Check(TNULLManager.Singleton.ConcurrentWorkersCount = (System.CPUCount * 8));

	TNULLManager.Singleton.ConcurrentWorkersCountPerCPU:=0;
	Check(TNULLManager.Singleton.ConcurrentWorkersCount = 2);

	TNULLManager.Singleton.SpareWorkersCountPerCPU:=1;
	Check(TNULLManager.Singleton.SpareWorkersCount = System.CPUCount);

	TNULLManager.Singleton.SpareWorkersCountPerCPU:=2;
	Check(TNULLManager.Singleton.SpareWorkersCount = (System.CPUCount * 2));

	TNULLManager.Singleton.SpareWorkersCountPerCPU:=8;
	Check(TNULLManager.Singleton.SpareWorkersCount = (System.CPUCount * 8));

	TNULLManager.Singleton.SpareWorkersCountPerCPU:=0;
	Check(TNULLManager.Singleton.SpareWorkersCount = 2);
end;

{** TNULLManager **}

class function TNULLManager.Singleton:TNULLManager;
begin
	Result:=TNULLManager(inherited Singleton);
end;

class function TNULLManager.WorkerClass:TPoolWorkerClass;
begin
	Result:=TNULLWorker;
end;

{** TNULLWorker **}

procedure TNULLWorker.ExecuteTask;
begin
	DoneTask(TRUE);
end;

{** TSLEEPManager **}

class function TSLEEPManager.Singleton:TSLEEPManager;
begin
	Result:=TSLEEPManager(inherited Singleton);
end;

class function TSLEEPManager.WorkerClass:TPoolWorkerClass;
begin
	Result:=TSLEEPWorker;
end;

{** TSLEEPWorker **}

procedure TSLEEPWorker.ExecuteTask;
begin
	Sleep(TSLEEPTask(ContextTask).SleepDuration);
	DoneTask(TRUE);
end;

initialization

RegisterTest(TTestThreadPool.Suite);

end.
