
{*******************************************************}
{                                                       }
{       Terminal Socket Server source code              }
{                                                       }
{       Copyright (c) 2002,03 Terminal                  }
{                                                       }
{*******************************************************}

program TScktSrv;



uses
  FastMM4 in '\\Swan\Terminal\Componen\SOURCE\Misc\FastMM\FastMM4.pas',
  FastMM4Messages in '\\Swan\Terminal\Componen\SOURCE\Misc\FastMM\FastMM4Messages.pas',
//  MultiMM,
  Windows,
  SysUtils,
  WinSvc,
  tScktMain in 'tScktMain.pas',
  vSconnect in 'vSconnect.pas',
  ScktSrvCfg in 'ScktSrvCfg.pas',
  vScktComp in 'vScktComp.pas',
  vSvcMgr in 'vSvcMgr.pas',
  TScktSrv_TLB in 'TScktSrv_TLB.pas',
  VisualConnect in 'VisualConnect.pas' {Server: CoClass},
  Db in 'db.pas',
  DbConsts in 'dbconsts.pas',
  MConnect in 'mconnect.pas',
  ComObj in 'comobj.pas',
{$ifdef logfile}
  LogFunc in 'LogFunc.pas',
{$endif}  
  ComServ in 'comserv.pas',
  tServiceMain in 'tServiceMain.pas',
  HostNameList in 'HostNameList.pas';

{$R *.TLB}

{$R *.RES}

function Installing: Boolean;
begin
	Result := FindCmdLineSwitch('install',['-','\','/'], True) or
						FindCmdLineSwitch('uninstall',['-','\','/'], True);
end;

function Registering: Boolean;
begin
	Result := FindCmdLineSwitch('regserver',['-','\','/'], True) or
						FindCmdLineSwitch('unregserver',['-','\','/'], True);
end;

function StartService: Boolean;
var
	Mgr, Svc: Integer;
begin
	Result := False;
	Mgr := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
	if Mgr <> 0 then
		begin
			Svc := OpenService(Mgr, PChar(ScktSrvCfg.trmScktSrvCfg.ServiceName), SERVICE_ALL_ACCESS);
			Result := Svc <> 0;
			if Result then
				CloseServiceHandle(Svc);
			CloseServiceHandle(Mgr);
		end;
	if Result then
		Result := FindCmdLineSwitch('s',['-','\','/'], True);
end;

begin
	if (Win32Platform = 2) and (Win32MajorVersion>=4) then begin
		try
			ScktSrvCfg.trmScktSrvCfg:=TScktSrvCfg.Create;
		except
			on E:Exception do
				begin
					MessageBox(0, PChar(E.Message), ScktSrvCfg.cvDisplayName, MB_ICONERROR);
				end;
		end;
		if Installing or StartService or Registering then
			begin
				tServiceMain.Application.Initialize;
				tServiceMain.Application.Run;
			end;
	end;
end.
