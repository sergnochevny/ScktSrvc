unit tScktCmd;

interface

uses
	Windows, Messages, SysUtils, Classes, ComObj,
	ControlConnection,	Db, DBClient;

resourcestring

  WrongIP = 'Invalid address IP.';
  WrongIPorPort = 'Invalid address IP or port value.';
  ErrorTCP = 'Error TCP/IP.';
  SNotRemovePort = 'This port will not be remote, because used.';
 
const
  Def_Ip = 'localhost';
  Def_Port = 211;
  
type

	TAdminCmd = class(TObject)
		ccGeneral: TControlConnection;
    ConnectionList: TStrings;
    lvPermit: TStrings;
    PortList: TStrings;
		procedure ModifyPortExecute(Port, Timeout: Integer);
		procedure DeletePortExecute(Port: Integer);
		function DropConnectExecute(Value: String): BOOL;
		function AddPortExecute(Port: Integer): BOOL;
		procedure GetConnectionsExecute;
		procedure ConnectedUpdate;
		procedure ConnectedExecute(ConnStr: String);
    procedure AcceptExecute(Value: Boolean);
    function DeletePermitExecute(Value: String):BOOL;
    function AddPermitExecute(Value: String):BOOL;
    procedure ParseIP_ConnectExecute(ConnStr: String);
	private
    FPort: Integer;
    FHost, FIPAddr: String;
    FAccptStop: Boolean;
		MyDispatchConnection: TControlDispatchConnection;
		FClosing: Boolean;
		FProgmanOpen: Boolean;
		FCurItem: Integer;

    FrfRslt: integer;
    FrfErrMsg: string;
    FStartDT: TDateTime;
    FStopDT: TDateTime;

//    FCfgRunFileName,
    FRsltFileName: string;

    FsHost, 
    FsPort, 
    FAddPort,
    FModifyPort,
    FDeletePort,
    FExclusWork,
    FSetPermit,
    FAddPermit,
    FDeletePermit,
    FDropconnect: String;

		procedure GetConnections;
		procedure GetPermits;
		procedure Connect;
		procedure Disconnect;

    procedure ReadCmdCfgFileName(var sFileName: string);
    procedure ReadConfig(sFileName: string; bSkipConnPrms: boolean);
    procedure WriteResult(bStop: boolean);
    procedure ReadCmdPrms;
    
	protected
		procedure InitSettings;
    procedure PortListUpdate;
	public
		constructor Create;
    procedure DoIt;
    destructor Destroy;   
	end;

function FindSwitch(const Switch: string): Boolean;

var
	trmAdminCmd: TAdminCmd;

const
  cCmdFileName = 'CfgFile';
  cCmdAddPort = 'AddPort';
  cCmdModifyPort = 'ModifyPort';
  cCmdDeletePort = 'DeletePort';
  cCmdExclusWork = 'ExclusWork';
  cCmdSetPermit = 'SetPermit';
  cCmdAddPermit = 'AddPermit';
  cCmdDeletePermit = 'DeletePermit';
  cCmdDropconnect = 'DropConnect';

  cCfgConnSection = 'Connection';
	cCfgHost   = 'Host';
  cCfgPort   = 'Port';
  
  cCfgParamSection = 'Parameters';
  cCfgRsltFileName = 'RsltFile';

  cCfgRsltSection = 'Result';
  cCfgRsltStartDT = 'StartDT';
  cCfgRsltStopDT  = 'StopDT';
  cCfgRsltResult  = 'Rslt';
  cCfgRsltMessage = 'ErrMsg';

implementation

uses ActiveX, MidConst, TSSAdminCfg, StrFunc, WinSock, StrUtils, Inifiles;

resourcestring

  ErrExclusWorkWrongPrm = 'Wrong value parameter. Valid values (''On'',''Off'')';
  ErrAddPermit = 'Permission is not set.';
  ErrDelPermit = 'Permission is not remove.';
  ErrWrongPrm = 'Wrong value parameter.';
  ErrDropConnection = 'Permission is not remove.';
  
function FindSwitch(const Switch: string): Boolean;
begin
  Result := FindCmdLineSwitch(Switch, ['-'], True);
