unit uASTM1381;

interface

uses
   Windows, Messages, SysUtils, Classes,Forms,Dialogs,
   uCommBuffer, OoMisc, AdPort, ExtCtrls, JvJCLUtils, ScktComp, Sockets;

type
  tASTM = class(tComponent)
    private
      fInputBuffer: tCommBuffer;
      fInputFrameBuffer: string;
      fOutputFrameBuffer: string;
      fCommPort: TApdComPort;
      fServerSocket: tServerSocket;
      fActive: boolean;
      fState: integer;
      FOnIdle: tNotifyEvent;
      fTimer: tDateTime;
      fBusyTimer: tDateTime;
      fInputFrameNumber: integer;
      fOutputFrameNumber: integer;
      fFrameInputList: tStringList;
      fFrameOutputList: tStringList;
      fIntFrameData: string;    //guarda lineas enteras de data (aunque vengan en varios frames)
      fRetryCount: integer;
      fTimerIdle: tDateTime;
      fRunTimer: tTimer;
      FOnInput: TGetStrProc;
      FOnDisconnect: TGetStrProc;
      FOnConnect: TGetStrProc;
      FServerConnected: boolean;
      FOnOutput: TGetStrProc;
      procedure DoOnIdle;
      procedure DoOnInput(Value: string);
      procedure DoOnOutput(Value: string);
      procedure SetActive(const Value: boolean);
      function GetActive: boolean;
      function GetComNumber: integer;
      procedure SetComNumber(const Value: integer);
      function GetBauds: integer;
      procedure SetBauds(const Value: integer);
      procedure ComPortTriggerAvail(CP: TObject; Count: Word);
      procedure ProcessStateMachine;
      procedure SetOnIdle(const Value: tNotifyEvent);
      procedure DoAwake;
      procedure DoCheckHaveData;
      procedure DoContention;
      procedure DoDataToSend;
      procedure DoFrameReady;
      procedure DoFrameReceived;
      procedure DoIdle;
      procedure DoInterruptRequested;
      procedure DoNextFrameSetUp;
      procedure DoOldFrameSetup;
      procedure DoWaitFrameAnswer;
      procedure DoWaitReceive;
      procedure DoWaitTransmit;
      function CheckFrame(Frame: string; FrameNumber: integer): boolean;
      function CheckSum(Frame: string): string;
      function InputFrameCheckSum(Frame:string): string;
      function InputFrameEndChar(Frame:string): integer;
      function InputFrameNumber(Frame:string): integer;
      function InputFrameData(Frame:string): string;
      function GetCount: integer;
      function GetData: string;
      procedure SetData(const Value: string);
      procedure RunTimer(Sender: TObject);
      procedure SetOnInput(const Value: TGetStrProc);
      procedure SetOnConnect(const Value: TGetStrProc);
      procedure SetOnDisconnect(const Value: TGetStrProc);
      procedure ServerSocket1ClientConnect(Sender: TObject; Socket: TCustomWinSocket);
      procedure ServerSocket1ClientDisconnect(Sender: TObject; Socket: TCustomWinSocket);
      procedure ServerSocket1ClientRead(Sender: TObject; Socket: TCustomWinSocket);
      procedure PutString(s: string);
      procedure SetServerConnected(const Value: boolean);
      procedure SetOnOutput(const Value: TGetStrProc);
    public
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
      procedure AddInput(s: string);
      procedure Run;
      procedure Stop;
      property Active: boolean read GetActive write SetActive;
      property ComNumber: integer read GetComNumber write SetComNumber;
      property Bauds: integer read GetBauds write SetBauds;
      property OnIdle: tNotifyEvent read FOnIdle write SetOnIdle;
      property OnInput: TGetStrProc read FOnInput write SetOnInput;
      property OnOutput: TGetStrProc read FOnOutput write SetOnOutput;
      property OnConnect: TGetStrProc read FOnConnect write SetOnConnect;
      property OnDisconnect: TGetStrProc read FOnDisconnect write SetOnDisconnect;
      property Count: integer read GetCount;
      property Data: string read GetData write SetData;
      property ServerConnected: boolean read FServerConnected write SetServerConnected;
  end;

