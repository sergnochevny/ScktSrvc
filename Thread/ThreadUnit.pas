unit ThreadUnit;

interface
uses
	Windows, Messages;

type

	TNotifyEvent = procedure(Sender: TObject) of object;
	TThreadMethod = procedure of object;
	TThreadPriority = (tpIdle, tpLowest, tpLower, tpNormal, tpHigher, tpHighest,
	tpTimeCritical);

	TMyThread = class
	private
	FHandle: THandle;
	FThreadID: THandle;
	FTerminated: Boolean;
	FSuspended: Boolean;
	FFreeOnTerminate: Boolean;
	FFinished: Boolean;
	FReturnValue: Integer;
	FOnTerminate: TNotifyEvent;
	procedure CallOnTerminate;
	function GetPriority: TThreadPriority;
	procedure SetPriority(Value: TThreadPriority);
	procedure SetSuspended(Value: Boolean);
	protected
	procedure DoTerminate; virtual;
	procedure Execute; virtual; abstract;
	property ReturnValue: Integer read FReturnValue write FReturnValue;
	property Terminated: Boolean read FTerminated;
	public
	constructor Create(CreateSuspended: Boolean);
	destructor Destroy; override;
	procedure Resume;
	procedure Suspend;
	procedure Terminate;
  procedure Synchronize(Method: TThreadMethod);
	function WaitFor: LongWord;
	property FreeOnTerminate: Boolean read FFreeOnTerminate write FFreeOnTerminate;
	property Handle: THandle read FHandle;
	property Priority: TThreadPriority read GetPriority write SetPriority;
	property Suspended: Boolean read FSuspended write SetSuspended;
	property ThreadID: THandle read FThreadID;
	property OnTerminate: TNotifyEvent read FOnTerminate write FOnTerminate;
	end;

var
  ThreadSyncCriticalSection: TRTLCriticalSection;

implementation

type
	PRaiseFrame = ^TRaiseFrame;
	TRaiseFrame = record
	NextRaise: PRaiseFrame;
	ExceptAddr: Pointer;
	ExceptObject: TObject;
	ExceptionRecord: PExceptionRecord;
	end;

function ThreadProc(Thread: TMyThread): Integer;
var
	FreeThread: Boolean;
begin
	try
	Thread.Execute;
	finally
	FreeThread := Thread.FFreeOnTerminate;
	Result := Thread.FReturnValue;
	Thread.FFinished := True;
	Thread.DoTerminate;
	if FreeThread then Thread.Free;
	EndThread(Result);
	end;
end;

constructor TMyThread.Create(CreateSuspended: Boolean);
var
	Flags: DWORD;
begin
	inherited Create;
	FSuspended := CreateSuspended;
	Flags := 0;
	if CreateSuspended then Flags := CREATE_SUSPENDED;
	FHandle := BeginThread(nil, 0, @ThreadProc, Pointer(Self), Flags, FThreadID);
end;

destructor TMyThread.Destroy;
begin
	if not FFinished and not Suspended then	begin
		Terminate;
		WaitFor;
	end;
	if FHandle <> 0 then CloseHandle(FHandle);
	inherited Destroy;
end;

procedure TMyThread.CallOnTerminate;
begin
	if Assigned(FOnTerminate) then FOnTerminate(Self);
end;

procedure TMyThread.DoTerminate;
begin
	CallOnTerminate;
end;

const
	Priorities: array [TThreadPriority] of Integer =
	 (THREAD_PRIORITY_IDLE, THREAD_PRIORITY_LOWEST, THREAD_PRIORITY_BELOW_NORMAL,
	THREAD_PRIORITY_NORMAL, THREAD_PRIORITY_ABOVE_NORMAL,
	THREAD_PRIORITY_HIGHEST, THREAD_PRIORITY_TIME_CRITICAL);

function TMyThread.GetPriority: TThreadPriority;
var
	P: Integer;
	I: TThreadPriority;
begin
	P := GetThreadPriority(FHandle);
	Result := tpNormal;
	for I := Low(TThreadPriority) to High(TThreadPriority) do
	if Priorities[I] = P then Result := I;
end;

procedure TMyThread.SetPriority(Value: TThreadPriority);
begin
	SetThreadPriority(FHandle, Priorities[Value]);
end;

procedure TMyThread.SetSuspended(Value: Boolean);
begin
	if Value <> FSuspended then
	if Value then Suspend
	else Resume;
end;

procedure TMyThread.Suspend;
begin
	FSuspended := True;
	SuspendThread(FHandle);
end;

procedure TMyThread.Resume;
begin
	if ResumeThread(FHandle) = 1 then FSuspended := False;
end;

procedure TMyThread.Terminate;
begin
	FTerminated := True;
end;

function TMyThread.WaitFor: LongWord;
var
	Msg: TMsg;
	H: THandle;
begin
	H := FHandle;
	if GetCurrentThreadID = MainThreadID then begin
		PeekMessage(msg, 0, WM_USER, WM_USER, PM_NOREMOVE);
		while True do begin
			case MsgWaitForMultipleObjects(1, H, False, INFINITE, QS_ALLINPUT) of
				WAIT_OBJECT_0 + 1:
					while PeekMessage(Msg, 0, 0, 0, PM_REMOVE) do
						DispatchMessage(Msg);
				WAIT_OBJECT_0: begin
					while PeekMessage(Msg, 0, 0, 0, PM_REMOVE) do
						DispatchMessage(Msg);
					break;
				end;
			end;
		end;
	end
	else WaitForSingleObject(H, INFINITE);
	GetExitCodeThread(H, Result);
end;

procedure TMyThread.Synchronize(Method: TThreadMethod);
begin
  EnterCriticalSection(ThreadSyncCriticalSection);
  try
	  Method;
  finally
    LeaveCriticalSection(ThreadSyncCriticalSection);
  end;
  Sleep(0);
end;

initialization
  InitializeCriticalSection(ThreadSyncCriticalSection);

finalization
  DeleteCriticalSection(ThreadSyncCriticalSection);

end.
