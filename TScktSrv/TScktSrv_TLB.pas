unit TScktSrv_TLB;

// ************************************************************************ //
// WARNING                                                                    
// -------                                                                    
// The types declared in this file were generated from data read from a       
// Type Library. If this type library is explicitly or indirectly (via        
// another type library referring to this type library) re-imported, or the   
// 'Refresh' command of the Type Library Editor activated while editing the   
// Type Library, the contents of this file will be regenerated and all        
// manual modifications will be lost.                                         
// ************************************************************************ //

// PASTLWTR : $Revision:   1.88.1.0.1.0  $
// File generated on 21.09.2010 11:21:52 from Type Library described below.

// ************************************************************************ //
// Type Lib: D:\Program Files\Delphi5\Projects\ScktSrvc\TScktSrv\TScktSrv.tlb (1)
// IID\LCID: {88C3B8E0-BCD7-4B1F-B031-AA2E345BC7BA}\0
// Helpfile: 
// DepndLst: 
//   (1) v2.0 stdole, (D:\WINDOWS\system32\stdole2.tlb)
//   (2) v4.0 StdVCL, (D:\WINDOWS\system32\STDVCL40.DLL)
// ************************************************************************ //
{$TYPEDADDRESS OFF} // Unit must be compiled without type-checked pointers. 
interface

uses Windows, Classes, ActiveX, OleServer, StdVCL;

// *********************************************************************//
// GUIDS declared in the TypeLibrary. Following prefixes are used:        
//   Type Libraries     : LIBID_xxxx                                      
//   CoClasses          : CLASS_xxxx                                      
//   DISPInterfaces     : DIID_xxxx                                       
//   Non-DISP interfaces: IID_xxxx                                        
// *********************************************************************//
const
  // TypeLibrary Major and minor versions
  TScktSrvMajorVersion = 1;
  TScktSrvMinorVersion = 0;

  LIBID_TScktSrv: TGUID = '{88C3B8E0-BCD7-4B1F-B031-AA2E345BC7BA}';

  IID_IServer: TGUID = '{F9642A0E-E1E8-42F9-9920-DDEAD8F4B166}';
  CLASS_Server: TGUID = '{8227CB5C-4F50-49E4-9BE8-A0DCE86A184C}';
  IID_IClient: TGUID = '{ABA0724A-EFF6-4326-A1EA-36592B2E2DD7}';
type

// *********************************************************************//
// Forward declaration of types defined in TypeLibrary                    
// *********************************************************************//
  IServer = interface;
  IServerDisp = dispinterface;
  IClient = interface;
  IClientDisp = dispinterface;

// *********************************************************************//
// Declaration of CoClasses defined in Type Library                       
// (NOTE: Here we map each CoClass to its Default Interface)              
// *********************************************************************//
  Server = IServer;


// *********************************************************************//
// Interface: IServer
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {F9642A0E-E1E8-42F9-9920-DDEAD8F4B166}
// *********************************************************************//
  IServer = interface(IDispatch)
    ['{F9642A0E-E1E8-42F9-9920-DDEAD8F4B166}']
    procedure SetCallBack(aCallBack: OleVariant); safecall;
    procedure RemoveConnect(P: OleVariant); safecall;
    function  ModifyPort(Dat: Integer; SetPort: Integer; LocalPort: Integer; SetTimeout: Integer): WordBool; safecall;
    procedure GetPortParams(Dat: Integer; var Port: Integer; var TimeOut: Integer); safecall;
    procedure GetPortList; safecall;
    function  AddPort(SetPort: Integer): Integer; safecall;
    function  RemovePort(Dat: Integer; LocalPort: Integer): WordBool; safecall;
    function  GetClientsInfo: OleVariant; safecall;
    function  SuspendAccepting: WordBool; safecall;
    function  GetAccepting: WordBool; safecall;
    procedure AddPermit(const Value: WideString); safecall;
    procedure RemovePermit(Idx: Integer); safecall;
    function  GetPermits: OleVariant; safecall;
    function  GetPortListData: OleVariant; safecall;
    function  Get_SysAffMask: Integer; safecall;
    function  Get_IsWinNT: WordBool; safecall;
    function  Get_ProcessAffMask: Integer; safecall;
    procedure Set_CPUAffinity(Param1: Integer); safecall;
    function  Get_ShowHost: WordBool; safecall;
    procedure Set_ShowHost(Value: WordBool); safecall;
    function  Get_RegisteredOnly: WordBool; safecall;
    procedure Set_RegisteredOnly(Value: WordBool); safecall;
    function  AddPermit_GetData(const Obj: WideString): OleVariant; safecall;
    property SysAffMask: Integer read Get_SysAffMask;
    property IsWinNT: WordBool read Get_IsWinNT;
    property ProcessAffMask: Integer read Get_ProcessAffMask;
    property CPUAffinity: Integer write Set_CPUAffinity;
    property ShowHost: WordBool read Get_ShowHost write Set_ShowHost;
    property RegisteredOnly: WordBool read Get_RegisteredOnly write Set_RegisteredOnly;
  end;

