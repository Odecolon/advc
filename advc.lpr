program advc;

uses crt;

const

  VERSION   = '0.2';
  LOG_FILE  = 'game.log';

  {Errors}

  ERR_IO               = 1;
  ERR_SETUP            = 2;
  ERR_TOO_MANY_VARS    = 3;
  ERR_NE_VAR           = 4;
  ERR_TOO_MANY_ITEMS   = 5;
  ERR_TOO_MANY_ALIASES = 6;
  ERR_CONVERT          = 7;
  ERR_STACK_OVERFLOW   = 8;
  ERR_STACK_EMPTY      = 9;
  ERR_VERSION_CONFLICT = 10;

  ERR_SYNTAX_IF_OP     = 11;
  ERR_SYNTAX_IF_IN     = 12;
  ERR_SYNTAX_IF_THEN   = 13;
  ERR_SYNTAX_AI        = 14;
  ERR_SYNTAX_RI        = 15;
  ERR_SYNTAX_MA        = 16;
  ERR_SYNTAX_SET       = 17;
  ERR_SYNTAX_SHIFT     = 18;

  {Maxes}

  MAX_VARS    = 128;
  MAX_LEXEMS  = 16;
  MAX_ALIASES = 128;
  MAX_ITEMS   = 64;
  MAX_STACK   = 64;

type

  tVar = Object

    vName : ansistring;
    vValue: ansistring;

    procedure Init();
    procedure Let(iname: ansistring; ivalue: ansistring);

    function Convert(): integer;
    function GetName(): string;
    function GetVal() : string;

  end;

  tItem = Object

    iName   : ansistring;
    iRoom   : ansistring;

    procedure Init();
    procedure Create(inname: ansistring; inroom: ansistring);
    procedure MoveTo(inroom: ansistring);

    function CheckRoom(inroom: ansistring): boolean;

  end;

  tAlias = Object

    aOne: ansistring;
    aTwo: ansistring;

    procedure Init();
    procedure Make(ione: ansistring; itwo: ansistring);

    function Check(ione: ansistring; itwo: ansistring): boolean;
    function CheckEmpty(): boolean;

  end;

  tStack = Object

    sStack: array [1..MAX_STACK] of ansistring;

    sSP: integer;

    procedure Init();

    procedure Push(ival: ansistring);
    function  Pull(): ansistring;

  end;

var

  Vars   : array [1..MAX_VARS] of tVar;
  Items  : array [1..MAX_ITEMS] of tItem;
  Aliases: array [1..MAX_ALIASES] of tAlias;
  Stack  : tStack;

  CStr: ansistring;

  ScriptFile: text;
  LogFile   : text;

  Lexems: array [1..MAX_LEXEMS] of ansistring;

  SysEvents: ansistring;

  GameName : ansistring;
  MaxScores: integer;

  Scores: integer;
  Moves : integer;

  CurrentRoom: ansistring;
  NextRoom   : ansistring;
  RoomName   : ansistring;
  RoomDesc   : ansistring;

  Verb: ansistring;
  Obj : ansistring;

  stdi: ansistring;
  stdo: ansistring;

function UpperCase(istr: ansistring): ansistring;
{var

  istw: widestring;
  ista: ansistring;

}
begin

  {istr:= UpCase(istr);

  writeln(istr);

  WSM.Ansi2WideMoveProc(PChar(istr), 20127, istw, Length(istw));

  writeln(istw[1]);

  istw:= WSM.UpperWideStringProc(istw);

  writeln(istw);

  WSM.Wide2AnsiMoveProc(PWideChar(istw), ista, 20127, Length(istw));

  }

  UpperCase:= UpCase(istr);

end;

procedure Quit();
begin

  Close(ScriptFile);
  Close(LogFile);

end;

