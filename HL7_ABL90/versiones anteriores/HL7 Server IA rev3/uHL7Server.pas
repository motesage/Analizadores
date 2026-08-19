unit uHL7Server;

interface

uses
  Classes,
  SysUtils,
  IdTCPServer,
  IdContext,
  IdGlobal;

const
  HL7_VT  = #11;
  HL7_FS  = #28;
  HL7_CR  = #13;
  HL7_SOH = #1;
  HL7_EOT = #4;

type
  THL7FramingMode = (fmAuto, fmMLLP, fmSOHEOT);

  THL7Context = class(TObject)
  public
    Buffer : AnsiString;
  end;

  THL7MessageEvent = procedure(Sender: TObject;
                               AContext : TIdContext;
                               const Msg : AnsiString) of object;

  TLogEvent = procedure(Sender: TObject;
                        const Texto : AnsiString) of object;

  THL7Server = class(TObject)
  private
    FTCPServer : TIdTCPServer;
    FOnHL7Message : THL7MessageEvent;
    FOnLog : TLogEvent;
    FAutoACK : Boolean;
    FLogOnlyAnalyzerData : Boolean;
    FLogFolder : AnsiString;
    FFramingMode : THL7FramingMode;

    procedure IdConnect(AContext : TIdContext);
    procedure IdDisconnect(AContext : TIdContext);
    procedure IdExecute(AContext : TIdContext);
    procedure Log(const S : AnsiString);
    procedure AppendToFile(const FileName : AnsiString; const S : AnsiString);
    procedure LogASC(const S : AnsiString; IsAnalyzerData : Boolean);
    procedure LogHEX(const S : AnsiString; IsAnalyzerData : Boolean);

    function BytesToHex(const S : AnsiString) : AnsiString;
    function SafeASC(const S : AnsiString) : AnsiString;

    function ExtractMessage(var Buffer : AnsiString;
                            out Msg : AnsiString;
                            out DetectedMode : THL7FramingMode) : Boolean;

    function ExtractMLLPMessage(var Buffer : AnsiString; out Msg : AnsiString) : Boolean;
    function ExtractSOHEOTMessage(var Buffer : AnsiString; out Msg : AnsiString) : Boolean;

    function MakeACK(const Msg : AnsiString) : AnsiString;
    function ExtractMessageControlID(const Msg : AnsiString) : AnsiString;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Start(APort : Integer);
    procedure Stop;

    procedure SendRaw(AContext : TIdContext; const S : AnsiString);
    procedure SendFramed(AContext : TIdContext; const Msg : AnsiString; AMode : THL7FramingMode);
    procedure SendACK(AContext : TIdContext; const Msg : AnsiString; AMode : THL7FramingMode);

    property AutoACK : Boolean read FAutoACK write FAutoACK;
    property LogOnlyAnalyzerData : Boolean read FLogOnlyAnalyzerData write FLogOnlyAnalyzerData;
    property LogFolder : AnsiString read FLogFolder write FLogFolder;
    property FramingMode : THL7FramingMode read FFramingMode write FFramingMode;

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
  FFramingMode := fmAuto;

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
  if FTCPServer.Active then
    Stop;

  FTCPServer.DefaultPort := APort;
  FTCPServer.Active := True;
  Log('Servidor iniciado en puerto ' + IntToStr(APort));
end;

procedure THL7Server.Stop;
begin
  if FTCPServer.Active then
  begin
    FTCPServer.Active := False;
    Log('Servidor detenido');
  end;
end;

procedure THL7Server.Log(const S : AnsiString);
var
  Linea : AnsiString;
begin
  Linea := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' - ' + S;

  if Assigned(FOnLog) then
    FOnLog(Self, Linea);

  if not FLogOnlyAnalyzerData then
  begin
    LogASC(Linea, False);
    LogHEX(Linea, False);
  end;
end;

procedure THL7Server.AppendToFile(const FileName : AnsiString; const S : AnsiString);
var
  F : TextFile;
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
var
  I : Integer;
  C : Byte;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    C := Ord(S[I]);
    case C of
      1 : Result := Result + '<SOH>';
      4 : Result := Result + '<EOT>';
      9 : Result := Result + '<TAB>';
      10: Result := Result + '<LF>';
      11: Result := Result + '<VT>';
      13: Result := Result + '<CR>';
      28: Result := Result + '<FS>';
    else
      if C < 32 then
        Result := Result + '<$' + IntToHex(C, 2) + '>'
      else
        Result := Result + S[I];
    end;
  end;
end;

function THL7Server.BytesToHex(const S : AnsiString) : AnsiString;
var
  I : Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    if Result <> '' then Result := Result + ' ';
    Result := Result + IntToHex(Ord(S[I]), 2);
  end;
end;

procedure THL7Server.LogASC(const S : AnsiString; IsAnalyzerData : Boolean);
var
  FileName : AnsiString;
begin
  FileName := IncludeTrailingPathDelimiter(FLogFolder) + 'LogASC.txt';
  if IsAnalyzerData then
    AppendToFile(FileName, SafeASC(S))
  else
    AppendToFile(FileName, S);
end;

procedure THL7Server.LogHEX(const S : AnsiString; IsAnalyzerData : Boolean);
var
  FileName : AnsiString;
begin
  FileName := IncludeTrailingPathDelimiter(FLogFolder) + 'LogHEX.txt';
  AppendToFile(FileName, BytesToHex(S));
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
  if Assigned(AContext.Data) then
  begin
    AContext.Data.Free;
    AContext.Data := nil;
  end;
  Log('Cliente desconectado');
end;

function THL7Server.ExtractMLLPMessage(var Buffer : AnsiString; out Msg : AnsiString) : Boolean;
var
  P1, P2 : Integer;