implementation

const
  STX_CHAR = 2;
  ETX_CHAR = 3;
  EOT_CHAR = 4;
  ENQ_CHAR = 5;
  ACK_CHAR = 6;
  LF_CHAR = 10;
  CR_CHAR = 13;
  NAK_CHAR = 21;
  ETB_CHAR = 23;


  cTimeoutIdle = 2; // estaba en 2;
  cTimeout = 10; // estaba en 30;
  cTimeoutDataSend = 15; // estaba en 15
  cTimeoutDoWait =10; // estaba en 10
  cTimeoutDoFrameReady = 15; // estaba en 15
  { tASTM }

constructor tASTM.Create(AOwner: TComponent);
begin
  inherited;
  fActive := false;
  FOnIdle := nil;
  fRetryCount := 0;
  fInputBuffer := tCommBuffer.Create(self);
  fFrameInputList := TStringList.Create;
  fFrameOutputList := TStringList.Create;
  fServerSocket := TServerSocket.Create(self);
  fServerSocket.Port := 50;
  fServerSocket.ServerType := stNonBlocking;
  fServerSocket.OnClientConnect := ServerSocket1ClientConnect;
  fServerSocket.OnClientDisconnect := ServerSocket1ClientDisconnect;
  fServerSocket.OnClientRead := ServerSocket1ClientRead;
  fServerSocket.Active := True;
  FServerConnected := false;

  fCommPort := TApdComPort.Create(self);
  fCommPort.AutoOpen := true;
  fCommPort.OnTriggerAvail := ComPortTriggerAvail;
  fCommPort.InSize := 4096*2;
  fCommPort.OutSize := 4096*2;
  fCommPort.ComNumber := 4;
  fCommPort.Baud := 9600;
  fState := 0;
  fTimer := 0;
  fTimerIdle := 0;
  fBusyTimer := 0;
  fRunTimer := TTimer.Create(self);
  fRunTimer.Interval := 2000;
  fRunTimer.Enabled := true;
  fRunTimer.OnTimer := RunTimer;
end;

destructor tASTM.Destroy;
begin
  fFrameInputList.Free;
  inherited;
end;

function tASTM.GetActive: boolean;
begin
  result :=  fActive;
end;

function tASTM.GetBauds: integer;
begin
  result := fCommPort.Baud;
end;

function tASTM.GetComNumber: integer;
begin
  result := fCommPort.ComNumber;
end;

procedure tASTM.SetActive(const Value: boolean);
begin
  try
    fCommPort.Open := Value;
  except
    on e: exception do ;
  end;
  FActive := Value;
end;

procedure tASTM.SetBauds(const Value: integer);
begin
  fCommPort.Baud := Value;
end;

procedure tASTM.SetComNumber(const Value: integer);
begin
  fCommPort.ComNumber := Value;
end;

procedure tASTM.ComPortTriggerAvail(CP: TObject; Count: Word);
var
	j: integer;
begin
	for j := 1 to Count do begin   // Iterate
		fInputBuffer.AddChar(fCommPort.GetChar);
	end;    // for
end;

procedure tASTM.ProcessStateMachine;
begin
  case fState of    //
    0:  DoIdle;  //idle
    100: DoAwake;
    200: DoWaitReceive;
    300: DoFrameReceived;
    400: DoCheckHaveData;
    500: DoOldFrameSetup;
    600: DoDataToSend;
    700: DoWaitTransmit;
    800: DoContention;
    900: DoNextFrameSetUp;
    1000: DoFrameReady;
    1100: DoWaitFrameAnswer;
    1200: DoInterruptRequested;
  else
    fState := 0;
  end;    // case
end;

procedure tASTM.DoIdle;
var
  cBuff: integer;
begin
  // se recibio algo?
  cBuff := fInputBuffer.GetChar;
  if cBuff>0 then begin
    if (cBuff = ENQ_CHAR) then begin
      fState := 100;   //comienza recepcion
    end;
  end
  else if (fFrameOutputList.Count>0) then begin
    fState := 600;    //hay data to send
  end
  else begin
    if Now>fTimerIdle then begin
      DoOnIdle;
      fTimerIdle := Now + EncodeTime(0,0,cTimeoutIdle,0);
    end;
  end;