procedure ErrExit(icode: byte);
begin

  case icode of

       ERR_IO: begin

         writeln('ERROR #', ERR_IO, ': ERROR WITH IO');

         Halt();

       end;

       ERR_SETUP  : begin

         writeln('ERROR #', ERR_SETUP, ': ERROR WITH SETUP');

         Halt();

       end;

       ERR_TOO_MANY_VARS: begin

         writeln('ERROR #', ERR_TOO_MANY_VARS, ': TOO MANY VARIABLES');
         writeln(LogFile, 'ERROR #', ERR_TOO_MANY_VARS, ': TOO MANY VARIABLES');

       end;

       ERR_NE_VAR: begin

         writeln('ERROR #', ERR_NE_VAR, ': NON-EXIST VARIABLE');
         writeln(LogFile, 'ERROR #', ERR_NE_VAR, ': NON-EXIST VARIABLE');

       end;

       ERR_TOO_MANY_ITEMS: begin

         writeln('ERROR #', ERR_TOO_MANY_ITEMS, ': TOO MANY ITEMS');
         writeln(LogFile, 'ERROR #', ERR_TOO_MANY_ITEMS, ': TOO MANY ITEMS');

       end;

       ERR_TOO_MANY_ALIASES: begin

         writeln('ERROR #', ERR_TOO_MANY_ALIASES, ': TOO MANY ALIASES');
         writeln(LogFile, 'ERROR #', ERR_TOO_MANY_ALIASES, ': TOO MANY ALIASES');

       end;

       ERR_CONVERT: begin

         writeln('ERROR #', ERR_CONVERT, ': ERROR WITH CONVERTING OF VALUE');
         writeln(LogFile, 'ERROR #', ERR_CONVERT, ': ERROR WITH CONVERTING OF VALUE');

       end;

       ERR_SYNTAX_IF_OP: begin

         writeln('ERROR #', ERR_SYNTAX_IF_OP, ': INVALID OPERAND IN "IF" COMMAND');
         writeln(LogFile, 'ERROR #', ERR_SYNTAX_IF_OP, ': INVALID OPERAND IN "IF" COMMAND');

       end;

       ERR_SYNTAX_IF_IN: begin

         writeln('ERROR #', ERR_SYNTAX_IF_IN, ': NEED "IN" IN "IF" COMMAND');
         writeln(LogFile, 'ERROR #', ERR_SYNTAX_IF_IN, ': NEED "IN" IN "IF" COMMAND');

       end;

       ERR_SYNTAX_IF_THEN: begin

         writeln('ERROR #', ERR_SYNTAX_IF_THEN, ': NEED "THEN" IN "IF" COMMAND');
         writeln(LogFile, 'ERROR #', ERR_SYNTAX_IF_THEN, ': NEED "THEN" IN "IF" COMMAND');

       end;

       ERR_STACK_OVERFLOW: begin

         writeln('ERROR #', ERR_STACK_OVERFLOW, ': STACK OVERFLOW');
         writeln(LogFile, 'ERROR #', ERR_STACK_OVERFLOW, ': STACK OVERFLOW');

       end;

       ERR_STACK_EMPTY: begin

         writeln('ERROR #', ERR_STACK_EMPTY, ': STACK IS EMPTY');
         writeln(LogFile, 'ERROR #', ERR_STACK_EMPTY, ': STACK IS EMPTY');

       end;

       ERR_SYNTAX_AI: begin

         writeln('ERROR #', ERR_SYNTAX_AI, ': NEED "TO" IN "ADDITEM" COMMAND');
         writeln(LogFile, 'ERROR #', ERR_SYNTAX_AI, ': NEED "TO" IN "ADDITEM" COMMAND');

       end;

       ERR_SYNTAX_RI: begin

         writeln('ERROR #', ERR_SYNTAX_RI, ': NEED "FROM" IN "REMOVEITEM" COMMAND');
         writeln(LogFile, 'ERROR #', ERR_SYNTAX_RI, ': NEED "FROM" IN "REMOVEITEM" COMMAND');

       end;

       ERR_SYNTAX_MA: begin

         writeln('ERROR #', ERR_SYNTAX_MA , ': NEED "AS" IN "MAKEALIAS" COMMAND');
         writeln(LogFile, 'ERROR #', ERR_SYNTAX_MA, ': NEED "AS" IN "MAKEALIAS" COMMAND');

       end;

       ERR_SYNTAX_SET: begin

         writeln('ERROR #', ERR_SYNTAX_SET, ': NEED "=" IN "SET" COMMAND');
         writeln(LogFile, 'ERROR #', ERR_SYNTAX_SET, ': NEED "=" IN "SET" COMMAND');

       end;

       ERR_SYNTAX_SHIFT: begin

         writeln('ERROR #', ERR_SYNTAX_SHIFT, ': NEED "TO" IN "SHIFTITEM" COMMAND');
         writeln(LogFile, 'ERROR #', ERR_SYNTAX_SHIFT, ': NEED "TO" IN "SHIFTITEM" COMMAND');

       end;

       ERR_VERSION_CONFLICT: begin

         writeln('ERROR #', ERR_VERSION_CONFLICT, ': VERSION CONFLICT');
         writeln(LogFile, 'ERROR #', ERR_VERSION_CONFLICT, ': VERSION CONFLICT');

       end;

  end;

  Quit();
  Halt();

end;

{tVar - Implementation}

procedure tVar.Init();
begin

  vName := 'NO_VAR';
  vValue:= 'NO_VAL';

