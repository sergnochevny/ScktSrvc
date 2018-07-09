unit tServiceMain;

interface
uses
	Windows, Classes, SysUtils, SyncObjs, 
	vSvcMgr, tScktMain, ScktSrvCfg, vScktComp, HostNameList;

type

	TServiceApplication = class(TCustomServiceApplication)
	protected
		FShowHost,
    FCloseToken,
		FRegisteredOnly: Boolean;
		function GetDisplayName: String;
		function GetServiceName: String;
		procedure BeforeStartService(Sender: TConsoleService; var Started: Boolean);
		procedure StartService(Sender: TConsoleService; var Started: Boolean);
		procedure StopService(Sender: TConsoleService; var Stopped: Boolean);
		procedure OpenSockets;
		procedure CloseSockets;
		property ServiceName: string read GetServiceName;
	private
    FHostNameList: THostNameList;
		ConsoleService: TConsoleService;
		FItems:	TStrings;
		FItemsPermit: TStrings;
	public
    procedure ClientConnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure ClientDisconnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure ClientNotify(Sender: TObject; Socket: TCustomWinSocket);
    procedure ClientShowHost(Sender: TObject; Socket: TCustomWinSocket);
		constructor Create;
		destructor Destroy; override;
		procedure ShowException(E: Exception; EvType: DWORD = EVENTLOG_ERROR_TYPE);
		procedure HandleException(Sender: TObject);
		procedure Initialize;
		procedure Run;
    function HostName(const IPAddress: WideString;
                      ClientSocket: TServerClientWinSocket): String;
		function AddPort(SetPort: Integer): Pointer;
		property Items: TStrings read FItems;
		property ItemsPermit: TStrings read FItemsPermit;
	end;

var
	Application: TServiceApplication = nil;

implementation
uses
	vSconnect, MidConst, VisualConnect, Messages;

{ TServiceApplication }

procedure TServiceApplication.BeforeStartService(Sender: TConsoleService;
	var Started: Boolean);
begin
	Started := True;
	Sender.Interactive:= False;
end;

constructor TServiceApplication.Create;
begin
	inherited Create;
	ConsoleService := TConsoleService.Create;
	FItems := TStringList.Create;
  FItemsPermit := TStringList.Create;
  FHostNameList := THostNameList.Create(Self);
  FCloseToken := False;
end;

function TServiceApplication.HostName(const IPAddress: WideString;
                                      ClientSocket: TServerClientWinSocket): String;
begin
  Result := '';
  try
    Result := FHostNameList.GetHostName(IPAddress, Integer(ClientSocket));
  except
    HandleException(Self);
  end;
end;

destructor TServiceApplication.Destroy;
begin
	ConsoleService.Free;
	ConsoleService:=nil;
  FHostNameList.Free;
	FItems.Free;
  FItemsPermit.Free;
	inherited;
end;

function TServiceApplication.GetDisplayName: String;
begin
	Result := trmScktSrvCfg.DisplayName;
end;

function TServiceApplication.GetServiceName: String;
begin
	Result := trmScktSrvCfg.ServiceName;
end;

procedure TServiceApplication.ClientConnect(Sender: TObject;
  Socket: TCustomWinSocket);
var
	k, i, j, CountCl:	Integer;
begin
{$ifndef s_pending}    
  if FCloseToken then Exit;
{$endif}    
	FLock.Enter;
  try
    try
      CountCl:=0; i := 0;
		  while i < FItems.Count do begin
			  Inc(CountCl, TSocketDispatcher(FItems.Objects[i]).Socket.ActiveControlConnections);
        Inc(i);
      end;
		  i := 0; k := 0;
		  while (i < FItems.Count) and (k < CountCl) do begin
			  j := 0;
			  while ((j < TSocketDispatcher(FItems.Objects[i]).Socket.ActiveControlConnections) and (k < CountCl)) do begin
          PostThreadMessage(TServerClientWinSocket(TSocketDispatcher(FItems.Objects[i]).Socket.ControlConnections[j]).ServerClientThread.ThreadID,
                            THREAD_SENDSTREAM,
                            Integer(asNotify or asNotifyAddClient),
                            Integer(Socket));
          inc(k);
          inc(j);
        end;
		    inc(i);
		  end;
    except
      HandleException(Self);
    end;
  finally
	  FLock.Leave;
  end;
end;

procedure TServiceApplication.ClientDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
var
	k, i, j, CountCl:	Integer;
