unit uHL7Server;

interface

uses
  Classes, SysUtils, IniFiles, IdTCPServer, IdContext, IdGlobal;

const
  HL7_VT  = #11;  HL7_FS  = #28;  HL7_CR  = #13;  HL7_LF  = #10;
  HL7_SOH = #1;   HL7_EOT = #4;

type
  THL7FramingMode = (fmAuto, fmMLLP, fmRadiometerTCP);

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
    FPort : Integer;
    FAutoACK : Boolean;
    FLogOnlyAnalyzerData : Boolean;
    FGenerateLogASC : Boolean;
    FGenerateLogHEX : Boolean;
    FLogFolder : AnsiString;
    FOutputFolder : AnsiString;
    FFilePrefix : AnsiString;
    FFramingMode : THL7FramingMode;

    procedure IdConnect(AContext : TIdContext);
    procedure IdDisconnect(AContext : TIdContext);
    procedure IdExecute(AContext : TIdContext);
    function IniFileName : AnsiString;
    function NormalizeFolder(const S : AnsiString) : AnsiString;
    procedure EnsureFolder(const Folder : AnsiString);
    function FramingToText(Mode : THL7FramingMode) : AnsiString;
    function TextToFraming(const S : AnsiString) : THL7FramingMode;
    procedure Log(const S : AnsiString);
    procedure AppendToFileRaw(const FileName : AnsiString; const S : AnsiString);
    procedure SaveTextFileRaw(const FileName : AnsiString; const S : AnsiString);
    procedure LogASC(const S : AnsiString; IsAnalyzerData : Boolean);
    procedure LogHEX(const S : AnsiString);
    function BytesToHex(const S : AnsiString) : AnsiString;
    function SafeASC(const S : AnsiString) : AnsiString;
    function NormalizeAnalyzerASC(const S : AnsiString) : AnsiString;
    function NormalizeHL7ForRES(const Msg : AnsiString) : AnsiString;
    function BuildPacketFileName : AnsiString;
    procedure SavePacketFiles(const Msg : AnsiString; const RawFrame : AnsiString);
    function ExtractMessage(var Buffer : AnsiString; out Msg : AnsiString; out RawFrame : AnsiString; out DetectedMode : THL7FramingMode) : Boolean;
    function ExtractMLLPMessage(var Buffer : AnsiString; out Msg : AnsiString; out RawFrame : AnsiString) : Boolean;
    function ExtractRadiometerMessage(var Buffer : AnsiString; out Msg : AnsiString; out RawFrame : AnsiString) : Boolean;
    function MakeACK(const Msg : AnsiString) : AnsiString;
    function ExtractMessageControlID(const Msg : AnsiString) : AnsiString;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadConfig;
    procedure SaveConfig;
    procedure Start(APort : Integer);
    procedure Stop;
    procedure SendRaw(AContext : TIdContext; const S : AnsiString);
    procedure SendFramed(AContext : TIdContext; const Msg : AnsiString; AMode : THL7FramingMode);
    procedure SendACK(AContext : TIdContext; const Msg : AnsiString; AMode : THL7FramingMode);
    property Port : Integer read FPort write FPort;
    property AutoACK : Boolean read FAutoACK write FAutoACK;
    property LogOnlyAnalyzerData : Boolean read FLogOnlyAnalyzerData write FLogOnlyAnalyzerData;
    property GenerateLogASC : Boolean read FGenerateLogASC write FGenerateLogASC;
    property GenerateLogHEX : Boolean read FGenerateLogHEX write FGenerateLogHEX;
    property LogFolder : AnsiString read FLogFolder write FLogFolder;
    property OutputFolder : AnsiString read FOutputFolder write FOutputFolder;
    property FilePrefix : AnsiString read FFilePrefix write FFilePrefix;
    property FramingMode : THL7FramingMode read FFramingMode write FFramingMode;
    property OnHL7Message : THL7MessageEvent read FOnHL7Message write FOnHL7Message;
    property OnLog : TLogEvent read FOnLog write FOnLog;
  end;

implementation

constructor THL7Server.Create;
begin
  inherited Create;
  FPort := 5655; FAutoACK := True; FLogOnlyAnalyzerData := True;
  FGenerateLogASC := True; FGenerateLogHEX := False;
  FLogFolder := ExtractFilePath(ParamStr(0)) + 'Logs';
  FOutputFolder := ExtractFilePath(ParamStr(0)) + 'RES';
  FFilePrefix := 'ABL90'; FFramingMode := fmRadiometerTCP;
  FTCPServer := TIdTCPServer.Create(nil);
  FTCPServer.DefaultPort := FPort;
  FTCPServer.OnConnect := IdConnect;
  FTCPServer.OnDisconnect := IdDisconnect;
  FTCPServer.OnExecute := IdExecute;
