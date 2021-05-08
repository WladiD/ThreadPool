
// HTTPThreadPool is a ready to use thread pool for any amount of HTTP requests
//
// By the way, it is a example for a implementation of a specialized thread pool through deriving
// from classes served by ThreadPool.
//
// HTTPThreadPool is licensed under the same conditions as the unit ThreadPool.pas
//
// The Original Code is HTTPThreadPool.pas
//
// The Initial Developer of the Original Code is Waldemar Derr.
// Portions created by Waldemar Derr are Copyright (C) 2010 Waldemar Derr.
// All Rights Reserved.
//
// @author Waldemar Derr <furevest@gmail.com>

unit HTTPThreadPool;

interface

uses
  System.SysUtils,
  System.Classes,
  System.ZLib,

  IdComponent,
  IdHTTPHeaderInfo,
  IdHTTP,

  ThreadPool;

type
  TProgressEvent = reference to procedure(Sender: TObject; Progress, MaxProgress: Int64);
  THTTPClientEvent = reference to procedure(Sender: TObject; HTTPClient: TIdHTTP);

  THTTPTask = class(TPoolTask)
  // Input fields
  protected
    FURL: string;
    FPostData: TStream;
    FTag: Integer;

  // Output fields & methods
  //
  // Not considered by the Assign method
  protected
    FResponseData: TStream;
    FResponseCode: Integer;
    FOnUploadStatus: TProgressEvent;
    FOnDownloadStatus: TProgressEvent;
    FOnConfigHTTPClient: THTTPClientEvent;

    function GetResponseData: TStream;
    function GetResponseSize: Integer;

  // Overriden protected methods
  protected
    procedure Assign(Source: TPoolTask); override;
    function IsTheSame(Compare: TPoolTask): Boolean; override;

  // Overriden public methods
  public
    destructor Destroy; override;

  // Input properties & events
  public
    property URL: string read FURL write FURL;
    property PostData: TStream read FPostData write FPostData;
    property Tag: Integer read FTag write FTag;
    property Priority;

    property OnUploadStatus: TProgressEvent read FOnUploadStatus write FOnUploadStatus;
    property OnDownloadStatus: TProgressEvent read FOnDownloadStatus write FOnDownloadStatus;
    property OnConfigHTTPClient: THTTPClientEvent read FOnConfigHTTPClient
      write FOnConfigHTTPClient;

  // Output properties (Read only)
  public
    property ResponseData:TStream read GetResponseData;
    property ResponseCode:Integer read FResponseCode;
    property ResponseSize:Integer read GetResponseSize;
  end;

  THTTPWorker = class(TPoolWorker)
  private
    FHTTPClient: TIdHTTP;
    FUploadMaxCount: Int64;
    FDownloadMaxCount: Int64;

    procedure IndyWorkBegin(Sender: TObject; WorkMode: TWorkMode; WorkCountMax: Int64);
    procedure IndyWork(Sender: TObject; WorkMode: TWorkMode; WorkCount: Int64);
    procedure IndyWorkEnd(Sender: TObject; WorkMode: TWorkMode);
  protected
    procedure FireUploadStatusEvent(Progress: Int64);
    procedure FireDownloadStatusEvent(Progress: Int64);

    function GetContextTask: THTTPTask;
    procedure ExecuteTask; override;
    procedure RequestSuccessful; virtual;
    procedure RequestFailed; virtual;

    property HTTPClient: TIdHTTP read FHTTPClient;
  public
    constructor Create(Owner: TPoolManager); override;
    destructor Destroy; override;
  end;

  THTTPManager = class(TPoolManager)
  type
    TNetAccessConfig = class
    public
      UserAgent: string;

      UseProxy: Boolean;
      ProxyServer: string;
      ProxyPort: Integer;

      ProxyRequireAuth: Boolean;
      ProxyUsername: string;
      ProxyPassword: string;

      ConnectTimeout: Integer;
    end;

  protected
    class function WorkerClass: TPoolWorkerClass; override;

  protected
    FNetAccessConfig: TNetAccessConfig;

    procedure ConfigHTTPClient(HTTPClient: TIdHTTP); virtual;
    function CreateWorker: TPoolWorker; override;
  public
    class function Singleton: THTTPManager; reintroduce;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure AddRequest(Owner: TObject; URL: string; PostData: TStream = nil;
      Priority: TTaskPriority = tpNormal; Tag: Integer = 0;
      OnDone: TAnonymousNotifyEvent = nil; OnConfigHTTPClient: THTTPClientEvent = nil;
      OnDownloadStatus: TProgressEvent = nil; OnUploadStatus: TProgressEvent = nil;
      OnStart: TAnonymousNotifyEvent = nil; OnCancel: TAnonymousNotifyEvent = nil);

    function RequestExists(URL: string):Boolean;
    function RequestsCountByOwner(Owner: TObject):Integer;

    property NetAccessConfig: TNetAccessConfig read FNetAccessConfig;
  end;

