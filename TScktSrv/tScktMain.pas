
{*******************************************************}
{                                                       }
{       Borland Delphi Visual Component Library         }
{       Borland Socket Server source code               }
{                                                       }
{       Copyright (c) 1997,99 Inprise Corporation       }
{                                                       }
{*******************************************************}

unit tScktMain;

interface

uses
	Windows, Messages, SysUtils, Classes,
	SyncObjs, vScktComp, vSconnect;

resourcestring
  Err_RefusConnect        = 'Access refused.';

type
	TCustomServiceApplication = class
	protected
		FLock: TCriticalSection;
	public
		constructor Create;
		destructor Destroy; override;
	end;

	TSocketDispatcher = class(TServerSocket)
	private
    FPermits: TStrings;
		FRegisteredOnly: Boolean;
		FTimeout: Integer;
		procedure GetThread(Sender: TObject; ClientSocket: TServerClientWinSocket;
			var SocketThread: TServerClientThread);
	public
		constructor Create(AOwner: TComponent); override;
		property RegisteredOnly: Boolean read FRegisteredOnly write FRegisteredOnly;
		property Timeout: Integer read FTimeout write FTimeout;
    property Permits: TStrings read FPermits write FPermits;
	end;

	{TServerDataBlockInterpreter}

	TSocketDispatcherThread = class;

	TServerDataBlockInterpreter = class(TDataBlockInterpreter)
	private
		FClientSocket: TServerClientWinSocket;
		FSocketDispatcherThread: TSocketDispatcherThread;
    FIsCmd: Boolean;    
	protected
		function CreateObject(const Name: string): OleVariant; override;
		procedure DoFreeControlObject(const Data: IDataBlock);
		function CreateControlObject(const Name: string): OleVariant;
		function InternalCreateControlObject(const ClassID: TGUID): OleVariant;
		procedure DoCreateControlObject(const Data: IDataBlock);
		function StoreObject(const Value: OleVariant): Integer; override;
	public
		constructor Create(SendDataBlock: ISendDataBlock; CheckRegValue: string;
											 ASocket: TServerClientWinSocket = nil);
		procedure InterpretData(const Data: IDataBlock);
		property SocketDispatcherThread: TSocketDispatcherThread read FSocketDispatcherThread write FSocketDispatcherThread;
	end;

{ TSocketDispatcherThread }

	TSocketDispatcherThread = class(TServerClientThread, ISendDataBlock)
	private
		FRefCount: Integer;
		FSocketDispatcher: TSocketDispatcher;
		FInterpreter: TServerDataBlockInterpreter;
		FTransport: ITransport;
		FLastActivity: TDateTime;
		FTimeConnect: TDateTime;
		FTimeout: TDateTime;
		FRegisteredOnly: Boolean;
    FObjIdx: Integer;
	protected
		function CreateServerTransport: ITransport; virtual;
		{ IUnknown }
		function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
		function _AddRef: Integer; stdcall;
		function _Release: Integer; stdcall;
		{ ISendDataBlock }
		function Send(const Data: IDataBlock; WaitForResult: Boolean): IDataBlock; stdcall;
    procedure PrepareDataForEvent(const Socket, Mask: Integer; const Data: IDataBlock);
    procedure ReActivate(ASocket: TServerClientWinSocket); override;
	public
		constructor Create(CreateSuspended: Boolean; ASocket: TServerClientWinSocket;
			                 Timeout: Integer; RegisteredOnly: Boolean;
                       ASocketDispatcher: TSocketDispatcher);
		procedure ClientExecute; override;
//    procedure ReleaseMyObj;
		property LastActivity: TDateTime read FLastActivity;
		property TimeConnect: TDateTime read FTimeConnect;
    property Transport: ITransport read FTransport;
	published
		property SocketDispatcher: TSocketDispatcher read FSocketDispatcher write FSocketDispatcher;
	end;

implementation

uses
  ActiveX, MidConst, ScktSrvCfg, ComObj, TScktSrv_TLB, VisualConnect, WinSock;

constructor TSocketDispatcherThread.Create(CreateSuspended: Boolean;
	ASocket: TServerClientWinSocket; Timeout: Integer; RegisteredOnly: Boolean;
  ASocketDispatcher: TSocketDispatcher);
begin
  FObjIdx := -1;
	FTimeout := EncodeTime(Timeout div 60, Timeout mod 60, 0, 0);
	FLastActivity := Now;
	FRegisteredOnly := RegisteredOnly;
  FInterpreter := nil;
	FSocketDispatcher := ASocketDispatcher;
	inherited Create(CreateSuspended, ASocket);
