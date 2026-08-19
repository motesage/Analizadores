unit uHL7Server;

interface

uses
  Classes, SysUtils, IdTCPServer, IdContext, IdGlobal;

const
  HL7_VT = #11;
  HL7_FS = #28;
  HL7_CR = #13;

type
  THL7Context = class(TObject)
  public
    Buffer : AnsiString;
  end;

  THL7MessageEvent = procedure(Sender: TObject; AContext : TIdContext; const Msg : AnsiString) of object;
  TLogEvent = procedure(Sender: TObject; const Texto : AnsiString) of object;

  THL7Server = class(TObject)
  private
    FTCPServer : TIdTCPServer;
    FOnHL7Message : THL7MessageEvent;
    FOnLog : TLogEvent;
    FAutoACK : Boolean;
    FLogOnlyAnalyzerData : Boolean;
    FLogFolder : AnsiString;
    procedure IdConnect(AContext : TIdContext);
    procedure IdDisconnect(AContext : TIdContext);
    procedure IdExecute(AContext : TIdContext);
    procedure Log(const S : AnsiString);
    procedure AppendToFile(const FileName : AnsiString; const S : AnsiString);
    procedure LogASC(const S : AnsiString; IsAnalyzerData : Boolean);
    procedure LogHEX(const S : AnsiString; IsAnalyzerData : Boolean);
    function BytesToHex(const S : AnsiString) : AnsiString;
    function SafeASC(const S : AnsiString) : AnsiString;
    function ExtractMLLPMessage(var Buffer : AnsiString; out Msg : AnsiString) : Boolean;
    function MakeACK(const Msg : AnsiString) : AnsiString;
    function ExtractMessageControlID(const Msg : AnsiString) : AnsiString;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start(APort : Integer);
    procedure Stop;
    procedure SendRaw(AContext : TIdContext; const S : AnsiString);
    procedure SendMLLP(AContext : TIdContext; const Msg : AnsiString);
    procedure SendACK(AContext : TIdContext; const Msg : AnsiString);
    property AutoACK : Boolean read FAutoACK write FAutoACK;
    property LogOnlyAnalyzerData : Boolean read FLogOnlyAnalyzerData write FLogOnlyAnalyzerData;
    property LogFolder : AnsiString read FLogFolder write FLogFolder;
    property OnHL7Message : THL7MessageEvent read FOnHL7Message write FOnHL7Message;
    property OnLog : TLogEvent read FOnLog write FOnLog;
  end;

implementation

constructor THL7Server.Create;
begin
  inherited Create;
  FAutoACK := True;
  FLogOnlyAnalyzerData := False;
  FLogFolder := ExtractFilePath(ParamStr(0));
  FTCPServer := TIdTCPServer.Create(nil);
  FTCPServer.DefaultPort := 5000;
  FTCPServer.OnConnect := IdConnect;
  FTCPServer.OnDisconnect := IdDisconnect;
  FTCPServer.OnExecute := IdExecute;
end;

destructor THL7Server.Destroy;
begin
  Stop;
  FTCPServer.Free;
  inherited;
end;

procedure THL7Server.Start(APort : Integer);
begin
  if FTCPServer.Active then Stop;
  FTCPServer.DefaultPort := APort;
  FTCPServer.Active := True;
  Log('Servidor iniciado en puerto ' + IntToStr(APort));
end;

procedure THL7Server.Stop;
begin
  if FTCPServer.Active then begin
    FTCPServer.Active := False;
    Log('Servidor detenido');
  end;
end;

procedure THL7Server.Log(const S : AnsiString);
var Linea : AnsiString;
begin
  Linea := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' - ' + S;
  if Assigned(FOnLog) then FOnLog(Self, Linea);
  if not FLogOnlyAnalyzerData then begin
    LogASC(Linea, False);
    LogHEX(Linea, False);
  end;
end;

procedure THL7Server.AppendToFile(const FileName : AnsiString; const S : AnsiString);
var F : TextFile;
begin
  AssignFile(F, FileName);
  if FileExists(FileName) then Append(F) else Rewrite(F);
  try
    WriteLn(F, S);
  finally
    CloseFile(F);
  end;
end;

function THL7Server.SafeASC(const S : AnsiString) : AnsiString;
var I : Integer; C : Byte;
begin
  Result := '';
  for I := 1 to Length(S) do begin
    C := Ord(S[I]);
    case C of
      13: Result := Result + '<CR>';
      10: Result := Result + '<LF>';
      11: Result := Result + '<VT>';
      28: Result := Result + '<FS>';
      9 : Result := Result + '<TAB>';
    else
      if C < 32 then Result := Result + '<$' + IntToHex(C, 2) + '>'
      else Result := Result + S[I];
    end;
  end;
end;

function THL7Server.BytesToHex(const S : AnsiString) : AnsiString;
var I : Integer;
begin
  Result := '';
  for I := 1 to Length(S) do begin
    if Result <> '' then Result := Result + ' ';
    Result := Result + IntToHex(Ord(S[I]), 2);
  end;
end;

