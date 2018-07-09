unit HostNameList;

interface
uses
  Windows, ThreadUnit, Classes, SyncObjs;

type

  THostNameList = class
  private
    FHostList: TStringList;
    FHostListLock: TCriticalSection;
  protected
    procedure SetHostName(const IPAddress, HostName: String);
  public
    constructor Create(Owner: TObject);
    destructor Destroy; override;
    function GetHostName(const IPAddress: WideString; ClientSocket: Integer): String;
  end;

  THostNameThread = class(TMyThread)
  private
    FHostNameList: THostNameList;
    FIPAddress: String;
  protected
    procedure Execute; override;
  public
    constructor Create(Owner: THostNameList; const IPAddress: String);
  end;

implementation
uses
  tServiceMain, WinSock, ScktSrvCfg;

{ THostNameList }

constructor THostNameList.Create(Owner: TObject);
begin
  inherited Create;
  FHostListLock := TCriticalSection.Create;
  FHostList := TStringList.Create;
end;

destructor THostNameList.Destroy;
begin
  FHostList.Free;
  FHostListLock.Free;
  inherited Destroy;
end;

function THostNameList.GetHostName(const IPAddress: WideString; ClientSocket: Integer): String;
var
  index: Integer;
begin
  FHostListLock.Enter;
  Result := '';
  try
    Result := FHostList.Values[IPAddress];
    if Result = '' then begin
	    if FHostList.IndexOfName(IPAddress) = -1 then begin
        Result := '...';
		    index := FHostList.AddObject(IPAddress+'='+Result, TObject(TList.Create));
        TList(FHostList.Objects[index]).Clear;
        TList(FHostList.Objects[index]).Add(Pointer(ClientSocket));
        THostNameThread.Create(Self, IPAddress);
      end;
    end
    else
      if Result = '...' then begin
	      index := FHostList.IndexOfName(IPAddress);
        TList(FHostList.Objects[index]).Add(Pointer(ClientSocket));
      end;
  finally
    FHostListLock.Leave;
  end;
end;

procedure THostNameList.SetHostName(const IPAddress, HostName: String);
var
  index: Integer;
  List: TList;
  P: Pointer;
begin
  FHostListLock.Enter;
  try
    index:=FHostList.IndexOfName(IPAddress);
    FHostList.Values[IPAddress]:=HostName;
    List:=TList(FHostList.Objects[index]);
    while List.Count > 0 do begin
      P := List.Last;
      Application.ClientShowHost(Self, P);
      List.Remove(P);
    end;
    List.Free;
    FHostList.Objects[index]:=nil;
  finally
    FHostListLock.Leave;
  end;
end;


{ THostNameThread }

constructor THostNameThread.Create(Owner: THostNameList;
  const IPAddress: String);
begin
  FHostNameList := Owner;
  FIPAddress := IPAddress;
  inherited Create(false);
  FreeOnTerminate := True;
end;

procedure THostNameThread.Execute;
var
	HostName: String;
	phe: PHostEnt;
	addr: u_long;
begin
  HostName := '';
  try
    addr := inet_addr(PChar(FIPAddress));
    phe := gethostbyaddr(@addr, 4, PF_INET);
    if phe <> nil then
      HostName := phe.h_name;
  except
    HostName := '';
  end;
  if HostName = '' then HostName := SHostUnknown;
  FHostNameList.SetHostName(FIPAddress, HostName);
end;

end.
