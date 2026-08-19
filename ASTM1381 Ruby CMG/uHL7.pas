unit uHL7;

interface

uses
   Windows, Messages, SysUtils, Classes,Forms,Dialogs,
   uCommBuffer, OoMisc, AdPort, ExtCtrls, JvJCLUtils, ScktComp, Sockets, udmParamsHL7, uLineFiles;

type
  tHL7 = class(tComponent)
    private
      fInputBuffer: tCommBuffer;
      fInputFrameBuffer: string;
      fOutputFrameBuffer: string;
      fServerSocket: tServerSocket;
      fActive: boolean;
      fState: integer;
      FOnIdle: tNotifyEvent;
      fTimer: tDateTime;
      fBusyTimer: tDateTime;
      fOutputFrameNumber: integer;
      fFrameInputList: tStringList;
      fFrameOutputList: tStringList;
      fIntFrameData: string;
      fRetryCount: integer;
      fTimerIdle: tDateTime;
      fRunTimer: tTimer;
      FOnInput: TGetStrProc;
      FOnDisconnect: TGetStrProc;
      FOnConnect: TGetStrProc;
      FServerConnected: boolean;
      FPort: integer;
      FOnOnReadData: TGetStrProc;
      procedure DoOnIdle;
      procedure DoOnInput(Value: string);
      procedure SetActive(const Value: boolean);
      function GetActive: boolean;
      procedure SetOnIdle(const Value: tNotifyEvent);
      procedure DoFrameReceived(sFrame:string);
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
      procedure ServerSocket1ClientWrite(Sender: TObject; Socket: TCustomWinSocket);
      procedure SetServerConnected(const Value: boolean);
      procedure SetPort(const Value: integer);
      procedure SendFrameAnswer(sInput: string);
      function MakeHL7Header(sMSH: string): string;
      function MessageType(sMSH: string): string;
      function MSH(sFrame: string): string;
      function ORC(sFrame: string): string;
      function SampleID(sORC: string): string;
      procedure SendDataAnswer(sMSH, sORC, sFileName: string);
      function MessageID(sMSH: string): string;
      function GetFileText(sFileName:string): string;
      function PonePipesDobles(s: string): string;
      function SacaPipesDobles(s: string): string;
      procedure SetOnReadData(const Value: TGetStrProc);
    public
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
      procedure Run;
      procedure Stop;
      property Active: boolean read GetActive write SetActive;
      property OnIdle: tNotifyEvent read FOnIdle write SetOnIdle;
      property OnInput: TGetStrProc read FOnInput write SetOnInput;
      property OnConnect: TGetStrProc read FOnConnect write SetOnConnect;
      property OnReadData: TGetStrProc read FOnOnReadData write SetOnReadData;
      property OnDisconnect: TGetStrProc read FOnDisconnect write SetOnDisconnect;
      property Count: integer read GetCount;
      property Data: string read GetData write SetData;
      property ServerConnected: boolean read FServerConnected write SetServerConnected;
      property Port: integer read FPort write SetPort;
  end;

implementation

const
  SB_CHAR = #11;
  EB_CHAR = #28;
  CR_CHAR = #13;



{ tHL7 }

constructor tHL7.Create(AOwner: TComponent);
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
  fServerSocket.OnClientWrite := ServerSocket1ClientWrite;
  fServerSocket.Active := True;
  FServerConnected := false;

  fState := 0;
  fTimer := 0;
  fTimerIdle := 0;
  fBusyTimer := 0;
  fRunTimer := TTimer.Create(self);
  fRunTimer.Interval := 2000;
  fRunTimer.Enabled := true;
  fRunTimer.OnTimer := RunTimer;
end;


procedure tHL7.SetActive(const Value: boolean);
begin
  FActive := Value;
end;


procedure tHL7.DoFrameReceived(sFrame: string);
var
  LinesCount, j: integer;
  sMSH, sORC, sMsgType, sID, sFileName: string;