begin
{$ifndef s_pending}    
  if FCloseToken then Exit;
{$endif}    
	FLock.Enter;
  try
    try
      CountCl:=0; i := 0;
		  while i < FItems.Count do begin
			  Inc(CountCl, TSocketDispatcher(FItems.Objects[i]).Socket.ActiveControlConnections);
        Inc(i);
      end;
		  i := 0; k := 0;
		  while (i < FItems.Count) and (k < CountCl) do begin
			  j := 0;
			  while ((j < TSocketDispatcher(FItems.Objects[i]).Socket.ActiveControlConnections) and (k < CountCl)) do begin
          PostThreadMessage(TServerClientWinSocket(TSocketDispatcher(FItems.Objects[i]).Socket.ControlConnections[j]).ServerClientThread.ThreadID,
                            THREAD_SENDSTREAM,
                            Integer(asNotify or asNotifyRemoveClient),
                            Integer(Socket));
          inc(k); inc(j);
        end;
		    inc(i);
		  end;
    except
      HandleException(Self);
    end;
  finally
	  FLock.Leave;
  end;
end;

procedure TServiceApplication.ClientNotify(Sender: TObject;
  Socket: TCustomWinSocket);
var
	k, i, j, CountCl:	Integer;
begin
{$ifndef s_pending}    
  if FCloseToken then Exit;
{$endif}    
	FLock.Enter;
  try
    try
      CountCl:=0; i := 0;
		  while i < FItems.Count do begin
			  Inc(CountCl, TSocketDispatcher(FItems.Objects[i]).Socket.ActiveControlConnections);
        Inc(i);
      end;
		  i := 0; k := 0;
		  while (i < FItems.Count) and (k < CountCl) do begin
			  j := 0;
			  while ((j < TSocketDispatcher(FItems.Objects[i]).Socket.ActiveControlConnections) and (k < CountCl)) do begin
          if Socket.Connected then
            if (Socket.SocketHandle <> TServerClientWinSocket(TSocketDispatcher(FItems.Objects[i]).Socket.ControlConnections[j]).SocketHandle) then
              PostThreadMessage(TServerClientWinSocket(TSocketDispatcher(FItems.Objects[i]).Socket.ControlConnections[j]).ServerClientThread.ThreadID,
                                THREAD_SENDSTREAM,
                                Integer(asNotify or asNotifyGenAction),
                                Integer(Socket));
          inc(k); inc(j);
        end;
		    inc(i);
		  end;
    except
      HandleException(Self);
    end;
  finally
	  FLock.Leave;
  end;
end;

procedure TServiceApplication.ClientShowHost(Sender: TObject;
  Socket: TCustomWinSocket);
var
	k, i, j, CountCl:	Integer;
begin
{$ifndef s_pending}    
  if FCloseToken then Exit;
{$endif}    
	FLock.Enter;
  try
    try
      CountCl:=0; i := 0;
		  while i < FItems.Count do begin
			  Inc(CountCl, TSocketDispatcher(FItems.Objects[i]).Socket.ActiveControlConnections);
        Inc(i);
      end;
		  i := 0; k := 0;
		  while (i < FItems.Count) and (k < CountCl) do begin
			  j := 0;
			  while ((j < TSocketDispatcher(FItems.Objects[i]).Socket.ActiveControlConnections) and (k < CountCl)) do begin
          if Socket.Connected then
            PostThreadMessage(TServerClientWinSocket(TSocketDispatcher(FItems.Objects[i]).Socket.ControlConnections[j]).ServerClientThread.ThreadID,
                              THREAD_SENDSTREAM,
                              Integer(asNotify or asNotifyHost),
                              Integer(Socket));
          inc(k); inc(j);
        end;
		    inc(i);
		  end;
    except
      HandleException(Self);
    end;
  finally
	  FLock.Leave;
  end;
end;

procedure TServiceApplication.Initialize;
begin
	if InitProc <> nil then TProcedure(InitProc);
	with ConsoleService do begin
		OnBeforeStart := BeforeStartService;
		OnStart := StartService;
		OnStop := StopService;
		DisplayName := GetDisplayName;
		ServiceStartName := GetServiceName;
		Interactive:= False;
		AllowPause := False;
		WaitHint := 5000;
		TagID := 0;
	end;
end;

procedure TServiceApplication.OpenSockets;
var
	pCnt, i: integer;

	procedure InitPort(const PortNo, Timeout: integer);
	var
		SH: TSocketDispatcher;
	begin
		SH := TSocketDispatcher.Create(nil);
		SH.RegisteredOnly:=FRegisteredOnly;
		SH.Port:=PortNo;
		SH.Timeout:=Timeout;
    SH.OnClientNotify := ClientNotify;
    SH.OnClientConnect := ClientConnect;
    SH.OnClientDisconnect := ClientDisconnect;
    SH.Permits := ItemsPermit;
		FItems.AddObject(IntToStr(SH.Port), SH);
		try
			SH.Open;
		except
			on E: Exception do
				raise Exception.CreateFmt(SOpenError, [SH.Port, E.Message]);
		end;
	end;