end;

procedure tASTM.DoAwake;
begin
  PutString(chr(ACK_CHAR));
  fTimer := Now + EncodeTime(0,0,cTimeout,0);
  fInputFrameNumber := 1;
  fInputFrameBuffer := '';
  fState := 200;    //hay data to send
  fIntFrameData := '';
end;


procedure tASTM.DoWaitReceive;
var
  cBuff: integer;
begin
  cBuff := fInputBuffer.GetChar;
  if cBuff > 0 then begin
    if (cBuff = EOT_CHAR) then begin
      fState := 0;    //vuelve a idle
    end
    else begin
      if Length(fInputFrameBuffer)=0 then begin    //todavia no empezó un frame
        if (cBuff = STX_CHAR) then begin
          fInputFrameBuffer  := fInputFrameBuffer + chr(cBuff);
        end;
      end
      else begin
        fInputFrameBuffer  := fInputFrameBuffer + chr(cBuff); //acumulo
        if (cBuff = LF_CHAR) then begin   //termina un frame
          fState := 300;    //frame recibido
        end;
      end;
    end;
  end;
  if (Now > fTimer) then begin
    fState := 0;    //vuelve a idle por timeout
  end;
end;

procedure tASTM.DoFrameReceived;
begin
  if CheckFrame(fInputFrameBuffer,fInputFrameNumber) then begin
    //acumulo lo recibido
    fIntFrameData := fIntFrameData + InputFrameData(fInputFrameBuffer);
    fInputFrameNumber := (fInputFrameNumber+1) mod 8;
    if InputFrameEndChar(fInputFrameBuffer) = ETX_CHAR then begin
      // si es un  final de frame agrego linea en buffer de salida
      fFrameInputList.Add(fIntFrameData);
      DoOnInput(fIntFrameData);
      fIntFrameData := '';
    end;
    if fFrameOutputList.Count>0 then begin
      //hay para transmitir pido interrupcion
      PutString(chr(EOT_CHAR));
    end
    else begin
      PutString(chr(ACK_CHAR));
    end;
  end
  else begin
    PutString(chr(NAK_CHAR));
  end;
  fTimer := Now + EncodeTime(0,0,cTimeout,0);
  fInputFrameBuffer := '';   //limpio le buffer de entrada
  fState := 200;    //frame recibido
end;

function tASTM.CheckFrame(Frame: string; FrameNumber: integer): boolean;
{ Valida el frame recibido y devuelve su status }

begin
  result := false;
  if Frame[1]=chr(STX_CHAR) then begin
    if ((InputFrameNumber(Frame) = FrameNumber) or (InputFrameNumber(Frame) = ((FrameNumber+1) mod 8))) then begin
      if (InputFrameCheckSum(Frame) = CheckSum(Frame)) then begin
        if ((InputFrameEndChar(Frame) = ETB_CHAR) or (InputFrameEndChar(Frame) = ETX_CHAR)) then begin
          result := true;
        end;
      end;
    end;
  end;
end;

function tASTM.CheckSum(Frame: string): string;
var
  j, iCheck: integer;
begin
  iCheck := 0;
  for j := 2 to length(Frame)-4 do begin    // Iterate
    iCheck := (iCheck + Ord(Frame[j])) mod 256;
  end;    // for
  result := Dec2Hex(iCheck,2);
end;

procedure tASTM.DoCheckHaveData;
begin

end;

procedure tASTM.DoOldFrameSetup; //state: 500
begin
  if fRetryCount>6 then begin
    PutString(chr(EOT_CHAR));   //aborta
    fState := 0;    //vuelve a idle por timeout
  end
  else begin
    fState := 1000;   //reenvia
  end;
end;

procedure tASTM.DoDataToSend;  //state: 600
begin
  if fBusyTimer=0 then begin
    PutString(chr(ENQ_CHAR));
    fTimer := Now + EncodeTime(0,0,cTimeoutDataSend,0);
    fOutputFrameNumber := 1;
    fState := 700;    //hay data to send voy a esperar el ACK
  end
  else begin
    fState := 800;    //voy a check busy timer
  end;
