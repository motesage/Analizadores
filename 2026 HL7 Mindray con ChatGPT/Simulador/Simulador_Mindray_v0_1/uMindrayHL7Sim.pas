unit uMindrayHL7Sim;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ScktComp;

type
  TfrmMindrayHL7Sim = class(TForm)
    pnlTop: TPanel;
    lblHost: TLabel;
    lblPort: TLabel;
    lblBarcode: TLabel;
    edtHost: TEdit;
    edtPort: TEdit;
    edtBarcode: TEdit;
    btnConnect: TButton;
    btnDisconnect: TButton;
    chkAutoACK: TCheckBox;
    pnlButtons: TPanel;
    btnQRY: TButton;
    btnORU: TButton;
    btnQRYFragmentado: TButton;
    btnDosQRY: TButton;
    btnEnviarManual: TButton;
    btnLimpiar: TButton;
    memManual: TMemo;
    memLog: TMemo;
    Splitter1: TSplitter;
    tmrFragment: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure btnQRYClick(Sender: TObject);
    procedure btnORUClick(Sender: TObject);
    procedure btnQRYFragmentadoClick(Sender: TObject);
    procedure btnDosQRYClick(Sender: TObject);
    procedure btnEnviarManualClick(Sender: TObject);
    procedure btnLimpiarClick(Sender: TObject);
    procedure tmrFragmentTimer(Sender: TObject);
  private
    FClient: TClientSocket;
    FReceiveBuffer: string;
    FFragmentRest: string;
    procedure ClientConnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure ClientDisconnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure ClientRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure ClientError(Sender: TObject; Socket: TCustomWinSocket;
      ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure Log(const S: string);
    procedure SendRaw(const S: string; const Description: string);
    procedure SendHL7(const S: string; const Description: string);
    procedure ProcessReceiveBuffer;
    procedure ProcessFrame(const Frame: string);
    function BuildQRY(const Barcode, MsgID: string): string;
    function BuildORU(const Barcode, MsgID: string): string;
    function BuildACKQ03(const MsgID: string): string;
    function MessageID(const Frame: string): string;
    function NormalizeHL7(const S: string): string;
    function ErrorEventName(ErrorEvent: TErrorEvent): string;
  public
  end;

var
  frmMindrayHL7Sim: TfrmMindrayHL7Sim;

implementation

{$R *.dfm}

const
  SB_CHAR = #11;
  EB_CHAR = #28;
  CR_CHAR = #13;

procedure TfrmMindrayHL7Sim.FormCreate(Sender: TObject);
begin
  FReceiveBuffer := '';
  FFragmentRest := '';

  FClient := TClientSocket.Create(Self);
  FClient.ClientType := ctNonBlocking;
  FClient.OnConnect := ClientConnect;
  FClient.OnDisconnect := ClientDisconnect;
  FClient.OnRead := ClientRead;
  FClient.OnError := ClientError;

  tmrFragment.Enabled := False;
  tmrFragment.Interval := 700;

  memManual.Lines.Text :=
    'MSH|^~\&|Mindray|BS-400|||' + FormatDateTime('yyyymmddhhmmss', Now) +
    '||QRY^Q02|900|P|2.3.1||||||ASCII|||' + #13#10 +
    'QRD|' + FormatDateTime('yyyymmddhhmmss', Now) +
    '|R|D|900|||RD|34567743|OTH|||T|' + #13#10 +
    'QRF|BS-400|||||RCT|COR|ALL||';

  Log('Simulador Mindray HL7 v0.1 listo.');
  Log('MLLP: <0B> mensaje <1C><0D>. Auto-ACK DSR=' + BoolToStr(chkAutoACK.Checked, True));
end;

procedure TfrmMindrayHL7Sim.FormDestroy(Sender: TObject);
begin
  if Assigned(FClient) then begin
    FClient.Active := False;
    FreeAndNil(FClient);
  end;
end;

procedure TfrmMindrayHL7Sim.Log(const S: string);
begin
  memLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + '  ' + S);
  memLog.SelStart := Length(memLog.Text);
end;

function TfrmMindrayHL7Sim.ErrorEventName(ErrorEvent: TErrorEvent): string;
begin
  case ErrorEvent of
    eeGeneral:    Result := 'eeGeneral';
    eeSend:       Result := 'eeSend';
    eeReceive:    Result := 'eeReceive';
    eeConnect:    Result := 'eeConnect';
    eeDisconnect: Result := 'eeDisconnect';
    eeAccept:     Result := 'eeAccept';
    eeLookup:     Result := 'eeLookup';
  else
    Result := 'desconocido';
  end;
end;