end;

function TSocketDispatcherThread.CreateServerTransport: ITransport;
var
	SocketTransport: TSocketTransport;
begin
	SocketTransport := TSocketTransport.Create;
	SocketTransport.Socket := ClientSocket;
	Result := SocketTransport as ITransport;
  FTimeConnect := Now;
end;

{ TSocketDispatcherThread.IUnknown }

function TSocketDispatcherThread.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
	if GetInterface(IID, Obj) then Result := 0 else Result := E_NOINTERFACE;
end;

function TSocketDispatcherThread._AddRef: Integer;
begin
	Inc(FRefCount);
	Result := FRefCount;
end;

function TSocketDispatcherThread._Release: Integer;
begin
	Dec(FRefCount);
	Result := FRefCount;
end;

{ TSocketDispatcherThread.ISendDataBlock }

function TSocketDispatcherThread.Send(const Data: IDataBlock; WaitForResult: Boolean): IDataBlock;
begin
	FTransport.Send(Data);
	if WaitForResult then
		while True do
		begin
      Result := FTransport.Receive(True, 0);
      if Result = nil then break;
      if (Result.Signature and ResultSig) = ResultSig then
        break else
        FInterpreter.InterpretData(Result);
		end;
end;

procedure TSocketDispatcherThread.ClientExecute;
var
	Data: IDataBlock;
	msg: TMsg;
	Obj: ISendDataBlock;
	Event: THandle;
	WaitTime: DWord;
  ReceiveSuccess: Boolean;
	wsNetEvents: WSANETWORKEVENTS;
begin
	CoInitialize(nil);
	try
		FTransport := CreateServerTransport;
		try
      Event := FTransport.GetWaitEvent;
      PeekMessage(msg, 0, WM_USER, WM_USER, PM_NOREMOVE);
      GetInterface(ISendDataBlock, Obj);
      if FRegisteredOnly then
        FInterpreter := TServerDataBlockInterpreter.Create(Obj, SSockets, ClientSocket) 
      else
        FInterpreter := TServerDataBlockInterpreter.Create(Obj, '', ClientSocket);
      FInterpreter.SocketDispatcherThread := Self;
      try
        Obj := nil;
        if FTimeout = 0 then
          WaitTime := INFINITE else
          WaitTime := 60000;
        while not Terminated and FTransport.Connected do
        try
          case MsgWaitForMultipleObjects(1, Event, False, WaitTime, QS_ALLEVENTS) of
            WAIT_OBJECT_0 + 1:
              while PeekMessage(msg, 0, 0, 0, PM_REMOVE) do begin
                FLastActivity := Now;
                if (msg.hwnd = 0) then
                  case msg.message of
                    THREAD_SENDSTREAM: begin
                      with FInterpreter do begin
                        if Assigned(Data)then Data.Clear
                        else  Data := TDataBlock.Create as IDataBlock;
                        PrepareDataForEvent(msg.lParam, msg.wParam, Data);
                        FSendDataBlock.Send(Data, False);
                      end;
                      Data := nil;
                    end;
                    THREAD_BREAK:	FTransport.Connected := False;
                  else DispatchMessage(msg);
                  end
                else DispatchMessage(msg);
              end;
            WAIT_OBJECT_0: 
              begin
                WSAEnumNetworkEvents(ClientSocket.SocketHandle, Event, @wsNetEvents);
                if (wsNetEvents.lNetworkEvents = FD_CLOSE)then begin
                  WSAResetEvent(Event);
                  FTransport.Connected := False;
                end else 
                begin
                  WSAResetEvent(Event);
                  try
                    Data := FTransport.Receive(False, 0);
                    ReceiveSuccess := True;
                  except
                    on E: ESocketConnectionError do begin
                      with FInterpreter do begin
                        if Assigned(Data)then Data.Clear
                        else  Data := TDataBlock.Create as IDataBlock;
                        WriteVariant(NULL, Data);
                        Data.Signature := ResultSig or asErrorSocket;
                        try
                          if not ((wsNetEvents.lNetworkEvents and FD_CLOSE)= FD_CLOSE)then 
                            FSendDataBlock.Send(Data, False);
                        except
                        end;
                      end;
                      Data := nil;
                      ReceiveSuccess := False;
                    end;
                  else
                    raise;
                  end;
                  if Assigned(Data) and ReceiveSuccess then
                  begin
                    FLastActivity := Now;
                    FInterpreter.InterpretData(Data);
                    Data := nil;
                    FLastActivity := Now;
                  end;
                end;
              end;
            WAIT_TIMEOUT:
            begin
              while PeekMessage(msg, 0, 0, 0, PM_REMOVE) do
                DispatchMessage(msg);
              if (ServerSocket.ListControlConnections.IndexOf(ClientSocket)=-1) and
                 (FTimeout > 0) and ((Now - FLastActivity) > FTimeout) then FTransport.Connected := False;
            end;
          end;
        except
          HandleException;
          FTransport.Connected := False;
        end;
      finally
        if FInterpreter <> nil then
          FInterpreter.Free;
        FInterpreter := nil;
        if FClientSocket <> nil then
          FClientSocket.Free;
        FClientSocket:=nil;
      end;
		finally
			FTransport := nil;
		end;
	finally
		CoUninitialize;
    Terminate;
	end;