procedure THL7Server.LogASC(const S : AnsiString; IsAnalyzerData : Boolean);
var FileName : AnsiString;
begin
  FileName := IncludeTrailingPathDelimiter(FLogFolder) + 'LogASC.txt';
  if IsAnalyzerData then AppendToFile(FileName, SafeASC(S))
  else AppendToFile(FileName, S);
end;

procedure THL7Server.LogHEX(const S : AnsiString; IsAnalyzerData : Boolean);
var FileName : AnsiString;
begin
  FileName := IncludeTrailingPathDelimiter(FLogFolder) + 'LogHEX.txt';
  if IsAnalyzerData then AppendToFile(FileName, BytesToHex(S))
  else AppendToFile(FileName, S);
end;

procedure THL7Server.IdConnect(AContext : TIdContext);
begin
  AContext.Data := THL7Context.Create;
  THL7Context(AContext.Data).Buffer := '';
  try
    Log('Cliente conectado: ' + AContext.Connection.Socket.Binding.PeerIP);
  except
    Log('Cliente conectado');
  end;
end;

procedure THL7Server.IdDisconnect(AContext : TIdContext);
begin
  if Assigned(AContext.Data) then begin
    AContext.Data.Free;
    AContext.Data := nil;
  end;
  Log('Cliente desconectado');
end;

function THL7Server.ExtractMLLPMessage(var Buffer : AnsiString; out Msg : AnsiString) : Boolean;
var P1, P2 : Integer;
begin
  Result := False; Msg := '';
  P1 := Pos(HL7_VT, Buffer);
  if P1 = 0 then begin
    if Length(Buffer) > 4096 then Buffer := Copy(Buffer, Length(Buffer) - 128, 128);
    Exit;
  end;
  if P1 > 1 then Delete(Buffer, 1, P1 - 1);
  P2 := Pos(HL7_FS + HL7_CR, Buffer);
  if P2 = 0 then Exit;
  Msg := Copy(Buffer, 2, P2 - 2);
  Delete(Buffer, 1, P2 + 1);
  Result := True;
end;

function THL7Server.ExtractMessageControlID(const Msg : AnsiString) : AnsiString;
var Linea : AnsiString; P, I, StartPos : Integer;
begin
  Result := '1';
  P := Pos(HL7_CR, Msg);
  if P > 0 then Linea := Copy(Msg, 1, P - 1) else Linea := Msg;
  if Copy(Linea, 1, 3) <> 'MSH' then Exit;
  StartPos := 1;
  for I := 1 to 9 do begin
    P := Pos('|', Copy(Linea, StartPos, MaxInt));
    if P = 0 then Exit;
    Inc(StartPos, P);
  end;
  P := Pos('|', Copy(Linea, StartPos, MaxInt));
  if P = 0 then Result := Copy(Linea, StartPos, MaxInt)
  else Result := Copy(Linea, StartPos, P - 1);
  if Result = '' then Result := '1';
end;

function THL7Server.MakeACK(const Msg : AnsiString) : AnsiString;
var CtrlID : AnsiString;
begin
  CtrlID := ExtractMessageControlID(Msg);
  Result :=
    'MSH|^~\&|LIS||||' + FormatDateTime('yyyymmddhhnnss', Now) +
    '||ACK|' + FormatDateTime('yyyymmddhhnnss', Now) + '|P|2.3' + HL7_CR +
    'MSA|AA|' + CtrlID + HL7_CR;
end;

procedure THL7Server.SendRaw(AContext : TIdContext; const S : AnsiString);
begin
  if Assigned(AContext) and Assigned(AContext.Connection) then begin
    AContext.Connection.IOHandler.Write(S);
    if not FLogOnlyAnalyzerData then begin
      LogASC('TX: ' + SafeASC(S), False);
      LogHEX('TX: ' + BytesToHex(S), False);
    end;
  end;
end;

procedure THL7Server.SendMLLP(AContext : TIdContext; const Msg : AnsiString);
begin
  SendRaw(AContext, HL7_VT + Msg + HL7_FS + HL7_CR);
end;

procedure THL7Server.SendACK(AContext : TIdContext; const Msg : AnsiString);
begin
  SendMLLP(AContext, MakeACK(Msg));
  Log('ACK enviado');
end;

procedure THL7Server.IdExecute(AContext : TIdContext);
var Ctx : THL7Context; Datos, Msg : AnsiString;
begin
  if not Assigned(AContext) then Exit;
  if not Assigned(AContext.Connection) then Exit;
  if not Assigned(AContext.Connection.IOHandler) then Exit;
  Ctx := THL7Context(AContext.Data);
  if not Assigned(Ctx) then Exit;
  if not AContext.Connection.IOHandler.CheckForDataOnSource(100) then Exit;
  Datos := AContext.Connection.IOHandler.InputBuffer.ExtractToString;
  if Datos = '' then Exit;
  Log('RX bytes: ' + IntToStr(Length(Datos)));
  LogASC(Datos, True);
  LogHEX(Datos, True);
  Ctx.Buffer := Ctx.Buffer + Datos;
  while ExtractMLLPMessage(Ctx.Buffer, Msg) do begin
    Log('Mensaje HL7 MLLP recibido');
    if Assigned(FOnHL7Message) then FOnHL7Message(Self, AContext, Msg);
    if FAutoACK then SendACK(AContext, Msg);
  end;
end;

end.