end;

procedure tVar.Let(iname: ansistring; ivalue: ansistring);
begin

  vName := iname;
  vValue:= ivalue;

end;

function  tVar.Convert(): integer;
var

  icode : integer;
  ivalue: integer;

begin

  Val(vValue, ivalue, icode);

  if(icode <> 0) then ErrExit(ERR_CONVERT);

  Convert:= ivalue;

end;

function tVar.GetName(): string;
begin

  GetName:= vName;

end;

function  tVar.GetVal(): string;
begin

  GetVal:= vValue;

end;

{tItem - Implementation}

procedure tItem.Init();
begin

  iName:= 'NO_ITEM';
  iRoom:= 'NO_ROOM';

end;

procedure tItem.Create(inname: ansistring; inroom: ansistring);
begin

  iName:= inname;
  iRoom:= inroom;

end;

procedure tItem.MoveTo(inroom: ansistring);
begin

  iRoom:= inroom;

end;

function tItem.CheckRoom(inroom: ansistring): boolean;
begin

  CheckRoom:= false;

  if (UpperCase(inroom) = UpperCase(iRoom)) then CheckRoom:= true;

end;

{tAlias - Implementation}

procedure tAlias.Init();
begin

  aOne:= 'NO_ALIAS';
  aTwo:= 'NO_ALIAS';

end;

procedure tAlias.Make(ione: ansistring; itwo: ansistring);
begin

  aOne:= ione;
  aTwo:= itwo;

end;

function tAlias.Check(ione: ansistring; itwo: ansistring): boolean;
begin

  Check:= false;

  if (UpperCase(ione) = UpperCase(aOne)) and (UpperCase(itwo) = UpperCase(aTwo)) then Check:= true;
  if (UpperCase(itwo) = UpperCase(aOne)) and (UpperCase(ione) = UpperCase(aTwo)) then Check:= true;

end;

function tAlias.CheckEmpty(): boolean;
begin

  CheckEmpty:= false;

  if (aOne = 'NO_ALIAS') and (aTwo = 'NO_ALIAS') then CheckEmpty:= true;

end;

{tStack - Implementation}

procedure tStack.Init();
var

  i: integer;

begin

  sSP:= 1;

  for i:= 1 to MAX_STACK do begin

    sStack[i]:= 'NO_VAL';

  end;

end;

procedure tStack.Push(ival: ansistring);
begin

     if (sSP + 1 > MAX_STACK) then ErrExit(ERR_STACK_OVERFLOW);

     sSP       := sSP + 1;
     sStack[sSP]:= ival;

end;

function tStack.Pull(): ansistring;
begin

     if (sSP = 0) then ErrExit(ERR_STACK_EMPTY);

     Pull       := sStack[sSP];
     sStack[sSP]:= 'NO_VAL';
     sSP        := sSP - 1;

end;

{Main - Impementation}

function RemoveCmdSymbols(istr: ansistring): ansistring;
var

  i: integer;

begin

  RemoveCmdSymbols:= '';

  for i:= 1 to length(istr) do begin

    if ((ord(istr[i]) <= 126) and (ord(istr[i]) >= 32)) or ((ord(istr[i]) <= 175) and (ord(istr[i]) >= 128)) or ((ord(istr[i]) <= 247) and (ord(istr[i]) >= 224)) then begin

    RemoveCmdSymbols:= RemoveCmdSymbols + istr[i];

    end;

  end;

end;

function MathRPN(iexp: ansistring): integer;
var

  i  : integer;
  ii : integer;

  mr : integer;
  mrs: ansistring;

  c  : integer;

  ic: integer;

  op: string;
  argss: array [1..2] of ansistring;
  argsi: array [1..2] of integer;

begin

  MathRPN:= 0;

  iexp:= RemoveCmdSymbols(iexp);

  for i:= 1 to length(iexp) do begin

    if (iexp[i] <> ' ') then break;

  end;

  ii := i;
  c  := 1;
  mr := 1;
  mrs:= '';
  op := '';

  while (true) do begin

    op      := '';
    argss[1]:= '';
    argsi[1]:= 0;
    argss[2]:= '';
    argsi[2]:= 0;

    for i:= ii to length(iexp) do begin

        if (iexp[i] = ' ') then c:= c + 1;
        if (c       = 3  ) then break;

        argss[c]:= argss[c] + iexp[i];

    end;

    if (argss[1] = '') or (argss[2] = '') then break;

    Val(argss[1], argsi[1], ic);
    if (ic <> 0) then exit;

    Val(argss[2], argsi[2], ic);
    if (ic <> 0) then exit;

    i:= i + 1;

    op:= iexp[i];

    case op of

         '+'  : mr:= argsi[1] + argsi[2];
         '-'  : mr:= argsi[1] - argsi[2];
         '*'  : mr:= argsi[1] * argsi[2];
         '/'  : mr:= argsi[1] div argsi[2];
         'mod': mr:= argsi[1] mod argsi[2];

         else begin

           break;

         end;

    end;

    Str(mr, mrs);

    delete(iexp, 1, i);
    insert(mrs, iexp, 1);

    ii:= 1;
    c := 1;

  end;

  Val(iexp, mr, ic);
  if (ic <> 0) then exit;

  MathRPN:= mr;

