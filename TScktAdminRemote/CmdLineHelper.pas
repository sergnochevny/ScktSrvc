unit CmdLineHelper;

interface

uses windows;
//type
// TStringDynArray = array of string;

//command line parameters + program path
function GetCommandLine: string;
//number of parameters
function GetParamCount: Integer;
//parameter by index
function GetParamStr(Index: Integer): String;

implementation

(*
var
  Args:TStringDynArray;

procedure ParseCmdLine(CmdLine:PChar;var Args:TStringDynArray);
  function ProcessArgument(var P:PChar;Arg:PChar):Integer;
  var
    InQuote:Boolean;//True = inside quotes
    CopyChar:Boolean;//True = copy char to *args
    NumSlash:Integer;//num of backslashes seen
  begin
    Result:=0;
    InQuote:=False;
    //loop through scanning one argument
    while True do begin
      CopyChar:=True;
      //Rules: 2N backslashes + " ==> N backslashes and begin/end quote
      //2N+1 backslashes + " ==> N backslashes + literal "
      //N backslashes ==> N backslashes
      NumSlash:=0;
      while P^='\' do begin
        //count number of backslashes for use below
        Inc(P);
        Inc(NumSlash);
      end;
      if P^='"' then begin
        //if 2N backslashes before, start/end quote, otherwise
        //copy literally
        if not Odd(NumSlash) then begin
          if InQuote and(P[1]='"') then
            Inc(P)//Double quote inside quoted string
                  //skip first quote char and copy second
          else
            CopyChar:=False;//don't copy quote
          InQuote:=not InQuote;
        end;
        NumSlash:=NumSlash div 2;//divide numslash by two
      end;
      //copy slashes
      if (NumSlash>0)and Assigned(Arg) then begin
        FillChar(Arg^,NumSlash,'\');
        Inc(Arg,NumSlash);
      end;
      Inc(Result,NumSlash);
      //if at end of arg, break loop
      if (P^=#0)or((not InQuote and((P^=' ')or(P^=#9)))) then
        Break;
      //copy character into argument
      if CopyChar then begin
        if Assigned(Arg) then begin
          Arg^:=P^;
          Inc(Arg);
        end;
        Inc(Result);
      end;
      Inc(P);
    end;
  end;
var
  First,P:PChar;
begin
  //first scan the program name, copy it, and count the bytes
  P:=CmdLine;
  SetLength(Args,1);//the program name at least
  //A quoted program name is handled here. The handling is much
  //simpler than for other arguments. Basically, whatever lies
  //between the leading double-quote and next one, or a terminal null
  //character is simply accepted. Fancier handling is not required
  //because the program name must be a legal NTFS/HPFS file name.
  //Note that the double-quote characters are not copied, nor do they
  //contribute to numchars.}
  if P^='"' then begin
    //scan from just past the first double-quote through the next
    //double-quote, or up to a null, whichever comes first
    Inc(P);
    First:=P;
    while (P^<>'"')and(P^<>#0) do
      Inc(P);
    SetString(Args[0],First,P-First);
    //if we stopped on a double-quote (usual case), skip over it
    if P^='"' then Inc(P);
  end
  else begin
    //Not a quoted program name
    First:=P;
    while (P^<>' ')and(P^<>#9)and(P^<>#0) do
      Inc(P);
    SetString(Args[0],First,P-First);
  end;
  //loop on each argument
  while True do begin
    while (P^=' ')or(P^=#9) do
      Inc(P);
    if P^=#0 then Break;//end of args
    //scan an argument
    SetLength(Args,Length(Args)+1);
    //first find out how much space is needed to store arg
    //and allocate it
    First:=P;
    SetLength(Args[High(Args)],ProcessArgument(First,nil));
    //second store arg in string
    ProcessArgument(P,Pointer(Args[High(Args)]));
  end;
end;

procedure InitArgs;
var
  Temp:TStringDynArray;
  Buffer:array[0..260] of Char;
begin
  ParseCmdLine(GetCommandLine,Temp);
  SetString(Temp[0],Buffer,GetModuleFileName(0,Buffer,SizeOf(Buffer)));
  if InterlockedCompareExchange(Pointer(Args),Pointer(Temp),nil)=nil then
    Pointer(Temp):=nil;
end;

function GetParamCount:Integer;
begin
  if Length(Args)=0 then InitArgs;
  Result:=High(Args);
end;

function GetParamStr(Index:Integer):string;
begin
  if Length(Args)=0 then InitArgs;
  if (Index>=0)and(Index<Length(Args)) then
    Result:=Args[Index]
  else
    Result:='';
end;
*)

function GetCommandLine : string;
begin
  result := windows.GetCommandLine;
end;

function GetNextParam(var CmdLine: PChar; Buffer: PChar; Len: PInteger): Boolean;
var
  InQuotedStr, IsOdd: Boolean;
  NumSlashes, NewLen, cnt: Integer;
begin
  Result := False;
  if Len <> nil then Len^ := 0;
  if CmdLine = nil then Exit;
  while (CmdLine^ <= ' ') and (CmdLine^ <> #0) do CmdLine := CharNext(CmdLine) ;
  if CmdLine^ = #0 then Exit;
  InQuotedStr := False;
  NewLen := 0;
  repeat
    if CmdLine^ = '\' then
    begin
      NumSlashes := 0;
      repeat
        Inc(NumSlashes) ;
        CmdLine := CharNext(CmdLine) ;
      until CmdLine^ <> '\';
      if CmdLine^ = '"' then
      begin
        IsOdd := (NumSlashes mod 2) <> 0;
        NumSlashes := NumSlashes div 2;
        Inc(NewLen, NumSlashes) ;
        if IsOdd then Inc(NewLen) ;
        if Buffer <> nil then
        begin
          for cnt := 0 to NumSlashes-1 do
          begin
            Buffer^ := '\';
            Inc(Buffer) ;
          end;
          if IsOdd then
          begin
            Buffer^ := '"';
            Inc(Buffer) ;
          end;
        end;
        if IsOdd then CmdLine := CharNext(CmdLine) ;
      end else
      begin
        Inc(NewLen, NumSlashes) ;
        if Buffer <> nil then
        begin
          for cnt := 0 to NumSlashes-1 do
          begin
            Buffer^ := '\';
            Inc(Buffer) ;
          end;
        end;
      end;
      Continue;
    end;
    if CmdLine^ <> '"' then
    begin
      if (CmdLine^ <= ' ') and (not InQuotedStr) then Break;
      Inc(NewLen) ;
      if Buffer <> nil then
      begin
        Buffer^ := CmdLine^;
        Inc(Buffer) ;
      end;
    end
    else
      InQuotedStr := not InQuotedStr;
    CmdLine := CharNext(CmdLine) ;
  until CmdLine^ = #0;
  if Len <> nil then Len^ := NewLen;
  Result := True;
end;

function GetParamCount: Integer;
var
  CmdLine: PChar;
begin
  Result := 0;
  CmdLine := windows.GetCommandLine;
  GetNextParam(CmdLine, nil, nil) ;
  while GetNextParam(CmdLine, nil, nil) do Inc(Result) ;
end;

function GetParamStr(Index: Integer): String;
var
  Buffer: array[0..MAX_PATH] of Char;
  CmdLine, P: PChar;
  Len: Integer;
begin
  Result := '';
  if Index <= 0 then
  begin
    Len := GetModuleFileName(0, Buffer, MAX_PATH+1) ;
    SetString(Result, Buffer, Len) ;
  end else
  begin
    CmdLine := windows.GetCommandLine;
    GetNextParam(CmdLine, nil, nil) ;
    repeat
      Dec(Index) ;
      if Index = 0 then Break;
      if not GetNextParam(CmdLine, nil, nil) then Exit;
    until False;
    P := CmdLine;
    if GetNextParam(P, nil, @Len) then
    begin
      SetLength(Result, Len) ;
      GetNextParam(CmdLine, PChar(Result), nil) ;
    end;
  end;
end;

end.