end;

destructor THL7Server.Destroy;
begin
  Stop; FTCPServer.Free; inherited;
end;

function THL7Server.IniFileName : AnsiString;
begin Result := ExtractFilePath(ParamStr(0)) + 'ABL90.INI'; end;

function THL7Server.NormalizeFolder(const S : AnsiString) : AnsiString;
begin Result := Trim(S); if Result = '' then Result := ExtractFilePath(ParamStr(0)); end;

procedure THL7Server.EnsureFolder(const Folder : AnsiString);
begin
  if not DirectoryExists(Folder) then begin
    ForceDirectories(Folder);
  end;
end;

function THL7Server.FramingToText(Mode : THL7FramingMode) : AnsiString;
begin case Mode of fmAuto: Result := 'AUTO'; fmMLLP: Result := 'MLLP'; else Result := 'RADIOMETER_TCP'; end; end;

function THL7Server.TextToFraming(const S : AnsiString) : THL7FramingMode;
var T : AnsiString;
begin T := UpperCase(Trim(S)); if T='AUTO' then Result:=fmAuto else if T='MLLP' then Result:=fmMLLP else Result:=fmRadiometerTCP; end;

procedure THL7Server.LoadConfig;
var Ini : TIniFile;
begin
  Ini := TIniFile.Create(IniFileName);
  try
    FPort := Ini.ReadInteger('CONFIG','Port',5655);
    FFramingMode := TextToFraming(Ini.ReadString('CONFIG','Framing','RADIOMETER_TCP'));
    FLogOnlyAnalyzerData := Ini.ReadBool('CONFIG','LogOnlyAnalyzerData',True);
    FGenerateLogASC := Ini.ReadBool('CONFIG','GenerateLogASC',True);
    FGenerateLogHEX := Ini.ReadBool('CONFIG','GenerateLogHEX',False);
    FAutoACK := Ini.ReadBool('CONFIG','AutoACK',True);
    FLogFolder := NormalizeFolder(Ini.ReadString('CONFIG','LogFolder',ExtractFilePath(ParamStr(0))+'Logs'));
    FOutputFolder := NormalizeFolder(Ini.ReadString('CONFIG','OutputFolder',ExtractFilePath(ParamStr(0))+'RES'));
    FFilePrefix := Ini.ReadString('CONFIG','FilePrefix','ABL90');
  finally Ini.Free; end;
  SaveConfig;
end;

procedure THL7Server.SaveConfig;
var Ini : TIniFile;
begin
  Ini := TIniFile.Create(IniFileName);
  try
    Ini.WriteInteger('CONFIG','Port',FPort);
    Ini.WriteString('CONFIG','Framing',FramingToText(FFramingMode));
    Ini.WriteBool('CONFIG','LogOnlyAnalyzerData',FLogOnlyAnalyzerData);
    Ini.WriteBool('CONFIG','GenerateLogASC',FGenerateLogASC);
    Ini.WriteBool('CONFIG','GenerateLogHEX',FGenerateLogHEX);
    Ini.WriteBool('CONFIG','AutoACK',FAutoACK);
    Ini.WriteString('CONFIG','LogFolder',FLogFolder);
    Ini.WriteString('CONFIG','OutputFolder',FOutputFolder);
    Ini.WriteString('CONFIG','FilePrefix',FFilePrefix);
  finally Ini.Free; end;
end;

procedure THL7Server.Start(APort : Integer);
begin
  if FTCPServer.Active then Stop;
  FPort := APort; SaveConfig; EnsureFolder(FLogFolder); EnsureFolder(FOutputFolder);
  FTCPServer.DefaultPort := FPort; FTCPServer.Active := True;
  Log('Servidor iniciado en puerto '+IntToStr(FPort)+' - Framing='+FramingToText(FFramingMode));
end;

//procedure THL7Server.Stop;
//begin
//  if FTCPServer.Active then begin
//    FTCPServer.Active := False;
//    Log('Servidor detenido');
//  end;
//end;

procedure THL7Server.Stop;
var
  LList : TList;
  I : Integer;
  Ctx : TIdContext;