end;

function SearchVar(ivar: ansistring): integer;
var

  i: integer;

begin

  SearchVar:= 0;

  for i:= 1 to MAX_VARS do begin

    if (Vars[i].GetName() = ivar) then begin

       SearchVar:= i;

       break;

    end;

  end;

end;

function SearchEmptyVar(): integer;
var

  i: integer;

begin

  SearchEmptyVar:= 0;

  for i:= 1 to MAX_VARS do begin

    if (Vars[i].GetName() = 'NO_VAR') then begin

       SearchEmptyVar:= i;
       break;

    end;

  end;

end;

function SearchItem(iname: ansistring): integer;
var

  i: integer;

begin

  SearchItem:= 0;

  for i:= 1 to MAX_ITEMS do begin

    if (Items[i].iName = iname) then begin

       SearchItem:= i;

       break;

    end;

  end;

end;

function SearchEmptyItem(): integer;
var

  i: integer;

begin

  SearchEmptyItem:= 0;

  for i:= 1 to MAX_ITEMS do begin

    if (Items[i].iName = 'NO_ITEM') then begin

       SearchEmptyItem:= i;
       break;

    end;

  end;

end;

function SearchAlias(ione: ansistring; itwo: ansistring): boolean;
var

  i: integer;

begin

  SearchAlias:= false;

  for i:= 1 to MAX_ALIASES do begin

    if (Aliases[i].Check(ione, itwo) = true) then begin

       SearchAlias:= true;
       break;

    end;

  end;

end;

function SearchEmptyAlias(): integer;
var

  i: integer;

begin

  SearchEmptyAlias:= 0;

  for i:= 1 to MAX_ALIASES do begin

    if (Aliases[i].CheckEmpty() = true) then begin

       SearchEmptyAlias:= i;
       break;

    end;

  end;

end;

procedure ScriptParser();
var

  i :  integer;
  c :  integer;

  rv:  char;

begin

  i:= 1;
  c:= 1;

  CStr:= '';

  read(ScriptFile, rv);

  while (eof(ScriptFile) = false) and (rv <> ';') do begin

    CStr:= CStr + rv;

    read(ScriptFile, rv);

  end;

  CStr:= RemoveCmdSymbols(CStr);

  for i:= 1 to length(CStr) do begin

    if(CStr[i] <> ' ') then break;

  end;

  while (c <= MAX_LEXEMS) do begin

    Lexems[c]:= '';

    while (i <= length(CStr)) do begin

      if (CStr[i] = '"') then begin

         i:= i + 1;

         while (i <= length(CStr)) do begin

           if (CStr[i] = '"') then break;

           Lexems[c]:= Lexems[c] + CStr[i];
           i        := i + 1;

         end;

         i:= i + 1;

         break;

      end;

      if (CStr[i] <> ' ') then Lexems[c]:= Lexems[c] + CStr[i];
      if (CStr[i] = ' ') and (CStr[i + 1] <> ' ') then break;

      i:= i + 1;

    end;

    i:= i + 1;
    c:= c + 1;

  end;

end;

procedure Flush();
var

  i: integer;

begin

  for i:= 1 to MAX_LEXEMS do begin

    Lexems[i]:= 'NO_LEXEM';

  end;

  RoomName   := 'NO_NAME';
  RoomDesc   := 'NO_DESC';

  stdi:= '';
  stdo:= '';

end;

procedure SearchRoom(iroom: ansistring);
begin

  while (true) do begin

    ScriptParser();

    if (Lexems[1] = 'room') and (Lexems[2] = iroom) then begin

       break;

    end;

    if (eof(ScriptFile) = true) then reset(ScriptFile);

  end;

end;

procedure VerbParser();
var

  i : integer;
  ii: integer;

begin

  Verb:= '';
  Obj := '';

  stdi:= RemoveCmdSymbols(stdi);

  for i:= 1 to length(stdi) do begin

    if (stdi[i] <> ' ') then Verb:= Verb + stdi[i];
    if (stdi[i] = ' ') and (stdi[i + 1] <> ' ') then break;

  end;

  i := i + 1;
  ii:= i;

  for i:= ii to length(stdi) do Obj:= Obj + stdi[i];