end;

//procedure TSocketDispatcherThread.ReleaseMyObj;
//var
//  P: IDispatch;
//begin
//  if FObjIdx > -1 then
//    if Assigned(FInterpreter) then begin
//      P := FInterpreter.LockObject(FObjIdx);
//      IUnknown(P)._Release;
//      FInterpreter.ReleaseObject(FObjIdx);
//    end;
//end;

procedure TSocketDispatcherThread.PrepareDataForEvent(const Socket, Mask: Integer; const Data: IDataBlock);
var
  Result: OleVariant;
begin
  case (Mask and asHiMask) of
    asNotifyAddClient: Result := GetConnectInfo(TServerClientWinSocket(Socket));
    asNotifyRemoveClient: Result := Socket;
    asNotifyHost: Result := GetConnectInfo(TServerClientWinSocket(Socket));
  end;
  FInterpreter.WriteVariant(Integer(Mask and asHiMask), Data);
  FInterpreter.WriteVariant(Result, Data);
  Data.Signature := CallSig or (Mask and asLoMask);
end;

procedure TSocketDispatcherThread.ReActivate(ASocket: TServerClientWinSocket);
var
  alive: tcp_keepalive;
  nSize: DWORD;
begin
  inherited ReActivate(ASocket);
 	alive.onoff := 1;
	alive.keepalivetime := 10000; // <- время между посылками keep-alive (мс)
	alive.keepaliveinterval := 1000;// <- время между посылками при отсутсвии ответа
  WSAIoctl(ASocket.SocketHandle, SIO_KEEPALIVE_VALS, Pointer(@alive), SizeOf(alive),
			     nil, 0, @nSize, nil, nil);  
end;

{ TSocketDispatcher }

constructor TSocketDispatcher.Create(AOwner: TComponent);
begin
	inherited Create(AOwner);
	FRegisteredOnly:=True;
	ServerType := stThreadBlocking;
	OnGetThread := GetThread;
end;

procedure TSocketDispatcher.GetThread(Sender: TObject;
	ClientSocket: TServerClientWinSocket;
	var SocketThread: TServerClientThread);
begin
	SocketThread := TSocketDispatcherThread.Create(False, ClientSocket,
		 Timeout, RegisteredOnly, Self);
end;

{ TServerDataBlockInterpreter }

function TServerDataBlockInterpreter.CreateObject(
  const Name: string): OleVariant;
begin

  if WaitForSingleObject(FAcceptEvent,0)<>WAIT_OBJECT_0 then begin
 		if ((FSocketDispatcherThread.SocketDispatcher.Permits.IndexOf(FClientSocket.RemoteAddress)=-1) and
      (FSocketDispatcherThread.SocketDispatcher.Permits.IndexOf(UpperCase(FClientSocket.RemoteHost))=-1)) then
      raise Exception.CreateRes(@Err_RefusConnect);
  end;
      
  Result := inherited CreateObject(Name);
  FSocketDispatcherThread.ServerSocket.AddClient(FClientSocket);
  if FSocketDispatcherThread.ServerSocket.ASyncStyles <> [] then begin
    FClientSocket.DoSetAsyncStyles;
    if FClientSocket.Connected then
      FClientSocket.Event(FClientSocket, seConnect);
  end
  else
    if FClientSocket.Connected then
      FSocketDispatcherThread.ServerSocket.Event(FClientSocket, seConnect);
end;

function TServerDataBlockInterpreter.InternalCreateControlObject(const ClassID: TGUID): OleVariant;
var
	typelib: ITypeLib;
