unit ScktSrvCfg;

interface
uses
  windows, sysutils, inifiles;
const
	SServiceOnly = 'The Socket Server can only be run as a service on NT 3.51 or later';
	SErrClose = 'Cannot exit when there are active connections. Kill connections?';
	SErrChangeSettings = 'Cannot change settings when there are active connections. Kill connections?';
	SQueryDisconnect = 'Disconnecting clients can cause application errors. Continue?';
	SOpenError = 'Error opening port %d with error: %s';
	SHostUnknown = '(Unknown)';
	SNotShown = '(Not Shown)';
	SNoWinSock2 = 'WinSock_2 must be installed to use the socket connection';
	SStatusline = '%d current connections';
	SNotUntilRestart = 'This change will not take affect until the Socket Server is restarted';

	cvDisplayName     = 'Terminal Socket Server';

type
	TPortSettings = record
		PortNo         : integer;
		Timeout        : integer;
		Listen         : boolean;
	end;
	TPortsToListen = array of TPortSettings;

	TScktSrvCfg = class(TObject)
	private
		FCfgFileExists: boolean;
		FCfgFileName: string;

		FServiceName: string;
		FDisplayName: string;
		FShowHost: boolean;
		FRegisteredOnly: boolean;
		FSysAffMask,
		FProcessAffMask,
		FCPUAffinity: DWORD;
		FhProcess: Thandle;
		FPortsToListen: TPortsToListen;
		function CheckSysAffMask: boolean;
		procedure ReadCfg;
		procedure SetShowHost(Value: boolean);
		procedure SetRegisteredOnly(Value: boolean);
		procedure SetCPUAffinity(Value: DWORD);
		function ApplyCPUAffinity(const Silent: boolean=False):boolean;
	public
		constructor Create;
		destructor Destroy; override;
		procedure WriteShowHost(CfgFile: TIniFile=nil);
		procedure WriteRegisteredOnly(CfgFile: TIniFile=nil);
		procedure WriteCPUAffinity(CfgFile: TIniFile=nil);
		procedure WritePortsSettings(CfgFile: TIniFile=nil);
		procedure WriteCfg(const FirstTime: boolean=False);
		function PortCount: integer;
		function IsWinNT: boolean;
		procedure RemovePort(PortNo: integer);
		procedure AddPortToListen(PortNo, Timeout: integer);
		property ServiceName: string read FServiceName;
		property DisplayName: string read FDisplayName;
		property ShowHost: boolean read FShowHost write SetShowHost;
		property RegisteredOnly: boolean read FRegisteredOnly write SetRegisteredOnly;
		property SysAffMask: DWORD read FSysAffMask;
		property ProcessAffMask: DWORD read FProcessAffMask;
		property CPUAffinity: DWORD read FCPUAffinity write SetCPUAffinity;
		property PortsToListen: TPortsToListen read FPortsToListen;
	end;

var
  trmScktSrvCfg: TScktSrvCfg=nil;

implementation

const
  cCfgFileExt = 'cfg';
  cTrueSign  = '1';
  cFalseSign = '0';

  csGeneral         = 'General';
  ckServiceName     = 'ServiceName';
  cvServiceName     = 'TrmScktSrvr';
  ckDisplayName     = 'DisplayName';

  csSettings        = 'Settings';
  ckShowHost        = 'ShowHost';
  cvShowHost        = cFalseSign;
  ckRegisteredOnly  = 'RegisteredOnly';
  cvRegisteredOnly  = cTrueSign;
  ckCPUAffinity     = 'CPUAffinity';
  cvCPUAffinity     = 0;

  ckListenToPorts   = 'ListenToPorts';
  cvListenToPorts   = 211;

  csPortPrefix      = 'Port_';
  ckTimeout         = 'InactiveTimeout';
  cvTimeout         = 0;

//========================================================================Create
constructor TScktSrvCfg.Create;
var
  s: string;
begin
  inherited Create;
  FServiceName:=cvServiceName;
  FDisplayName:=cvDisplayName;
  FShowHost:=False;
  FRegisteredOnly:=True;
  CheckSysAffMask;
  FCPUAffinity:=0;
  FPortsToListen:=nil;
  FCfgFileName:='';
  s:=system.ParamStr(0);
  if Length(s)>4 then
    begin
      if s[Length(s)-3]='.' then
        FCfgFileName:=Copy(s,1,Length(s)-3)+cCfgFileExt
      else
        FCfgFileName:=s+'.'+cCfgFileExt;
      FCfgFileExists:=FileExists(FCfgFileName);
      if not FCfgFileExists then WriteCfg(True);
      ReadCfg;
    end;
  ApplyCPUAffinity(True);  
end;

//=====================================================================PortCount
function TScktSrvCfg.PortCount: integer;
begin
  Result:=Length(FPortsToListen);
end;

//=======================================================================IsWinNT
function TScktSrvCfg.IsWinNT: boolean;
begin
  Result:=SysUtils.Win32Platform=VER_PLATFORM_WIN32_NT;
end;