end;

procedure Preprocessor();
var

  i   : integer;
  ii  : integer;
  ipos: integer;

  rs  : string;
  istr: string;

begin

  i   := 0;
  ii  := 0;
  ipos:= 0;
  rs  := '';
  istr:= '';

  for i:= 1 to MAX_LEXEMS do begin

    istr:= Lexems[i];
    rs  := Copy(istr, 1, 1);

    case rs of

         '$': begin

           delete(istr, 1, 1);

           if (SearchVar(istr) <> 0) then begin

             Lexems[i]:= Vars[SearchVar(istr)].GetVal();

           end else begin

             ErrExit(ERR_NE_VAR);

           end;

         end;

         '%': begin

           delete(istr, 1, 1);

           ipos:= 0;

           for ii:= 1 to MAX_VARS do begin

             if (pos(Vars[ii].GetName, istr) <> 0) then begin

                writeln('DEBUG');
                readln();

                ipos:= pos(Vars[ii].GetName, istr);

                delete(istr, ipos, length(Vars[ii].GetName));
                insert(Vars[ii].GetVal, istr, ipos);

             end;

           end;

           Str(MathRPN(istr), Lexems[i]);

         end;

    end;

  end;

end;

procedure SkipUntil(icmdin: ansistring; icmdout: ansistring);
var

   i : integer;
   ii: integer;

begin

  i := 1;
  ii:= 2;

  while (i <= ii) do begin

      while (UpperCase(Lexems[1]) <> UpperCase(icmdout)) do begin

        ScriptParser();

        if (UpperCase(Lexems[1]) = UpperCase(icmdin)) then begin

           ii:= ii + 1;

        end;

      end;

      i:= i + 1;

  end;

end;

{Commands - Implemenation}

procedure Cmd_Addscores();
var

   i : integer;
   ic: integer;

begin

   Val(Lexems[2], i, ic);

   if (ic <> 0) then ErrExit(ERR_CONVERT);

   Scores:= Scores + i;

   if (Scores > MaxScores) then Scores:= MaxScores;

end;

procedure Cmd_Delscores();
var

   i : integer;
   ic: integer;

begin

   Val(Lexems[2], i, ic);

   if (ic <> 0) then ErrExit(ERR_CONVERT);

   Scores:= Scores - i;

   if (Scores < 0) then Scores:= 0;

end;

procedure Cmd_Type();
var

  i: integer;

begin

  i:= 2;

  while (i <= MAX_LEXEMS) and (Lexems[i] <> 'NO_LEXEM') do begin

      case Lexems[i] of

           'endl': begin

             stdo:= stdo + chr(10) + chr(13);

           end;

           else begin

                if (SearchVar(Lexems[i]) <> 0) then begin

                  stdo:= stdo + Vars[SearchVar(Lexems[i])].vValue;

                end else begin

                  stdo:= stdo + Lexems[i];

                end;

           end;

      end;

      i:= i + 1;

  end;

end;

procedure Cmd_Roomname();
begin

  RoomName:= Lexems[2];

end;

procedure Cmd_Description();
begin

   RoomDesc:= Lexems[2];

end;

procedure Cmd_Set();
begin

  if (UpperCase(Lexems[1]) = 'SET') and (Lexems[3] = '=') then begin

    if (SearchVar(Lexems[2]) <> 0) then begin

      if (SearchVar(Lexems[4]) <> 0) then begin

        Vars[SearchVar(Lexems[2])].Let(Lexems[2], Vars[SearchVar(Lexems[4])].vValue);

      end else begin

        Vars[SearchVar(Lexems[2])].Let(Lexems[2], Lexems[4]);

      end;

    end else begin

      if (SearchEmptyVar() <> 0) then begin

        if (SearchVar(Lexems[4]) <> 0) then begin

           Vars[SearchEmptyVar()].Let(Lexems[2], Vars[SearchVar(Lexems[4])].vValue);

        end else begin

            Vars[SearchEmptyVar()].Let(Lexems[2], Lexems[4]);

        end;

      end else begin

        ErrExit(ERR_TOO_MANY_VARS);

      end;

    end;

  end;

end;

procedure Cmd_Go();
begin

  SysEvents:= 'GO_ROOM';
  NextRoom := Lexems[2];

end;