end;

procedure tASTM.DoWaitTransmit; //state: 700
var
  cBuff: integer;
begin
  cBuff := fInputBuffer.GetChar;
  if cBuff > 0 then begin
    if (cBuff = ACK_CHAR) then begin
      fState := 900;    //va a prepara un nuevo frame para enviar
    end
    else if (cBuff = ENQ_CHAR) then  begin    //contention
      fBusyTimer := Now + EncodeTime(0,0,cTimeoutIdle,0); //doy tiempo a que el instrumento transmita
      fState := 800;    //voy a check busy timer
    end
    else if (cBuff = NAK_CHAR) then  begin
      fBusyTimer := Now + EncodeTime(0,0,cTimeoutDoWait,0); //esta ocupado. espero 10s
      fState := 800;    //voy a check busy timer
    end;
  end;
  // sale por timeout?
  if (Now > fTimer) then begin
    PutString(chr(EOT_CHAR));
    fState := 0;    //vuelve a idle por timeout
  end;
end;

procedure tASTM.DoContention; //state: 800
begin
  if ((fBusyTimer=0) or (Now>fBusyTimer)) then begin
    fBusyTimer := 0;     //estaba en Busy pero ya paso
  end;
  fState := 0;
end;

procedure tASTM.DoNextFrameSetUp; //state: 900
var
  S, sCheck: string;
begin
  fRetryCount := 0;
  if fFrameOutputList.Count=0 then begin
    PutString(chr(EOT_CHAR));
    fState := 0;
  end
  else begin
    s := fFrameOutputList.Strings[0];
    if length(s)>240 then begin
      s := copy(s,1,240)+chr(ETB_CHAR);   //tamaño máximo de data de un frame (termino con intermedio)
    end
    else begin
      s := s + chr(ETX_CHAR);    //menor que el maximo, termino con final
    end;
    fOutputFrameBuffer := chr(STX_CHAR)+chr(ord('0')+fOutputFrameNumber)+s+'00'+chr(CR_CHAR)+chr(LF_CHAR);  //para poder calcular el checksum
    sCheck := CheckSum(fOutputFrameBuffer);
    fOutputFrameBuffer := chr(STX_CHAR)+chr(ord('0')+fOutputFrameNumber)+s+sCheck+chr(CR_CHAR)+chr(LF_CHAR);
    fState := 1000;
  end;
end;

procedure tASTM.DoFrameReady;  //state: 1000
begin
  PutString(fOutputFrameBuffer);
  fTimer := Now + EncodeTime(0,0,cTimeOutDoFrameReady,0);
  fState := 1100;
end;

procedure tASTM.DoWaitFrameAnswer; //state: 1100
var
  cBuff: integer;
  S: string;
begin
  cBuff := fInputBuffer.GetChar;
  if cBuff > 0 then begin
    if (cBuff = ACK_CHAR) or (cBuff = EOT_CHAR) then begin      //no voy a dar bola a los pedidos de interrupcion (por ahora)
      fOutputFrameNumber := (fOutputFrameNumber + 1) mod 8;   //incremento el frame number
      //anulo lo que ya mande
      s := fFrameOutputList.Strings[0];
      if length(s)>240 then begin
        s := copy(s,241,length(s)-240);
        fFrameOutputList.Strings[0] := s;   //si es parcial saco la primera parte
      end
      else begin
        fFrameOutputList.Delete(0);   //ya lo mande
      end;
      fState := 900;    //va a prepara un nuevo frame para enviar
    end
    else begin
      inc(fRetryCount);
      fState := 500;    //reintenta y se fija si fueron demasiadas veces
    end;
  end;
  // sale por timeout?
  if (Now > fTimer) then begin
    PutString(chr(EOT_CHAR));
    fState := 0;    //vuelve a idle por timeout
  end;
end;

procedure tASTM.DoInterruptRequested;
begin
//
end;


procedure tASTM.Run;
begin
  self.Active := true;
  fState := 0;
  while (fActive and not Application.Terminated) do  begin
    ProcessStateMachine;
    Application.ProcessMessages;
    sleep(10);
  end;    // while
  ShowMessage('sali del proceso');
