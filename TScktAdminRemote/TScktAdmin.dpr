
{*******************************************************}
{                                                       }
{       Borland Delphi Visual Component Library         }
{       Borland Socket Server source code               }
{                                                       }
{       Copyright (c) 1997,99 Inprise Corporation       }
{                                                       }
{*******************************************************}

program TScktAdmin;

uses
  FastMM4 in '\\Swan\Terminal\Componen\SOURCE\Misc\FastMM\FastMM4.pas',
  FastMM4Messages in '\\Swan\Terminal\Componen\SOURCE\Misc\FastMM\FastMM4Messages.pas',
  SysUtils, StrUtils,
  Forms,
//{$ifndef Console}
  tScktMain in 'tScktMain.pas' {trmSocketForm},
//{$else}  
  tScktCmd in 'tScktCmd.pas',
//{$endif}  
  TSSAdminCfg in 'TSSAdminCfg.pas';

{$R *.RES}
{$R tscktsrv.RES}

begin
{$ifndef Console}
    Application.Initialize;
    Application.Title := 'Terminal Socket Server administrator utility remote version';
    if (ParamCount = 0) or ((ParamCount = 1) and (CompareText(cCmdFileName,Copy(ReplaceStr(ParamStr(1),'<#34>','"'),1,Length(cCmdFileName)))=0)) then begin
      Application.CreateForm(TtrmSocketForm, trmSocketForm);
      Application.Run;
    end
    else begin
      trmAdminCmd := TAdminCmd.Create;
      trmAdminCmd.DoIt;
      trmAdminCmd.Free;
    end;
{$else}
    if (FindSwitch('help') or FindSwitch('h') or (ParamCount = 0)) then begin
      WriteLn;
      WriteLn('Usage:');
      WriteLn('      TScktAdmin.exe [-h/-help] [[-c/-connection <address>[:<port>]]');
      WriteLn;
      WriteLn('                      [[-ap/-add_port port:<portval> [timeout:<timeoutval>]]');
      WriteLn('                      [-mp/-modify_port port:<portval> timeout:<timeoutval>]');
      WriteLn('                      [-dp/-delete_port port:<portval>]]');
      WriteLn;
      WriteLn('                      [[-ew/-exclusive_work <on/off>]');
      WriteLn('                      [-apt/-add_permit <address/host>]');
      WriteLn('                      [-dpt/-delete_permit <address/host>]]');
      WriteLn;
      WriteLn('                      [-d/-disconnect <address/host>]]');
      WriteLn;
      WriteLn('Syntax:');
      WriteLn('      -h/-help               This information.');
      WriteLn;
      WriteLn('      -c/-connection         Connection parameters <address/host> and <port> for connect to server.');
      WriteLn('                             Not necessary. 127.0.0.1:211 is set by default that the same localhost:211.');
      WriteLn('                             <port> not necessary. 211 is set by default.');
      WriteLn;
      WriteLn('      -ap/-add_port port     Addition of port. timeout:<timeoutval> parameter not necessary.'); 
      WriteLn('                             <timeoutval> 0 is set by default.');
      WriteLn('      -mp/-modify_port       Modify port parameters. Set timeout:<timeoutval> for port:<portval>.');
      WriteLn('                             Required both parameters.');
      WriteLn('      -dp/-delete_port       Deletind port:<portval> from port list.');
      WriteLn;
      WriteLn('      -ew/-exclusive_work    Exclusive work for permittion list <on/off>.');
      WriteLn('      -apt/-add_permit       Addition permittion <address/host>.');
      WriteLn('      -dpt/-delete_permit    Deleting permittion <address/host>.');
      WriteLn('                             When specify <address/host> to All, will be remove all permittion.');
      WriteLn;
      WriteLn('      -d/-disconnect         Deleting connection from connection list for <address/host>.');
      WriteLn('                             When specify <address/host> to All, will be remove all connections.');
    end
    else begin
    end;
{$endif}      
end.