procedure Cmd_Additem();
begin

  if (UpperCase(Lexems[3]) <> 'TO') then ErrExit(ERR_SYNTAX_AI);

  if (Lexems[2] <> 'NO_LEXEM') and (Lexems[4] <> 'NO_LEXEM') then begin

    if (SearchItem(Lexems[2]) = 0) then begin

      if (SearchEmptyItem() <> 0) then begin

        Items[SearchEmptyItem()].Create(Lexems[2], Lexems[4]);

      end else begin

        ErrExit(ERR_TOO_MANY_ITEMS);

      end;

    end;

  end;

end;

procedure Cmd_Removeitem();
begin

  if (UpperCase(Lexems[3]) = 'FROM') then ErrExit(ERR_SYNTAX_RI);

  if (Lexems[2] <> 'NO_LEXEM') and (Lexems[4] <> 'NO_LEXEM') then begin

    if (SearchItem(Lexems[2]) <> 0) then begin

      if (UpperCase(Lexems[4]) = 'GLOBAL') then begin

        Items[SearchItem(Lexems[2])].Init();

      end;

      if (Items[SearchItem(Lexems[2])].CheckRoom(Lexems[4]) = true) then begin

        Items[SearchItem(Lexems[2])].Init();

      end;

    end;

  end;

end;

procedure Cmd_Shiftitem();
begin

  if (UpperCase(Lexems[3]) <> 'TO') then ErrExit(ERR_SYNTAX_SHIFT);

  if (Lexems[2] <> 'NO_LEXEM') and (Lexems[4] <> 'NO_LEXEM') then begin

    if (SearchItem(Lexems[2]) <> 0) then begin

      Items[SearchItem(Lexems[2])].MoveTo(Lexems[4]);

    end;

  end;

end;

procedure Cmd_Makealias();
begin

  if (UpperCase(Lexems[3]) = 'AS') then begin

     if (SearchEmptyAlias() <> 0) then begin

       Aliases[SearchEmptyAlias()].Make(Lexems[2], Lexems[4]);

     end else begin

       ErrExit(ERR_TOO_MANY_ALIASES);

     end;

  end else begin

    ErrExit(ERR_SYNTAX_MA);

  end;

end;

procedure Cmd_Verb();
begin

  if (SearchAlias(UpperCase(Verb), UpperCase(Lexems[2])) = false) and (UpperCase(Verb) <> UpperCase(Lexems[2])) then begin

     SkipUntil('verb', 'endverb');

  end else begin

    if (UpperCase(Lexems[3]) = 'WITH') then begin

    if (SearchAlias(UpperCase(Obj), UpperCase(Lexems[4])) = false) and (UpperCase(Obj) <> UpperCase(Lexems[4])) then begin

       SkipUntil('verb', 'endverb');

       exit;

    end else begin

      Verb:= 'NO_VERB';
      Obj := 'NO_OBJ';

      exit;

    end;

  end;

    Verb:= 'NO_VERB';
    Obj := 'NO_OBJ';

  end;

end;

procedure Cmd_If();
var

  a : integer;
  b : integer;
  ic: integer;

begin

  case UpperCase(Lexems[3]) of

       '=' : begin

         if (UpperCase(Lexems[5]) <> 'THEN') then ErrExit(ERR_SYNTAX_IF_THEN);
         if (Lexems[2] <> Lexems[4]) then SkipUntil('if', 'endif');

       end;

       '<>': begin

         if (UpperCase(Lexems[5]) <> 'THEN') then ErrExit(ERR_SYNTAX_IF_THEN);
         if (Lexems[2] = Lexems[4]) then SkipUntil('if', 'endif');

       end;

       '<' : begin

         Val(Lexems[2], a, ic);
         Val(Lexems[4], b, ic);

         if (ic <> 0) then ErrExit(ERR_CONVERT);
         if (UpperCase(Lexems[5]) <> 'THEN') then ErrExit(ERR_SYNTAX_IF_THEN);
         if (a > b) or (a >= b) then SkipUntil('if', 'endif');

       end;

       '>' : begin

         Val(Lexems[2], a, ic);
         Val(Lexems[4], b, ic);

         if (ic <> 0) then ErrExit(ERR_CONVERT);
         if (UpperCase(Lexems[5]) <> 'THEN') then ErrExit(ERR_SYNTAX_IF_THEN);
         if (a < b) or (a <= b) then SkipUntil('if', 'endif');

       end;

       '<=': begin

         Val(Lexems[2], a, ic);
         Val(Lexems[4], b, ic);

         if (ic <> 0) then ErrExit(ERR_CONVERT);
         if (UpperCase(Lexems[5]) <> 'THEN') then ErrExit(ERR_SYNTAX_IF_THEN);
         if (a > b) then SkipUntil('if', 'endif');

       end;

       '>=': begin

         Val(Lexems[2], a, ic);
         Val(Lexems[4], b, ic);

         if (ic <> 0) then ErrExit(ERR_CONVERT);
         if (UpperCase(Lexems[5]) <> 'THEN') then ErrExit(ERR_SYNTAX_IF_THEN);
         if (a < b) then SkipUntil('if', 'endif');

       end;

       'EXIST': begin

         if (UpperCase(Lexems[6]) <> 'THEN') then ErrExit(ERR_SYNTAX_IF_THEN);
         if (UpperCase(Lexems[4]) <> 'IN') then ErrExit(ERR_SYNTAX_IF_IN);

         if (SearchItem(Lexems[2]) = 0) then SkipUntil('if', 'endif');
         if (Items[SearchItem(Lexems[2])].CheckRoom(Lexems[5]) = false) then SkipUntil('if', 'endif');

       end;

       'DO_NOT_EXIST': begin

         if (UpperCase(Lexems[6]) <> 'THEN') then ErrExit(ERR_SYNTAX_IF_THEN);
         if (UpperCase(Lexems[4]) <> 'IN') then ErrExit(ERR_SYNTAX_IF_IN);
         if (SearchItem(Lexems[2]) <> 0) and (Items[SearchItem(Lexems[2])].CheckRoom(Lexems[5]) = true) then SkipUntil('if', 'endif');

       end;

       else begin

         ErrExit(ERR_SYNTAX_IF_OP);

       end;

  end;