end;

{ TAdminCmd }

function ResolveAddr(var FAddress: String): Boolean;
var
    Phe : PHostEnt;             // HostEntry buffer for name lookup
    FIPAddress: Integer;
  
begin
    // Convert host address to IP address
    Result := False;
    FIPAddress := inet_addr(PChar(FAddress));
    if FIPAddress = LongInt(INADDR_NONE) then begin
      // Not a numeric dotted address, try to resolve by name

      Phe := gethostbyname(PChar(FAddress));
      if Phe = nil then begin
          Exit;
      end;
      FIPAddress := longint(plongint(Phe^.h_addr_list^)^);
    end;
    FAddress := StrPas(inet_ntoa(TInAddr(FIPAddress)));
    Result := True;
end;

procedure ClientHandleException(ExceptObject: TObject; ExceptAddr: Pointer); far;
begin
	trmAdminCmd.Disconnect;
  trmAdminCmd.FrfRslt := 1;
  trmAdminCmd.FrfErrMsg:=Exception(ExceptObject).ClassName+': '+Exception(ExceptObject).Message;
  trmAdminCmd.WriteResult(True);
end;

//TAdminCmd.

constructor TAdminCmd.Create();
var
  sCfgFile: string;
begin
  inherited Create;
  ExceptProc := @ClientHandleException;
	ccGeneral := TControlConnection.Create(nil);
  ccGeneral.SupportCallbacks := True;
	MyDispatchConnection:=ccGeneral;
	FClosing := False;
	FProgmanOpen := True;
  FAccptStop := False;

//  FAddress := '';
  FsHost := '';
  FsPort := '';
  FAddPort := '';
  FModifyPort := '';
  FDeletePort := '';
  FExclusWork := '';
  FSetPermit := '';
  FAddPermit := '';
  FDeletePermit := '';
  FDropconnect := '';

//  FCfgRunFileName := '';
  FRsltFileName := '';
  sCfgFile := '';

  ConnectionList := TStringList.Create;
  lvPermit := TStringList.Create;
  PortList := TStringList.Create;

  ReadCmdCfgFileName(sCfgFile);
  ReadConfig(sCfgFile,False);
  ReadCmdPrms;
end;

destructor TAdminCmd.Destroy;   
begin
  ConnectionList.Free;
  if ccGeneral <> nil then begin
    ccGeneral.Close;
    ccGeneral.Free; 
    MyDispatchConnection :=nil;
    ccGeneral:=nil;
  end;
  ConnectionList.Free;
  lvPermit.Free;
  PortList.Free;
end;

procedure TAdminCmd.DoIt;
var
  Port, TimeOut: Integer;
  Addr,
  ProcParam: String;