begin
  OleCheck(LoadRegTypeLib(LIBID_TScktSrv, 1, 0, 0, typelib));
  Result := TServer.Create(typelib, ClassID, FIsCmd) as IDispatch;
end;

function TServerDataBlockInterpreter.CreateControlObject(
	const Name: string): OleVariant;
var
	ClassID: TGUID;
begin
	if (Name[1] = '{') and (Name[Length(Name)] = '}') then
		ClassID := StringToGUID(Name) else
		ClassID := ProgIDToClassID(Name);
	if CanCreateObject(ClassID) then begin
		Result := InternalCreateControlObject(ClassID);
		FSocketDispatcherThread.ServerSocket.AddClient(FClientSocket, True);
    if FIsCmd then
      if FSocketDispatcherThread.ServerSocket.ASyncStyles <> [] then begin
        FClientSocket.DoSetAsyncStyles;
        if FClientSocket.Connected then
          FClientSocket.IsCmd := FIsCmd;
//          FClientSocket.Event(FClientSocket, seNotify);
      end
      else
        if FClientSocket.Connected then
//          FSocketDispatcherThread.ServerSocket.Event(FClientSocket, seNotify);
          FSocketDispatcherThread.ClientSocket.IsCmd := FIsCmd;
	end
  else
    raise Exception.CreateResFmt(@SObjectNotAvailable, [GuidToString(ClassID)]);
end;

procedure TServerDataBlockInterpreter.DoCreateControlObject(const Data: IDataBlock);
var
	V: OleVariant;
	VarFlags: TVarFlags;
	I: Integer;
begin
	V := CreateControlObject(ReadVariant(VarFlags, Data));
	Data.Clear;
	I := TVarData(V).VType;
	if (I and varTypeMask) = varInteger then
	begin
		I := varDispatch;
		Data.Write(I, SizeOf(Integer));
		I := V;
		Data.Write(I, SizeOf(Integer));
	end else
		WriteVariant(V, Data);
	Data.Signature := ResultSig or asCreateControlObject;
	FSendDataBlock.Send(Data, False);
end;

procedure TServerDataBlockInterpreter.DoFreeControlObject(const Data: IDataBlock);
var
	VarFlags: TVarFlags;
  ID: Integer;
begin
	try
    ID := ReadVariant(VarFlags, Data);
		ReleaseObject(ID);
	except
		{ Don't return any exceptions }
	end;
end;

procedure TServerDataBlockInterpreter.InterpretData(const Data: IDataBlock);
var
	Action: Integer;
begin
	Action := Data.Signature;
	if (Action and asMask) = asError then DoException(Data);
	try
		case (Action and asMask) of
			asInvoke: DoInvoke(Data);
			asGetID: DoGetIDsOfNames(Data);
			asCreateObject:	DoCreateObject(Data);
			asFreeObject:	DoFreeObject(Data);
			asGetServers: DoGetServerList(Data);
			asGetAppServers: DoGetAppServerList(Data);
			asCreateControlObject: begin
	      if (Action and asCmd) = asCmd then FIsCmd := True;
        DoCreateControlObject(Data)
      end;
			asFreeControlObject: DoFreeControlObject(Data);
			else
				if not DoCustomAction(Action and asMask, Data) then
					raise EInterpreterError.CreateResFmt(@SInvalidAction, [Action and asMask]);
		end;
	except
		on E: Exception do begin
			Data.Clear;
			WriteVariant(E.Message, Data);
			Data.Signature := ResultSig or asError;
			FSendDataBlock.Send(Data, False);
		end;
	end;
end;

constructor TServerDataBlockInterpreter.Create(SendDataBlock: ISendDataBlock; CheckRegValue: string;
																								ASocket: TServerClientWinSocket);
begin
	inherited Create(SendDataBlock, CheckRegValue);
	FClientSocket := ASocket;
	FSocketDispatcherThread := nil;
  FIsCmd := False;
end;

function TServerDataBlockInterpreter.StoreObject(
  const Value: OleVariant): Integer;
begin
  Result := inherited StoreObject(Value);
  SocketDispatcherThread.FObjIdx := Result;
end;

{ TCustomServiceApplication }

constructor TCustomServiceApplication.Create;
begin
	inherited Create;
	FLock := TCriticalSection.Create;
end;

destructor TCustomServiceApplication.Destroy;
begin
	FLock.Free;
	inherited;
end;

end.