end;

procedure Cmd_Do();
begin

  Stack.Push(CurrentRoom);
  CurrentRoom:= Lexems[2];
  SearchRoom(Lexems[2]);

end;

procedure Cmd_Return();
var

  PreRoom: ansistring;

begin

  PreRoom    := CurrentRoom;
  CurrentRoom:= Stack.Pull();
  SearchRoom(CurrentRoom);

  while (UpperCase(Lexems[1]) <> 'DO') and (UpperCase(Lexems[2]) <> UpperCase(PreRoom)) do ScriptParser();

end;

{Structure - Impementation}

procedure ExecuteCmd();
begin

  case UpperCase(Lexems[1]) of

       'ADDSCORES'  : Cmd_Addscores();
       'DELSCORES'  : Cmd_Delscores();
       'TYPE'       : Cmd_Type();
       'ROOMNAME'   : Cmd_Roomname();
       'DESCRIPTION': Cmd_Description();
       'SET'        : Cmd_Set();
       'GO'         : Cmd_Go();
       'ADDITEM'    : Cmd_Additem();
       'REMOVEITEM' : Cmd_Removeitem();
       'MAKEALIAS'  : Cmd_Makealias();
       'SHIFTITEM'  : Cmd_Shiftitem();
       'VERB'       : Cmd_Verb();
       'IF'         : Cmd_If();
       'DO'         : Cmd_Do();
       'RETURN'     : Cmd_Return();

       else begin

       end;

  end;

end;

procedure IrregularVerbs();
var

  i: integer;

begin

  if (SearchAlias(Verb, 'инвентарь') = true) or (UpperCase(Verb) = 'инвентарь') then begin

    writeln();
    writeln('В инвентаре:');
    writeln();

    for i:= 1 to MAX_ITEMS do begin

      if (Items[i].CheckRoom('INVENTORY') = true) then writeln(Items[i].iName);

    end;

    readln();

  end;

  if (SearchAlias(Verb, 'INVENTORY') = true) or (UpperCase(Verb) = 'INVENTORY') then begin

    writeln();
    writeln('In inventory:');
    writeln();

    for i:= 1 to MAX_ITEMS do begin

      if (Items[i].CheckRoom('INVENTORY') = true) then writeln(Items[i].iName);

    end;

    readln();

  end;

  if (SearchAlias(Verb, 'выход') = true) or (UpperCase(Verb) = 'выход') then begin

    SysEvents:= 'END_GAME';

  end;

  if (SearchAlias(Verb, 'EXIT') = true) or (UpperCase(Verb) = 'EXIT') then begin

    SysEvents:= 'END_GAME';

  end;

end;

procedure Interpreter();
begin

  while(UpperCase(Lexems[1]) <> 'ENDROOM') do begin

    ScriptParser();
    Preprocessor();
    ExecuteCmd();

  end;

  case SysEvents of

       'GO_ROOM': begin

         SearchRoom(NextRoom);

         CurrentRoom:= NextRoom;
         SysEvents  := 'STAY';

         Flush();
         Interpreter();

       end;

       'STAY'   : begin

         SearchRoom(CurrentRoom);

       end;

  end;

end;