end;

procedure tASTM.Stop;
begin
  fActive := false;
end;

procedure tASTM.SetOnIdle(const Value: tNotifyEvent);
begin
  FOnIdle := Value;
end;

procedure tASTM.DoOnIdle;
begin
	if Assigned(fOnIdle) then begin
		fOnIdle(self);
	end;
end;

function tASTM.InputFrameCheckSum(Frame:string): string;
var
  iLen: integer;
begin
  result := '';
  iLen := Length(Frame);
  if iLen>=7 then begin
    result := Frame[iLen-3]+Frame[iLen-2];
  end;
end;

function tASTM.InputFrameEndChar(Frame:string): integer;
var
  iLen: integer;
begin
  result := 0;
  iLen := Length(Frame);
  if iLen>=7 then begin
    result := Ord(Frame[iLen-4]);
  end;
end;

function tASTM.InputFrameNumber(Frame:string): integer;
begin
    result := Ord(Frame[2]) - Ord('0');
end;

function tASTM.InputFrameData(Frame:string): string;
var
  iLen: integer;
begin
  result := '';
  iLen := Length(Frame);
  if iLen>7 then begin
    result := copy(Frame,3,iLen-8);
  end;
end;

function tASTM.GetCount: integer;
begin
  result := fFrameInputList.Count;
end;

function tASTM.GetData: string;
begin
  result := '';
  if fFrameInputList.Count>0 then begin
    result := fFrameInputList.Strings[0];
    fFrameInputList.Delete(0);
  end;
end;

procedure tASTM.SetData(const Value: string);
begin
  fFrameOutputList.Add(Value+chr(CR_CHAR))
end;

procedure tASTM.RunTimer(Sender: TObject);
begin
  fRunTimer.Enabled := false;
  self.Run;
end;

procedure tASTM.SetOnInput(const Value: TGetStrProc);
begin
  FOnInput := Value;
end;

procedure tASTM.DoOnInput(Value: string);
begin
	if Assigned(fOnInput) then begin
		fOnInput(Value);
	end;
end;

procedure tASTM.DoOnOutput(Value: string);
begin
	if Assigned(fOnOutput) then begin
		fOnOutput(Value);
	end;
end;

procedure tASTM.AddInput(s: string);
var
	j: integer;
begin
	for j := 1 to length(s) do begin   // Iterate
		fInputBuffer.AddChar(s[j]);
	end;    // for
end;

procedure tASTM.SetOnConnect(const Value: TGetStrProc);
begin
  FOnConnect := Value;
end;

procedure tASTM.SetOnDisconnect(const Value: TGetStrProc);
begin
  FOnDisconnect := Value;
end;

procedure tASTM.ServerSocket1ClientConnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  FServerConnected := true;
  if Assigned(FOnConnect) then begin
    FOnConnect('Conectado: ' +  Socket.RemoteHost + ' (' +  Socket.RemoteAddress + ')' );
  end;
end;

procedure tASTM.ServerSocket1ClientDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  FServerConnected := false;
  if Assigned(FOnDisconnect) then begin
    FOnConnect('Desconectado: ' + Socket.RemoteHost + ' (' + Socket.RemoteAddress + ')' );
  end;

end;

procedure tASTM.ServerSocket1ClientRead(Sender: TObject; Socket: TCustomWinSocket);
var
  sFrame: string;
begin
  // read from the client
  sFrame := Socket.ReceiveText;
  fFrameInputList.Add(sFrame);
  DoOnInput(sFrame);

  //  ShowMessage(sFrame);
end;

procedure tASTM.PutString(s: string);
var
  j: integer;
begin
  if FServerConnected then begin
    fServerSocket.Socket.SendText(s);
    DoOnOutput(s);
  end
  else begin
    for j := 0 to length(s) do begin
      fCommPort.PutChar(s[j]);
    end;
    DoOnOutput(s);
  end;
end;

procedure tASTM.SetServerConnected(const Value: boolean);
begin
  FServerConnected := Value;
end;

procedure tASTM.SetOnOutput(const Value: TGetStrProc);
begin
  FOnOutput := Value;
end;

end.
