unit tScktMain;

interface

uses
	Windows, Messages, SysUtils, Classes, Controls, Forms,
	ActnList,	Dialogs, ComObj,
	{TScktSrv_TLB,} ControlConnection,
	TB97Ctls, Db, DBClient, ComCtrls, ExtCtrls, StdCtrls, Placemnt, ImgList,
  Graphics, Mask, RXSpin, AppEvent, Menus, SConnect;

resourcestring
	SErrChangeSettings = 'Cannot change settings when there are active connections. Kill connections?';
	SStatusline = '%d current connections';
	SNotUntilRestart = 'This change will not take affect until the Socket Server is restarted';
	SErrClose = 'Cannot exit when there are active connections. Kill connections?';
	SQueryDisconnect = 'Disconnecting clients can cause application errors. Continue?';
  WrongIP = 'Invalid address IP.';
  WrongIPorPort = 'Invalid address IP or port value.';
  
const
	DisconnectHint = 'Disconnect';
	ConnectHint = 'Connect';
  AcceptStartHint = 'Enable new connections';
  AcceptStopHint = 'Disable new connections';
	SHostUnknown = '(Unknown)';
	SNotShown = '(Not Shown)';
  ErrorTCP = 'Error TCP/IP.';

  Def_Ip = 'localhost';
  Def_Port = 211;
  
  WM_UPDFROMSRV = WM_USER + 1000;
  WM_ADDCLIENT = WM_UPDFROMSRV + 1; 
  WM_REMOVECLIENT = WM_ADDCLIENT + 1;
  WM_SHOWHOST = WM_REMOVECLIENT + 1;
  
type

{
    procedure AddPermit(const Value: WideString; Idx: Integer); safecall;
	end;}

	TtrmSocketForm = class(TForm)
    mainPanel: TPanel;
		Pages: TPageControl;
		StatPage: TTabSheet;
		UserStatus: TStatusBar;
		PropPage: TTabSheet;
		gbSocket: TGroupBox;
    llistenport: TLabel;
    linactivetimeout: TLabel;
		ApplyButton: TButton;
		gbSystem: TGroupBox;
    mainActionList: TActionList;
		ApplyAction: TAction;
		DisconnectAction: TAction;
		ShowHostAction: TAction;
		RemovePortAction: TAction;
		RegisteredAction: TAction;
		gbPorts: TGroupBox;
		pnlPorts: TPanel;
		PortList: TListBox;
		btnPortAdd: TButton;
		btnPortRemove: TButton;
		pnlConnectBtns: TPanel;
		sbDisconnect: TButton;
		sbRefresh: TButton;
		AddPortAction: TAction;
		cbRegisteredOnly: TCheckBox;
		gbCPUAffinity: TGroupBox;
		cbCPU0: TCheckBox;
		cbCPU1: TCheckBox;
		btnApplyAffinity: TButton;
		pnlShowHostName: TPanel;
		cbShowHostName: TCheckBox;
		ccGeneral: TControlConnection;
		GetConnectionsAction: TAction;
		UpdateStatusAction: TAction;
		ConnectedAction: TAction;
		gbSrvSett: TGroupBox;
    pnlConnect: TPanel;
		btConnect: TToolbarButton97;
    RefreshAction: TAction;
    pnlAcceptStop: TPanel;
    btnAcceptStop: TToolbarButton97;
    AcceptAction: TAction;
    DoubleRefreshAction: TAction;
    SelectAllAction: TAction;
    mainFormStorage: TFormPlacement;
    RemovePermitAction: TAction;
    AddPermitAction: TAction;
    pnlConnections: TPanel;
    pnlConnectList: TPanel;
    pnlPermit: TPanel;
    ConnectionList: TListView;
    pnlNewIP: TPanel;
    meNewIP: TMaskEdit;
    btnPermAdd: TButton;
    btnPermRem: TButton;
    pnlPermitIP: TPanel;
    lvPermit: TListView;
    pnlPermHead: TPanel;
    PortNo: TRxSpinEdit;
    Timeout: TRxSpinEdit;
    meCCIP: TMaskEdit;
    ParseIP_ConnectAction: TAction;
		procedure FormCreate(Sender: TObject);
		procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
		procedure ApplyActionExecute(Sender: TObject);
		procedure ApplyActionUpdate(Sender: TObject);
		procedure DisconnectActionUpdate(Sender: TObject);
		procedure ShowHostActionExecute(Sender: TObject);
		procedure RemovePortActionUpdate(Sender: TObject);
		procedure RemovePortActionExecute(Sender: TObject);
		procedure PortListClick(Sender: TObject);
		procedure ConnectionListCompare(Sender: TObject; Item1,
			Item2: TListItem; Data: Integer; var Compare: Integer);
		procedure ConnectionListColumnClick(Sender: TObject;
			Column: TListColumn);
		procedure IntegerExit(Sender: TObject);
		procedure RegisteredActionExecute(Sender: TObject);
		procedure RefreshActionExecute(Sender: TObject);
		procedure DisconnectActionExecute(Sender: TObject);
		procedure AddPortActionExecute(Sender: TObject);
		procedure btnApplyAffinityClick(Sender: TObject);
		procedure cbCPUNClick(Sender: TObject);
		procedure GetConnectionsActionExecute(Sender: TObject);
		procedure UpdateStatusActionUpdate(Sender: TObject);
		procedure ConnectedActionUpdate(Sender: TObject);
		procedure FormDestroy(Sender: TObject);
		procedure ConnectedActionExecute(Sender: TObject);
		procedure AddPortActionUpdate(Sender: TObject);
    procedure AcceptActionExecute(Sender: TObject);
    procedure AcceptActionUpdate(Sender: TObject);
    procedure SelectAllActionExecute(Sender: TObject);
    procedure RemovePermitActionUpdate(Sender: TObject);
    procedure RemovePermitActionExecute(Sender: TObject);
    procedure lvPermitColumnClick(Sender: TObject; Column: TListColumn);
    procedure lvPermitCompare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure AddPermitActionUpdate(Sender: TObject);
    procedure AddPermitActionExecute(Sender: TObject);
    procedure meNewIPKeyPress(Sender: TObject; var Key: Char);
    procedure miConnectClick(Sender: TObject);
    procedure PopupActionExecute(Sender: TObject);
    procedure PagesChange(Sender: TObject);
    procedure meCCIPKeyPress(Sender: TObject; var Key: Char);
    procedure ParseIP_ConnectActionExecute(Sender: TObject);
    procedure ccGeneralNotifyClientFromServer(Flag: TNotifyFlag;
      Data: OleVariant);
//    procedure lvPermitExit(Sender: TObject);
	private
    FPort: Integer;
    FHost, FIPAddr: String;
    FAccptStop: Boolean;
		FAscendCompare: Boolean;
    FAscendComparePerm: Boolean;