var
  // Shortcut for the statement "THTTPManager.Singleton"
  //
  // You save 11 bytes of pascal code on each call ;)
  HTTPManager: function: THTTPManager;

implementation

function DefaultHTTPManager: THTTPManager;
begin
  Result := THTTPManager.Singleton;
end;

{ THTTPManager }

constructor THTTPManager.Create;
begin
  inherited Create;

  SortTasks := True;

  FNetAccessConfig := TNetAccessConfig.Create;
  FNetAccessConfig.UserAgent := 'Mozilla/4.0 (compatible;)';
  FNetAccessConfig.UseProxy := FALSE;
  FNetAccessConfig.ConnectTimeout := 5000;
end;

destructor THTTPManager.Destroy;
begin
  FNetAccessConfig.Free;

  inherited Destroy;
end;

function THTTPManager.RequestExists(URL: string): Boolean;
begin
  Result:=CustomTaskExists(
    function(Task: TPoolTask): Boolean
    begin
      Result := (Task is THTTPTask) and (THTTPTask(Task).URL = URL);
    end);
end;

function THTTPManager.RequestsCountByOwner(Owner: TObject): Integer;
begin
  Result := TasksCountByOwner(Owner);
end;

function THTTPManager.CreateWorker: TPoolWorker;
begin
  Result := inherited CreateWorker;
  ConfigHTTPClient(THTTPWorker(Result).HTTPClient);
end;

// Add a request as a task
//
// This method should be a shortcut for the creating of the task object.
//
// PostData - Optional. The passed stream is managed by the task and will be destroyed
//            automatically.
procedure THTTPManager.AddRequest(Owner: TObject; URL: string; PostData: TStream;
  Priority: TTaskPriority; Tag: Integer; OnDone: TAnonymousNotifyEvent;
  OnConfigHTTPClient: THTTPClientEvent; OnDownloadStatus, OnUploadStatus: TProgressEvent;
  OnStart, OnCancel: TAnonymousNotifyEvent);
var
  HTTPTask: THTTPTask;
begin
  HTTPTask := THTTPTask.Create(Owner);
  HTTPTask.URL := URL;
  HTTPTask.PostData := PostData;
  HTTPTask.Priority := Priority;
  HTTPTask.Tag := Tag;
  HTTPTask.OnDone := OnDone;
  HTTPTask.OnConfigHTTPClient := OnConfigHTTPClient;
  HTTPTask.OnDownloadStatus := OnDownloadStatus;
  HTTPTask.OnUploadStatus := OnUploadStatus;
  HTTPTask.OnStart := OnStart;
  HTTPTask.OnCancel := OnCancel;

  AddTask(HTTPTask);
end;

procedure THTTPManager.ConfigHTTPClient(HTTPClient: TIdHTTP);
var
  ProxyParams: TIdProxyConnectionInfo;
begin
  HTTPClient.HandleRedirects := True;
  HTTPClient.ConnectTimeout := NetAccessConfig.ConnectTimeout;

  if NetAccessConfig.UseProxy then
  begin
    ProxyParams := HTTPClient.ProxyParams;
    ProxyParams.ProxyServer := NetAccessConfig.ProxyServer;
    ProxyParams.ProxyPort := NetAccessConfig.ProxyPort;
    if NetAccessConfig.ProxyRequireAuth then
    begin
      ProxyParams.BasicAuthentication := True;
      ProxyParams.ProxyUsername := NetAccessConfig.ProxyUsername;
      ProxyParams.ProxyPassword := NetAccessConfig.ProxyPassword;
    end;
  end;
  HTTPClient.Request.UserAgent := NetAccessConfig.UserAgent;
end;

class function THTTPManager.Singleton: THTTPManager;
begin
  Result := THTTPManager(inherited Singleton);