begin
  Result := False;
  Msg := '';

  P1 := Pos(HL7_VT, Buffer);
  if P1 = 0 then Exit;

  if P1 > 1 then Delete(Buffer, 1, P1 - 1);

  P2 := Pos(HL7_FS + HL7_CR, Buffer);
  if P2 = 0 then Exit;

  Msg := Copy(Buffer, 2, P2 - 2);
  Delete(Buffer, 1, P2 + 1);
  Result := True;
end;

function THL7Server.ExtractSOHEOTMessage(var Buffer : AnsiString; out Msg : AnsiString) : Boolean;
var
  P1, P2 : Integer;
begin
  Result := False;
  Msg := '';

  P1 := Pos(HL7_SOH, Buffer);
  if P1 = 0 then Exit;

  if P1 > 1 then Delete(Buffer, 1, P1 - 1);

  P2 := Pos(HL7_EOT, Buffer);
  if P2 = 0 then Exit;

  Msg := Copy(Buffer, 2, P2 - 2);
  Delete(Buffer, 1, P2);
  Result := True;
end;

function THL7Server.ExtractMessage(var Buffer : AnsiString;
                                   out Msg : AnsiString;
                                   out DetectedMode : THL7FramingMode) : Boolean;
var
  TryBuffer : AnsiString;
begin
  Result := False;
  Msg := '';
  DetectedMode := FFramingMode;

  case FFramingMode of
    fmMLLP:
      begin
        Result := ExtractMLLPMessage(Buffer, Msg);
        DetectedMode := fmMLLP;
      end;
    fmSOHEOT:
      begin
        Result := ExtractSOHEOTMessage(Buffer, Msg);
        DetectedMode := fmSOHEOT;
      end;
  else
    TryBuffer := Buffer;
    if ExtractMLLPMessage(TryBuffer, Msg) then
    begin
      Buffer := TryBuffer;
      DetectedMode := fmMLLP;
      Result := True;
      Exit;
    end;

    TryBuffer := Buffer;
    if ExtractSOHEOTMessage(TryBuffer, Msg) then
    begin
      Buffer := TryBuffer;
      DetectedMode := fmSOHEOT;
      Result := True;
      Exit;
    end;
  end;

  if (not Result) and (Length(Buffer) > 8192) then
    Buffer := Copy(Buffer, Length(Buffer) - 256, 256);
end;

function THL7Server.ExtractMessageControlID(const Msg : AnsiString) : AnsiString;
var
  Linea : AnsiString;
  P, I, StartPos : Integer;
begin
  Result := '1';

  P := Pos(HL7_CR, Msg);
  if P > 0 then Linea := Copy(Msg, 1, P - 1) else Linea := Msg;

  if Copy(Linea, 1, 3) <> 'MSH' then Exit;

  StartPos := 1;
  for I := 1 to 9 do
  begin
    P := Pos('|', Copy(Linea, StartPos, MaxInt));
    if P = 0 then Exit;
    Inc(StartPos, P);
  end;

  P := Pos('|', Copy(Linea, StartPos, MaxInt));
  if P = 0 then
    Result := Copy(Linea, StartPos, MaxInt)
  else
    Result := Copy(Linea, StartPos, P - 1);

  if Result = '' then Result := '1';
end;

function THL7Server.MakeACK(const Msg : AnsiString) : AnsiString;
var
  CtrlID : AnsiString;
begin
  CtrlID := ExtractMessageControlID(Msg);

  Result :=
    'MSH|^~\&|LIS||||' +
    FormatDateTime('yyyymmddhhnnss', Now) +
    '||ACK|' +
    FormatDateTime('yyyymmddhhnnss', Now) +
    '|P|2.5' + HL7_CR +
    'MSA|AA|' + CtrlID + HL7_CR;
end;

procedure THL7Server.SendRaw(AContext : TIdContext; const S : AnsiString);
begin
  if Assigned(AContext) and Assigned(AContext.Connection) then
  begin
    AContext.Connection.IOHandler.Write(S);

    if not FLogOnlyAnalyzerData then
    begin
      LogASC('TX: ' + SafeASC(S), False);
      LogHEX('TX: ' + BytesToHex(S), False);
    end;
  end;
end;

procedure THL7Server.SendFramed(AContext : TIdContext; const Msg : AnsiString; AMode : THL7FramingMode);
begin
  case AMode of
    fmSOHEOT:
      SendRaw(AContext, HL7_SOH + Msg + HL7_EOT);
  else
    SendRaw(AContext, HL7_VT + Msg + HL7_FS + HL7_CR);
  end;
end;

procedure THL7Server.SendACK(AContext : TIdContext; const Msg : AnsiString; AMode : THL7FramingMode);
begin
  SendFramed(AContext, MakeACK(Msg), AMode);

  case AMode of
    fmSOHEOT: Log('ACK enviado con framing SOH/EOT');
    fmMLLP:   Log('ACK enviado con framing MLLP');
  else
    Log('ACK enviado');
  end;
end;

procedure THL7Server.IdExecute(AContext : TIdContext);
var
  Ctx : THL7Context;
  Datos : AnsiString;
  Msg : AnsiString;
  DetectedMode : THL7FramingMode;
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

  while ExtractMessage(Ctx.Buffer, Msg, DetectedMode) do
  begin
    case DetectedMode of
      fmSOHEOT: Log('Mensaje HL7 recibido con framing SOH/EOT');
      fmMLLP:   Log('Mensaje HL7 recibido con framing MLLP');
    else
      Log('Mensaje HL7 recibido');
    end;

    if Assigned(FOnHL7Message) then
      FOnHL7Message(Self, AContext, Msg);

    if FAutoACK then
      SendACK(AContext, Msg, DetectedMode);
  end;
end;

end.