//		FClient: TClient;
		MyDispatchConnection: TControlDispatchConnection;
		FClosing: Boolean;
		FProgmanOpen: Boolean;
		FCurItem: Integer;
		FSortCol: Integer;
    FSortColPerm: Integer;
		procedure UpdateStatus;
		function GetItemIndex: Integer;
		procedure SetItemIndex(Value: Integer);
		function GetSelectedSocket: Pointer;
		function GetSelectedPort: Integer;
		procedure CheckValues;
		procedure ClientHandleException(Sender: TObject; E: Exception);
		procedure GetConnections;
		procedure GetPermits;
		procedure RefreshConnections;
		procedure UpdatePortParamsControl;
		procedure Connect;
		procedure Disconnect(Value: Boolean = True);
		procedure SetEnabledControls(const GroupBox: TGroupBox; Value: Boolean);
    procedure AddClient(var Msg: TMessage); message WM_ADDCLIENT;
    procedure RemoveClient(var Msg: TMessage); message WM_REMOVECLIENT;
    procedure ShowHost(var Msg: TMessage); message WM_SHOWHOST;
    procedure UpdateFromServer(var Msg: TMessage); message WM_UPDFROMSRV;
	protected
		procedure ClearModifications;
		procedure InitSettings;
		procedure ShowCPUAffinity;
    procedure PortListUpdate;
	public
		property SelectedSocket: Pointer read GetSelectedSocket;
		property SelectedPort: Integer read GetSelectedPort;
		property ItemIndex: Integer read GetItemIndex write SetItemIndex;
	end;

var
	trmSocketForm: TtrmSocketForm;

function ReadArray(VType: Integer; const Data: IDataBlock): OleVariant;
procedure WriteArray(const Value: OleVariant; const Data: IDataBlock);
function ReadVariant(out Flags: TVarFlags; const Data: IDataBlock): OleVariant;
procedure WriteVariant(const Value: OleVariant; const Data: IDataBlock);
  
implementation

uses ActiveX, MidConst, TSSAdminCfg, StrFunc, WinSock;

{$R *.DFM}

const
  varShortInt = $0010; { vt_i1          16 }
  varWord     = $0012; { vt_ui2         18 }
  varLongWord = $0013; { vt_ui4         19 }
  varInt64    = $0014; { vt_i8          20 }

  EasyArrayTypes = [varSmallInt, varInteger, varSingle, varDouble, varCurrency,
                    varDate, varBoolean, varShortInt, varByte, varWord, varLongWord];

  VariantSize: array[0..varLongWord] of Word  = (0, 0, SizeOf(SmallInt), SizeOf(Integer),
    SizeOf(Single), SizeOf(Double), SizeOf(Currency), SizeOf(TDateTime), 0, 0,
    SizeOf(Integer), SizeOf(WordBool), 0, 0, 0, 0, SizeOf(ShortInt), SizeOf(Byte),
    SizeOf(Word), SizeOf(LongWord));

function ReadArray(VType: Integer;
  const Data: IDataBlock): OleVariant;
var
  Flags: TVarFlags;
  LoDim, HiDim, Indices, Bounds: PIntArray;
  DimCount, VSize, i: Integer;
  P: Pointer;
  V: OleVariant;
  VarArrayPtr: PSafeArray;
begin
  VarClear(Result);
  Data.Read(DimCount, SizeOf(DimCount));
  VSize := DimCount * SizeOf(Integer);
  GetMem(LoDim, VSize);
  try
    GetMem(HiDim, VSize);
    try
      Data.Read(LoDim^, VSize);
      Data.Read(HiDim^, VSize);
      GetMem(Bounds, VSize * 2);
      try
        for i := 0 to DimCount - 1 do
        begin
          Bounds[i * 2] := LoDim[i];
          Bounds[i * 2 + 1] := HiDim[i];
        end;
        Result := VarArrayCreate(Slice(Bounds^,DimCount * 2), VType and varTypeMask);
      finally
        FreeMem(Bounds);
      end;
      VarArrayPtr := PSafeArray(TVarData(Result).VArray);
      if VType and varTypeMask in EasyArrayTypes then
      begin
        Data.Read(VSize, SizeOf(VSize));
        P := VarArrayLock(Result);
        try
          Data.Read(P^, VSize);
        finally
          VarArrayUnlock(Result);
        end;
      end else
      begin
        GetMem(Indices, VSize);
        try
          FillChar(Indices^, VSize, 0);
          for I := 0 to DimCount - 1 do
            Indices[I] := LoDim[I];
          while True do
          begin
            V := ReadVariant(Flags, Data);
            if VType and varTypeMask = varVariant then
              OleCheck(SafeArrayPutElement(VarArrayPtr, Indices^, V)) else
              OleCheck(SafeArrayPutElement(VarArrayPtr, Indices^, TVarData(V).VPointer^));
            Inc(Indices[DimCount - 1]);
            if Indices[DimCount - 1] > HiDim[DimCount - 1] then
              for i := DimCount - 1 downto 0 do
                if Indices[i] > HiDim[i] then
                begin
                  if i = 0 then Exit;
                  Inc(Indices[i - 1]);
                  Indices[i] := LoDim[i];
                end;
          end;
        finally
          FreeMem(Indices);
        end;
      end;
    finally
      FreeMem(HiDim);
    end;
  finally
    FreeMem(LoDim);
  end;
end;

function ReadVariant(out Flags: TVarFlags;
  const Data: IDataBlock): OleVariant;
var
  I, VType: Integer;
  W: WideString;
  TmpFlags: TVarFlags;
begin
  VarClear(Result);
  Flags := [];
  Data.Read(VType, SizeOf(VType));
  if VType and varByRef = varByRef then Include(Flags, vfByRef);
  if VType = varByRef then
  begin
    Include(Flags, vfVariant);
    Result := ReadVariant(TmpFlags, Data);
    Exit;
  end;
  if vfByRef in Flags then VType := VType xor varByRef;
  if (VType and varArray) = varArray then
    Result := ReadArray(VType, Data) else
  case VType and varTypeMask of
    varEmpty: VarClear(Result);
    varNull: Result := NULL;
    varOleStr:
    begin
      Data.Read(I, SizeOf(Integer));
      SetLength(W, I);
      Data.Read(W[1], I * 2);
      Result := W;
    end;
    varUnknown:
      raise EInterpreterError.CreateResFmt(@SBadVariantType,[IntToHex(VType,4)]);
  else
    TVarData(Result).VType := VType;
    Data.Read(TVarData(Result).VPointer, VariantSize[VType and varTypeMask]);
  end;
end;

procedure WriteArray(const Value: OleVariant;
  const Data: IDataBlock);
var
  VType, VSize, i, DimCount, ElemSize: Integer;
  VarArrayPtr: PSafeArray;
  LoDim, HiDim, Indices: PIntArray;
  V: OleVariant;
  P: Pointer;