//====================================================================RemovePort
procedure TScktSrvCfg.RemovePort(PortNo: integer);
var
  pCnt, i, pIndx: integer;
begin
  pIndx:=-1;
  pCnt:=PortCount;
  for i:=0 to pCnt-1 do
    if FPortsToListen[i].PortNo=PortNo then
      begin
        pIndx:=i;
        break;
      end;
  if pIndx>=0 then
    FPortsToListen[pIndx].Listen:=False;
end;

//===============================================================AddPortToListen
procedure TScktSrvCfg.AddPortToListen(PortNo, Timeout: integer);
var
  pCnt, i, pIndx: integer;
begin
  if PortNo<0 then Exit;
  if Timeout<0 then
    Timeout:=0
  else if Timeout>32767 then
    Timeout:=32767;
  pIndx:=-1;
  pCnt:=PortCount;
  for i:=0 to pCnt-1 do
    if FPortsToListen[i].PortNo=PortNo then
      begin
        pIndx:=i;
        break;
      end;
  if pIndx<0 then
    begin
      SetLength(FPortsToListen,pCnt+1);
      pIndx:=PortCount-1;
    end;
  FPortsToListen[pIndx].PortNo:=PortNo;
  FPortsToListen[pIndx].Timeout:=Timeout;
  FPortsToListen[pIndx].Listen:=True;
end;

//===============================================================CheckSysAffMask
function TScktSrvCfg.CheckSysAffMask: boolean;
var
  process_affmask,
  sys_affmask: DWORD;
begin
  Result:=False;
  FSysAffMask:=0;
  FProcessAffMask:=0;
  FhProcess:=GetCurrentProcess;
  if not IsWinNT then Exit;
  Result:=GetProcessAffinityMask(FhProcess, process_affmask, sys_affmask);
  if Result then
    begin
      FSysAffMask:=sys_affmask;
      FProcessAffMask:=process_affmask;
    end;
end;

//=======================================================================ReadCfg
procedure TScktSrvCfg.ReadCfg;
var
  CfgFile: TINIFile;
  sLen, i, iPort, iTimeout : integer;
  sPortsToListen,sPort,sSection: string;
begin
  CfgFile:=nil;
  if Length(FCfgFileName)>0 then
    try
      CfgFile:=TIniFile.Create(FCfgFileName);
      FServiceName:=CfgFile.ReadString(csGeneral,ckServiceName,cvServiceName);
      FDisplayName:=CfgFile.ReadString(csGeneral,ckDisplayName,cvDisplayName);
      FShowHost:=CfgFile.ReadString(csSettings,ckShowHost,cFalseSign)=cTrueSign;
      FRegisteredOnly:=CfgFile.ReadString(csSettings,ckRegisteredOnly,cTrueSign)=cTrueSign;
      FCPUAffinity:=StrToIntDef(CfgFile.ReadString(csSettings,ckCPUAffinity,IntToStr(cvCPUAffinity)),cvCPUAffinity);

      sPortsToListen:=Trim(CfgFile.ReadString(csSettings,ckListenToPorts,IntToStr(cvListenToPorts)));
      sLen:=Length(sPortsToListen);
      sPort:='';
      for i:=1 to sLen do
        begin
          if not(sPortsToListen[i] in [',',' ']) then
            sPort:=sPort+sPortsToListen[i];
          if (sPortsToListen[i]=',')or(i=sLen) then
            begin
              iPort:=StrToIntDef(sPort,-1);
              if iPort>-1 then
                begin
                  sSection:=csPortPrefix+IntToStr(iPort);
                  iTimeout:=CfgFile.ReadInteger(sSection,ckTimeout,cvTimeout);
                  AddPortToListen(iPort, iTimeout);
                end;
              sPort:='';
            end;
        end;
    finally
      CfgFile.Free;
      if PortCount=0 then
        begin
          AddPortToListen(cvListenToPorts, cvTimeout);
        end;
    end;
end;

//=================================================================WriteShowHost
procedure TScktSrvCfg.WriteShowHost(CfgFile: TIniFile=nil);
var
  FreeINIFile: boolean;
  sValue: string;
begin
  if Length(FCfgFileName)=0 then Exit;
  FreeINIFile:=False;
  if CfgFile=nil then
    begin
      CfgFile:=TIniFile.Create(FCfgFileName);
      FreeINIFile:=True;
    end;
  try
    sValue:=cFalseSign;
    if ShowHost then sValue:=cTrueSign;
    CfgFile.WriteString(csSettings,ckShowHost,sValue);
  finally
    if FreeINIFile then CfgFile.Free;
  end;
end;

//===========================================================WriteRegisteredOnly
procedure TScktSrvCfg.WriteRegisteredOnly(CfgFile: TIniFile=nil);
var
  FreeINIFile: boolean;
  sValue: string;
