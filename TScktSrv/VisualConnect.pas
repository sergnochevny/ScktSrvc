unit VisualConnect;

interface

uses
	tServiceMain, ScktSrvCfg, Classes, vScktComp,
	ComObj, ActiveX, TScktSrv_TLB, Windows, SyncObjs, StdVcl;

type
	TServer = class(TAutoIntfObject, IServer)
	private
    FIsCmd: Boolean;
		FCallBack:	OleVariant;
    FSuspAccpt: Boolean;
	protected
    function Get_RegisteredOnly: WordBool; safecall;
    procedure Set_RegisteredOnly(Value: WordBool); safecall;  
  
    function Get_IsWinNT: WordBool; safecall;
    function Get_ProcessAffMask: Integer; safecall;
    function Get_ShowHost: WordBool; safecall;
    function Get_SysAffMask: Integer; safecall;
    function GetAccepting: WordBool; safecall;
    function GetClientsInfo: OleVariant; safecall;
    function GetPermits: OleVariant; safecall;
    function GetPortListData: OleVariant; safecall;
    function AddPort(SetPort: Integer): Integer; safecall;
    function ModifyPort(Dat, SetPort, LocalPort, SetTimeout: Integer): WordBool; safecall;
    function RemovePort(Dat, LocalPort: Integer): WordBool; safecall;
    function SuspendAccepting: WordBool; safecall;
    procedure AddPermit(const Value: WideString); safecall;
    procedure GetPortList; safecall;
    procedure GetPortParams(Dat: Integer; var Port, TimeOut: Integer); safecall;
    procedure RemoveConnect(P: OleVariant); safecall;
    procedure RemovePermit(Idx: Integer); safecall;
    procedure Set_CPUAffinity(Value: Integer); safecall;
    procedure Set_ShowHost(Value: WordBool); safecall;
    function AddPermit_GetData(const Obj: WideString): OleVariant; safecall;
	public
    procedure SetCallBack(aCallBack: OleVariant); safecall;
    constructor Create(const TypeLib: ITypeLib; const DispIntf: TGUID; const IsCmd: Boolean = False);
//		constructor Create(const TypeLib: ITypeLib; const DispIntf: TGUID);
		destructor Destroy; override;
	end;

function GetConnectInfo(Socket: TServerClientWinSocket): OleVariant;

var
	FLock: TCriticalSection;
  FMutex: Cardinal;
	FAcceptEvent: Cardinal;

implementation

uses ComServ, tScktMain, Sysutils, WinSock, MidConst;

const
  THREAD_BREAK            = $0402;

resourcestring  
  Err_RepeatedControl      = 'The administrator utility is already connected.';

procedure TServer.SetCallBack(aCallBack: OleVariant);
begin
  FCallBack := aCallBack;
end;

function TServer.ModifyPort(Dat, SetPort, LocalPort, SetTimeout: Integer): WordBool;
var
	OldPortNo: integer;
begin
	FLock.Enter;
	Result := False;
	try
		with TSocketDispatcher(Dat) do begin
      try
			  OldPortNo:=TSocketDispatcher(Dat).Port;
        if (SetPort<>OldPortNo) and (Application.Items.IndexOf(IntToStr(SetPort))>-1) then Exit;
			  if TSocketDispatcher(Dat).Port<>LocalPort then begin
				  if Socket.ActiveConnections > 0 then
	          if (IDispatch(FCallback) <> nil) then
					    if not FCallback.GetClosePermission then Exit;
				  Close;
				  Port := SetPort;
				  Timeout := SetTimeout;
				  try
					  Open;
				  except
					  on E: Exception do
						  raise Exception.CreateFmt(SOpenError, [Port, E.Message]);
				  end;
				  Result := True;
			  end
			  else
	        if (IDispatch(FCallback) <> nil) then
				    FCallback.WarningMessage;
      except
        Application.HandleException(Self);
        Result := False;
      end;
    end;
		if SetPort<>OldPortNo then
			trmScktSrvCfg.RemovePort(OldPortNo);
		trmScktSrvCfg.AddPortToListen(SetPort,{SetThreadCashe,}SetTimeout);
		trmScktSrvCfg.WritePortsSettings;
	finally
		FLock.Leave;
	end;