begin
  VType := VarType(Value);
  Data.Write(VType, SizeOf(Integer));
  DimCount := VarArrayDimCount(Value);
  Data.Write(DimCount, SizeOf(DimCount));
  VarArrayPtr := PSafeArray(TVarData(Value).VArray);
  VSize := SizeOf(Integer) * DimCount;
  GetMem(LoDim, VSize);
  try
    GetMem(HiDim, VSize);
    try
      for i := 1 to DimCount do
      begin
        LoDim[i - 1] := VarArrayLowBound(Value, i);
        HiDim[i - 1] := VarArrayHighBound(Value, i);
      end;
      Data.Write(LoDim^,VSize);
      Data.Write(HiDim^,VSize);
      if VType and varTypeMask in EasyArrayTypes then
      begin
        ElemSize := SafeArrayGetElemSize(VarArrayPtr);
        VSize := 1;
        for i := 0 to DimCount - 1 do
          VSize := (HiDim[i] - LoDim[i] + 1) * VSize;
        VSize := VSize * ElemSize;
        P := VarArrayLock(Value);
        try
          Data.Write(VSize, SizeOf(VSize));
          Data.Write(P^,VSize);
        finally
          VarArrayUnlock(Value);
        end;
      end else
      begin
        GetMem(Indices, VSize);
        try
          for I := 0 to DimCount - 1 do
            Indices[I] := LoDim[I];
          while True do
          begin
            if VType and varTypeMask <> varVariant then
            begin
              OleCheck(SafeArrayGetElement(VarArrayPtr, Indices^, TVarData(V).VPointer));
              TVarData(V).VType := VType and varTypeMask;
            end else
              OleCheck(SafeArrayGetElement(VarArrayPtr, Indices^, V));
            WriteVariant(V, Data);
            Inc(Indices[DimCount - 1]);
            if Indices[DimCount - 1] > HiDim[DimCount - 1] then
              for i := DimCount - 1 downto 0 do
                if Indices[i] > HiDim[i] then
                begin
                  if i = 0 then Exit;
                  Inc(Indices[i - 1]);
                  Indices[i] := LoDim[i];
                end;
          end;
        finally
          FreeMem(Indices);
        end;
      end;
    finally
      FreeMem(HiDim);
    end;
  finally
    FreeMem(LoDim);
  end;
end;

procedure WriteVariant(const Value: OleVariant;
  const Data: IDataBlock);
var
  I, VType: Integer;
  W: WideString;
begin
  VType := VarType(Value);
  if VarIsArray(Value) then
    WriteArray(Value, Data) else
  case (VType and varTypeMask) of
		varEmpty, varNull: Data.Write(VType, SizeOf(Integer));
    varOleStr:
    begin
      W := WideString(Value);
      I := Length(W);
      Data.Write(VType, SizeOf(Integer));
      Data.Write(I,SizeOf(Integer));
      Data.Write(W[1], I * 2);
    end;
    varVariant:
    begin
      if VType and varByRef <> varByRef then
        raise EInterpreterError.CreateResFmt(@SBadVariantType,[IntToHex(VType,4)]);
      I := varByRef;
      Data.Write(I, SizeOf(Integer));
      WriteVariant(Variant(TVarData(Value).VPointer^), Data);
    end;
    varUnknown:
      raise EInterpreterError.CreateResFmt(@SBadVariantType,[IntToHex(VType,4)]);
  else
    Data.Write(VType, SizeOf(Integer));
    if VType and varByRef = varByRef then
      Data.Write(TVarData(Value).VPointer^, VariantSize[VType and varTypeMask]) else
			Data.Write(TVarData(Value).VPointer, VariantSize[VType and varTypeMask]);
  end;
end;

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

{ TSocketForm }

procedure TtrmSocketForm.FormCreate(Sender: TObject);
begin
	Application.OnException := ClientHandleException;
	MyDispatchConnection:=ccGeneral;
	trmScktAdmCfg := TScktAdmCfg.Create;
  meCCIP.Text := trmScktAdmCfg.Address;
	FClosing := False;
	FCurItem := -1;
	FSortCol := -1;
  FSortColPerm := -1;
	FProgmanOpen := True;
	FAscendCompare := False;
  FAscendComparePerm := False;
  FAccptStop := False;
	Pages.ActivePage := Pages.Pages[0];
	SetEnabledControls(gbSrvSett, MyDispatchConnection.Connected);
  SetProcessAffinityMask(GetCurrentProcess, 1);
end;

procedure TtrmSocketForm.CheckValues;
begin
	StrToInt(PortNo.Text);
	StrToInt(Timeout.Text);
end;

function TtrmSocketForm.GetItemIndex: Integer;
begin
	Result := FCurItem;
end;

procedure TtrmSocketForm.SetItemIndex(Value: Integer);
var
	Selected: Boolean;
begin
	if (FCurItem <> Value) then
	try
		if ApplyAction.Enabled then ApplyAction.Execute;
	except
		PortList.ItemIndex := FCurItem;
		raise;
	end;
	if Value = -1 then Value := 0;
	PortList.ItemIndex := Value;
	FCurItem := PortList.ItemIndex;
	Selected := FCurItem <> -1;
	if Selected then	UpdatePortParamsControl;
	ClearModifications;
	PortNo.Enabled := Selected;
	Timeout.Enabled := Selected;
end;

procedure TtrmSocketForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  FProgmanOpen := False;
  if ApplyAction.Enabled then ApplyAction.Execute;
  MyDispatchConnection.Close;
  CanClose := True;
end;

procedure TtrmSocketForm.InitSettings;
begin
	if MyDispatchConnection.Connected then begin
    PortListUpdate;
		ItemIndex:=0;
		ShowHostAction.Checked := MyDispatchConnection.AppServer.ShowHost;
		RegisteredAction.Checked := MyDispatchConnection.AppServer.RegisteredOnly;
    FAccptStop := MyDispatchConnection.AppServer.GetAccepting;
		ShowCPUAffinity;
	end;
end;

procedure TtrmSocketForm.ShowCPUAffinity;
const
	cbNNamePrefix='cbCPU';
	cbNCaptionPrefix='CPU ';
	cEvenLeft=8;
	cOddLeft=78;
var
	i, iCnt, iOneCPUMask,
	iTop: integer;
	cbN: TCheckBox;