// *********************************************************************//
// DispIntf:  IServerDisp
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {F9642A0E-E1E8-42F9-9920-DDEAD8F4B166}
// *********************************************************************//
  IServerDisp = dispinterface
    ['{F9642A0E-E1E8-42F9-9920-DDEAD8F4B166}']
    procedure SetCallBack(aCallBack: OleVariant); dispid 2;
    procedure RemoveConnect(P: OleVariant); dispid 3;
    function  ModifyPort(Dat: Integer; SetPort: Integer; LocalPort: Integer; SetTimeout: Integer): WordBool; dispid 4;
    procedure GetPortParams(Dat: Integer; var Port: Integer; var TimeOut: Integer); dispid 5;
    procedure GetPortList; dispid 6;
    function  AddPort(SetPort: Integer): Integer; dispid 14;
    function  RemovePort(Dat: Integer; LocalPort: Integer): WordBool; dispid 15;
    function  GetClientsInfo: OleVariant; dispid 1;
    function  SuspendAccepting: WordBool; dispid 11;
    function  GetAccepting: WordBool; dispid 16;
    procedure AddPermit(const Value: WideString); dispid 17;
    procedure RemovePermit(Idx: Integer); dispid 18;
    function  GetPermits: OleVariant; dispid 19;
    function  GetPortListData: OleVariant; dispid 20;
    property SysAffMask: Integer readonly dispid 8;
    property IsWinNT: WordBool readonly dispid 9;
    property ProcessAffMask: Integer readonly dispid 10;
    property CPUAffinity: Integer writeonly dispid 12;
    property ShowHost: WordBool dispid 23;
    property RegisteredOnly: WordBool dispid 21;
    function  AddPermit_GetData(const Obj: WideString): OleVariant; dispid 7;
  end;

// *********************************************************************//
// Interface: IClient
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {ABA0724A-EFF6-4326-A1EA-36592B2E2DD7}
// *********************************************************************//
  IClient = interface(IDispatch)
    ['{ABA0724A-EFF6-4326-A1EA-36592B2E2DD7}']
    function  GetClosePermission: WordBool; safecall;
    procedure SetPortItem(Port: Integer; Dat: Integer); safecall;
    procedure WarningMessage; safecall;
    procedure AddPermit(const Value: WideString; Idx: Integer); safecall;
  end;

// *********************************************************************//
// DispIntf:  IClientDisp
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {ABA0724A-EFF6-4326-A1EA-36592B2E2DD7}
// *********************************************************************//
  IClientDisp = dispinterface
    ['{ABA0724A-EFF6-4326-A1EA-36592B2E2DD7}']
    function  GetClosePermission: WordBool; dispid 3;
    procedure SetPortItem(Port: Integer; Dat: Integer); dispid 4;
    procedure WarningMessage; dispid 5;
    procedure AddPermit(const Value: WideString; Idx: Integer); dispid 1;
  end;

// *********************************************************************//
// The Class CoServer provides a Create and CreateRemote method to          
// create instances of the default interface IServer exposed by              
// the CoClass Server. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoServer = class
    class function Create: IServer;
    class function CreateRemote(const MachineName: string): IServer;
  end;

implementation

uses ComObj;

class function CoServer.Create: IServer;
begin
  Result := CreateComObject(CLASS_Server) as IServer;
end;

class function CoServer.CreateRemote(const MachineName: string): IServer;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_Server) as IServer;
end;

end.