begin
  ProcParam := ''; 
  WriteResult(False);
  try
    Addr := '';
    if (length(FsHost)>0) then begin
      Addr := FsHost;
      if (length(FsPort)>0) then
        Addr := Addr+':'+FsPort;
    end;
    ConnectedExecute(Addr);
    if Length(FAddPort)>0 then begin
      ProcParam := cCmdAddPort;
      Port := StrToInt(Trim(StrFunc.ExtractWord(FAddPort,':',1)));
      try
        TimeOut := StrToInt(Trim(StrFunc.ExtractWord(FAddPort,':',2)));
      except
        TimeOut := 0;
      end;
      if AddPortExecute(Port) then
        ModifyPortExecute(Port, TimeOut);
    end;
    if Length(FModifyPort)>0 then begin
      ProcParam := cCmdModifyPort;
      Port := StrToInt(Trim(StrFunc.ExtractWord(FModifyPort,':',1)));
      try
        TimeOut := StrToInt(Trim(StrFunc.ExtractWord(FModifyPort,':',2)));
      except
        TimeOut := 0;
      end;
      ModifyPortExecute(Port, TimeOut);
    end;
    if Length(FDeletePort)>0 then begin
      ProcParam := cCmdDeletePort;
      Port := StrToInt(Trim(StrFunc.ExtractWord(FDeletePort,':',1)));
      DeletePortExecute(Port);
    end;
    if Length(FExclusWork)>0 then begin
      ProcParam := cCmdExclusWork;
      if (UpperCase(Trim(FExclusWork))='ON') then
        AcceptExecute(True)
      else
        if (UpperCase(Trim(FExclusWork))='OFF') then
          AcceptExecute(False)
        else
          raise Exception.CreateRes(@ErrExclusWorkWrongPrm);
    end;
    if Length(FSetPermit)>0 then begin
      ProcParam := cCmdDeletePermit;
      Addr := Trim(StrFunc.ExtractWord(FSetPermit,':',1));
      if (length(Addr)>0) then begin
        if (not DeletePermitExecute('All')) then
          Exception.CreateRes(@ErrDelPermit);
        if (not AddPermitExecute(Addr)) then
          Exception.CreateRes(@ErrAddPermit);
      end
      else
        Exception.CreateRes(@ErrWrongPrm);
    end;
    if Length(FDeletePermit)>0 then begin
      ProcParam := cCmdDeletePermit;
      Addr := Trim(StrFunc.ExtractWord(FDeletePermit,':',1));
      if (length(Addr)>0) then begin
        if (not DeletePermitExecute(Addr)) then
          Exception.CreateRes(@ErrDelPermit);
      end
      else
        Exception.CreateRes(@ErrWrongPrm);
    end;
    if Length(FAddPermit)>0 then begin
      ProcParam := cCmdAddPermit;
      Addr := Trim(StrFunc.ExtractWord(FAddPermit,':',1));
      if (length(Addr)>0) then begin
        if (not AddPermitExecute(Addr)) then
          Exception.CreateRes(@ErrAddPermit);
      end
      else
        Exception.CreateRes(@ErrWrongPrm);
    end;
    if Length(FDropConnect)>0 then begin
      ProcParam := cCmdDropConnect;
      Addr := Trim(StrFunc.ExtractWord(FDropConnect,':',1));
      if (length(Addr)>0) then begin
        if not DropConnectExecute(Addr) then
          Exception.CreateRes(@ErrDropConnection);
      end
      else
        Exception.CreateRes(@ErrWrongPrm);
    end;
    ConnectedExecute('');
    WriteResult(True);
  except
    on E:Exception do
      begin
        FrfRslt := 1;
        FrfErrMsg:='';
        if (length(ProcParam)>0) then
          FrfErrMsg:='Parameter: '+ProcParam+', ';
        FrfErrMsg:=FrfErrMsg+E.ClassName+' - '+E.Message;
        WriteResult(True);
      end;
  end;

{$ifdef debug}
  if (not FrfRslt)and(Length(FrfErrMsg)>0) then
    raise Exception.Create(FrfErrMsg);
{$endif}
end;

procedure TAdminCmd.ReadCmdCfgFileName(var sFileName: string);
var
  i, iPrmCount: integer;
  sPrm: string;
begin
  iPrmCount:=ParamCount;
  if iPrmCount<1 then Exit;
  for i:=1 to iPrmCount do
    begin
      sPrm:=ReplaceStr(ParamStr(i),'<#34>','"');
      if CompareText(cCmdFileName,Copy(sPrm,1,Length(cCmdFileName)))=0 then
        begin
          sFileName:=Copy(sPrm,Length(cCmdFileName)+2,Length(sPrm));
          break;
        end
   end;
end;

//===================================================================ReadCmdPrms
procedure TAdminCmd.ReadCmdPrms;
var
  i, iPrmCount: integer;
  sPrm, CurrValue: string;