begin
  if Length(FCfgFileName)=0 then Exit;
  FreeINIFile:=False;
  if CfgFile=nil then
    begin
      CfgFile:=TIniFile.Create(FCfgFileName);
      FreeINIFile:=True;
    end;
  try
    sValue:=cTrueSign;
    if not RegisteredOnly then sValue:=cFalseSign;
    CfgFile.WriteString(csSettings,ckRegisteredOnly,sValue);
  finally
    if FreeINIFile then CfgFile.Free;
  end;
end;

//==============================================================WriteCPUAffinity
procedure TScktSrvCfg.WriteCPUAffinity(CfgFile: TIniFile=nil);
var
  FreeINIFile: boolean;
begin
  if Length(FCfgFileName)=0 then Exit;
  FreeINIFile:=False;
  if CfgFile=nil then
    begin
      CfgFile:=TIniFile.Create(FCfgFileName);
      FreeINIFile:=True;
    end;
  try
    CfgFile.WriteString(csSettings,ckCPUAffinity,IntToStr(FCPUAffinity));
  finally
    if FreeINIFile then CfgFile.Free;
  end;
end;

//============================================================WritePortsSettings
procedure TScktSrvCfg.WritePortsSettings(CfgFile: TIniFile=nil);
var
  FreeINIFile: boolean;
  sSection, sPortsToListen: string;
  pCnt, i: integer;
begin
  if Length(FCfgFileName)=0 then Exit;
  FreeINIFile:=False;
  if CfgFile=nil then
    begin
      CfgFile:=TIniFile.Create(FCfgFileName);
      FreeINIFile:=True;
    end;
  try
    pCnt:=PortCount;
    sPortsToListen:='';
    if pCnt>0 then
      begin
        for i:=0 to pCnt-1 do
          begin
            sSection:=csPortPrefix+IntToStr(FPortsToListen[i].PortNo);
            if FPortsToListen[i].Listen then
              begin
                if Length(sPortsToListen)>0 then
                  sPortsToListen:=sPortsToListen+',';
                sPortsToListen:=sPortsToListen+IntToStr(FPortsToListen[i].PortNo);
                CfgFile.WriteInteger(sSection,ckTimeout,FPortsToListen[i].Timeout);
              end
            else
              try
                CfgFile.EraseSection(sSection);
              except
              end;
          end;
      end
    else
      begin
        sPortsToListen:=IntToStr(cvListenToPorts);
        sSection:=csPortPrefix+IntToStr(cvListenToPorts);
        CfgFile.WriteInteger(sSection,ckTimeout,cvTimeout);
      end;
    CfgFile.WriteString(csSettings,ckListenToPorts,sPortsToListen);
  finally
    if FreeINIFile then CfgFile.Free;
  end;
end;

//======================================================================WriteCfg
procedure TScktSrvCfg.WriteCfg(const FirstTime: boolean=False);
var
  CfgFile: TINIFile;
begin
  if Length(FCfgFileName)=0 then Exit;
  CfgFile:=TIniFile.Create(FCfgFileName);
  try
    if FirstTime then
      begin
        CfgFile.WriteString(csGeneral,ckServiceName,ServiceName);
        CfgFile.WriteString(csGeneral,ckDisplayName,DisplayName);
      end;
    WriteShowHost(CfgFile);
    WriteRegisteredOnly(CfgFile);
    WriteCPUAffinity(CfgFile);
    WritePortsSettings(CfgFile);
  finally
    CfgFile.Free;
  end;
end;

//===================================================================SetShowHost
procedure TScktSrvCfg.SetShowHost(Value: boolean);
begin
  if FShowHost=Value then exit;
  FShowHost:=Value;
  WriteShowHost(nil);
end;

//=============================================================SetRegisteredOnly
procedure TScktSrvCfg.SetRegisteredOnly(Value: boolean);
begin
  if RegisteredOnly=Value then exit;
  FRegisteredOnly:=Value;
  WriteRegisteredOnly(nil);
end;

//================================================================SetCPUAffinity
procedure TScktSrvCfg.SetCPUAffinity(Value: DWORD);
begin
  if FCPUAffinity=Value then Exit;
  FCPUAffinity:=Value;
  if ApplyCPUAffinity then WriteCPUAffinity(nil);
end;

//==============================================================ApplyCPUAffinity
function TScktSrvCfg.ApplyCPUAffinity(const Silent: boolean=False):boolean;
var
  iCPUAffinity: DWORD;
begin
  Result:=False;
  FCPUAffinity:=(FCPUAffinity and FSysAffMask);
  iCPUAffinity:=FCPUAffinity;
  if FCPUAffinity<=0 then iCPUAffinity:=FSysAffMask;
  if (iCPUAffinity<=0)or(not CheckSysAffMask) then Exit;
  if Silent then
    try
      Result:=SetProcessAffinityMask(FhProcess, iCPUAffinity);
    except
    end
  else
    begin
      Result:=Win32Check(SetProcessAffinityMask(FhProcess, iCPUAffinity));
    end;
  if Result then CheckSysAffMask;
end;

//=======================================================================Destroy
destructor TScktSrvCfg.Destroy;
begin
  inherited Destroy;
end;

initialization

finalization
  trmScktSrvCfg.Free;

end.
