unit LogFunc;

interface
uses
	Windows;

procedure OpenLog(NameFileLog: String); stdcall;
procedure WriteToLog(P: Pointer; Amount: Cardinal); stdcall;
procedure WriteToLogR(P: Pointer; Amount: Cardinal); stdcall;
procedure CloseLog; stdcall;

const
	SizeDelim			= 2;
	DelimLofFile: WORD	= WORD($0D0A);
	DelimLofFileR: WORD	= WORD($e11e);

var
	HandleLog:	Cardinal = 0;
	EnableLog:	Boolean = false;

implementation

//=======================================================================OpenLog
procedure OpenLog(NameFileLog: String); stdcall;
begin
	HandleLog := CreateFile(PChar(NameFileLog), GENERIC_READ or GENERIC_WRITE,
							 0, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
	EnableLog := (HandleLog <> INVALID_HANDLE_VALUE)and(HandleLog > 0);
  if EnableLog then
    SetFilePointer(HandleLog, 0, nil, FILE_END);
end;

//====================================================================WriteToLog
procedure WriteToLog(P: Pointer; Amount: Cardinal); stdcall;
var
	AmountWritten:	Cardinal;
begin
	if EnableLog then begin
		AmountWritten := 0;
		if WriteFile(HandleLog, P^, Amount, AmountWritten, nil) then
			if BOOL(AmountWritten) then
				WriteFile(HandleLog, DelimLofFile, SizeDelim, AmountWritten, nil);
	end;
end;

//===================================================================WriteToLogR
procedure WriteToLogR(P: Pointer; Amount: Cardinal); stdcall;
var
	AmountWritten:	Cardinal;
begin
	if EnableLog then begin
		AmountWritten := 0;
		if WriteFile(HandleLog, P^, Amount, AmountWritten, nil) then
			if BOOL(AmountWritten) then
				WriteFile(HandleLog, DelimLofFileR, SizeDelim, AmountWritten, nil);
	end;
end;

//======================================================================CloseLog
procedure CloseLog; stdcall;
begin
	if EnableLog then CloseHandle(HandleLog);
end;

end.