begin
  if not Assigned(FTCPServer) then
    Exit;
  if not FTCPServer.Active then
    Exit;
  try
    LList := FTCPServer.Contexts.LockList;
    try
      for I := LList.Count - 1 downto 0 do begin
        Ctx := TIdContext(LList[I]);
        try
          if Assigned(Ctx) and
             Assigned(Ctx.Connection) and
             Ctx.Connection.Connected then
            Ctx.Connection.Disconnect;
        except
        end;
      end;
    finally
      FTCPServer.Contexts.UnlockList;
    end;
    FTCPServer.Active := False;
    Log('Servidor detenido');
  except
    on E: Exception do
      Log('Error deteniendo servidor: ' + E.Message);
  end;
end;


procedure THL7Server.Log(const S : AnsiString);
var Linea : AnsiString;
begin
  Linea := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)+' - '+S;
  if Assigned(FOnLog) then FOnLog(Self, Linea);
  if not FLogOnlyAnalyzerData then begin
    if FGenerateLogASC then LogASC(Linea+HL7_CR+HL7_LF, False);
    if FGenerateLogHEX then LogHEX(Linea+HL7_CR+HL7_LF);
  end;
end;

procedure THL7Server.AppendToFileRaw(const FileName : AnsiString; const S : AnsiString);
var F : File;
begin
  AssignFile(F, FileName); if FileExists(FileName) then Reset(F,1) else Rewrite(F,1);
  try Seek(F, FileSize(F)); if Length(S)>0 then BlockWrite(F, S[1], Length(S)); finally CloseFile(F); end;
end;

procedure THL7Server.SaveTextFileRaw(const FileName : AnsiString; const S : AnsiString);
var F : File;
begin
  AssignFile(F, FileName); Rewrite(F,1);
  try if Length(S)>0 then BlockWrite(F, S[1], Length(S)); finally CloseFile(F); end;
end;

function THL7Server.SafeASC(const S : AnsiString) : AnsiString;
var I : Integer; C : Byte;
begin
  Result := '';
  for I := 1 to Length(S) do begin
    C := Ord(S[I]);
    case C of
      1: Result := Result + '<SOH>';
      4: Result := Result + '<EOT>';
      9: Result := Result + '<TAB>';
      10: Result := Result + HL7_LF;
      11: Result := Result + '<VT>';
      13: Result := Result + HL7_CR;
      28: Result := Result + '<FS>';
    else
      if C < 32 then Result := Result + '<$' + IntToHex(C,2) + '>' else Result := Result + S[I];
    end;
  end;
end;

function THL7Server.NormalizeAnalyzerASC(const S : AnsiString) : AnsiString;
begin
  Result := SafeASC(S);
  if (Length(S)>=1) and (S[Length(S)] = HL7_EOT) then Result := Result + HL7_CR + HL7_LF;
end;

function THL7Server.BytesToHex(const S : AnsiString) : AnsiString;
var I : Integer;
begin
  Result := '';
  for I := 1 to Length(S) do begin if Result<>'' then Result := Result + ' '; Result := Result + IntToHex(Ord(S[I]),2); end;
  Result := Result + HL7_CR + HL7_LF;
end;

procedure THL7Server.LogASC(const S : AnsiString; IsAnalyzerData : Boolean);
var FileName : AnsiString;
begin
  if not FGenerateLogASC then Exit;
  EnsureFolder(FLogFolder); FileName := IncludeTrailingPathDelimiter(FLogFolder)+'LogASC.txt';
  if IsAnalyzerData then AppendToFileRaw(FileName, NormalizeAnalyzerASC(S)) else AppendToFileRaw(FileName, S);
end;

procedure THL7Server.LogHEX(const S : AnsiString);
var FileName : AnsiString;
begin
  if not FGenerateLogHEX then Exit;
  EnsureFolder(FLogFolder); FileName := IncludeTrailingPathDelimiter(FLogFolder)+'LogHEX.txt';
  AppendToFileRaw(FileName, BytesToHex(S));
end;

function THL7Server.NormalizeHL7ForRES(const Msg : AnsiString) : AnsiString;
begin Result := Msg; if (Result='') or (Result[Length(Result)]<>HL7_CR) then Result := Result + HL7_CR; end;

