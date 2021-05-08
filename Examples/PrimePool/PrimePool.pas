unit PrimePool;

interface

uses
	SysUtils, Classes, Generics.Collections, SyncObjs, ThreadPool, Types;

type

	TPrimeTask = class(TPoolTask)
	{**
	 * Input related
	 *}
	protected
		FFromNumber:Cardinal;
		FToNumber:Cardinal;
	{**
	 * Output related
	 *}
	protected
		FPrimesOutput:TCardinalDynArray;

		procedure AddPrime(Prime:Cardinal);
	{**
	 * Overriden stuff
	 *}
	protected
		procedure Assign(Source:TPoolTask); override;
		function IsTheSame(Compare:TPoolTask):Boolean; override;
	{**
	 * Public input
	 *}
	public
		property FromNumber:Cardinal read FFromNumber write FFromNumber;
		property ToNumber:Cardinal read FToNumber write FToNumber;
	{**
	 * Public output
	 *}
	public
		property PrimesOutput:TCardinalDynArray read FPrimesOutput;
	end;

	TPrimeWorker = class(TPoolWorker)
	protected
		procedure ExecuteTask; override;
	end;

	TPrimeManager = class(TPoolManager)
	protected
		class function WorkerClass:TPoolWorkerClass; override;
	public
		class function Singleton:TPrimeManager; reintroduce;
	end;

implementation

{** TPrimeTask **}

procedure TPrimeTask.AddPrime(Prime:Cardinal);
var
	InsertIndex:Integer;
begin
	InsertIndex:=Length(FPrimesOutput);
	SetLength(FPrimesOutput, InsertIndex + 1);
	FPrimesOutput[InsertIndex]:=Prime;
end;

{**
 * Assign only data which is required for do the job (no calculated data)
 *}
procedure TPrimeTask.Assign(Source:TPoolTask);
var
	PT:TPrimeTask;
begin
	inherited Assign(Source);
	PT:=TPrimeTask(Source);
	FromNumber:=PT.FromNumber;
	ToNumber:=PT.ToNumber;
end;

function TPrimeTask.IsTheSame(Compare:TPoolTask):Boolean;
var
	PT:TPrimeTask;
begin
	Result:=Compare is TPrimeTask;
	if not Result then
		Exit;
	PT:=TPrimeTask(Compare);
	Result:=(PT.FromNumber = FromNumber) and (PT.ToNumber = ToNumber);
end;

{** TPrimeWorker **}

procedure TPrimeWorker.ExecuteTask;
var
	cc:Cardinal;
	{**
	 * Local representation of the property Task, because it's expensive to get it often.
	 *}
	Task:TPrimeTask;

	function IsPrime(Test:Cardinal):Boolean;
	var
		h:Cardinal;
	begin
		Result:=Test > 1;
		if not Result then
			Exit;
		for h:=2 to Trunc(Test/2) do
			if Test mod h = 0 then
			begin
				Result:=FALSE;
				Exit;
			end;
	end;
begin
	Task:=TPrimeTask(ContextTask);
	cc:=Task.FromNumber;
	while not Canceled and (cc < Task.ToNumber) do
	begin
		if IsPrime(cc) then
			Task.AddPrime(cc);
		Inc(cc);
	end;

	DoneTask(TRUE);
end;

{** TPrimeManager **}

class function TPrimeManager.Singleton:TPrimeManager;
begin
	Result:=TPrimeManager(inherited Singleton);
end;

class function TPrimeManager.WorkerClass:TPoolWorkerClass;
begin
	Result:=TPrimeWorker;
end;


end.