begin
	if MyDispatchConnection.Connected then begin
		if MyDispatchConnection.AppServer.SysAffMask<=0 then
			begin
				iCnt:=gbCPUAffinity.ControlCount;
				for i:=0 to iCnt do
					begin
						gbCPUAffinity.Controls[i].Enabled:=False;
						gbCPUAffinity.Controls[i].Visible:=False;
					end;
				gbCPUAffinity.Enabled:=False;
				gbCPUAffinity.Visible:=False;
				Exit;
			end;
		iTop:=cbCPU0.Top+cbCPU0.Height+Round(cbCPU0.Height/4);
		for i:=0 to MyDispatchConnection.AppServer.SysAffMask do
			begin
				iOneCPUMask:=$01 shl i;
				if iOneCPUMask> MyDispatchConnection.AppServer.SysAffMask then Break;
				case i of
					0:cbN:=cbCPU0;
					1:cbN:=cbCPU1;
				else 
          begin
            cbN:=TCheckBox(gbCPUAffinity.FindChildControl(cbNNamePrefix+IntToStr(i)));
            if (cbN = nil) then begin
              cbN:=TCheckBox.Create(Self);
						  cbN.Name:=cbNNamePrefix+IntToStr(i);
						  cbN.Caption:=cbNCaptionPrefix+IntToStr(i);
						  cbN.Tag:=iOneCPUMask;
						  cbN.Parent:=gbCPUAffinity;
						  cbN.Top:=iTop;
						  cbN.Width:=cbCPU0.Width;
              if Odd(i) then
                begin
                  cbN.Left:=cOddLeft;
                  iTop:=cbN.Top+cbN.Height+Round(cbN.Height/4);
                end
              else
                begin
                  cbN.Left:=cEvenLeft;
                  gbCPUAffinity.Height:=gbCPUAffinity.Height+cbN.Height+Round(cbN.Height/4);
                  gbSystem.Height:=gbSystem.Height+cbN.Height+Round(cbN.Height/4);
                  gbPorts.Height:=gbPorts.Height+cbN.Height+Round(cbN.Height/4);
                  pnlPorts.Height:=pnlPorts.Height+cbN.Height+Round(cbN.Height/4);
                  gbSrvSett.Height:=gbSrvSett.Height+cbN.Height+Round(cbN.Height/4);
                end;
            end;
					end;
				end;
				if cbN<>nil then
					begin
						cbN.Checked:=Longint(cbN.Tag and DWORD(MyDispatchConnection.AppServer.ProcessAffMask))=cbN.Tag;
						cbN.Enabled:=True;
						cbN.OnClick:=cbCPUNClick;
					end
			end;
		if (not Boolean(MyDispatchConnection.AppServer.IsWinNT))or
			(MyDispatchConnection.AppServer.SysAffMask<3) then
			begin
				iCnt:=gbCPUAffinity.ControlCount;
				for i:=0 to iCnt-1 do
					gbCPUAffinity.Controls[i].Enabled:=False;
				gbCPUAffinity.Enabled:=False;
			end;
	end;
end;

procedure TtrmSocketForm.UpdateStatus;
begin
  UserStatus.SimpleText := Format(SStatusLine,[ConnectionList.Items.Count]);
end;

procedure TtrmSocketForm.ApplyActionExecute(Sender: TObject);
var
  Idx: Integer;
begin
  if MyDispatchConnection.Connected then begin
    Idx := PortList.Items.IndexOf(PortNo.Text);
    if (Idx = -1) or (PortList.Items[ItemIndex] = PortNo.Text) then begin
      if (GetSelectedPort <> TControlConnection(MyDispatchConnection).Port) then begin
        if (MessageDlg(SErrChangeSettings, mtConfirmation, [mbYes, mbNo], 0) = idYes) then
          if MyDispatchConnection.AppServer.ModifyPort(Integer(SelectedSocket),
                                            StrToInt(PortNo.Text),
                                            TControlConnection(MyDispatchConnection).Port,
                                            StrToInt(Self.Timeout.Text)) then begin
            if PortList.Items[ItemIndex] <> PortNo.Text then
              PortList.Items[ItemIndex] := PortNo.Text;
          end;
        UpdatePortParamsControl;
      end
      else begin
        ShowMessage(SNotUntilRestart);
        if MyDispatchConnection.AppServer.ModifyPort(Integer(SelectedSocket),
                                          StrToInt(PortNo.Text),
                                          TControlConnection(MyDispatchConnection).Port,
                                          StrToInt(Self.Timeout.Text)) then begin
          if PortList.Items[ItemIndex] <> PortNo.Text then
            PortList.Items[ItemIndex] := PortNo.Text;
          UpdatePortParamsControl;
        end;
      end;
    end
    else begin
      ClearModifications;
      ItemIndex := Idx;
    end;
  end;
  ClearModifications;
end;

procedure TtrmSocketForm.ApplyActionUpdate(Sender: TObject);
begin
	ApplyAction.Enabled := PortNo.Modified or
                         Timeout.Modified;
	ApplyButton.Enabled := ApplyAction.Enabled;
end;

procedure TtrmSocketForm.ClearModifications;
begin
	PortNo.Modified  := False;
	Timeout.Modified := False;
end;

procedure TtrmSocketForm.DisconnectActionUpdate(Sender: TObject);
begin
	DisconnectAction.Enabled := ConnectionList.SelCount > 0;
  ConnectedActionUpdate(Self);
end;

procedure TtrmSocketForm.ShowHostActionExecute(Sender: TObject);
begin
	ShowHostAction.Checked := not ShowHostAction.Checked;
	if MyDispatchConnection.Connected then begin
		MyDispatchConnection.AppServer.ShowHost:=ShowHostAction.Checked;
		RefreshAction.Execute;
	end;
end;
{
procedure TtrmSocketForm.DisconnectActionExecute(Sender: TObject);
var
	i: integer;
begin
  if MessageDlg(SQueryDisconnect, mtConfirmation, [mbYes, mbNo], 0) = mrNo then
    Exit;
  while ConnectionList.SelCount > 0 do begin
  	i := 0;
  	while i < ConnectionList.Items.Count do
  		with ConnectionList.Items[i] do begin
  			if Selected then
  				if MyDispatchConnection.Connected then
  					MyDispatchConnection.AppServer.RemoveConnect(Integer(Data))
  				else break;
  			inc(i);
      end;
  end;
end;
}

procedure TtrmSocketForm.DisconnectActionExecute(Sender: TObject);
var
	i, j, DelCount:	Integer;
  DelArray: Variant;
begin
  if MessageDlg(SQueryDisconnect, mtConfirmation, [mbYes, mbNo], 0) = mrNo then
    Exit;
  DelArray := varNull;
  DelCount:=0;
  i := 0;
  while i < ConnectionList.Items.Count do begin
    with ConnectionList.Items[i] do begin
      if Selected then Inc(DelCount);
    end;
    Inc(i);
  end;
  if DelCount>0 then begin
    DelArray := VarArrayCreate([0,DelCount-1], varInteger);
    i:=0; j:=0;
    while i < ConnectionList.Items.Count do begin
      with ConnectionList.Items[i] do begin
        if Selected then begin
          DelArray[j] := Integer(Data);
          Delete;
          Inc(j);
        end
        else
          Inc(i);
      end;
    end;
    if MyDispatchConnection.Connected then
      MyDispatchConnection.AppServer.RemoveConnect(DelArray);
  end;
end;