function THL7Server.BuildPacketFileName : AnsiString;
var BaseName, FullName : AnsiString; N : Integer;
begin
  EnsureFolder(FOutputFolder);
  BaseName := FFilePrefix + '_' + FormatDateTime('yyyymmdd_hhnnss_zzz', Now);
  FullName := IncludeTrailingPathDelimiter(FOutputFolder)+BaseName+'.RES';
  N := 1;
  while FileExists(FullName) do begin
    FullName := IncludeTrailingPathDelimiter(FOutputFolder)+BaseName+'_'+Format('%.3d',[N])+'.RES'; Inc(N);
  end;
  Result := FullName;
end;

procedure THL7Server.SavePacketFiles(const Msg : AnsiString; const RawFrame : AnsiString);
var FinalName, TempName, HexName, AscName, HL7Text : AnsiString;
begin
  FinalName := BuildPacketFileName; TempName := ChangeFileExt(FinalName,'.TMP');
  HL7Text := NormalizeHL7ForRES(Msg);
  SaveTextFileRaw(TempName, HL7Text);
  if FileExists(FinalName) then DeleteFile(FinalName);
  if not RenameFile(TempName, FinalName) then Log('ERROR: no se pudo renombrar TMP a RES: '+FinalName)
  else Log('Paquete HL7 guardado: '+ExtractFileName(FinalName));
  if FGenerateLogASC then begin AscName := ChangeFileExt(FinalName,'.ASC'); SaveTextFileRaw(AscName, NormalizeAnalyzerASC(RawFrame)); end;
  if FGenerateLogHEX then begin HexName := ChangeFileExt(FinalName,'.HEX'); SaveTextFileRaw(HexName, BytesToHex(RawFrame)); end;
end;

procedure THL7Server.IdConnect(AContext : TIdContext);
begin
  AContext.Data := THL7Context.Create; THL7Context(AContext.Data).Buffer := '';
  try Log('Cliente conectado: '+AContext.Connection.Socket.Binding.PeerIP); except Log('Cliente conectado'); end;
end;

procedure THL7Server.IdDisconnect(AContext : TIdContext);
begin if Assigned(AContext.Data) then begin AContext.Data.Free; AContext.Data := nil; end; Log('Cliente desconectado'); end;

function THL7Server.ExtractMLLPMessage(var Buffer : AnsiString; out Msg : AnsiString; out RawFrame : AnsiString) : Boolean;
var P1, P2 : Integer;
begin
  Result := False; Msg := ''; RawFrame := '';
  P1 := Pos(HL7_VT, Buffer); if P1=0 then Exit;
  if P1>1 then Delete(Buffer,1,P1-1);
  P2 := Pos(HL7_FS+HL7_CR, Buffer); if P2=0 then Exit;
  Msg := Copy(Buffer,2,P2-2); RawFrame := Copy(Buffer,1,P2+1); Delete(Buffer,1,P2+1); Result := True;
end;

function THL7Server.ExtractRadiometerMessage(var Buffer : AnsiString; out Msg : AnsiString; out RawFrame : AnsiString) : Boolean;
var P1, P2 : Integer;
begin
  Result := False; Msg := ''; RawFrame := '';
  P1 := Pos(HL7_SOH, Buffer); if P1=0 then Exit;
  if P1>1 then Delete(Buffer,1,P1-1);
  P2 := Pos(HL7_EOT, Buffer); if P2=0 then Exit;
  Msg := Copy(Buffer,2,P2-2); RawFrame := Copy(Buffer,1,P2); Delete(Buffer,1,P2);
  while (Length(Buffer)>0) and ((Buffer[1]=HL7_CR) or (Buffer[1]=HL7_LF)) do Delete(Buffer,1,1);
  Result := True;
end;

function THL7Server.ExtractMessage(var Buffer : AnsiString; out Msg : AnsiString; out RawFrame : AnsiString; out DetectedMode : THL7FramingMode) : Boolean;
var TryBuffer : AnsiString;
begin
  Result := False; Msg := ''; RawFrame := ''; DetectedMode := FFramingMode;
  case FFramingMode of
    fmMLLP: begin Result := ExtractMLLPMessage(Buffer,Msg,RawFrame); DetectedMode := fmMLLP; end;
    fmRadiometerTCP: begin Result := ExtractRadiometerMessage(Buffer,Msg,RawFrame); DetectedMode := fmRadiometerTCP; end;
  else
    TryBuffer := Buffer;
    if ExtractMLLPMessage(TryBuffer,Msg,RawFrame) then begin Buffer := TryBuffer; DetectedMode := fmMLLP; Result := True; Exit; end;
    TryBuffer := Buffer;
    if ExtractRadiometerMessage(TryBuffer,Msg,RawFrame) then begin Buffer := TryBuffer; DetectedMode := fmRadiometerTCP; Result := True; Exit; end;
  end;
  if (not Result) and (Length(Buffer)>8192) then Buffer := Copy(Buffer, Length(Buffer)-256, 256);
