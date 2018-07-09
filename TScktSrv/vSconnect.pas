
{*******************************************************}
{                                                       }
{       Borland Delphi Visual Component Library         }
{       Streamed Connection classes                     }
{                                                       }
{       Copyright (c) 1997,99 Inprise Corporation       }
{                                                       }
{*******************************************************}

unit vSconnect;

{$R-}

interface

uses
	Windows, Messages, Classes, SysUtils, MConnect,
	vScktComp, WinSock, WinINet;

type

	{ IDataBlock }

	IDataBlock = interface(IUnknown)
	['{CA6564C2-4683-11D1-88D4-00A0248E5091}']
		function GetBytesReserved: Integer; stdcall;
		function GetMemory: Pointer; stdcall;
		function GetSize: Integer; stdcall;
		procedure SetSize(Value: Integer); stdcall;
		function GetStream: TStream; stdcall;
		function GetSignature: Integer; stdcall;
		procedure SetSignature(Value: Integer); stdcall;
		procedure Clear; stdcall;
		function Write(const Buffer; Count: Integer): Integer; stdcall;
		function Read(var Buffer; Count: Integer): Integer; stdcall;
		procedure IgnoreStream; stdcall;
		function InitData(Data: Pointer; DataLen: Integer; CheckLen: Boolean): Integer; stdcall;
		property BytesReserved: Integer read GetBytesReserved;
		property Memory: Pointer read GetMemory;
		property Signature: Integer read GetSignature write SetSignature;
		property Size: Integer read GetSize write SetSize;
		property Stream: TStream read GetStream;
	end;

	{ ISendDataBlock }

	ISendDataBlock = interface
	['{87AD1043-470E-11D1-88D5-00A0248E5091}']
		function Send(const Data: IDataBlock; WaitForResult: Boolean): IDataBlock; stdcall;
	end;

	{ ITransport }

	ITransport = interface(IUnknown)
	['{CA6564C1-4683-11D1-88D4-00A0248E5091}']
		function GetWaitEvent: THandle; stdcall;
		function GetConnected: Boolean; stdcall;
		procedure SetConnected(Value: Boolean); stdcall;
		function Receive(WaitForInput: Boolean; Context: Integer): IDataBlock; stdcall;
		function Send(const Data: IDataBlock): Integer; stdcall;
		property Connected: Boolean read GetConnected write SetConnected;
  end;

  TDataBlock = class(TInterfacedObject, IDataBlock)
  private
    FStream: TMemoryStream;
    FReadPos: Integer;
    FWritePos: Integer;
    FIgnoreStream: Boolean;
  protected
    { IDataBlock }
    function GetBytesReserved: Integer; stdcall;
    function GetMemory: Pointer; stdcall;
    function GetSize: Integer; stdcall;
    procedure SetSize(Value: Integer); stdcall;
		function GetStream: TStream; stdcall;
    function GetSignature: Integer; stdcall;
    procedure SetSignature(Value: Integer); stdcall;
    procedure Clear; stdcall;
    function Write(const Buffer; Count: Integer): Integer; stdcall;
    function Read(var Buffer; Count: Integer): Integer; stdcall;
    procedure IgnoreStream; stdcall;
    function InitData(Data: Pointer; DataLen: Integer; CheckLen: Boolean): Integer; stdcall;
    property BytesReserved: Integer read GetBytesReserved;
    property Memory: Pointer read GetMemory;
    property Signature: Integer read GetSignature write SetSignature;
    property Size: Integer read GetSize write SetSize;
    property Stream: TStream read GetStream;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  { TDataBlockInterpreter }

// New WSAIoctl Options

const

  IOC_IN              = $80000000;
	IOC_VENDOR          = $18000000;
  
  SIO_KEEPALIVE_VALS  = 4 or IOC_VENDOR or IOC_IN;

	FD_MAX_EVENTS    = 8;

type

  tcp_keepalive = record 
      onoff: u_long;
      keepalivetime: u_long;
      keepaliveinterval: u_long;
  end;
  
//	WinSock 2 extension -- data type for WSAEnumNetworkEvents()
	WSAEVENT = THandle;
	PWSAEVENT = ^WSAEVENT;
	LPWSAEVENT = PWSAEVENT;

	TWSANetworkEvents = record
		lNetworkEvents: LongInt;
		iErrorCode: Array[0..FD_MAX_EVENTS-1] of Integer;
	end;
	PWSANetworkEvents = ^TWSANetworkEvents;
	LPWSANetworkEvents = PWSANetworkEvents;

  WSANETWORKEVENTS = TWSANetworkEvents;

const  
  { Action Signatures }

  CallSig                 = $DA00; // Call signature
  ResultSig               = $DB00; // Result signature
  asError                 = $01;   // Specify an exception was raised
  asInvoke                = $02;   // Specify a call to Invoke
	asGetID                 = $03;   // Specify a call to GetIdsOfNames
  asCreateObject          = $04;   // Specify a com object to create
  asFreeObject            = $05;   // Specify a dispatch to free
	asCreateControlObject   = $06;   // Specify a com control object to create
	asFreeControlObject     = $07;   // Specify a dispatch to control free

  asNotify                = $0b;   // for mechanism retrieves host name 
  asNotifyAddClient       = $0800;   // Specify a callback to
  asNotifyRemoveClient    = $0900;   // control communications
  asNotifyHost            = $0100;
  asNotifyGenAction       = $0e00;
  asLoMask                = $FF;
  asHiMask                = $FF00;

  asErrorSocket           = $0a;   // Specify a error winsocket
  asGetServers            = $10;   // Get classname list
  asGetGUID               = $11;   // Get GUID for ClassName
  asGetAppServers         = $12;   // Get AppServer classname list
  asMask                  = $FF;   // Mask for action
  asCmd                   = $400;   // Mask for action

  
