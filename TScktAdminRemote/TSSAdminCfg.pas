unit TSSAdminCfg;

interface
uses
	windows, sysutils, inifiles;

type

	TScktAdmCfg = class(TObject)
	private
		FCfgFileExists: boolean;
		FCfgFileName: string;
		FPort: String;
		FHost: String;
    FAddress: string;
		procedure ReadCfg;
		procedure WriteAddress(CfgFile: TIniFile=nil);
		procedure SetAddress(Value: String);
    procedure ReadCmdCfgFileName(var sFileName: string);
	public
		constructor Create;
		destructor Destroy; override;
		procedure WriteCfg();
    property Address: String read FAddress write SetAddress;
	end;

var
	trmScktAdmCfg: TScktAdmCfg=nil;

implementation
uses
  StrFunc, StrUtils, tScktCmd;
  
const
	cCfgFileExt = '.cfg';
	csConnection  = 'Connection';
	ckHost   = 'Host';
	ckPort   = 'Port';
	cvPort      = 211;

procedure TScktAdmCfg.ReadCmdCfgFileName(var sFileName: string);
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

//========================================================================Create
constructor TScktAdmCfg.Create;
var
	s: string;
begin
	inherited Create;
	FCfgFileName:='';
	s:=system.ParamStr(0);
	if Length(s)>4 then begin
    FCfgFileName:=ChangeFileExt(s,cCfgFileExt);
    ReadCmdCfgFileName(FCfgFileName);
		FCfgFileExists:=FileExists(FCfgFileName);
		if not FCfgFileExists then WriteCfg();
		ReadCfg;
  end;
end;

//=======================================================================ReadCfg
procedure TScktAdmCfg.ReadCfg;
var
	CfgFile: TINIFile;
begin
	CfgFile:=nil;
	if Length(FCfgFileName)>0 then
		try
			CfgFile:=TIniFile.Create(FCfgFileName);
      FHost:=CfgFile.ReadString(csConnection,ckHost,'');
      FPort:=CfgFile.ReadString(csConnection,ckPort,'');
      if (Length(FHost)>0) then begin
        FAddress:=FHost;
        if (length(FPort)>0) then
			    FAddress:=FAddress+':'+FPort;
      end;
		finally
			CfgFile.Free;
		end;
end;

//=====================================================================WritePort
procedure TScktAdmCfg.WriteAddress(CfgFile: TIniFile=nil);
var
	FreeINIFile: boolean;
begin
	if Length(FCfgFileName)=0 then Exit;
	FreeINIFile:=False;
	if CfgFile=nil then	begin
		CfgFile:=TIniFile.Create(FCfgFileName);
		FreeINIFile:=True;
	end;
	try
    FHost:=StrFunc.ExtractWord(FAddress,':',1);
    FPort:=StrFunc.ExtractWord(FAddress,':',2);
    CfgFile.WriteString(csConnection,ckHost,FHost);
    CfgFile.WriteString(csConnection,ckPort,FPort);
	finally
		if FreeINIFile then CfgFile.Free;
	end;
end;

//======================================================================WriteCfg
procedure TScktAdmCfg.WriteCfg();
var
	CfgFile: TINIFile;
begin
	if Length(FCfgFileName)=0 then Exit;
	CfgFile:=TIniFile.Create(FCfgFileName);
	try
		WriteAddress(CfgFile);
	finally
		CfgFile.Free;
	end;
end;

//=======================================================================Destroy
destructor TScktAdmCfg.Destroy;
begin
	inherited Destroy;
end;

procedure TScktAdmCfg.SetAddress(Value: String);
begin
		FAddress := Value;
end;

initialization

finalization
	trmScktAdmCfg.Free;

end.