end;

function THL7Server.ExtractMessageControlID(const Msg : AnsiString) : AnsiString;
var Linea : AnsiString; P, I, StartPos : Integer;
begin
  Result := '1'; P := Pos(HL7_CR, Msg); if P>0 then Linea := Copy(Msg,1,P-1) else Linea := Msg;
  if Copy(Linea,1,3)<>'MSH' then Exit;
  StartPos := 1;
  for I := 1 to 9 do begin P := Pos('|', Copy(Linea,StartPos,MaxInt)); if P=0 then Exit; Inc(StartPos,P); end;
  P := Pos('|', Copy(Linea,StartPos,MaxInt)); if P=0 then Result := Copy(Linea,StartPos,MaxInt) else Result := Copy(Linea,StartPos,P-1);
  if Result='' then Result := '1';
end;

function THL7Server.MakeACK(const Msg : AnsiString) : AnsiString;
var CtrlID : AnsiString;
begin
  CtrlID := ExtractMessageControlID(Msg);
  Result := 'MSH|^~\&|LIS||||'+FormatDateTime('yyyymmddhhnnss',Now)+'||ACK|'+FormatDateTime('yyyymmddhhnnss',Now)+'|P|2.5'+HL7_CR+'MSA|AA|'+CtrlID+HL7_CR;
end;

procedure THL7Server.SendRaw(AContext : TIdContext; const S : AnsiString);
begin
  if Assigned(AContext) and Assigned(AContext.Connection) then begin
    AContext.Connection.IOHandler.Write(S);
    if not FLogOnlyAnalyzerData then begin
      if FGenerateLogASC then LogASC('TX: '+SafeASC(S)+HL7_CR+HL7_LF, False);
      if FGenerateLogHEX then LogHEX(S);
    end;
  end;
end;

procedure THL7Server.SendFramed(AContext : TIdContext; const Msg : AnsiString; AMode : THL7FramingMode);
begin case AMode of fmRadiometerTCP: SendRaw(AContext, HL7_SOH+Msg+HL7_EOT); else SendRaw(AContext, HL7_VT+Msg+HL7_FS+HL7_CR); end; end;

procedure THL7Server.SendACK(AContext : TIdContext; const Msg : AnsiString; AMode : THL7FramingMode);
begin
  SendFramed(AContext, MakeACK(Msg), AMode);
  case AMode of fmRadiometerTCP: Log('ACK enviado con framing Radiometer TCP'); fmMLLP: Log('ACK enviado con framing MLLP'); else Log('ACK enviado'); end;
end;

procedure THL7Server.IdExecute(AContext : TIdContext);
var Ctx : THL7Context; Datos, Msg, RawFrame : AnsiString; DetectedMode : THL7FramingMode;
begin
  if not Assigned(AContext) then Exit;
  if not Assigned(AContext.Connection) then Exit;
  if not Assigned(AContext.Connection.IOHandler) then Exit;
  Ctx := THL7Context(AContext.Data); if not Assigned(Ctx) then Exit;
  if not AContext.Connection.IOHandler.CheckForDataOnSource(100) then Exit;
  Datos := AContext.Connection.IOHandler.InputBuffer.ExtractToString; if Datos='' then Exit;
  Log('RX bytes: '+IntToStr(Length(Datos)));
  if not FLogOnlyAnalyzerData then begin if FGenerateLogASC then LogASC(Datos, True); if FGenerateLogHEX then LogHEX(Datos); end;
  Ctx.Buffer := Ctx.Buffer + Datos;
  while ExtractMessage(Ctx.Buffer, Msg, RawFrame, DetectedMode) do begin
    case DetectedMode of fmRadiometerTCP: Log('Mensaje HL7 recibido con framing Radiometer TCP'); fmMLLP: Log('Mensaje HL7 recibido con framing MLLP'); else Log('Mensaje HL7 recibido'); end;
    SavePacketFiles(Msg, RawFrame);
    if Assigned(FOnHL7Message) then FOnHL7Message(Self, AContext, Msg);
    if FAutoACK then SendACK(AContext, Msg, DetectedMode);
  end;
end;

end.