begin

  //acumulo lo recibido
  fIntFrameData := sFrame;   //fIntFrameData + fInputFrameBuffer;

  // a partir de aca me fijo que tipo de cosa vino
  sMSH := MSH(fIntFrameData);
  if length(sMSH)>1 then begin
    sMsgType := MessageType(sMSH);
    if sMsgType = 'ORM^O01' then begin   //este es un pedido de datos
      sORC := ORC(fIntFrameData);
      sID := SampleID(sORC);
      if length(sID)>1 then begin
        sFileName := AppPath + 'Pedidos\'+sID+'.PED';
        if FileExists(sFileName) then begin
          SendDataAnswer(sMSH,sORC,sFileName);
        end;
      end;
    end
    else begin
      LinesCount := WordCount(fIntFrameData,[#13]);
      for j := 1 to LinesCount do begin
        fFrameInputList.Add(ExtractWord(j,fIntFrameData,[#13]));
      end;
      DoOnInput(fIntFrameData);
      SendFrameAnswer(fIntFrameData);
    end;
    fIntFrameData := '';
    fInputFrameBuffer := '';   //limpio le buffer de entrada
//    fState := 200;    //frame recibido
    fState := 0;    //frame recibido
  end;
end;

function tHL7.MSH(sFrame: string): string;
var
  sBuf, sType: string;
  toksCount, linesCount: integer;
begin
  result := '';
  sFrame := SacaPipesDobles(sFrame);
  linesCount := WordCount(sFrame,[#13]);
  if (linesCount>=1) then begin
    sBuf := ExtractWord(1,sFrame,[#13]);
    toksCount := WordCount(sBuf,['|']);
    if toksCount>=1 then begin
      sType := ExtractWord(1,sBuf,['|']);
      if (sType='MSH') then begin
        result := sBuf;
      end;
    end;
  end;
end;

function tHL7.ORC(sFrame: string): string;
var
  sBuf, sType: string;
  toksCount, linesCount: integer;
begin
  result := '';
  sFrame := SacaPipesDobles(sFrame);
  linesCount := WordCount(sFrame,[#13]);
  if (linesCount>=2) then begin
    sBuf := ExtractWord(2,sFrame,[#13]);
    toksCount := WordCount(sBuf,['|']);
    if toksCount>=1 then begin
      sType := ExtractWord(1,sBuf,['|']);
      if (sType='ORC') then begin
        result := sBuf;
      end;
    end;
  end;
end;


function tHL7.MessageType(sMSH: string): string;
var
  toksCount: integer;
begin
  result := '';
  toksCount := WordCount(sMSH,['|']);
  if toksCount>=9 then begin
    result := ExtractWord(9,sMSH,['|']);
  end;
end;

function tHL7.MessageID(sMSH: string): string;
var
  toksCount: integer;
begin
  result := '';
  toksCount := WordCount(sMSH,['|']);
  if toksCount>=10 then begin
    result := ExtractWord(10,sMSH,['|']);
  end;
end;


function tHL7.SampleID(sORC: string): string;
var
  toksCount: integer;
begin
  result := '';
  toksCount := WordCount(sORC,['|']);
  if toksCount>=4 then begin
    result := trim(ExtractWord(4,sORC,['|']));
  end;
end;

procedure tHL7.SendDataAnswer(sMSH,sORC,sFileName: string);
var
  sAns, sMsgID, sMsg: string;
  LinesCount, toksCount, j: integer;
begin
  sAns := MakeHL7Header(sMSH);
  if length(sAns)>1 then begin
    sMsgID := MessageID(sMSH);
    sAns := sAns + Char(CR_CHAR) + 'MSA|AA|'+sMsgId+ Char(CR_CHAR)+GetFileText(sFileName);
    fOutputFrameBuffer := sAns;
  end;
end;

function tHL7.GetFileText(sFileName:string): string;
var
  s: string;
  lFile: tLineFile;
begin
  lFile := tLineFile.Create;
  try
    lFile.FileName := sFileName;
    lFile.OpenForRead;
    s := '';
    while not lFile.Eof do begin
      s := s + lFile.Read;
      if not lFile.Eof then begin
        s := s + Char(CR_CHAR);
      end;
    end;
    result := s;
  finally
    lFile.Close;
    lFile.Free;
  end;
end;

procedure tHL7.SendFrameAnswer(sInput: string);
var
  sMSH: string;
  sAns, sMsgID: string;
  LinesCount, toksCount, j: integer;
begin
  sInput := SacaPipesDobles(sInput);
  LinesCount := WordCount(sInput,[#13]);
  if LinesCount>=1 then begin
    sMSH := MSH(ExtractWord(1,sInput,[#13]));
  end;

  if length(sMSH)>=1 then begin
    sAns := MakeHL7Header(sMSH);
    if length(sAns)>1 then begin
      sMsgID := MessageID(sMSH);
      sAns := sAns + Char(CR_CHAR) + 'MSA|AA|'+sMsgId;
      fOutputFrameBuffer := sAns;
    end;
  end;

end;

function tHL7.MakeHL7Header(sMSH: string): string;
var
  sType, sMsgId, sMsgType, sSender, sReceiver, sEncodChars, sProcID, sVersion, sResto: string;
  sTok5, sTok6, sTok7, sTok8: string;
  sAns: string;
  LinesCount, toksCount, j: integer;
begin
    result := '';
    sType := ExtractWord(1,sMSH,['|']);
    toksCount := WordCount(sMSH,['|']);
    if (sType='MSH') and (toksCount>=12) then begin
      sEncodChars := ExtractWord(2,sMSH,['|']);
      sSender := ExtractWord(3,sMSH,['|']);
      sReceiver := ExtractWord(4,sMSH,['|']);
      sTok5 := ExtractWord(5,sMSH,['|']);
      sTok6 := ExtractWord(6,sMSH,['|']);
      sTok7 := ExtractWord(7,sMSH,['|']);
      sTok8 := ExtractWord(8,sMSH,['|']);
      sMsgType := ExtractWord(9,sMSH,['|']);
      sMsgId := ExtractWord(10,sMSH,['|']);
      sProcID := ExtractWord(11,sMSH,['|']);
      sVersion := ExtractWord(12,sMSH,['|']);
      sResto := '';
      for j := 13 to toksCount do begin
        sResto := sResto + ExtractWord(j,sMSH,['|']);
      end;
      if sMsgType = 'ORM^O01' then begin
        sMsgType := 'ORR^O02';
      end;
      result := 'MSH|'+sEncodChars+'|'+sReceiver+'|'+sSender+'|'+sTok5+'|'+sTok6+'|'+FormatDateTime('yyyymmddhhmmss',Now)+'|'+sTok8+'|'+sMsgType+'|'+sMsgId+'|'+sProcID+'|'+sVersion+'|'+sResto;
    end;
end;



procedure tHL7.Run;
begin
  self.Active := true;
  while (fActive and not Application.Terminated) do  begin
    Application.ProcessMessages;
    sleep(10);
    DoOnIdle;
  end;    // while
  ShowMessage('sali del proceso');
end;

procedure tHL7.Stop;
begin
  fActive := false;
end;

procedure tHL7.SetOnIdle(const Value: tNotifyEvent);
begin
  FOnIdle := Value;
end;

procedure tHL7.DoOnIdle;
begin
	if Assigned(fOnIdle) then begin
		fOnIdle(self);
	end;
end;

function tHL7.GetData: string;
begin
  result := '';
  if fFrameInputList.Count>0 then begin
    result := fFrameInputList.Strings[0];
    fFrameInputList.Delete(0);
  end;
end;

procedure tHL7.SetData(const Value: string);
begin
  fFrameOutputList.Add(Value+CR_CHAR)
end;


procedure tHL7.ServerSocket1ClientConnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  FServerConnected := true;
  if Assigned(FOnConnect) then begin
    FOnConnect('Conectado: ' +  Socket.RemoteHost + ' (' +  Socket.RemoteAddress + ':'+IntToStr(Socket.RemotePort) + ')' );
  end;
end;


// -----------       revisados

procedure tHL7.SetPort(const Value: integer);
begin
  FPort := Value;
end;

procedure tHL7.SetServerConnected(const Value: boolean);
begin
  FServerConnected := Value;
end;

procedure tHL7.ServerSocket1ClientDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  FServerConnected := false;
  if Assigned(FOnDisconnect) then begin
    FOnConnect('Desconectado: ' + Socket.RemoteHost + ' (' + Socket.RemoteAddress + ')' );
  end;
end;

procedure tHL7.SetOnConnect(const Value: TGetStrProc);
begin
  FOnConnect := Value;
end;

procedure tHL7.SetOnDisconnect(const Value: TGetStrProc);
begin
  FOnDisconnect := Value;
end;

procedure tHL7.RunTimer(Sender: TObject);
begin
  fRunTimer.Enabled := false;
  self.Run;
end;

procedure tHL7.SetOnInput(const Value: TGetStrProc);
begin
  FOnInput := Value;
end;

procedure tHL7.DoOnInput(Value: string);
begin
	if Assigned(fOnInput) then begin
		fOnInput(Value);
	end;
end;

function tHL7.GetCount: integer;
begin
  result := fFrameInputList.Count;
end;

procedure tHL7.ServerSocket1ClientRead(Sender: TObject; Socket: TCustomWinSocket);
var
  sFrame: string;
begin
  sFrame := Socket.ReceiveText;
  if sFrame[1]=SB_CHAR then begin
    sFrame := copy(sFrame,2,length(sFrame)-2);
  end;
  //debug
  DoFrameReceived(sFrame);
  if length(fOutputFrameBuffer)>0 then begin
    Socket.SendText(Char(SB_CHAR)+fOutputFrameBuffer+Char(EB_CHAR)+Char(CR_CHAR));
    DoOnInput(fOutputFrameBuffer);
    fOutputFrameBuffer := '';
  end;
end;

procedure tHL7.ServerSocket1ClientWrite(Sender: TObject; Socket: TCustomWinSocket);
var
  sFrame: string;
begin
//  if length(fOutputFrameBuffer)>0 then begin
//    Socket.SendText(Char(SB_CHAR)+fOutputFrameBuffer+Char(EB_CHAR)+Char(CR_CHAR));
//    DoOnInput(fOutputFrameBuffer);
//    fOutputFrameBuffer := '';
//  end;
end;

destructor tHL7.Destroy;
begin
  fFrameInputList.Free;
  inherited;
end;

function tHL7.GetActive: boolean;
begin
  result :=  fActive;
end;

function tHL7.SacaPipesDobles(s: string):string;
var
  s1: string;
begin
  s1 := s;
  s := ReplaceStr(s,'||','| |');
  while s<>s1 do begin
    s1 := s;
    s := ReplaceStr(s,'||','| |');
  end;
  result := s;
end;

function tHL7.PonePipesDobles(s: string):string;
var
  s1: string;
begin
  s1 := s;
  s := ReplaceStr(s,'| |','||');
  while s<>s1 do begin
    s1 := s;
    s := ReplaceStr(s,'| |','||');
  end;
  result := s;
end;

procedure tHL7.SetOnReadData(const Value: TGetStrProc);
begin
  FOnOnReadData := Value;
end;

end.