end;

class function THTTPManager.WorkerClass: TPoolWorkerClass;
begin
  Result := THTTPWorker;
end;

{ THTTPTask }

destructor THTTPTask.Destroy;
begin
  FreeAndNil(FPostData);
  FreeAndNil(FResponseData);

  inherited Destroy;
end;

function THTTPTask.GetResponseData: TStream;
begin
  if not Assigned(FResponseData) then
    FResponseData := TMemoryStream.Create;
  Result := FResponseData;
end;

function THTTPTask.GetResponseSize: Integer;
begin
  if Assigned(FResponseData) then
    Result := FResponseData.Size
  else
    Result := 0;
end;

procedure THTTPTask.Assign(Source: TPoolTask);
var
  HTTPSource: THTTPTask;
begin
  inherited Assign(Source);

  HTTPSource := THTTPTask(Source);
  URL := HTTPSource.URL;
  if Assigned(PostData) then
    FreeAndNil(FPostData);
  if Assigned(HTTPSource.PostData) then
  begin
    PostData := TMemoryStream.Create;
    PostData.CopyFrom(HTTPSource.PostData, 0);
  end;
  Tag := HTTPSource.Tag;
  OnUploadStatus := HTTPSource.OnUploadStatus;
  OnDownloadStatus := HTTPSource.OnDownloadStatus;
  OnConfigHTTPClient := HTTPSource.OnConfigHTTPClient;
end;

function THTTPTask.IsTheSame(Compare: TPoolTask): Boolean;
var
  HTTPCompare: THTTPTask;
  BothHasPostData: Boolean;
  ByteIndex, CompareBlockLength: Integer;
  Source, Dest: PByte;
begin
  HTTPCompare := THTTPTask(Compare);

  // First (fast) compare
  Result:=(URL = HTTPCompare.URL) and (Tag = HTTPCompare.Tag);
  if not Result then
    Exit;

  // Second (fast) compare
  BothHasPostData := Assigned(PostData) and Assigned(HTTPCompare.PostData) and
    (PostData.Size = HTTPCompare.PostData.Size);
  Result := BothHasPostData or (not Assigned(PostData) and not Assigned(HTTPCompare.PostData));
  if not BothHasPostData then
    Exit;

  // Third (slow) byte wise post stream compare
  if PostData.Size > 1024 then
    CompareBlockLength := 1024
  else
    CompareBlockLength := PostData.Size;

  GetMem(Source, CompareBlockLength);
  GetMem(Dest, CompareBlockLength);
  try
    PostData.Position := 0;
    HTTPCompare.PostData.Position := 0;

    repeat
      ByteIndex := PostData.Read(Pointer(Source)^, CompareBlockLength);
      if ByteIndex = 0 then
        Break;
      HTTPCompare.PostData.Read(Pointer(Dest)^, CompareBlockLength);
      while (ByteIndex > -1) and (Source[ByteIndex] = Dest[ByteIndex]) do
        Dec(ByteIndex);
      Result := ByteIndex < 0;
    until not Result;
  finally
    FreeMem(Source);
    FreeMem(Dest);
  end;
end;

{ THTTPWorker }

constructor THTTPWorker.Create(Owner: TPoolManager);
begin
  inherited Create(Owner);

  FHTTPClient := TIdHTTP.Create(nil);
  HTTPClient.OnWorkBegin := IndyWorkBegin;
  HTTPClient.OnWork := IndyWork;
  HTTPClient.OnWorkEnd := IndyWorkEnd;
end;

destructor THTTPWorker.Destroy;
begin
  FreeAndNil(FHTTPClient);

  inherited Destroy;
end;

function THTTPWorker.GetContextTask: THTTPTask;
begin
  Result := THTTPTask(inherited ContextTask);
end;

// Event handler for TIdHTTP.OnWorkBegin
procedure THTTPWorker.IndyWorkBegin(Sender: TObject; WorkMode: TWorkMode; WorkCountMax: Int64);
begin
  case WorkMode of
    wmRead:
      FDownloadMaxCount := WorkCountMax;
    wmWrite:
      FUploadMaxCount := WorkCountMax;
  end;
end;