begin
  iPrmCount:=ParamCount;
  if iPrmCount<1 then Exit;

  for i:=1 to iPrmCount do
    begin
      sPrm:=ReplaceStr(ParamStr(i),'<#34>','"');
      if CompareText(cCfgHost,Copy(sPrm,1,Length(cCfgHost)))=0 then
        begin
          CurrValue:=Copy(sPrm,Length(cCfgHost)+2,Length(sPrm));
          FsHost:=CurrValue;
        end
      else if CompareText(cCfgPort,Copy(sPrm,1,Length(cCfgPort)))=0 then
        begin
          CurrValue:=Copy(sPrm,Length(cCfgPort)+2,Length(sPrm));
          FsPort:=CurrValue;
        end
      else if CompareText(cCfgRsltFileName,Copy(sPrm,1,Length(cCfgRsltFileName)))=0 then
        begin
          CurrValue:=Copy(sPrm,Length(cCfgRsltFileName)+2,Length(sPrm));
          FRsltFileName:=CurrValue;
        end
      else if CompareText(cCmdAddPort,Copy(sPrm,1,Length(cCmdAddPort)))=0 then
        begin
          CurrValue:=Copy(sPrm,Length(cCmdAddPort)+2,Length(sPrm));
          FAddPort := CurrValue;
        end
      else if CompareText(cCmdModifyPort,Copy(sPrm,1,Length(cCmdModifyPort)))=0 then
        begin
          CurrValue:=Copy(sPrm,Length(cCmdModifyPort)+2,Length(sPrm));
          FModifyPort := CurrValue;
        end
      else if CompareText(cCmdDeletePort,Copy(sPrm,1,Length(cCmdDeletePort)))=0 then
        begin
          CurrValue:=Copy(sPrm,Length(cCmdDeletePort)+2,Length(sPrm));
          FDeletePort := CurrValue;
        end
      else if CompareText(cCmdExclusWork,Copy(sPrm,1,Length(cCmdExclusWork)))=0 then
        begin
          CurrValue:=Copy(sPrm,Length(cCmdExclusWork)+2,Length(sPrm));
          FExclusWork := CurrValue;
        end
      else if CompareText(cCmdSetPermit,Copy(sPrm,1,Length(cCmdSetPermit)))=0 then
        begin
          CurrValue:=Copy(sPrm,Length(cCmdSetPermit)+2,Length(sPrm));
          FSetPermit := CurrValue;
        end
      else if CompareText(cCmdAddPermit,Copy(sPrm,1,Length(cCmdAddPermit)))=0 then
        begin
          CurrValue:=Copy(sPrm,Length(cCmdAddPermit)+2,Length(sPrm));
          FAddPermit := CurrValue;
        end
      else if CompareText(cCmdDeletePermit,Copy(sPrm,1,Length(cCmdDeletePermit)))=0 then
        begin
          CurrValue:=Copy(sPrm,Length(cCmdDeletePermit)+2,Length(sPrm));
          FDeletePermit := CurrValue;
        end
      else if CompareText(cCmdDropconnect,Copy(sPrm,1,Length(cCmdDropconnect)))=0 then
        begin
          CurrValue:=Copy(sPrm,Length(cCmdDropconnect)+2,Length(sPrm));
          FDropconnect := CurrValue;
        end
        ;
    end;
end;

procedure TAdminCmd.ReadConfig(sFileName: string; bSkipConnPrms: boolean);
var
  CurrSection, CurrIdent, CurrValue: string;
  iValue: integer;
  IniFile: TIniFile;

  sRunCfgFileName: string;