procedure TtrmSocketForm.RemovePortActionUpdate(Sender: TObject);
begin
  RemovePortAction.Enabled := (PortList.Items.Count > 1) and (ItemIndex <> -1);
end;

procedure TtrmSocketForm.AddPortActionExecute(Sender: TObject);
var
	SD: Integer;
	Idx: Integer;
begin
  if MyDispatchConnection.Connected then begin	  
    if (Pages.ActivePage<>PropPage) then Exit;
    CheckValues;
    PortNo.Value := PortNo.Value + 1;
    Idx := PortList.Items.IndexOf(PortNo.Text);
    if Idx = -1 then begin
      SD := MyDispatchConnection.AppServer.AddPort(Integer(Round(PortNo.Value)));
      if SD>0 then Idx := PortList.Items.AddObject(PortNo.Text,TObject(SD))
      else Idx := 0;
      PortNo.Modified := True;
      ItemIndex := Idx;
      PortNo.SetFocus;
    end
    else begin
      PortList.ItemIndex := Idx;
    end;
  end;
end;

procedure TtrmSocketForm.RemovePortActionExecute(Sender: TObject);
var
	iIndex: integer;
begin
  if MyDispatchConnection.Connected then begin	  
    if (Pages.ActivePage<>PropPage) then Exit;
    CheckValues;
    if GetSelectedPort = TControlConnection(MyDispatchConnection).Port then
      ShowMessage(SNotUntilRestart);
    if MyDispatchConnection.AppServer.RemovePort(Integer(SelectedSocket),
  	   TControlConnection(MyDispatchConnection).Port)then begin
  	  iIndex:=ItemIndex;
  	  PortList.Items.Delete(ItemIndex);
  	  FCurItem := -1;
  	  while iIndex>PortList.Items.Count-1 do Dec(iIndex);
  	  ItemIndex := iIndex;
    end;
  end;
end;

procedure TtrmSocketForm.PortListClick(Sender: TObject);
begin
	ItemIndex := PortList.ItemIndex;
end;

procedure TtrmSocketForm.ConnectionListCompare(Sender: TObject; Item1,
	Item2: TListItem; Data: Integer; var Compare: Integer);
begin
	if Data = -1 then
		Compare := AnsiCompareText(Item1.Caption, Item2.Caption) 
  else
    if (Data = 2) or (Data = 3) then begin
      try
        if (StrToDateTime(Item1.SubItems[Data]) > StrToDateTime(Item2.SubItems[Data])) then Compare := 1 else
        if (StrToDateTime(Item1.SubItems[Data]) < StrToDateTime(Item2.SubItems[Data])) then Compare := -1 else
        Compare := 0;
      except
		    Compare := AnsiCompareText(Item1.SubItems[Data], Item2.SubItems[Data]);
      end;
    end
    else
		  Compare := AnsiCompareText(Item1.SubItems[Data], Item2.SubItems[Data]);
	if (not FAscendCompare) and (Compare<>0) then
		Compare := -Compare;
end;

procedure TtrmSocketForm.ConnectionListColumnClick(Sender: TObject;
	Column: TListColumn);
begin
	FSortCol := Column.Index - 1;
	FAscendCompare := not FAscendCompare;
  ConnectionList.CustomSort(nil, FSortCol)
end;

procedure TtrmSocketForm.IntegerExit(Sender: TObject);
begin
	try
		StrToInt(TRxSpinEdit(Sender as TRxSpinEdit).Text);
	except
		ActiveControl := PortNo;
		if Active then raise;
	end;
end;

procedure TtrmSocketForm.RegisteredActionExecute(Sender: TObject);
begin
	if MyDispatchConnection.Connected then begin
		RegisteredAction.Checked := not RegisteredAction.Checked;
		MyDispatchConnection.AppServer.RegisteredOnly:=RegisteredAction.Checked;
		ShowMessage(SNotUntilRestart);
	end;
end;

procedure TtrmSocketForm.RefreshActionExecute(Sender: TObject);
begin
	sbRefresh.Enabled := False;
	if FProgmanOpen then RefreshConnections;
	sbRefresh.Enabled := True;
end;

procedure TtrmSocketForm.cbCPUNClick(Sender: TObject);
begin
	if (Sender=nil)or(not (Sender is TCheckBox))or(ActiveControl<>Sender) then Exit;
	btnApplyAffinity.Enabled:=True;
end;

procedure TtrmSocketForm.btnApplyAffinityClick(Sender: TObject);
var
	i,iCnt: integer;
	iCPUAffinity: DWORD;
begin
	if MyDispatchConnection.Connected then begin
		if not btnApplyAffinity.Enabled then Exit;
		iCPUAffinity:=0;
		iCnt:=gbCPUAffinity.ControlCount;
		for i:=0 to iCnt-1 do
			if (gbCPUAffinity.Controls[i] is TCheckBox)and
				 (TCheckBox(gbCPUAffinity.Controls[i]).Enabled)and
				 (TCheckBox(gbCPUAffinity.Controls[i]).Checked) then
				iCPUAffinity:=iCPUAffinity+DWORD(TCheckBox(gbCPUAffinity.Controls[i]).Tag);
		try
			MyDispatchConnection.AppServer.CPUAffinity:=iCPUAffinity;
			btnApplyAffinity.Enabled:=False;
		finally
			ShowCPUAffinity;
		end;
	end;
end;


procedure TtrmSocketForm.GetConnectionsActionExecute(Sender: TObject);
begin
	if FProgmanOpen then begin
		GetConnections;
  end;
end;

procedure TtrmSocketForm.ClientHandleException(Sender: TObject; E: Exception);
begin
	Disconnect(False);
	Application.ShowException(E);
end;

function TtrmSocketForm.GetSelectedSocket: Pointer;
begin
  Result := Pointer(PortList.Items.Objects[ItemIndex]);
end;

function TtrmSocketForm.GetSelectedPort: Integer;
begin
  Result := StrToInt(PortList.Items.Strings[ItemIndex]);
end;

procedure TtrmSocketForm.UpdateStatusActionUpdate(Sender: TObject);
begin
	UpdateStatus;
end;

procedure TtrmSocketForm.ConnectedActionUpdate(Sender: TObject);
var
	Connected: Boolean;
begin
	Connected := MyDispatchConnection.Connected;
	btConnect.Down := Connected;
	if Connected then btConnect.Hint := DisconnectHint
  else btConnect.Hint := ConnectHint;
	meCCIP.Enabled :=  not Connected;
	gbSrvSett.Enabled := Connected;
	StatPage.TabVisible := Connected;
  if (not pnlPermit.Visible) and FAccptStop then begin