// Event handler for TIdHTTP.OnWork
procedure THTTPWorker.IndyWork(Sender: TObject; WorkMode: TWorkMode; WorkCount: Int64);
begin
  if Canceled then
  begin
    HTTPClient.Disconnect;
    Exit;
  end;

  // Not fire here, if it's on 100%, because this is done in IndyWorkEnd too.
  case WorkMode of
    wmRead:
      if FDownloadMaxCount <> WorkCount then
        FireDownloadStatusEvent(WorkCount);
    wmWrite:
      if FUploadMaxCount <> WorkCount then
        FireUploadStatusEvent(WorkCount);
  end;
end;

// Event handler for TIdHTTP.OnWorkEnd
procedure THTTPWorker.IndyWorkEnd(Sender: TObject; WorkMode: TWorkMode);
begin
  if Canceled then
    Exit;
  case WorkMode of
    wmRead:
      FireDownloadStatusEvent(FDownloadMaxCount);
    wmWrite:
      FireUploadStatusEvent(FUploadMaxCount);
  end;
end;

procedure THTTPWorker.RequestFailed;
begin
  DoneTask(False);
end;

procedure THTTPWorker.RequestSuccessful;
begin
  DoneTask(True);
end;

// Remember: This method will be executed in a thread context
procedure THTTPWorker.ExecuteTask;
var
  Task: THTTPTask;
  TempStream: TMemoryStream;
  ContentEncoding: string;
  RequestSuccessful: Boolean;
begin
  Task := GetContextTask;

  // Fire the OnConfigHTTPClient event
  FireEvent(
    procedure(FireTask: TPoolTask)
    begin
      THTTPTask(FireTask).OnConfigHTTPClient(Task, HTTPClient);
    end,
    function(FireTask: TPoolTask): Boolean
    begin
      Result := Assigned(THTTPTask(FireTask).OnConfigHTTPClient);
    end);

  // Do a GET or POST call
  //
  // These are blocking operations, but the Cancel property is checked in the IndyWork method,
  // and if it's true, so it try to do a Disconnect prematurely.
  try
    if Assigned(Task.PostData) then
      HTTPClient.Post(Task.URL, Task.PostData, Task.ResponseData)
    else
      HTTPClient.Get(Task.URL, Task.ResponseData);

    Task.FResponseCode := HTTPClient.ResponseCode;
    RequestSuccessful := not Canceled;
  except
    RequestSuccessful := False;
  end;

  if RequestSuccessful then
  begin
    // Decompress
    ContentEncoding := LowerCase(HTTPClient.Response.ContentEncoding);
    if (ContentEncoding = 'gzip') or (ContentEncoding = 'deflate') then
    begin
      TempStream := TMemoryStream.Create;
      try
        Task.ResponseData.Position := 0;
        ZDecompressStream(Task.ResponseData, TempStream);

        TMemoryStream(Task.ResponseData).Clear;
        TempStream.Position := 0;
        TempStream.SaveToStream(Task.ResponseData);
      finally
        TempStream.Free;
      end;
    end;

    // Call the virtual method on success, for the ability, to do more in descendants
    Self.RequestSuccessful;
  end
  else
  begin
    FreeAndNil(Task.FResponseData);
    Self.RequestFailed;
  end;
end;

procedure THTTPWorker.FireDownloadStatusEvent(Progress: Int64);
var
  ContextTask: THTTPTask;
  MaxProgress: Int64;
begin
  if State <> wsBusy then
    Exit;
  ContextTask := GetContextTask;
  MaxProgress := FDownloadMaxCount;
  FireEvent(
    procedure(Task: TPoolTask)
    begin
      THTTPTask(Task).OnDownloadStatus(ContextTask, Progress, MaxProgress);
    end,
    function(Task: TPoolTask):Boolean
    begin
      Result := Assigned(THTTPTask(Task).OnDownloadStatus);
    end);
end;

procedure THTTPWorker.FireUploadStatusEvent(Progress: Int64);
var
  ContextTask: THTTPTask;
  MaxProgress: Int64;
begin
  if State <> wsBusy then
    Exit;
  ContextTask := GetContextTask;
  MaxProgress := FUploadMaxCount;
  FireEvent(
    procedure(Task: TPoolTask)
    begin
      THTTPTask(Task).OnUploadStatus(ContextTask, Progress, MaxProgress);
    end,
    function(Task: TPoolTask):Boolean
    begin
      Result := Assigned(THTTPTask(Task).OnUploadStatus);
    end);
end;

initialization
  HTTPManager := DefaultHTTPManager;

end.