begin

  if sFileName='' then
    sFileName:=ChangeFileExt(system.ParamStr(0),'.cfg')
  else if Pos('\',sFileName)=0 then
    sFileName:=ExtractFileDir(system.ParamStr(0))+'\'+sFileName;
  if not FileExists(sFileName) then Exit;

  IniFile:=TIniFile.Create(sFileName);
  try

    if not bSkipConnPrms then begin
        CurrSection:=cCfgConnSection;
        CurrIdent:=cCfgHost;
        CurrValue:=IniFile.ReadString(CurrSection,CurrIdent,'');
        FsHost:=CurrValue;
        CurrIdent:=cCfgPort;
        CurrValue:=IniFile.ReadString(CurrSection,CurrIdent,'');
        FsPort:=CurrValue;
    end;

    CurrSection:=cCfgParamSection;
    CurrIdent:=cCfgRsltFileName;
    CurrValue:=IniFile.ReadString(CurrSection,CurrIdent,'');

    if Length(CurrValue)>0 then
      FRsltFileName:=CurrValue
    else FRsltFileName:=sFileName;

  finally
    IniFile.Free;
  end;
end;

procedure TAdminCmd.WriteResult(bStop: boolean);
var
  dtNow: TDateTime;
  CurrSection, CurrIdent, CurrValue: string;
  IniFile: TIniFile;
begin
  if Length(FRsltFileName)=0 then Exit;
  if Pos('\',FRsltFileName)=0 then
    FRsltFileName:=ExtractFileDir(system.ParamStr(0))+'\'+FRsltFileName;
  dtNow:=now;
  IniFile:=TIniFile.Create(FRsltFileName);
  try
    CurrSection:=cCfgRsltSection;
    if not bStop then
      begin
        CurrIdent:=cCfgRsltStartDT;
        CurrValue:=DateTimeToStr(dtNow);
        IniFile.WriteString(CurrSection,CurrIdent,CurrValue);

        CurrIdent:=cCfgRsltStopDT;
        CurrValue:='';
        IniFile.WriteString(CurrSection,CurrIdent,CurrValue);

        CurrIdent:=cCfgRsltResult;
        CurrValue:='';
        IniFile.WriteString(CurrSection,CurrIdent,CurrValue);

        CurrIdent:=cCfgRsltMessage;
        CurrValue:='';
        IniFile.WriteString(CurrSection,CurrIdent,CurrValue);

      end
    else
      begin
        CurrIdent:=cCfgRsltStopDT;
        CurrValue:=DateTimeToStr(dtNow);;
        IniFile.WriteString(CurrSection,CurrIdent,CurrValue);

        CurrIdent:=cCfgRsltResult;
        if FrfRslt=0 then
          CurrValue:='OK'
        else
          CurrValue:='ERROR'
          ;
        IniFile.WriteString(CurrSection,CurrIdent,CurrValue);

        CurrIdent:=cCfgRsltMessage;
        CurrValue:=ReplaceStr(FrfErrMsg,Chr(13)+Chr(10),'<#13#10>');
        IniFile.WriteString(CurrSection,CurrIdent,CurrValue);

      end;
  finally
    IniFile.Free;
  end;
end;

procedure TAdminCmd.InitSettings;
begin
	if MyDispatchConnection.Connected then begin
    PortListUpdate;
    FAccptStop := MyDispatchConnection.AppServer.GetAccepting;
	end;
end;

procedure TAdminCmd.ModifyPortExecute(Port, Timeout: Integer);
var
  Idx: Integer;
  SelectedSocket: Pointer;
begin
  if MyDispatchConnection.Connected then begin
    Idx := PortList.IndexOf(IntToStr(Port));
    if (Idx > -1) then begin
      SelectedSocket := Pointer(PortList.Objects[Idx]);
      MyDispatchConnection.AppServer.ModifyPort(Integer(SelectedSocket),
                                          Port,
                                          TControlConnection(MyDispatchConnection).Port,
                                          Timeout);
    end;
  end;
end;

function TAdminCmd.DropconnectExecute(Value: String): BOOL;
var
	i, ResIdx, Idx: integer;
  Addr: String;
begin
  Idx := -1;
  ResIdx := -1;
	if MyDispatchConnection.Connected then begin
    if (UpperCase(Value)='ALL') then begin
      while BOOL(ConnectionList.Count) do begin
        Idx := 0;
        MyDispatchConnection.AppServer.RemoveConnect(Integer(Pointer(ConnectionList.Objects[Idx])));
        ConnectionList.Delete(Idx);
      end;
    end
    else begin
      i := 1;
      repeat 
        Addr := StrFunc.ExtractWord(Value,',',i);
        if (Length(Addr)>0) then begin
          repeat
            Idx := ConnectionList.IndexOf(UpperCase(Addr));
            if Idx > -1 then begin
              ResIdx := Idx;
              MyDispatchConnection.AppServer.RemoveConnect(Integer(Pointer(ConnectionList.Objects[Idx])));
              ConnectionList.Delete(Idx);
            end
            else begin
              ResolveAddr(Addr);
              Idx := ConnectionList.IndexOf(UpperCase(Addr));
              if Idx > -1 then begin
                ResIdx := Idx;
                MyDispatchConnection.AppServer.RemoveConnect(Integer(Pointer(ConnectionList.Objects[Idx])));
                ConnectionList.Delete(Idx);
              end;
            end;
            Inc(i);
          until (Idx = -1);
        end;
      until (Length(Addr)=0);
    end;
  end;
  Result := BOOL(ResIdx+1);
end;

function TAdminCmd.AddPortExecute(Port: Integer):BOOL;
var
	SD: Integer;
	Idx: Integer;
begin
  Idx := -1;
  if MyDispatchConnection.Connected then begin	  
    SD := MyDispatchConnection.AppServer.AddPort(Port);
    if SD>0 then Idx := PortList.AddObject(IntToStr(Port),TObject(SD))
    else Idx := -1;
  end;
  Result := Bool(Idx);
end;

procedure TAdminCmd.DeletePortExecute(Port: Integer);
var
	Idx: integer;
begin
  if MyDispatchConnection.Connected then begin	  
    Idx := PortList.IndexOf(IntToStr(Port));
    if Idx >= 0 then begin
      if (Port = TControlConnection(MyDispatchConnection).Port) then
        raise Exception.CreateRes(@SNotRemovePort);
      if MyDispatchConnection.AppServer.RemovePort(Port,
         TControlConnection(MyDispatchConnection).Port)then
        PortList.Delete(Idx);
    end;
  end;
end;

procedure TAdminCmd.GetConnectionsExecute();
begin
	if FProgmanOpen then begin
		GetConnections;
  end;
end;

procedure TAdminCmd.ConnectedUpdate();
var
	Connected: Boolean;
begin
	Connected := MyDispatchConnection.Connected;
  GetPermits;
  if not Connected and (Connectionlist.Count > 0) then
    ConnectionList.Clear;
  if not Connected and (lvPermit.Count > 0) then
    lvPermit.Clear;
  if not Connected then begin
    PortList.Clear;
  end;    
end;

procedure TAdminCmd.Connect;
begin
	TControlConnection(MyDispatchConnection).Port := FPort;
  TControlConnection(MyDispatchConnection).SetRemoteAddress(FIPAddr);
  TControlConnection(MyDispatchConnection).Host := FHost;
  TControlConnection(MyDispatchConnection).IsCmd := True;
	MyDispatchConnection.Open;
	if MyDispatchConnection.Connected then
		InitSettings;
end;

procedure TAdminCmd.Disconnect;
begin
	if MyDispatchConnection.Connected then
		MyDispatchConnection.AppServer.SetCallBack(varNull);
	MyDispatchConnection.Connected := False;
  FAccptStop := False;
  ConnectedUpdate();
end;

procedure TAdminCmd.GetConnections;
var
	j,k: integer;
  ResArray: Variant;
begin
  if MyDispatchConnection.Connected then begin
    ResArray := MyDispatchConnection.AppServer.GetClientsInfo;
    if VarIsArray(ResArray) then begin
      for j:=0 to VarArrayHighBound(ResArray,1)-1 do begin
        try k:=Integer(ResArray[j,0]);
        except k:=0; end;
        if k>0 then begin
          ConnectionList.AddObject(ResArray[j,1],TObject(Pointer(Integer(ResArray[j,4]))));
        end;
      end;
    end;
  end;
end;

procedure TAdminCmd.GetPermits;
var
	j: integer;
  ResArray: Variant;
begin
  if MyDispatchConnection.Connected then begin
    ResArray := MyDispatchConnection.AppServer.GetPermits;
    if VarIsArray(ResArray) then
      for j:=0 to VarArrayHighBound(ResArray,1)-1 do
        lvPermit.AddObject(ResArray[j,0],TObject(Pointer(Integer(ResArray[j,1]))));
  end;
end;

procedure TAdminCmd.ConnectedExecute(ConnStr: String);
begin
	if not MyDispatchConnection.Connected then begin
    ParseIP_ConnectExecute(ConnStr);
    Connect;
    GetConnectionsExecute;
    ConnectedUpdate
  end
	else begin
    Disconnect;
  end;
end;


procedure TAdminCmd.AcceptExecute(Value: Boolean);
begin
	if MyDispatchConnection.Connected then begin
    if (FAccptStop <> Value) then
      FAccptStop := MyDispatchConnection.AppServer.SuspendAccepting;
  end;
end;

function TAdminCmd.DeletePermitExecute(Value: String):BOOL;
var
	i, ResIdx, Idx: integer;
  Addr: String;
begin
  Idx := -1;
  ResIdx := -1;
	if MyDispatchConnection.Connected then begin
    Addr := Trim(StrFunc.ExtractWord(Value,',',1));
    if (UpperCase(Addr)='ALL') then begin
      while BOOL(lvPermit.Count) do begin
        Idx := 0;
        MyDispatchConnection.AppServer.RemovePermit(Integer(lvPermit.Objects[Idx]));
        lvPermit.Delete(Idx);
      end;
    end
    else begin
      i := 1;
      repeat
        Addr := Trim(StrFunc.ExtractWord(Value,',',i));
        if (Length(Addr) > 0) then begin
          Idx := lvPermit.IndexOf(UpperCase(Addr));
          if Idx > -1 then begin
            ResIdx := Idx;
            MyDispatchConnection.AppServer.RemovePermit(Integer(lvPermit.Objects[Idx]));
            lvPermit.Delete(Idx);
          end
          else begin
            ResolveAddr(Addr);
            Idx := lvPermit.IndexOf(UpperCase(Addr));
            if Idx > -1 then begin
              ResIdx := Idx;
              MyDispatchConnection.AppServer.RemovePermit(Integer(lvPermit.Objects[Idx]));
              lvPermit.Delete(Idx);
            end
          end;
          Inc(i);
        end;
      until (Length(Addr) = 0);
    end;
  end;
  Result := BOOL(ResIdx+1);
end;

function TAdminCmd.AddPermitExecute(Value: String):BOOL;
var
  i, Idx: Integer;
  IP, aIP: String;
  Data: Variant;
  Addr: String;
begin
  Idx := -1;
  if MyDispatchConnection.Connected then begin
    i:=1;
    repeat
      Idx := -1;
      Addr := StrFunc.ExtractWord(Value,',',i);
      if (Length(Addr)>0) then begin
        IP := Addr;
        if ResolveAddr(IP) then
          aIP := IP
        else
          aIP := IP;
        Data := MyDispatchConnection.AppServer.AddPermit_GetData(aIP);
        if VarIsArray(Data) then
          Idx := lvPermit.AddObject(Data[0],TObject(Pointer(Integer(Data[1]))));
        Inc(i);
      end;
    until ((Length(Addr)=0) or (Idx = -1));
  end;
  Result := Bool(Idx+1);
end;

procedure TAdminCmd.PortListUpdate;
var
  ResArray: Variant;
  j, Port, Dat: Integer;
begin
  ResArray := MyDispatchConnection.AppServer.GetPortListData;
  if VarIsArray(ResArray) then begin
    for j:=0 to VarArrayHighBound(ResArray,1)-1 do begin
      try
        Port := Integer(ResArray[j,0]);
        Dat := Integer(ResArray[j,1]);
	      PortList.AddObject(IntToStr(Port), TObject(Dat));
      finally
      end;
    end;
  end;
end;

procedure TAdminCmd.ParseIP_ConnectExecute(ConnStr: String);
var
  Contin: Boolean;
  ConnectStr,Port,IP: String;
begin
  FHost := '';
  FIPAddr := '';
  Contin := True;
  ConnectStr := Trim(StringReplace(ConnStr,' ','',[rfReplaceAll]));
  IP := Trim(StrFunc.ExtractWord(ConnectStr,':',1));
  if (IP = '') then IP := Def_Ip;
  Port := Trim(StrFunc.ExtractWord(ConnectStr,':',2));
  try
    FPort := StrToInt(Port);
    if ((FPort<=0) or (FPort >= 65535)) then begin
      Contin := False;
    end;
  except
    FPort := Def_Port;
  end;
  if Contin then begin
    if ResolveAddr(IP) then
      FIPAddr := IP
    else
      FHost := IP;
  end
  else
    raise Exception.CreateRes(@WrongIPorPort);
end;

end.