//    meNewIp.SetFocus;
    GetPermits;
    meNewIp.SelectAll;
    meNewIp.SetSelTextBuf('127.0.0.1');
  end;
  pnlPermit.Visible := FAccptStop;
  if not Connected and (Connectionlist.Items.Count > 0) then
    ConnectionList.Items.Clear;
  if not Connected and (lvPermit.Items.Count > 0) then
    lvPermit.Items.Clear;
  if not Connected then begin
    PortList.Clear;
    PortNo.Value := 1;
    Timeout.Value := 0;
    Pages.ActivePageIndex := 0;
    SetEnabledControls(gbSrvSett, Connected);
  end;    
end;

procedure TtrmSocketForm.Connect;
begin
	TControlConnection(MyDispatchConnection).Port := FPort;
  TControlConnection(MyDispatchConnection).SetRemoteAddress(FIPAddr);
  TControlConnection(MyDispatchConnection).Host :=  FHost;
	MyDispatchConnection.Open;
	SetEnabledControls(gbSrvSett, MyDispatchConnection.Connected);
	if MyDispatchConnection.Connected then begin
    trmScktAdmCfg.Address := meCCIP.EditText;
		InitSettings;
  end;
end;

procedure TtrmSocketForm.Disconnect(Value: Boolean = True);
begin
  if Value then
	  if MyDispatchConnection.Connected then
		  MyDispatchConnection.AppServer.SetCallBack(varNull);
	MyDispatchConnection.Connected := False;
  FAccptStop := False;
  ConnectedActionUpdate(Self);
end;

procedure TtrmSocketForm.GetConnections;
var
	j,k: integer;
  ResArray: Variant;
	Item: TListItem;
begin
  with ConnectionList do begin
    ResArray := MyDispatchConnection.AppServer.GetClientsInfo;
    if VarIsArray(ResArray) then begin
      for j:=0 to VarArrayHighBound(ResArray,1)-1 do begin
        try k:=Integer(ResArray[j,0]);
        except k:=0; end;
        if k>0 then begin
          Item := Items.Add;
          try
            Item.Caption := ResArray[j,0];
            Item.SubItems.Add(ResArray[j,1]);
            Item.SubItems.Add(ResArray[j,5]);
            Item.SubItems.Add(ResArray[j,2]);
            Item.SubItems.Add(ResArray[j,3]);
            Item.Data := Pointer(Integer(ResArray[j,4]));
          finally
          end;
        end;
      end;
      if FSortCol <> -1 then CustomSort(nil, FSortCol);
    end;
	end;
end;

procedure TtrmSocketForm.GetPermits;
var
	j: integer;
  ResArray: Variant;
	Item: TListItem;
begin
  if MyDispatchConnection.Connected then 
    with lvPermit do begin
      ResArray := MyDispatchConnection.AppServer.GetPermits;
      if VarIsArray(ResArray) then begin
        Items.Clear;
        for j:=0 to VarArrayHighBound(ResArray,1)-1 do begin
          Item := Items.Add;
          try
            Item.Caption := ResArray[j,0];
            Item.Data := Pointer(Integer(ResArray[j,1]));
          finally
          end;
        end;
        if FSortColPerm <> -1 then CustomSort(nil, FSortColPerm);
      end;
    end;
end;

procedure TtrmSocketForm.RefreshConnections;
var
	j,i: integer;
  ResArray: Variant;
  Exist:  Boolean;
begin
	with ConnectionList do begin
    ResArray := MyDispatchConnection.AppServer.GetClientsInfo;
    if VarIsArray(ResArray) then begin
      i:=0;
      while i <	Items.Count do begin
        Exist := False;
        for j:=0 to VarArrayHighBound(ResArray,1)-1 do
          if (Integer(Items.Item[i].Data) = Integer(ResArray[j,4])) then begin
            Exist := True;
            break;
          end;
    	  if Exist then begin
    		  Items.Item[i].SubItems.Strings[1]:=ResArray[j,5];
    		  Items.Item[i].SubItems.Strings[3]:=ResArray[j,3];
    		  inc(i);
    	  end
    	  else
          try
           Items.Delete(i);
          except end;
      end;
      if FSortCol <> -1 then CustomSort(nil, FSortCol);
    end;
	end;
end;

procedure TtrmSocketForm.FormDestroy(Sender: TObject);
begin
	trmScktAdmCfg.WriteCfg;
end;

procedure TtrmSocketForm.UpdatePortParamsControl;
var
	Port,
	TimeOut_: Integer;
begin
  if MyDispatchConnection.Connected then begin
    MyDispatchConnection.AppServer.GetPortParams(Integer(PortList.Items.Objects[FCurItem]),
  																						 Port,
  																						 TimeOut_);
    PortNo.Value := Port;
    Timeout.Value := Timeout_;
    ClearModifications;
  end;
end;

procedure TtrmSocketForm.ConnectedActionExecute(Sender: TObject);
begin
	if not MyDispatchConnection.Connected then begin
    try
      ParseIP_ConnectAction.Execute;
      Connect;
      GetConnectionsAction.Execute;
      PropPage.SetFocus;
    except
      on E: Exception do
        MessageBox(Self.Handle, PChar(E.Message),
        PChar(ErrorTCP), MB_OK or MB_TASKMODAL or
        MB_ICONSTOP);
    end;
  end
	else begin
    Disconnect;
  end;
end;

procedure TtrmSocketForm.AddPortActionUpdate(Sender: TObject);
begin
	AddPortAction.Enabled := MyDispatchConnection.Connected;
end;

procedure TtrmSocketForm.AcceptActionExecute(Sender: TObject);
begin
	if MyDispatchConnection.Connected then begin
    FAccptStop := MyDispatchConnection.AppServer.SuspendAccepting;
//    if FAccptStop then begin
//      GetPermits;
//      meNewIp.SelectAll;
//      meNewIp.SetSelTextBuf('127.0.0.1');
//    end;
  end;
end;

procedure TtrmSocketForm.AcceptActionUpdate(Sender: TObject);
begin
	btnAcceptStop.Down := FAccptStop;
  pnlPermit.Visible := FAccptStop;
  if not FAccptStop and (lvPermit.Items.Count > 0) then
    lvPermit.Items.Clear;
	if FAccptStop then btnAcceptStop.Hint := AcceptStartHint
  else btnAcceptStop.Hint := AcceptStopHint;
end;

procedure TtrmSocketForm.SelectAllActionExecute(Sender: TObject);
var
  i: integer;
begin
  ConnectionList.SetFocus;
  with ConnectionList.Items do begin
    BeginUpdate;
    for i := 0 to Count-1 do
      Item[i].Selected := true;
    EndUpdate;
  end
end;

procedure TtrmSocketForm.SetEnabledControls(const GroupBox: TGroupBox; Value: Boolean);
var
	i: Integer;
begin
	for i:=0 to	GroupBox.ControlCount-1 do begin
		GroupBox.Controls[i].Enabled := Value;
		if (GroupBox.Controls[i] is TGroupBox) then
			SetEnabledControls(TGroupBox(GroupBox.Controls[i]), Value);
	end;
end;