procedure UserInterface();
begin

  writeln(LogFile, '--------------------');
  writeln(LogFile, 'SCORES: ', Scores, ' OF ', MaxScores, ' / MOVES: ', Moves, ' - ', GameName);
  writeln(LogFile, '');

  textbackground(0);
  textcolor(3);

  gotoxy(1, 24);

  writeln();
  writeln(logfile, '');

  if (RoomName <> 'NO_NAME') then begin

     writeln(RoomName);
     writeln(LogFile, RoomName);

  end;

  textbackground(0);
  textcolor(7);

  if (RoomDesc <> 'NO_DESC') then begin

     writeln('');
     writeln(LogFile, '');
     writeln(RoomDesc);
     writeln(LogFile, RoomDesc);

  end;

  if (stdo <> '') then begin

     writeln('');
     writeln(LogFile, '');
     writeln(stdo);
     writeln(LogFile, stdo);

  end else begin

     writeln('');
     writeln(LogFile, '');

  end;

  textbackground(4);
  textcolor(14);

  gotoxy(1, 1);

  while (wherey <> 2) do write(' ');

  gotoxy(1, 1);

  writeln('SCORES: ', scores, ' / MOVES: ', moves, ' - ', gamename);

  textbackground(0);
  textcolor(15);

  gotoxy(1, 25);

  write('>');
  write(LogFile, '>');

  readln(stdi);
  writeln(LogFile, stdi);

  VerbParser();
  IrregularVerbs();

  writeln('');
  writeln(LogFile, '');

  Moves:= Moves + 1;

end;

procedure GameCycle();
begin

  while(SysEvents <> 'END_GAME') do begin

    Interpreter();
    UserInterface();
    Flush();

  end;

  Quit();

end;

procedure Setup();
var

  i: integer;

  iscript: ansistring;
  ilog   : ansistring;

begin

  iscript:= 'NO_FILE';
  ilog   := LOG_FILE;

  if (ParamCount <> 0) then begin

     for i:= 1 to ParamCount do begin

       if(ParamStr(i + 1) <> '') then begin

       if(ParamStr(i) = '-game') then iscript:= ParamStr(i + 1);
       if(ParamStr(i) = '-log')  then ilog   := ParamStr(i + 1);

       end;

     end;

  end else begin

    writeln('');
    writeln('advc v0.2 by Odecolon - a simple IF engine');
    writeln('');
    writeln('Use:  advc -game %gamefile% -log %logfile%');
    writeln('');

    halt(0);

  end;

  Assign(LogFile, ilog);
  Rewrite(LogFile);

  if IOResult <> 0 then ErrExit(ERR_IO);

  if (iscript = 'NO_FILE') then ErrExit(ERR_SETUP);

  Assign(ScriptFile, iscript);
  Reset(ScriptFile);

  if IOResult <> 0 then ErrExit(ERR_IO);

  clrscr();
  TextMode(Co80);

  while (UpCase(Lexems[1]) <> '#CONFIG') do begin

    ScriptParser();

    if (EOF(ScriptFile) = true) then Reset(ScriptFile);

  end;

  while (UpCase(Lexems[1]) <> '#ENDCONFIG') do begin

    ScriptParser();
    Preprocessor();

    case UpCase(Lexems[1]) of

         '#GAMENAME': begin

           GameName:= Lexems[2];

         end;

         '#MAXSCORES': begin

           Val(Lexems[2], MaxScores, i);
           if (i <> 0)  then ErrExit(ERR_CONVERT);

         end;

         '#VERSION_ADVC': begin

           if (Lexems[2] <> VERSION) then ErrExit(ERR_VERSION_CONFLICT);

         end;

    end;

  end;

  SearchRoom(CurrentRoom);

end;

procedure Init();
var

  i : integer;

begin

  for i:= 1 to MAX_VARS do begin

    Vars[i].Init();

  end;

  for i:= 1 to MAX_LEXEMS do begin

    Lexems[i]:= 'NO_LEXEM';

  end;

  for i:= 1 to MAX_ITEMS do begin

    Items[i].Init();

  end;

  for i:= 1 to MAX_ALIASES do begin

    Aliases[i].Init();

  end;

  Stack.Init();

  SysEvents:= 'STAY';

  Scores:= 0;
  Moves := 0;

  GameName := 'NO_NAME';
  MaxScores:= 0;

  CurrentRoom:= 'start';
  NextRoom   := 'NO_ROOM';
  RoomName   := 'NO_NAME';
  RoomDesc   := 'NO_DESC';

  stdi:= '';
  stdo:= '';

end;

begin

  Init();
  Setup();

  GameCycle();

end.