procedure TfrmMindrayHL7Sim.btnConnectClick(Sender: TObject);
begin
  if FClient.Active then
    Exit;

  FClient.Host := Trim(edtHost.Text);
  FClient.Port := StrToIntDef(Trim(edtPort.Text), 5050);
  Log('Conectando a ' + FClient.Host + ':' + IntToStr(FClient.Port) + ' ...');
  FClient.Active := True;
end;

procedure TfrmMindrayHL7Sim.btnDisconnectClick(Sender: TObject);
begin
  if FClient.Active then begin
    Log('Desconexion solicitada.');
    FClient.Active := False;
  end;
end;

procedure TfrmMindrayHL7Sim.ClientConnect(Sender: TObject; Socket: TCustomWinSocket);
begin
  Log('CONECTADO a ' + Socket.RemoteAddress + ':' + IntToStr(Socket.RemotePort));
end;

procedure TfrmMindrayHL7Sim.ClientDisconnect(Sender: TObject; Socket: TCustomWinSocket);
begin
  Log('DESCONECTADO.');
end;

procedure TfrmMindrayHL7Sim.ClientError(Sender: TObject; Socket: TCustomWinSocket;
  ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
  Log('ERROR ' + IntToStr(ErrorCode) + ' / ' + ErrorEventName(ErrorEvent));
  ErrorCode := 0;
end;

procedure TfrmMindrayHL7Sim.ClientRead(Sender: TObject; Socket: TCustomWinSocket);
var
  S: string;
begin
  S := Socket.ReceiveText;
  if S = '' then
    Exit;

  Log('RX chunk bytes=' + IntToStr(Length(S)));
  FReceiveBuffer := FReceiveBuffer + S;
  ProcessReceiveBuffer;
end;

procedure TfrmMindrayHL7Sim.ProcessReceiveBuffer;
var
  pStart, pEnd: Integer;
  Frame: string;
begin
  while True do begin
    pStart := Pos(SB_CHAR, FReceiveBuffer);
    if pStart = 0 then begin
      if Length(FReceiveBuffer) > 8192 then
        FReceiveBuffer := '';
      Exit;
    end;

    if pStart > 1 then
      Delete(FReceiveBuffer, 1, pStart - 1);

    pEnd := Pos(EB_CHAR + CR_CHAR, FReceiveBuffer);
    if pEnd = 0 then
      Exit;

    Frame := Copy(FReceiveBuffer, 2, pEnd - 2);
    Delete(FReceiveBuffer, 1, pEnd + 1);
    ProcessFrame(Frame);
  end;
end;

procedure TfrmMindrayHL7Sim.ProcessFrame(const Frame: string);
var
  MsgID: string;
begin
  Log('----- RX HL7 FRAME -----');
  memLog.Lines.Add(StringReplace(Frame, CR_CHAR, #13#10, [rfReplaceAll]));
  Log('----- FIN RX FRAME -----');

  if chkAutoACK.Checked and (Pos('DSR^Q03', Frame) > 0) then begin
    MsgID := MessageID(Frame);
    if MsgID <> '' then begin
      Log('Auto-ACK para DSR^Q03 ID=' + MsgID);
      SendHL7(BuildACKQ03(MsgID), 'ACK^Q03 automatico');
    end;
  end;
end;

function TfrmMindrayHL7Sim.NormalizeHL7(const S: string): string;
begin
  Result := StringReplace(S, #13#10, #13, [rfReplaceAll]);
  Result := StringReplace(Result, #10, #13, [rfReplaceAll]);
  while (Length(Result) > 0) and (Result[Length(Result)] = #13) do
    Delete(Result, Length(Result), 1);
end;

procedure TfrmMindrayHL7Sim.SendRaw(const S: string; const Description: string);
var
  N: Integer;
begin
  if not FClient.Active then begin
    Log('No conectado: no se envia ' + Description);
    Exit;
  end;

  N := FClient.Socket.SendText(S);
  Log('TX ' + Description + ' solicitado=' + IntToStr(Length(S)) +
      ' enviado=' + IntToStr(N));
end;

procedure TfrmMindrayHL7Sim.SendHL7(const S: string; const Description: string);
var
  Packet: string;
begin
  Packet := SB_CHAR + NormalizeHL7(S) + EB_CHAR + CR_CHAR;
  SendRaw(Packet, Description);
end;

function TfrmMindrayHL7Sim.BuildQRY(const Barcode, MsgID: string): string;
var
  DT: string;
begin
  DT := FormatDateTime('yyyymmddhhmmss', Now);
  Result :=
    'MSH|^~\&|Mindray|BS-400|||' + DT + '||QRY^Q02|' + MsgID +
    '|P|2.3.1||||||ASCII|||' + CR_CHAR +
    'QRD|' + DT + '|R|D|' + MsgID + '|||RD|' + Barcode + '|OTH|||T|' + CR_CHAR +
    'QRF|BS-400|||||RCT|COR|ALL||';
end;

function TfrmMindrayHL7Sim.BuildORU(const Barcode, MsgID: string): string;
var
  DT: string;
begin
  DT := FormatDateTime('yyyymmddhhmmss', Now);
  Result :=
    'MSH|^~\&|Mindray|BS-400|||' + DT + '||ORU^R01|' + MsgID +
    '|P|2.3.1||||0||ASCII|||' + CR_CHAR +
    'PID|1||||Paciente Simulador||19000101000000||||||||||||||||||||||||' + CR_CHAR +
    'OBR|1|' + Barcode + '|1|Mindray^BS-400|N||' + DT +
    '|||||||'+ DT +'|Suero|||||||||||||||||||||||||||||||||' + CR_CHAR +
    'OBX|1|NM|GLU-WB|GLU-WB|100.000000|mg/dL|-|N|||F||100.000000|' + DT + '||||';
end;

function TfrmMindrayHL7Sim.BuildACKQ03(const MsgID: string): string;
var
  DT: string;
begin
  DT := FormatDateTime('yyyymmddhhmmss', Now);
  Result :=
    'MSH|^~\&|Mindray|BS-400|||' + DT + '||ACK^Q03|' + MsgID +
    '|P|2.3.1||||||ASCII|||' + CR_CHAR +
    'MSA|AA|' + MsgID + '|Message accepted|||0|' + CR_CHAR +
    'ERR|0|';
end;

function TfrmMindrayHL7Sim.MessageID(const Frame: string): string;
var
  MSH, Tmp: string;
  p, FieldNo: Integer;
begin
  Result := '';
  p := Pos(CR_CHAR, Frame);
  if p > 0 then
    MSH := Copy(Frame, 1, p - 1)
  else
    MSH := Frame;

  FieldNo := 1;
  Tmp := MSH;
  while FieldNo < 10 do begin
    p := Pos('|', Tmp);
    if p = 0 then
      Exit;
    Delete(Tmp, 1, p);
    Inc(FieldNo);
  end;

  p := Pos('|', Tmp);
  if p > 0 then
    Result := Copy(Tmp, 1, p - 1)
  else
    Result := Tmp;
end;

procedure TfrmMindrayHL7Sim.btnQRYClick(Sender: TObject);
begin
  SendHL7(BuildQRY(Trim(edtBarcode.Text), '101'), 'QRY^Q02');
end;

procedure TfrmMindrayHL7Sim.btnORUClick(Sender: TObject);
begin
  SendHL7(BuildORU(Trim(edtBarcode.Text), '201'), 'ORU^R01');
end;

procedure TfrmMindrayHL7Sim.btnQRYFragmentadoClick(Sender: TObject);
var
  Packet: string;
  CutPos: Integer;
begin
  if not FClient.Active then begin
    Log('No conectado.');
    Exit;
  end;

  Packet := SB_CHAR + BuildQRY(Trim(edtBarcode.Text), '301') + EB_CHAR + CR_CHAR;
  CutPos := Length(Packet) div 2;
  FFragmentRest := Copy(Packet, CutPos + 1, MaxInt);
  SendRaw(Copy(Packet, 1, CutPos), 'QRY fragmentado PARTE 1');
  tmrFragment.Enabled := True;
end;

procedure TfrmMindrayHL7Sim.tmrFragmentTimer(Sender: TObject);
begin
  tmrFragment.Enabled := False;
  if FFragmentRest <> '' then begin
    SendRaw(FFragmentRest, 'QRY fragmentado PARTE 2');
    FFragmentRest := '';
  end;
end;

procedure TfrmMindrayHL7Sim.btnDosQRYClick(Sender: TObject);
var
  Packet: string;
begin
  Packet :=
    SB_CHAR + BuildQRY(Trim(edtBarcode.Text), '401') + EB_CHAR + CR_CHAR +
    SB_CHAR + BuildQRY(Trim(edtBarcode.Text), '402') + EB_CHAR + CR_CHAR;
  SendRaw(Packet, 'DOS QRY en un unico SendText');
end;

procedure TfrmMindrayHL7Sim.btnEnviarManualClick(Sender: TObject);
begin
  SendHL7(memManual.Text, 'HL7 manual');
end;

procedure TfrmMindrayHL7Sim.btnLimpiarClick(Sender: TObject);
begin
  memLog.Clear;
end;

end.