procedure TtrmSocketForm.AddClient(var Msg: TMessage);
var
	k: integer;
	Item: TListItem;
  Data: OleVariant;  
  vData: IDataBlock;
  Flags: TVarFlags;
begin
  vData := IDataBlock(msg.LParam);
  vData._Release;
  Data := ReadVariant(Flags, vData);
  with ConnectionList do begin
    if VarIsArray(Data) then begin
      try k:=Integer(Data[0]);
      except k:=0; end;
      if k>0 then begin
        Item := Items.Add;
        try
          Item.Caption := Data[0];
          Item.SubItems.Add(Data[1]);
          Item.SubItems.Add(Data[5]);
          Item.SubItems.Add(Data[2]);
          Item.SubItems.Add(Data[3]);
          Item.Data := Pointer(Integer(Data[4]));
        finally
          if FSortCol <> -1 then CustomSort(nil, FSortCol);
        end;
      end;
    end;
  end;
end;

procedure TtrmSocketForm.ShowHost(var Msg: TMessage);
var
	i: integer;
	Item: TListItem;
  Data: OleVariant;  
  vData: IDataBlock;
  Flags: TVarFlags;
begin
  vData := IDataBlock(msg.LParam);
  vData._Release;
  Data := ReadVariant(Flags, vData);
  with ConnectionList do begin
		if VarIsArray(Data) then begin
			i:=0;
			while i <	Items.Count do begin
				if (Integer(Items.Item[i].Data) = Integer(Data[4])) then begin
					Item := Items.Item[i];
					Item.SubItems.Strings[1]:=Data[5];
					Item.SubItems.Strings[3]:=Data[3];
					break;
				end;
				inc(i);
			end;
			if FSortCol <> -1 then CustomSort(nil, FSortCol);
		end;
	end;
end;

procedure TtrmSocketForm.UpdateFromServer(var Msg: TMessage);
var
  i: Integer;
var
	Connected: Boolean;
begin
	Connected := MyDispatchConnection.Connected;
	if MyDispatchConnection.Connected then begin
    PortListUpdate;
		ItemIndex:=0;
		ShowHostAction.Checked := MyDispatchConnection.AppServer.ShowHost;
		RegisteredAction.Checked := MyDispatchConnection.AppServer.RegisteredOnly;
    FAccptStop := MyDispatchConnection.AppServer.GetAccepting;
		ShowCPUAffinity;
    btConnect.Down := Connected;
    if Connected then btConnect.Hint := DisconnectHint
    else btConnect.Hint := ConnectHint;
    meCCIP.Enabled :=  not Connected;
    gbSrvSett.Enabled := Connected;
    StatPage.TabVisible := Connected;
    if FAccptStop then GetPermits;
    if (not pnlPermit.Visible) and FAccptStop then begin
      meNewIp.SelectAll;
      meNewIp.SetSelTextBuf('127.0.0.1');
    end;
    pnlPermit.Visible := FAccptStop;
    btnAcceptStop.Down := FAccptStop;
    pnlPermit.Visible := FAccptStop;
    if not FAccptStop and (lvPermit.Items.Count > 0) then
      lvPermit.Items.Clear;
    if FAccptStop then btnAcceptStop.Hint := AcceptStartHint
    else btnAcceptStop.Hint := AcceptStopHint;
  end;
end;

procedure TtrmSocketForm.RemoveClient(var Msg: TMessage); 
var
	i: integer;
  Data: OleVariant;  
  vData: IDataBlock;
  Flags: TVarFlags;
begin
  vData := IDataBlock(msg.LParam);
  vData._Release;
  Data := ReadVariant(Flags, vData);
  with ConnectionList do begin
    i:=0;
    while i <	Items.Count do begin
      if (Integer(Items.Item[i].Data) = Integer(Data)) then begin
        Items.Delete(i);
        break;
      end;
      inc(i);
    end;
    if FSortCol <> -1 then CustomSort(nil, FSortCol);
  end;
end;

var
  OldInitProc: Pointer = nil;

procedure InstallRemoteUtil;

const
  StrPSDispatch = '{00020420-0000-0000-C000-000000000046}';

  LIBID_TScktSrv: TGUID = '{88C3B8E0-BCD7-4B1F-B031-AA2E345BC7BA}';

  IID_IServer: TGUID = '{F9642A0E-E1E8-42F9-9920-DDEAD8F4B166}';
  CLASS_Server: TGUID = '{8227CB5C-4F50-49E4-9BE8-A0DCE86A184C}';
  IID_IClient: TGUID = '{ABA0724A-EFF6-4326-A1EA-36592B2E2DD7}';

  TScktSrvMajorVersion = 1;
  TScktSrvMinorVersion = 0;
var
  Stream: TFileStream;
  FResource: HRSRC;
  PathName: String;
  ResourceSize: Integer;
  ResourcePtr: PChar;
  vTScktSrv: THandle;
  lenSysDir: Cardinal;