end;

procedure TServer.RemoveConnect(P: OleVariant);
var 
  i: Integer;
begin
  if VarIsArray(P) then begin
		FLock.Enter;
		try
			try
        for i:=0 to VarArrayHighBound(P,1) do
          if Pointer(Pointer(Integer(P[i]))^)=Pointer(TServerClientWinSocket) then begin
            TServerClientWinSocket(Integer(P[i])).NoSendDisconnEvent := True;
            TServerClientWinSocket(Integer(P[i])).Close;
            TSocketDispatcherThread(TServerClientWinSocket(Integer(P[i])).ServerClientThread).Terminate;
            PostThreadMessage(TSocketDispatcherThread(TServerClientWinSocket(Integer(P[i])).ServerClientThread).ThreadID, THREAD_BREAK, 0, 0);
          end;
			except
				Application.HandleException(Self);
			end;
		finally
			FLock.Leave;
		end;
	end;
end;

procedure TServer.GetPortParams(Dat: Integer; var Port, TimeOut: Integer);
begin
  try
    Port := TSocketDispatcher(Dat).Port;
    TimeOut := TSocketDispatcher(Dat).Timeout;
  except
    Application.HandleException(Self);
  end;
end;

procedure TServer.GetPortList;
var
	i: Integer;
begin
  try
      for i:=0 to Application.Items.Count-1 do begin
        if (IDispatch(FCallback) <> nil) then
          FCallback.SetPortItem(TSocketDispatcher(Application.Items.Objects[i]).Port,
                                Integer(Application.Items.Objects[i]));
      end;
  except
    Application.HandleException(Self);
  end;
end;

function TServer.AddPort(SetPort: Integer): Integer;
var
  Idx,
	Dat: Integer;
begin
  Dat := 0;
  try
    Idx := Application.Items.IndexOf(IntToStr(SetPort));
    if (Idx=-1) then begin
	    Dat := Integer(Application.AddPort(SetPort));
	    trmScktSrvCfg.AddPortToListen(TSocketDispatcher(Dat).Port,
																TSocketDispatcher(Dat).Timeout);
	    trmScktSrvCfg.WritePortsSettings;
    end
    else Dat:=Integer(Application.Items.Objects[Idx]);
  except
    Application.HandleException(Self);
    Dat := 0;
  end;
  Result := Dat;
end;

function TServer.RemovePort(Dat, LocalPort: Integer): WordBool;
var
	OldPortNo: integer;
begin
	FLock.Enter;
	Result := False;
	try
    try
      if Application.Items.IndexOfObject(TObject(Dat))>-1then begin
        with TSocketDispatcher(Dat) do
        begin
          OldPortNo:=TSocketDispatcher(Dat).Port;
          if TSocketDispatcher(Dat).Port<>LocalPort then begin
            if Socket.ActiveConnections > 0 then
              if (IDispatch(FCallback) <> nil) then
                if not FCallback.GetClosePermission then Exit;
            TSocketDispatcher(Application.Items.Objects[Application.Items.IndexOfObject(TObject(Dat))]).Close;
            Application.Items.Objects[Application.Items.IndexOfObject(TObject(Dat))].Free;
            Application.Items.Delete(Application.Items.IndexOfObject(TObject(Dat)));
            Result := True;
          end
          else
            if (IDispatch(FCallback) <> nil) then
              FCallback.WarningMessage;
        end;
        trmScktSrvCfg.RemovePort(OldPortNo);
        trmScktSrvCfg.WritePortsSettings;
      end
      else Result := True;
    except
      Application.HandleException(Self);
      Result := False;
    end;
	finally
		FLock.Leave;
	end;