type

  PIntArray = ^TIntArray;
  TIntArray = array[0..0] of Integer;

  PVariantArray = ^TVariantArray;
  TVariantArray = array[0..0] of OleVariant;

  TVarFlag = (vfByRef, vfVariant);
  TVarFlags = set of TVarFlag;

  EInterpreterError = class(Exception);

  TDataDispatch = class;

  TDataBlockInterpreter = class
	protected
		FDispatchList: TList;
		FDispList: OleVariant;
		FSendDataBlock: ISendDataBlock;
		FCheckRegValue: string;
		function GetVariantPointer(const Value: OleVariant): Pointer;
		procedure CopyDataByRef(Source: TVarData; var Dest: TVarData);
		function ReadArray(VType: Integer; const Data: IDataBlock): OleVariant;
		procedure WriteArray(const Value: OleVariant; const Data: IDataBlock);
		procedure DoException(const Data: IDataBlock);
		procedure AddDispatch(Value: TDataDispatch);
		procedure RemoveDispatch(Value: TDataDispatch);
		function InternalCreateObject(const ClassID: TGUID): OleVariant; virtual;
		function CreateObject(const Name: string): OleVariant; virtual;
		function StoreObject(const Value: OleVariant): Integer; virtual;
		function LockObject(ID: Integer): IDispatch; virtual;
		procedure UnlockObject(ID: Integer; const Disp: IDispatch); virtual;
		procedure ReleaseObject(ID: Integer); virtual;
		function CanCreateObject(const ClassID: TGUID): Boolean; virtual;
		{Sending Calls}
		procedure CallFreeObject(DispatchIndex: Integer);
		function CallGetIDsOfNames(DispatchIndex: Integer; const IID: TGUID; Names: Pointer;
			NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
		function CallInvoke(DispatchIndex, DispID: Integer; const IID: TGUID; LocaleID: Integer;
			Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
		function CallGetServerList: OleVariant;
		{Receiving Calls}
		procedure DoCreateObject(const Data: IDataBlock);
		procedure DoFreeObject(const Data: IDataBlock);
		procedure DoGetIDsOfNames(const Data: IDataBlock);
		procedure DoInvoke(const Data: IDataBlock);
		function DoCustomAction(Action: Integer; const Data: IDataBlock): Boolean; virtual;
		procedure DoGetAppServerList(const Data: IDataBlock);
		procedure DoGetServerList(const Data: IDataBlock);
	public
		constructor Create(SendDataBlock: ISendDataBlock; CheckRegValue: string);
		destructor Destroy; override;
		function CallCreateObject(Name: string): OleVariant;
		procedure InterpretData(const Data: IDataBlock);
		function ReadVariant(out Flags: TVarFlags; const Data: IDataBlock): OleVariant;
		procedure WriteVariant(const Value: OleVariant; const Data: IDataBlock);
	end;

{ TDataDispatch }

	TDataDispatch = class(TInterfacedObject, IDispatch)
	private
		FDispatchIndex: Integer;
		FInterpreter: TDataBlockInterpreter;
	protected
		property DispatchIndex: Integer read FDispatchIndex;
		{ IDispatch }
		function GetTypeInfoCount(out Count: Integer): HResult; stdcall;
		function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
		function GetIDsOfNames(const IID: TGUID; Names: Pointer;
			NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
		function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
			Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
	public
		constructor Create(Interpreter: TDataBlockInterpreter; DispatchIndex: Integer);
		destructor Destroy; override;
	end;

	{ TTransportThread }

const
	THREAD_SENDSTREAM       = WM_USER + 1;
	THREAD_RECEIVEDSTREAM   = THREAD_SENDSTREAM + 1;
	THREAD_EXCEPTION        = THREAD_RECEIVEDSTREAM + 1;
	THREAD_SENDNOTIFY       = THREAD_EXCEPTION + 1;
	THREAD_REPLACETRANSPORT = THREAD_SENDNOTIFY + 1;
  THREAD_BREAK            = THREAD_REPLACETRANSPORT + 1000;

type

  { TSocketTransport }

  ESocketConnectionError = class(Exception);

  TSocketTransport = class(TInterfacedObject, ITransport)
  private
    FEvent: THandle;
    FAddress: string;
    FHost: string;
    FPort: Integer;
    FClientSocket: TClientSocket;
    FSocket: TCustomWinSocket;
  protected
    { ITransport }
    function GetWaitEvent: THandle; stdcall;
    function GetConnected: Boolean; stdcall;
    procedure SetConnected(Value: Boolean); stdcall;
    function Receive(WaitForInput: Boolean; Context: Integer): IDataBlock; stdcall;
    function Send(const Data: IDataBlock): Integer; stdcall;
  public
    constructor Create;
    destructor Destroy; override;
    property Host: string read FHost write FHost;
    property Address: string read FAddress write FAddress;
    property Port: Integer read FPort write FPort;
    property Socket: TCustomWinSocket read FSocket write FSocket;
  end;

{ Utility functions }

type
	WSAOVERLAPPED   = TOverlapped;
	TWSAOverlapped  = WSAOverlapped;
	PWSAOverlapped  = ^WSAOverlapped;
	LPWSAOVERLAPPED = PWSAOverlapped;
	LPWSAOVERLAPPED_COMPLETION_ROUTINE = procedure ( const dwError, cbTransferred : DWORD; const lpOverlapped : LPWSAOVERLAPPED; const dwFlags : DWORD ); stdcall;

function LoadWinSock2: Boolean;

var
  WSACreateEvent: function: THandle stdcall;
  WSAResetEvent: function(hEvent: THandle): Boolean stdcall;
  WSACloseEvent: function(hEvent: THandle): Boolean stdcall;
  WSAEventSelect: function(s: TSocket; hEventObject: THandle; lNetworkEvents: Integer): Integer stdcall;
  WSAIoctl: function(s: TSocket; dwIoControlCode: DWORD; lpvInBuffer: Pointer; cbInBuffer: DWORD; lpvOutBuffer: Pointer; cbOutBuffer: DWORD;
	                   lpcbBytesReturned: LPDWORD; lpOverlapped: LPWSAOVERLAPPED; lpCompletionRoutine: LPWSAOVERLAPPED_COMPLETION_ROUTINE ): Integer; stdcall;
  WSAEnumNetworkEvents: function (const s : TSocket; const hEventObject: WSAEVENT; lpNetworkEvents: LPWSANETWORKEVENTS) :Integer; stdcall;

implementation

uses
	ActiveX, ComObj, MidConst, 
{$ifdef logfile}
  LogFunc,
{$endif}  
  tServiceMain, MyForms, Consts;

var
  hWinSock2: THandle;

{ Utility functions }

function LoadWinSock2: Boolean;
const
  DLLName = 'ws2_32.dll';
begin
  Result := hWinSock2 > HINSTANCE_ERROR;
  if Result then Exit;
  hWinSock2 := LoadLibrary(PChar(DLLName));
  Result := hWinSock2 > HINSTANCE_ERROR;
  if Result then
  begin
    WSACreateEvent := GetProcAddress(hWinSock2, 'WSACreateEvent');
    WSAResetEvent := GetProcAddress(hWinSock2, 'WSAResetEvent');
    WSACloseEvent := GetProcAddress(hWinSock2, 'WSACloseEvent');
    WSAEventSelect := GetProcAddress(hWinSock2, 'WSAEventSelect');
    WSAIoctl := GetProcAddress(hWinSock2, 'WSAIoctl');
    WSAEnumNetworkEvents := GetProcAddress(hWinSock2, 'WSAEnumNetworkEvents');
  end;
end;

procedure FreeWinSock2;
begin
  if hWinSock2 > HINSTANCE_ERROR then
  begin
    WSACreateEvent := nil;
    WSAResetEvent := nil;
    WSACloseEvent := nil;
    WSAEventSelect := nil;
    WSAIoctl := nil;
    WSAEnumNetworkEvents := nil;
    FreeLibrary(hWinSock2);
  end;
  hWinSock2 := 0;
end;

procedure GetDataBrokerList(List: TStringList; const RegCheck: string);

  function OpenRegKey(Key: HKey; const SubKey: string): HKey;
  begin
    if Windows.RegOpenKey(Key, PChar(SubKey), Result) <> 0 then Result := 0;
  end;

  function EnumRegKey(Key: HKey; Index: Integer; var Value: string): Boolean;
  var
    Buffer: array[0..255] of Char;
  begin
    Result := False;
    if Windows.RegEnumKey(Key, Index, Buffer, SizeOf(Buffer)) = 0 then
    begin
      Value := Buffer;
      Result := True;
    end;
  end;

  function QueryRegKey(Key: HKey; const SubKey: string;
    var Value: string): Boolean;
  var
    BufSize: Longint;
    Buffer: array[0..255] of Char;
  begin
    Result := False;
    BufSize := SizeOf(Buffer);
    if Windows.RegQueryValue(Key, PChar(SubKey), Buffer, BufSize) = 0 then
    begin
      Value := Buffer;
      Result := True;
    end;
  end;

  procedure CloseRegKey(Key: HKey);
  begin
    RegCloseKey(Key);
  end;

var
  I: Integer;
  ClassIDKey: HKey;
  ClassID, S: string;
begin
  List.Clear;
  ClassIDKey := OpenRegKey(HKEY_CLASSES_ROOT, 'CLSID');
  if ClassIDKey <> 0 then
    try
      I := 0;
      while EnumRegKey(ClassIDKey, I, ClassID) do
      begin
        if RegCheck <> '' then
        begin
          QueryRegKey(ClassIDKey, ClassID + '\' + RegCheck, S);
          if S <> SFlagOn then continue;
        end;
        if not QueryRegKey(ClassIDKey, ClassID + '\Control', S) and
           QueryRegKey(ClassIDKey, ClassID + '\ProgID', S) and
           QueryRegKey(ClassIDKey, ClassID + '\TypeLib', S) and
           QueryRegKey(ClassIDKey, ClassID + '\Version', S) and
           QueryRegKey(ClassIDKey, ClassID + '\Borland DataBroker', S) then
          List.Add(ClassIDToProgID(StringToGUID(ClassID)));
        Inc(I);
      end;
    finally
      CloseRegKey(ClassIDKey);
    end;
end;

{ TDataBlock }

constructor TDataBlock.Create;
begin
  inherited Create;
  FIgnoreStream := False;
  FStream := TMemoryStream.Create;
  Clear;
end;

destructor TDataBlock.Destroy;
begin
  if not FIgnoreStream then
    FStream.Free;
  inherited Destroy;
end;

{ TDataBlock.IDataBlock }

function TDataBlock.GetBytesReserved: Integer;
begin
  Result := SizeOf(Integer) * 2;
end;

function TDataBlock.GetMemory: Pointer;
var
  DataSize: Integer;
begin
  FStream.Position := 4;
  DataSize := FStream.Size - BytesReserved;
  FStream.Write(DataSize, SizeOf(DataSize));
  Result := FStream.Memory;
end;

function TDataBlock.GetSize: Integer;
begin
  Result := FStream.Size - BytesReserved;
end;

procedure TDataBlock.SetSize(Value: Integer);
begin
  FStream.Size := Value + BytesReserved;
end;

function TDataBlock.GetStream: TStream;
var
  DataSize: Integer;
begin
  FStream.Position := 4;
  DataSize := FStream.Size - BytesReserved;
  FStream.Write(DataSize, SizeOf(DataSize));
  FStream.Position := 0;
  Result := FStream;
end;

function TDataBlock.GetSignature: Integer;
begin
  FStream.Position := 0;
  FStream.Read(Result, SizeOf(Result));
end;

procedure TDataBlock.SetSignature(Value: Integer);
begin
  FStream.Position := 0;
  FStream.Write(Value, SizeOf(Value));
end;

procedure TDataBlock.Clear;
begin
  FStream.Size := BytesReserved;
  FReadPos := BytesReserved;
  FWritePos := BytesReserved;
end;

function TDataBlock.Write(const Buffer; Count: Integer): Integer;
begin
  FStream.Position := FWritePos;
  Result := FStream.Write(Buffer, Count);
  FWritePos := FStream.Position;
end;

function TDataBlock.Read(var Buffer; Count: Integer): Integer;
begin { TODO : Read }
  FStream.Position := FReadPos;
  Result := FStream.Read(Buffer, Count);
  FReadPos := FStream.Position;
end;

procedure TDataBlock.IgnoreStream;
begin
  FIgnoreStream := True;
end;

function TDataBlock.InitData(Data: Pointer; DataLen: Integer; CheckLen: Boolean): Integer; stdcall;
var
  Sig: Integer;
  P: Pointer;
begin
  P := Data;
  if DataLen < 8 then
    raise Exception.CreateRes(@SInvalidDataPacket);
  Sig := Integer(P^);
  P := Pointer(Integer(Data) + SizeOf(Sig));
  if (Sig and CallSig <> CallSig) and
     (Sig and ResultSig <> ResultSig) then
    raise Exception.CreateRes(@SInvalidDataPacket);
  Signature := Sig;
  Result := Integer(P^);
  P := Pointer(Integer(P) + SizeOf(Result));
  if CheckLen then
  begin
    if (Result <> DataLen - 8) then
      raise Exception.CreateRes(@SInvalidDataPacket);
    Size := Result;
    if Result > 0 then
      Write(P^, Result);
  end else
  begin
    Size := DataLen - 8;
    if Size > 0 then
      Write(P^, Size);
  end;
end;

{ TDataBlockInterpreter }

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

//  EasyArrayTypes = [varSmallInt, varInteger, varSingle, varDouble, varCurrency,
//                    varDate, varBoolean, varByte];
//
//  VariantSize: array[0..varByte] of Word  = (0, 0, SizeOf(SmallInt), SizeOf(Integer),
//    SizeOf(Single), SizeOf(Double), SizeOf(Currency), SizeOf(TDateTime), 0, 0,
//    SizeOf(Integer), SizeOf(WordBool), 0, 0, 0, 0, 0, SizeOf(Byte));

constructor TDataBlockInterpreter.Create(SendDataBlock: ISendDataBlock; CheckRegValue: string);
begin
  inherited Create;
  FSendDataBlock := SendDataBlock;
  FDispatchList := TList.Create;
  FCheckRegValue := CheckRegValue;
end;

destructor TDataBlockInterpreter.Destroy;
var
  i: Integer;
begin
  for i := FDispatchList.Count - 1 downto 0 do
    TDataDispatch(FDispatchList[i]).FInterpreter := nil;
  FDispatchList.Free;
  FSendDataBlock := nil;
  inherited Destroy;
end;

procedure TDataBlockInterpreter.AddDispatch(Value: TDataDispatch);
begin
  if FDispatchList.IndexOf(Value) = -1 then
    FDispatchList.Add(Value);
end;

procedure TDataBlockInterpreter.RemoveDispatch(Value: TDataDispatch);
begin
  FDispatchList.Remove(Value);
end;

{ Variant conversion methods }

function TDataBlockInterpreter.GetVariantPointer(const Value: OleVariant): Pointer;
begin
  case VarType(Value) of
    varEmpty, varNull: Result := nil;
    varDispatch: Result := TVarData(Value).VDispatch;
    varVariant: Result := @Value;
    varUnknown: Result := TVarData(Value).VUnknown;
  else
    Result := @TVarData(Value).VPointer;
  end;
end;

procedure TDataBlockInterpreter.CopyDataByRef(Source: TVarData; var Dest: TVarData);
var
  VType: Integer;
begin
  VType := Source.VType;
  if Source.VType and varArray = varArray then
  begin
    VarClear(OleVariant(Dest));
    SafeArrayCopy(PSafeArray(Source.VArray), PSafeArray(Dest.VArray));
  end else
    case Source.VType and varTypeMask of
      varEmpty, varNull: ;
      varOleStr:
      begin
        if (Dest.VType and varTypeMask) <> varOleStr then
          Dest.VOleStr := SysAllocString(Source.VOleStr) else
        if (Dest.VType and varByRef) = varByRef then
          SysReallocString(PBStr(Dest.VOleStr)^,Source.VOleStr) else
          SysReallocString(Dest.VOleStr,Source.VOleStr);
      end;
      varDispatch: Dest.VDispatch := Source.VDispatch;
      varVariant: CopyDataByRef(PVarData(Source.VPointer)^, Dest);
      varUnknown: Dest.VUnknown := Source.VUnknown;
    else
      if Dest.VType = 0 then
        OleVariant(Dest) := OleVariant(Source) else
      if Dest.VType and varByRef = varByRef then
      begin
        VType := VType or varByRef;
        Move(Source.VPointer, Dest.VPointer^, VariantSize[Source.VType and varTypeMask]);
      end else
        Move(Source.VPointer, Dest.VPointer, VariantSize[Source.VType and varTypeMask]);
    end;
  Dest.VType := VType;
end;

function TDataBlockInterpreter.ReadArray(VType: Integer;
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

procedure TDataBlockInterpreter.WriteArray(const Value: OleVariant;
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

function TDataBlockInterpreter.ReadVariant(out Flags: TVarFlags;
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
    varDispatch:
    begin            { TODO : ReadVariant }
      Data.Read(I, SizeOf(Integer));
      Result := TDataDispatch.Create(Self, I) as IDispatch;
    end;
    varUnknown:
      raise EInterpreterError.CreateResFmt(@SBadVariantType,[IntToHex(VType,4)]);
  else
    TVarData(Result).VType := VType;
    Data.Read(TVarData(Result).VPointer, VariantSize[VType and varTypeMask]);
  end;
end;

function TDataBlockInterpreter.CanCreateObject(const ClassID: TGUID): Boolean;
begin
  Result := (FCheckRegValue = '') or
    (GetRegStringValue(SClsid + GuidToString(ClassID), FCheckRegValue) = SFlagOn);
end;

function TDataBlockInterpreter.InternalCreateObject(const ClassID: TGUID): OleVariant;
var
  Unk: IUnknown;
begin
	OleCheck(CoCreateInstance(ClassID, nil, CLSCTX_INPROC_SERVER or
		CLSCTX_LOCAL_SERVER or CLSCTX_REMOTE_SERVER, IUnknown, Unk));
	Result := Unk as IDispatch;
end;

function TDataBlockInterpreter.CreateObject(const Name: string): OleVariant;
var
  ClassID: TGUID;
begin
  if (Name[1] = '{') and (Name[Length(Name)] = '}') then
    ClassID := StringToGUID(Name) else
		ClassID := ProgIDToClassID(Name);
	if CanCreateObject(ClassID) then begin
    Result := InternalCreateObject(ClassID);
  end
  else
    raise Exception.CreateResFmt(@SObjectNotAvailable, [GuidToString(ClassID)]);
end;

function TDataBlockInterpreter.StoreObject(const Value: OleVariant): Integer;
begin
  if not VarIsArray(FDispList) then
    FDispList := VarArrayCreate([0,10], varVariant);
  Result := 0;
  while Result <= VarArrayHighBound(FDispList, 1) do
    if VarIsEmpty(FDispList[Result]) then break else Inc(Result);
  if Result > VarArrayHighBound(FDispList, 1) then
    VarArrayRedim(FDispList, Result + 10);
  FDispList[Result] := Value;
end;

function TDataBlockInterpreter.LockObject(ID: Integer): IDispatch;
begin
  Result := FDispList[ID];
end;

procedure TDataBlockInterpreter.UnlockObject(ID: Integer; const Disp: IDispatch);
begin
end;

procedure TDataBlockInterpreter.ReleaseObject(ID: Integer);
begin
  if (ID >= 0) and (VarIsArray(FDispList)) and
     (ID < VarArrayHighBound(FDispList, 1)) then
    FDispList[ID] := UNASSIGNED;
end;

procedure TDataBlockInterpreter.WriteVariant(const Value: OleVariant;
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
    varDispatch:
    begin
      if VType and varByRef = varByRef then
        raise EInterpreterError.CreateResFmt(@SBadVariantType,[IntToHex(VType,4)]);
      I := StoreObject(Value);
      Data.Write(VType, SizeOf(Integer));
      Data.Write(I, SizeOf(Integer));
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

{ Sending Calls }

function TDataBlockInterpreter.CallGetServerList: OleVariant;
var
  Flags: TVarFlags;
  Data: IDataBlock;
begin { TODO : CallGetServerList }
  Data := TDataBlock.Create as IDataBlock;
  Data.Signature := CallSig or asGetAppServers;
  Data := FSendDataBlock.Send(Data, True);
  Result := ReadVariant(Flags, Data);
end;

function TDataBlockInterpreter.CallCreateObject(Name: string): OleVariant;
var
  Flags: TVarFlags;
  Data: IDataBlock;
begin
  Data := TDataBlock.Create as IDataBlock;
  WriteVariant(Name, Data);
  Data.Signature := CallSig or asCreateObject;
  Data := FSendDataBlock.Send(Data, True);
  Result := ReadVariant(Flags, Data);
end;

procedure TDataBlockInterpreter.CallFreeObject(DispatchIndex: Integer);
var
  Data: IDataBlock;
begin
  Data := TDataBlock.Create as IDataBlock;
  WriteVariant(DispatchIndex, Data);
  Data.Signature := CallSig or asFreeObject;
  FSendDataBlock.Send(Data, False);
end;

function TDataBlockInterpreter.CallGetIDsOfNames(DispatchIndex: Integer;
  const IID: TGUID; Names: Pointer; NameCount, LocaleID: Integer;
  DispIDs: Pointer): HResult; stdcall;
var
  Flags: TVarFlags;
  Data: IDataBlock;
begin
  if NameCount <> 1 then
    Result := E_NOTIMPL else
  begin
    Data := TDataBlock.Create as IDataBlock;
    WriteVariant(DispatchIndex, Data);
    WriteVariant(WideString(POleStrList(Names)^[0]), Data);
    Data.Signature := CallSig or asGetID;
    Data := FSendDataBlock.Send(Data, True);
    Result := ReadVariant(Flags, Data);
    if Result = S_OK then
      PDispIdList(DispIDs)^[0] := ReadVariant(Flags, Data);
  end;
end;

function TDataBlockInterpreter.CallInvoke(DispatchIndex, DispID: Integer; const IID: TGUID; LocaleID: Integer;
  Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
var
  VarFlags: TVarFlags;
  PDest: PVarData;
  i: Integer;
  Data: IDataBlock;
begin { TODO : callInvoke }
  Data := TDataBlock.Create as IDataBlock;
  WriteVariant(DispatchIndex, Data);
  WriteVariant(DispID, Data);
  WriteVariant(Flags, Data);
  WriteVariant(VarResult <> nil, Data);
  WriteVariant(PDispParams(@Params).cArgs, Data);
  WriteVariant(PDispParams(@Params).cNamedArgs, Data);
  for i := 0 to PDispParams(@Params).cNamedArgs - 1 do
    WriteVariant(PDispParams(@Params).rgdispidNamedArgs[i], Data);
  for i := 0 to PDispParams(@Params).cArgs - 1 do
    WriteVariant(OleVariant(PDispParams(@Params).rgvarg^[i]), Data);
  Data.Signature := CallSig or asInvoke;
  Data := FSendDataBlock.Send(Data, True);
  Result := ReadVariant(VarFlags, Data);
  if (Result = DISP_E_EXCEPTION) then
  begin
    PExcepInfo(ExcepInfo).scode := ReadVariant(VarFlags, Data);
    PExcepInfo(ExcepInfo).bstrDescription := ReadVariant(VarFlags, Data);
  end;
  for i := 0 to PDispParams(@Params).cArgs - 1 do
    with PDispParams(@Params)^ do
      if rgvarg^[i].vt and varByRef = varByRef then
      begin
        if rgvarg^[i].vt = (varByRef or varVariant) then
          PDest := @TVarData(TVarData(rgvarg^[i]).VPointer^) else
          PDest := @TVarData(rgvarg^[i]);
        CopyDataByRef(TVarData(ReadVariant(VarFlags, Data)), PDest^);
      end;
  if VarResult <> nil then
    PVariant(VarResult)^ := ReadVariant(VarFlags, Data);
end;

{ Receiving Calls }

procedure TDataBlockInterpreter.InterpretData(const Data: IDataBlock);
var
  Action: Integer;
begin { TODO : InterpretData }
  Action := Data.Signature;
  if (Action and asMask) = asError then DoException(Data);
  try
    case (Action and asMask) of
      asInvoke: DoInvoke(Data);
      asGetID: DoGetIDsOfNames(Data);
      asCreateObject: DoCreateObject(Data);
      asFreeObject: DoFreeObject(Data);
      asGetServers: DoGetServerList(Data);
      asGetAppServers: DoGetAppServerList(Data);
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

procedure TDataBlockInterpreter.DoException(const Data: IDataBlock);
var
  VarFlags: TVarFlags;
begin
  raise Exception.Create(ReadVariant(VarFlags, Data));
end;

procedure TDataBlockInterpreter.DoGetAppServerList(const Data: IDataBlock);
var
  VList: OleVariant;
  List: TStringList;
  i: Integer;
begin
  Data.Clear;
  List := TStringList.Create;
  try
    GetMIDASAppServerList(List, FCheckRegValue);
    if List.Count > 0 then
    begin
      VList := VarArrayCreate([0, List.Count - 1], varOleStr);
      for i := 0 to List.Count - 1 do
        VList[i] := List[i];
    end else
      VList := NULL;
  finally
    List.Free;
  end;
  WriteVariant(VList, Data);
  Data.Signature := ResultSig or asGetAppServers;
  FSendDataBlock.Send(Data, False);
end;

procedure TDataBlockInterpreter.DoGetServerList(const Data: IDataBlock);
var
  VList: OleVariant;
  List: TStringList;
  i: Integer;
begin
  Data.Clear;
  List := TStringList.Create;
  try
    GetDataBrokerList(List, FCheckRegValue);
    if List.Count > 0 then
    begin
      VList := VarArrayCreate([0, List.Count - 1], varOleStr);
      for i := 0 to List.Count - 1 do
        VList[i] := List[i];
    end else
      VList := NULL;
  finally
    List.Free;
  end;
  WriteVariant(VList, Data);
  Data.Signature := ResultSig or asGetServers;
  FSendDataBlock.Send(Data, False);
end;

procedure TDataBlockInterpreter.DoCreateObject(const Data: IDataBlock);
var
  V: OleVariant;
  VarFlags: TVarFlags;
  I: Integer;
begin
	V := CreateObject(ReadVariant(VarFlags, Data));
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
  Data.Signature := ResultSig or asCreateObject;
  FSendDataBlock.Send(Data, False);
end;

procedure TDataBlockInterpreter.DoFreeObject(const Data: IDataBlock);
var
  VarFlags: TVarFlags;
begin
  try
    ReleaseObject(ReadVariant(VarFlags, Data));
  except
    { Don't return any exceptions }
  end;
end;

procedure TDataBlockInterpreter.DoGetIDsOfNames(const Data: IDataBlock);
var
  ObjID, RetVal, DispID: Integer;
  Disp: IDispatch;
  W: WideString;
  VarFlags: TVarFlags;
begin { TODO : DoGetIDsOfNames }
  ObjID := ReadVariant(VarFlags, Data);
  Disp := LockObject(ObjID);
  try
    W := ReadVariant(VarFlags, Data);
    Data.Clear;
		if Disp = nil then begin
			RetVal:=E_NOINTERFACE;
			raise EOleError.Create('catastrophic error');
		end;
		RetVal := Disp.GetIDsOfNames(GUID_NULL, @W, 1, 0, @DispID);
	finally
		UnlockObject(ObjID, Disp);
	end;
	WriteVariant(RetVal, Data);
	if RetVal = S_OK then
		WriteVariant(DispID, Data);
	Data.Signature := ResultSig or asGetID;
	FSendDataBlock.Send(Data, False);
end;

procedure TDataBlockInterpreter.DoInvoke(const Data: IDataBlock);
var
  ExcepInfo: TExcepInfo;
  DispParams: TDispParams;
  ObjID, DispID, Flags, i: Integer;
  RetVal: HRESULT;
  ExpectResult: Boolean;
  VarFlags: TVarFlags;
  Disp: IDispatch;
  VarList: PVariantArray;
  V: OleVariant;
begin { TODO : DoInvoke }
  VarList := nil;
  FillChar(ExcepInfo, SizeOf(ExcepInfo), 0);
  FillChar(DispParams, SizeOf(DispParams), 0);
  ObjID := ReadVariant(VarFlags, Data);
  Disp := LockObject(ObjID);
  try
    DispID := ReadVariant(VarFlags, Data);
    Flags := ReadVariant(VarFlags, Data);
    ExpectResult := ReadVariant(VarFlags, Data);
    DispParams.cArgs := ReadVariant(VarFlags, Data);
    DispParams.cNamedArgs := ReadVariant(VarFlags, Data);
    try
      DispParams.rgdispidNamedArgs := nil;
      if DispParams.cNamedArgs > 0 then
      begin
        GetMem(DispParams.rgdispidNamedArgs, DispParams.cNamedArgs * SizeOf(Integer));
        for i := 0 to DispParams.cNamedArgs - 1 do
          DispParams.rgdispidNamedArgs[i] := ReadVariant(VarFlags, Data);
      end;
      if DispParams.cArgs > 0 then
      begin
        GetMem(DispParams.rgvarg, DispParams.cArgs * SizeOf(TVariantArg));
        GetMem(VarList, DispParams.cArgs * SizeOf(OleVariant));
        Initialize(VarList^, DispParams.cArgs);
        for i := 0 to DispParams.cArgs - 1 do
        begin
          VarList[i] := ReadVariant(VarFlags, Data);
          if vfByRef in VarFlags then
          begin
            if vfVariant in VarFlags then
            begin
              DispParams.rgvarg[i].vt := varVariant or varByRef;
              TVarData(DispParams.rgvarg[i]).VPointer := @VarList[i];
            end else
            begin
              DispParams.rgvarg[i].vt := VarType(VarList[i]) or varByRef;
              TVarData(DispParams.rgvarg[i]).VPointer := GetVariantPointer(VarList[i]);
            end;
          end else
            DispParams.rgvarg[i] := TVariantArg(VarList[i]);
        end;
      end;
      Data.Clear;
      RetVal := Disp.Invoke(DispID, GUID_NULL, 0, Flags, DispParams, @V, @ExcepInfo, nil);
      WriteVariant(RetVal, Data);
      if RetVal = DISP_E_EXCEPTION then
      begin
        WriteVariant(ExcepInfo.scode, Data);
        WriteVariant(ExcepInfo.bstrDescription, Data);
      end;
      if DispParams.rgvarg <> nil then
      begin
        for i := 0 to DispParams.cArgs - 1 do
          if DispParams.rgvarg[i].vt and varByRef = varByRef then
            WriteVariant(OleVariant(DispParams.rgvarg[i]), Data);
      end;
      if ExpectResult then WriteVariant(V, Data);
      Data.Signature := ResultSig or asInvoke;
      FSendDataBlock.Send(Data, False);
    finally
      if DispParams.rgdispidNamedArgs <> nil then
        FreeMem(DispParams.rgdispidNamedArgs);
      if VarList <> nil then
      begin
        Finalize(VarList^, DispParams.cArgs);
        FreeMem(VarList);
      end;
      if DispParams.rgvarg <> nil then
        FreeMem(DispParams.rgvarg);
    end;
  finally
    UnlockObject(ObjID, Disp);
  end;
end;

function TDataBlockInterpreter.DoCustomAction(Action: Integer;
  const Data: IDataBlock): Boolean;
begin
  Result := False;
end;

{ TDataDispatch }

constructor TDataDispatch.Create(Interpreter: TDataBlockInterpreter; DispatchIndex: Integer);
begin
  inherited Create;
  FDispatchIndex := DispatchIndex;
  FInterpreter := Interpreter;
  Interpreter.AddDispatch(Self);
end;

destructor TDataDispatch.Destroy;
begin
  if Assigned(FInterpreter) then
  begin
    FInterpreter.CallFreeObject(FDispatchIndex);
    FInterpreter.RemoveDispatch(Self);
  end;
  inherited Destroy;
end;

{ TDataDispatch.IDispatch }

function TDataDispatch.GetTypeInfoCount(out Count: Integer): HResult; stdcall;
begin
  Count := 0;
  Result := S_OK;
end;

function TDataDispatch.GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
begin
  Result := E_NOTIMPL;
end;

function TDataDispatch.GetIDsOfNames(const IID: TGUID; Names: Pointer;
  NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
begin
  Result := FInterpreter.CallGetIDsOfNames(FDispatchIndex, IID, Names, NameCount,
    LocaleID, DispIDs);
end;

function TDataDispatch.Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
  Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
begin                        { TODO : Invoke }
  Result := FInterpreter.CallInvoke(FDispatchIndex, DispID, IID, LocaleID, Flags,
    Params, VarResult, ExcepInfo, ArgErr);
end;

{ TSocketTransport }

constructor TSocketTransport.Create;
begin
  inherited Create;
  FEvent := 0;
end;

destructor TSocketTransport.Destroy;
begin
  SetConnected(False);
  inherited Destroy;
end;

function TSocketTransport.GetWaitEvent: THandle;
begin
  if FEvent = 0 then begin
    FEvent := WSACreateEvent;
    WSAEventSelect(FSocket.SocketHandle, FEvent, FD_READ or FD_CLOSE);
  end;
  Result := FEvent;
end;

function TSocketTransport.GetConnected: Boolean;
begin
  Result := (FSocket <> nil) and (FSocket.Connected);
end;

procedure TSocketTransport.SetConnected(Value: Boolean);
begin
  if GetConnected = Value then Exit;
  if Value then begin
    if (FAddress = '') and (FHost = '') then
      raise ESocketConnectionError.CreateRes(@SNoAddress);
    FClientSocket := TClientSocket.Create(nil);
    FClientSocket.ClientType := ctBlocking;
    FSocket := FClientSocket.Socket;
    FClientSocket.Port := FPort;
    if FAddress <> '' then
      FClientSocket.Address := FAddress 
    else
      FClientSocket.Host := FHost;
    FClientSocket.Open;
  end
  else begin
    try
      FSocket.Close;
      FClientSocket.Free;
    finally
      if FEvent <> 0 then begin
        WSAResetEvent(FEvent);
        WSACloseEvent(FEvent);
        FEvent := 0;
      end;
    end;
  end;
end;

function TSocketTransport.Receive(WaitForInput: Boolean; Context: Integer): IDataBlock;
var
  RetLen, Sig, StreamLen: Integer;
  P: Pointer;
  FDSet: TFDSet;
  TimeVal: PTimeVal;
  RetVal: Integer;
{$ifdef logfile}
  F: Pointer;
{$endif}  
begin { TODO : TSocketTransport.Receive }
  Result := nil;
  TimeVal := nil;
  FD_ZERO(FDSet);
  FD_SET(FSocket.SocketHandle, FDSet);
  if not WaitForInput then
  begin
    New(TimeVal);
    TimeVal.tv_sec := 0;
    TimeVal.tv_usec := 1;
  end;
  RetVal := select(0, @FDSet, nil, nil, TimeVal);
  if Assigned(TimeVal) then
    FreeMem(TimeVal);
  if RetVal = SOCKET_ERROR then
    raise ESocketConnectionError.Create(SysErrorMessage(WSAGetLastError));
  if (RetVal = 0) then Exit;
  RetLen := FSocket.ReceiveBuf(Sig, SizeOf(Sig));
//  if RetLen <= 0 then begin
//    SetConnected(False);
//    Exit;
//  end;
  if RetLen <> SizeOf(Sig) then
    raise ESocketConnectionError.CreateRes(@SSocketReadError);
  if (Sig and CallSig <> CallSig) and
     (Sig and ResultSig <> ResultSig) then
    raise Exception.CreateRes(@SInvalidDataPacket);
  RetLen := FSocket.ReceiveBuf(StreamLen, SizeOf(StreamLen));
  if RetLen = 0 then
    raise ESocketConnectionError.CreateRes(@SSocketReadError);
  if RetLen <> SizeOf(StreamLen) then
    raise ESocketConnectionError.CreateRes(@SSocketReadError);
  Result := TDataBlock.Create as IDataBlock;
  Result.Size := StreamLen;
  Result.Signature := Sig;
  P := Result.Memory;
  Inc(Integer(P), Result.BytesReserved);
  while StreamLen > 0 do begin
    RetLen := FSocket.ReceiveLength;
    if RetLen > 0 then begin
      if RetLen > StreamLen then RetLen := StreamLen;
      RetLen := FSocket.ReceiveBuf(P^, RetLen);
    end;
    if RetLen = 0 then begin
      if WaitForSingleObject(FEvent, 60000)=WAIT_OBJECT_0 then
        WSAResetEvent(FEvent)
      else break;
    end;
    if RetLen > 0 then begin
      Dec(StreamLen, RetLen);
      Inc(Integer(P), RetLen);
    end;
  end;
  if StreamLen <> 0 then
    raise ESocketConnectionError.CreateRes(@SInvalidDataPacket);

{$ifdef logfile}
  F := Result.Memory;
  OpenLog('log\read'+IntToStr(Integer(FSocket.SocketHandle))+'.dmp');
  WriteToLog(F, Result.Size + Result.BytesReserved);
  CloseLog;
{$endif}  
    
end;

function TSocketTransport.Send(const Data: IDataBlock): Integer;
var
  P: Pointer;
{$ifdef logfile}
  F: Pointer;
{$endif}  
begin
  Result := 0;
  P := Data.Memory;
{$ifdef logfile}
  F := Data.Memory;
  OpenLog('log\send'+IntToStr(Integer(FSocket.SocketHandle))+'.dmp');
  WriteToLog(F, Data.Size + Data.BytesReserved);
  CloseLog;
{$endif}  
  FSocket.SendBuf(P^, Data.Size + Data.BytesReserved);
end;

initialization
finalization
  FreeWinSock2;
end.