begin
  if OldInitProc <> nil then TProcedure(OldInitProc);
  lenSysDir := GetSystemDirectory(nil,0);
  SetLength(PathName,lenSysDir);
  GetSystemDirectory(PChar(PathName), lenSysDir);
  PathName := Trim(PathName) + '\TScktSrv.tlb';
  if (not FileExists(PathName)) then begin
    Stream := TFileStream.Create(PathName, fmCreate);
    try
      FResource := FindResource(HInstance, 'TScktSrv', RT_RCDATA);
      ResourceSize := SizeofResource(HInstance, FResource);
      vTScktSrv := LoadResource(HInstance, FResource);
      ResourcePtr := LockResource(vTScktSrv);
      Stream.Write(ResourcePtr^, ResourceSize);
      UnlockResource(vTScktSrv);
      FreeResource(vTScktSrv);
    finally
      Stream.Free;
    end;
    
    CreateRegKey('TypeLib\'+GUIDToString(LIBID_TScktSrv)+'\1.0','','TScktSrv Library');
    CreateRegKey('TypeLib\'+GUIDToString(LIBID_TScktSrv)+'\1.0\FLAGS','','0');
    CreateRegKey('TypeLib\'+GUIDToString(LIBID_TScktSrv)+'\1.0\0\win32','',PathName);
    CreateRegKey('TypeLib\'+GUIDToString(LIBID_TScktSrv)+'\1.0\HELPDIR','','');
    CreateRegKey('Interface\'+GUIDToString(IID_IServer),'','IServer');
    CreateRegKey('Interface\'+GUIDToString(IID_IServer)+'\ProxyStubClsid','',StrPSDispatch);
    CreateRegKey('Interface\'+GUIDToString(IID_IServer)+'\ProxyStubClsid32','',StrPSDispatch);
    CreateRegKey('Interface\'+GUIDToString(IID_IServer)+'\TypeLib','',GUIDToString(LIBID_TScktSrv));
    CreateRegKey('Interface\'+GUIDToString(IID_IServer)+'\TypeLib','Version',
                  IntToStr(TScktSrvMajorVersion)+'.'+IntToStr(TScktSrvMinorVersion));
    CreateRegKey('Interface\'+GUIDToString(IID_IClient),'','IClient');
    CreateRegKey('Interface\'+GUIDToString(IID_IClient)+'\ProxyStubClsid','',StrPSDispatch);
    CreateRegKey('Interface\'+GUIDToString(IID_IClient)+'\ProxyStubClsid32','',StrPSDispatch);
    CreateRegKey('Interface\'+GUIDToString(IID_IClient)+'\TypeLib','',GUIDToString(LIBID_TScktSrv));
    CreateRegKey('Interface\'+GUIDToString(IID_IClient)+'\TypeLib','Version',
                  IntToStr(TScktSrvMajorVersion)+'.'+IntToStr(TScktSrvMinorVersion));
  end;
end;

procedure TtrmSocketForm.RemovePermitActionUpdate(Sender: TObject);
begin
	RemovePermitAction.Enabled := lvPermit.SelCount > 0;
end;

procedure TtrmSocketForm.RemovePermitActionExecute(Sender: TObject);
var
	i: integer;
begin
  while lvPermit.SelCount > 0 do begin
  	i := 0;
  	while i < lvPermit.Items.Count do
  		with lvPermit.Items[i] do begin
  			if Selected then
  				if MyDispatchConnection.Connected then begin
  					MyDispatchConnection.AppServer.RemovePermit(Integer(Data));
            lvPermit.Items.Delete(i);
          end
  				else break;
  			inc(i);
      end;
  end;
  if FSortColPerm <> -1 then lvPermit.CustomSort(nil, FSortColPerm);
end;

procedure TtrmSocketForm.lvPermitColumnClick(Sender: TObject;
  Column: TListColumn);
begin
	FSortColPerm := Column.Index - 1;
	FAscendComparePerm := not FAscendComparePerm;
	lvPermit.CustomSort(nil, FSortColPerm);
end;

procedure TtrmSocketForm.lvPermitCompare(Sender: TObject; Item1,
  Item2: TListItem; Data: Integer; var Compare: Integer);
begin
	if Data = -1 then
		Compare := AnsiCompareText(Item1.Caption, Item2.Caption) else
		Compare := AnsiCompareText(Item1.SubItems[Data], Item2.SubItems[Data]);
	if (not FAscendComparePerm) and (Compare<>0) then
		Compare := -Compare;
end;

procedure TtrmSocketForm.AddPermitActionUpdate(Sender: TObject);
begin
  AddPermitAction.Enabled := meNewIp.Modified;
end;

procedure TtrmSocketForm.AddPermitActionExecute(Sender: TObject);
var
//  Contin: Boolean;
  IP,aIP: String;
  Data: Variant;
	Item: TListItem;
begin
  if MyDispatchConnection.Connected then begin
    IP := StringReplace(meNewIP.EditText,' ','',[rfReplaceAll]);
    if ResolveAddr(IP) then
      aIP := IP
    else
      aIP := UpperCase(IP);
    if MyDispatchConnection.Connected then begin
      Data := MyDispatchConnection.AppServer.AddPermit_GetData(aIP);
      if VarIsArray(Data) then
        with trmSocketForm.lvPermit do begin
          Item := Items.Add;
          try
            Item.Caption := Data[0];
            Item.Data := Pointer(Integer(Data[1]));
          finally
            if trmSocketForm.FSortColPerm <> -1 then 
              CustomSort(nil, trmSocketForm.FSortColPerm);
          end;
        end;
  {
        MessageBox(Self.Handle, PChar(WrongIP),
        PChar(ErrorTCP), MB_OK or MB_TASKMODAL or
        MB_ICONSTOP);
  }      
      meNewIp.Clear;
      meNewIp.SetFocus;
    end;
  end;
end;

procedure TtrmSocketForm.meNewIPKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) then AddPermitAction.Execute;
end;

{
procedure TtrmSocketForm.lvPermitExit(Sender: TObject);
var
  i: integer;
begin
  with lvPermit.Items do begin
    BeginUpdate;
    for i := 0 to Count-1 do
      if Item[i].Selected then
        Item[i].Selected := false;
    EndUpdate;
  end;
  meNewIp.SetFocus;
end;
}

procedure TtrmSocketForm.miConnectClick(Sender: TObject);
begin
  ConnectedActionExecute(Sender);
end;

procedure TtrmSocketForm.PopupActionExecute(Sender: TObject);
begin
  ConnectedActionExecute(Sender);
end;

procedure TtrmSocketForm.PagesChange(Sender: TObject);
begin
  Pages.ActivePage.SetFocus;  
end;

procedure TtrmSocketForm.PortListUpdate;
var
  ResArray: Variant;
  j, Port, Dat: Integer;
begin
  ResArray := MyDispatchConnection.AppServer.GetPortListData;
  if VarIsArray(ResArray) then begin
    PortList.Items.Clear;
    for j:=0 to VarArrayHighBound(ResArray,1)-1 do begin
      try
        Port := Integer(ResArray[j,0]);
        Dat := Integer(ResArray[j,1]);
	      trmSocketForm.PortList.Items.AddObject(IntToStr(Port), TObject(Dat));
      finally
      end;
    end;
  end;
end;

procedure TtrmSocketForm.meCCIPKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) then
    ConnectedAction.Execute;
end;

procedure TtrmSocketForm.ParseIP_ConnectActionExecute(Sender: TObject);
var
  Contin: Boolean;
  ConnectStr,Port,IP: String;
begin
  FHost := '';
  FIPAddr := '';
  Contin := True;
  ConnectStr := Trim(StringReplace(meCCIP.EditText,' ','',[rfReplaceAll]));
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

procedure TtrmSocketForm.ccGeneralNotifyClientFromServer(Flag: TNotifyFlag;
  Data: OleVariant);
var  
  vData: IDataBlock;
begin
  case Flag of
    vfAddClient: begin
      vData := TDataBlock.Create as IDataBlock;
      WriteVariant(Data, vData);
      vData._AddRef;
      PostMessage(Self.Handle, WM_ADDCLIENT, 0, Integer(Pointer(vData)));
    end;
    vfRemoveClient: begin
      vData := TDataBlock.Create as IDataBlock;
      WriteVariant(Data, vData);
      vData._AddRef;
      PostMessage(Self.Handle, WM_REMOVECLIENT, 0, Integer(Pointer(vData)));
    end;
    vfHost: begin
      vData := TDataBlock.Create as IDataBlock;
      WriteVariant(Data, vData);
      vData._AddRef;
      PostMessage(Self.Handle, WM_SHOWHOST, 0, Integer(Pointer(vData)));
    end;
    vfGenAction: PostMessage(Self.Handle, WM_UPDFROMSRV, 0, 0);
  end
end;

initialization
  OldInitProc := InitProc;
  InitProc := @InstallRemoteUtil;

end.