end;

var
  OldInitProc: Pointer = nil;

procedure EnableSocketTransport(const ClassID: string);
begin
  CreateRegKey(SClsid + ClassID, SSockets, SFlagOn);
end;

procedure DeleteRegValue(const Key, ValueName: string);
var
  Handle: HKey;
  Status: Integer;
begin
  Status := RegOpenKey(HKEY_CLASSES_ROOT, PChar(Key), Handle);
  if Status = 0 then
    RegDeleteValue(Handle, PChar(ValueName));
end;

procedure DisableSocketTransport(const ClassID: string);
begin
  DeleteRegValue(SClsid + ClassID, SSockets);
end;

procedure NewInitProc;
var
  Description,
  ClassID: String;
begin
  if OldInitProc <> nil then TProcedure(OldInitProc);
  ClassID := GUIDTOString(IID_IServer);
  if ComServer.StartMode <> smUnregServer then begin
    EnableSocketTransport(ClassID);
    Description := GetRegStringValue('CLSID\' + ClassID, '');
    CreateRegKey('AppID\' + ClassID, '', Description);
    CreateRegKey('CLSID\' + ClassID, 'AppID', ClassID);
  end
  else begin
    DisableSocketTransport(ClassID);
    DeleteRegKey('CLSID\' + ClassID);
    DeleteRegKey('AppID\' + ClassID);
  end;
  if ComServer.StartMode in [smRegServer, smUnregServer] then Halt;
end;

function TServer.GetClientsInfo: OleVariant;
var
	k, i, j, CountCl:	Integer;
	HostName: String;
begin
  Result := varNull;
	FLock.Enter;
  try
    try
      CountCl:=0;
		  i := 0;
		  while i < Application.Items.Count do begin
			  Inc(CountCl, TSocketDispatcher(Application.Items.Objects[i]).Socket.ActiveConnections);
        Inc(i);
      end;
      if CountCl>0 then
        Result := VarArrayCreate([0,CountCl,0,5], varVariant);
		  i := 0; k := 0;
		  while (i < Application.Items.Count) and (k < CountCl) do begin
			  j := 0;
			  while ((j < TSocketDispatcher(Application.Items.Objects[i]).Socket.ActiveConnections) and (k < CountCl)) do begin
				  if trmScktSrvCfg.ShowHost then begin
            HostName := Application.HostName(TServerClientWinSocket(TSocketDispatcher(
																	Application.Items.Objects[i]).Socket.Connections[j]).RemoteAddress,
                                  TServerClientWinSocket(TSocketDispatcher(
                                  Application.Items.Objects[i]).Socket.Connections[j]));
				  end
				  else HostName := SNotShown;
          try
            Result[k,0]:= TServerClientWinSocket(TSocketDispatcher(Application.Items.Objects[i]).Socket.Connections[j]).LocalPort;
          except Result[k,0]:=0; end;
          try
				    Result[k,1]:= TServerClientWinSocket(TSocketDispatcher(Application.Items.Objects[i]).Socket.Connections[j]).RemoteAddress;
          except Result[k,1]:='...'; end;
          try
            Result[k,2]:= TSocketDispatcherThread(TServerClientWinSocket(TSocketDispatcher(Application.Items.Objects[i]).Socket.Connections[j]).ServerClientThread).TimeConnect;
          except Result[k,2]:=0; end;
          try
            Result[k,3]:= TSocketDispatcherThread(TServerClientWinSocket(TSocketDispatcher(Application.Items.Objects[i]).Socket.Connections[j]).ServerClientThread).LastActivity;
          except Result[k,3]:=0; end;
          try
            Result[k,4]:= Integer(TServerClientWinSocket(TSocketDispatcher(Application.Items.Objects[i]).Socket.Connections[j]));
          except Result[k,4]:=0; end;
          try
            Result[k,5]:= HostName;
          except Result[k,5]:='...'; end;
          inc(k); inc(j);
        end;
		    inc(i);
		  end;
    except
      Application.HandleException(Self);
      Result := varNull;
    end;
  finally
		FLock.Leave;
	end;
end;

procedure RemoveConnect(P: Integer);
begin
	try
		if Pointer(Pointer(P)^)=Pointer(TServerClientWinSocket) then begin
			TServerClientWinSocket(P).Close;
			with TServerClientThread(TServerClientWinSocket(P).ServerClientThread) do begin
				PostThreadMessage(ThreadID, THREAD_BREAK, 0, 0);
				Terminate;
			end;
		end;
	except
		Application.HandleException(nil);
	end;
end;

function GetConnectInfo(Socket: TServerClientWinSocket): OleVariant;
var
	HostName: String;
begin
	Result := varNull;
	try
    if not assigned(Socket) then exit;
    if Socket.LocalPort <= 0 then begin
      RemoveConnect(Integer(Socket));
      Exit;
    end;
		Result := VarArrayCreate([0,5], varVariant);
		if trmScktSrvCfg.ShowHost then begin
			HostName := Application.HostName(Socket.RemoteAddress, Socket);
		end
		else HostName := SNotShown;
		try Result[0]:= Socket.LocalPort;
		except Result[0]:=0; end;
		try Result[1]:= Socket.RemoteAddress;
		except Result[1]:='...'; end;
		try Result[3]:= Now;
		except Result[3]:=0; end;
		try Result[2]:= Result[3];
		except Result[2]:=0; end;
		try Result[4]:= Integer(Socket);
		except Result[4]:=0; end;
		try Result[5]:= HostName;
		except Result[5]:='...'; end;
	except
		Application.HandleException(nil);
	end;
end;

constructor TServer.Create(const TypeLib: ITypeLib; const DispIntf: TGUID; const IsCmd: Boolean = False);
begin
  FSuspAccpt:=False;
  FIsCmd := IsCmd;
  if (IsCmd or (Boolean(FMutex) and (WaitForSingleObject(FMutex,0)=WAIT_OBJECT_0))) then
    inherited Create(TypeLib, DispIntf)
  else
    raise Exception.Create(Err_RepeatedControl);
end;

destructor TServer.Destroy;
begin
  FCallBack := varNull;
  inherited;
  if Boolean(FMutex) then ReleaseMutex(FMutex);
end;

function TServer.SuspendAccepting: WordBool;
begin
  FSuspAccpt := GetAccepting;
  if not FSuspAccpt then
    ResetEvent(FAcceptEvent)
  else
    SetEvent(FAcceptEvent);
  FSuspAccpt := GetAccepting;
  Result := FSuspAccpt;
end;

function TServer.GetAccepting: WordBool;
begin
  Result := False;
  if WaitForSingleObject(FAcceptEvent,0)=WAIT_TIMEOUT then Result := True;
end;

procedure TServer.AddPermit(const Value: WideString);
var
  Index: Integer;
begin
	FLock.Enter;
  try
    if Application.ItemsPermit.IndexOf(Value) = -1 then begin
      Index := Application.ItemsPermit.AddObject(Value, TObject(Pointer(Application.ItemsPermit.Count)));
      try
        if (IDispatch(FCallback) <> nil) then
          FCallback.AddPermit(Application.ItemsPermit[Index], Index);
      except
        Application.HandleException(Self);
      end;
    end;
  finally
		FLock.Leave;
	end;
end;

procedure TServer.RemovePermit(Idx: Integer);
var
  Index: Integer;
begin
	FLock.Enter;
  try
    try
      Index := Application.ItemsPermit.IndexOfObject(TObject(Pointer(Idx)));
      if Index <> -1 then Application.ItemsPermit.Delete(Index);
    except
      Application.HandleException(Self);
    end;
  finally
		FLock.Leave;
	end;
end;

function TServer.GetPermits: OleVariant;
var
  i: Integer;
begin
  Result := varNull;
//  if (IDispatch(FCallback) <> nil) then begin
    FLock.Enter;
    try
      try
        if Application.ItemsPermit.Count > 0 then begin
          Result := VarArrayCreate([0,Application.ItemsPermit.Count,0,1], varVariant);
          for i := 0 to Application.ItemsPermit.Count - 1 do begin
            try
              Result[i,0]:= String(Application.ItemsPermit[i]);
            except Result[i,0]:='0.0.0.0'; end;
            try
              Result[i,1]:= i;
            except Result[i,0]:=0; end;
          end;
        end
      except
        Application.HandleException(Self);
        Result := varNull;
      end;
    finally
      FLock.Leave;
    end;
//  end;
end;

function TServer.GetPortListData: OleVariant;
var
  i: Integer;
begin
  Result := varNull;
  FLock.Enter;
  try
    try
      if Application.Items.Count > 0 then begin
        Result := VarArrayCreate([0,Application.Items.Count,0,1], varVariant);
        for i := 0 to Application.Items.Count - 1 do begin
          Result[i,0]:= Integer(TSocketDispatcher(Application.Items.Objects[i]).Port);
          Result[i,1]:= Integer(Application.Items.Objects[i])
        end;
      end
    except
      Application.HandleException(Self);
      Result := varNull;
    end;
  finally
    FLock.Leave;
  end;
end;

function TServer.Get_ShowHost: WordBool;
begin
  Result := trmScktSrvCfg.ShowHost;
end;

function TServer.Get_IsWinNT: WordBool;
begin
	Result := WordBool(trmScktSrvCfg.IsWinNT);
end;

function TServer.Get_ProcessAffMask: Integer;
begin
	Result := Integer(trmScktSrvCfg.ProcessAffMask);
end;

function TServer.Get_RegisteredOnly: WordBool;
begin
	Result := trmScktSrvCfg.RegisteredOnly;
end;

function TServer.Get_SysAffMask: Integer;
begin
	Result := Integer(trmScktSrvCfg.SysAffMask);
end;

procedure TServer.Set_ShowHost(Value: WordBool);
begin
	trmScktSrvCfg.ShowHost := Value;
end;

procedure TServer.Set_CPUAffinity(Value: Integer);
begin
  trmScktSrvCfg.CPUAffinity := Cardinal(Value);
end;

procedure TServer.Set_RegisteredOnly(Value: WordBool);
begin
	trmScktSrvCfg.RegisteredOnly := Value;
end;

function TServer.AddPermit_GetData(const Obj: WideString): OleVariant;
var
  Index: Integer;
begin
	FLock.Enter;
  try
    if Application.ItemsPermit.IndexOf(Obj) = -1 then begin
      Index := Application.ItemsPermit.AddObject(Obj, TObject(Pointer(Application.ItemsPermit.Count)));
      try
     		Result := VarArrayCreate([0,1], varVariant);
        Result[0] := Application.ItemsPermit[Index];
        Result[1] := Index;
      except
        Application.HandleException(Self);
      end;
    end;
  finally
		FLock.Leave;
	end;
end;

initialization
  FAcceptEvent := CreateEvent(nil,true,true,nil);
	FLock := TCriticalSection.Create;
  FMutex := CreateMutex(nil, false, nil);
  ComServer.LoadTypeLib;
  OldInitProc := InitProc;
  InitProc := @NewInitProc;
  
finalization
  if Boolean(FMutex) then begin
    if WaitForSingleObject(FMutex,0)=WAIT_TIMEOUT then
      ReleaseMutex(FMutex);
    CloseHandle(FMutex);
  end;
  if Boolean(FAcceptEvent) then begin
    if WaitForSingleObject(FAcceptEvent,0)=WAIT_TIMEOUT then
      ResetEvent(FAcceptEvent);
    CloseHandle(FAcceptEvent);
  end;
  FLock.Free;

end.