begin
{$ifndef s_pending}    
  if FCloseToken then Exit;
{$endif}    
	FLock.Enter;
  try
    try
	    ConsoleService.DisplayName := trmScktSrvCfg.DisplayName;
	    ConsoleService.ServiceStartName := trmScktSrvCfg.ServiceName;
	    pCnt:=trmScktSrvCfg.PortCount;
	    FShowHost :=trmScktSrvCfg.ShowHost;
	    FRegisteredOnly := trmScktSrvCfg.RegisteredOnly;
	    for i:=0 to pCnt-1 do
		    InitPort(trmScktSrvCfg.PortsToListen[i].PortNo,
						 trmScktSrvCfg.PortsToListen[i].TimeOut);
    except
      Application.HandleException(Self);
    end;
  finally
	  FLock.Leave;
  end;
end;

procedure TServiceApplication.Run;
begin
  try
	  ConsoleService.Run;
  except
    HandleException(Self);
  end;
end;

procedure TServiceApplication.StartService(Sender: TConsoleService;
	var Started: Boolean);
begin
	Started := True;
	if not LoadWinSock2 then raise Exception.Create(SNoWinSock2);
	OpenSockets;
end;

procedure TServiceApplication.StopService(Sender: TConsoleService;
	var Stopped: Boolean);
begin
	Stopped := True;
  CloseSockets;
end;

procedure TServiceApplication.CloseSockets;
var
	i: Integer;
begin
  try
    FCloseToken := True;
    FLock.Enter;
    try
      for i := 0 to FItems.Count - 1 do begin
        try
          while TSocketDispatcher(FItems.Objects[i]).Socket.ActiveControlConnections > 0 do
            with TSocketDispatcherThread(TServerClientWinSocket(TSocketDispatcher(
               FItems.Objects[i]).Socket.ListControlConnections.Last).ServerClientThread) do begin
              FreeOnTerminate := False;
              Terminate;
              PlayEvent.SetEvent;
              if (ClientSocket <> nil) and ClientSocket.Connected then
                ClientSocket.Close;
              PostThreadMessage(ThreadID, WM_USER, 0, 0);
              WaitFor;
              Free;
            end;
        except
          Application.HandleException(Self);
        end;
      end;
    finally
      FLock.Leave;
    end;
    Sleep(0);
    FLock.Enter;
    try
      for i := 0 to FItems.Count - 1 do begin
        try
          TSocketDispatcher(FItems.Objects[i]).Close;
          FItems.Objects[i].Free;
        except
          Application.HandleException(Self);
        end;
      end;
    finally
      FLock.Leave;
    end;
  except
    Application.HandleException(Self);
  end;
end;

function TServiceApplication.AddPort(SetPort: Integer): Pointer;
var
	SH: TSocketDispatcher;
begin
{$ifndef s_pending}    
  if FCloseToken then Exit;
{$endif}    
	FLock.Enter;
	SH := TSocketDispatcher.Create(nil);
	SH.RegisteredOnly:=FRegisteredOnly;
	SH.Port:=SetPort;
  SH.OnClientNotify := ClientNotify;
  SH.OnClientConnect := ClientConnect;
  SH.OnClientDisconnect := ClientDisconnect;
  SH.Permits := ItemsPermit;
	FItems.AddObject(IntToStr(SH.Port), SH);
	Result := Pointer(SH);
  try
    SH.Open;
  except
    on E: Exception do
      raise Exception.CreateFmt(SOpenError, [SH.Port, E.Message]);
  end;
	FLock.Leave;
end;

procedure TServiceApplication.HandleException(Sender: TObject);
begin
	if ExceptObject is Exception then begin
		if not (ExceptObject is EAbort) then
				ShowException(Exception(ExceptObject));
	end else
		SysUtils.ShowException(ExceptObject, ExceptAddr);
end;

procedure TServiceApplication.ShowException(E: Exception; EvType: DWORD = EVENTLOG_ERROR_TYPE);
var
	Msg: string;
begin
	Msg := E.Message;
	if (Msg <> '') and (AnsiLastChar(Msg) > '.') then Msg := Msg + '.';
	if ConsoleService.Interactive then
		MessageBox(0, PChar(Msg), PChar(ServiceName), MB_OK + MB_ICONSTOP)
	else
		ConsoleService.LogMessage(Msg, EvType, 0, 0);
end;

procedure NewExceptProc(ExceptObject: TObject; ExceptAddr: Pointer); far;
begin
	if ExceptObject is Exception then begin
		if not (ExceptObject is EAbort) then
				Application.ShowException(Exception(ExceptObject));
	end else
		SysUtils.ShowException(ExceptObject, ExceptAddr);
end;

procedure InitApplication;
begin
	Application := TServiceApplication.Create;
  ExceptProc := @NewExceptProc;
end;

procedure DoneApplication;
begin
	Application.Free;
	Application := nil;
end;

initialization
	InitApplication;

finalization
	DoneApplication;

end.
