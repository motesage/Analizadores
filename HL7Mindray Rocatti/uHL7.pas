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
      fFrameInputList: tStringList;
      fFrameOutputList: tStringList;
      fIntFrameData: string;
      fRetryCount: integer;
      fTimerIdle: tDateTime;
      fRunTimer: tTimer;
      FOnInput: TGetStrProc;
      FOnError: TGetStrProc;
      FOnDisconnect: TGetStrProc;
      FOnConnect: TGetStrProc;
      FServerConnected: boolean;
      FPort: integer;
      FOnOnReadData: TGetStrProc;
      FOnMessage: TGetStrProc;
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
      procedure ServerSocket1ClientError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
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
      procedure SendDataAnswerQRY(sMSH, sORC, sFileName: string);
      procedure SetOnError(const Value: TGetStrProc);
      procedure DoOnError(Value: string);
      function GetTokenLine(sToken, sFrame: string): string;
      function GetLineField(sLine: string;iField: integer): string;
      procedure SetOnMessage(const Value: TGetStrProc);
      procedure DoOnMessage(Value: string);
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
      property OnError: TGetStrProc read FOnError write SetOnError;
      property OnMessage: TGetStrProc read FOnMessage write SetOnMessage;
      property Count: integer read GetCount;
      property Data: string read GetData write SetData;
      property ServerConnected: boolean read FServerConnected write SetServerConnected;
      property Port: integer read FPort write SetPort;
  end;

  procedure GetFilesList(sPath: string; lstFiles: TStringList);

implementation

const
  SB_CHAR = #11;
  EB_CHAR = #28;
  CR_CHAR = #13;

procedure GetFilesList(sPath: string; lstFiles: TStringList);
var
  Rec: tSearchRec;
begin
  lstFiles.Clear;
  if FindFirst(sPath,faAnyFile - faDirectory,Rec)=0 then begin
    try
      repeat
        lstFiles.Add(Rec.Name) ;
      until FindNext(Rec) <> 0;
    finally
      FindClose(Rec) ;
    end;
  end;
  lstFiles.Sort;
end;


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
  fServerSocket.OnClientError := ServerSocket1ClientError;
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
  sMSH, sORC, sMsgType, sIDInicial, sIDFinal, sQRF, sFileName, sFileNameInicial, sFileNameFinal: string;
  lstFiles: TStringList;
begin

  //acumulo lo recibido
  fIntFrameData := sFrame;   //fIntFrameData + fInputFrameBuffer;

  // a partir de aca me fijo que tipo de cosa vino
  sMSH := MSH(fIntFrameData);
  if length(sMSH)>1 then begin
    sMsgType := MessageType(sMSH);
    if sMsgType = 'ORM^O01' then begin   //este es un pedido de datos  BC5380 (MesaLeis)
      sORC := ORC(fIntFrameData);
      sIDInicial := SampleID(sORC);
      if length(sIDInicial)>1 then begin
        sFileName := AppPath + 'Pedidos\'+sIDInicial+'.PED';
        if FileExists(sFileName) then begin
          SendDataAnswer(sMSH,sORC,sFileName);
        end;
      end;
    end
    else if sMsgType = 'QRY^Q02' then begin   //este es un pedido de datos  BS400 Rocatti
      sQRF := GetTokenLine('QRF',fIntFrameData);
      if length(sQRF)>1 then begin
        sIDInicial := GetLineField(sQRF,5);
        sIDFinal := GetLineField(sQRF,6);
        if (length(sIDInicial)>0) then begin
          if ((length(sIDFinal)=0) or (sIDInicial = sIDFinal)) then begin           //esto es para pedir uno solo
            sFileName := AppPath + 'Pedidos\'+sIDInicial+'.PED';
            SendDataAnswerQRY(sMSH,sORC,sFileName);
          end
          else begin
            lstFiles := TStringList.Create;
            try
              sFileNameInicial := AppPath + 'Pedidos\'+sIDInicial+'.PED';
              sFileNameFinal := AppPath + 'Pedidos\'+sIDFinal+'.PED';
              GetFilesList(AppPath + 'Pedidos\*.PED',lstFiles);
              for j := 0 to lstFiles.Count-1 do begin
                sFileName := lstFiles.Strings[j];
                DoOnMessage('Pidiendo: '+sFileName);
                if (sFileName>=sFileNameInicial) and (sFileName<=sFileNameFinal) then begin
                  DoOnMessage('Enviando: '+sFileName);
                  SendDataAnswerQRY(sMSH,sORC,sFileName);
                end;
              end
            finally
              lstFiles.Free;
            end;
          end;
        end;
      end;
    end
    else begin
      LinesCount := WordCount(fIntFrameData,[#13]);
      for j := 1 to LinesCount do begin
        fFrameInputList.Add(ExtractWord(j,fIntFrameData,[#13]));
      end;
      DoOnInput(fIntFrameData);
//      SendFrameAnswer(fIntFrameData);       // si no es uno de los de arriba no contesto nada
    end;
    fIntFrameData := '';
    fInputFrameBuffer := '';   //limpio le buffer de entrada
    fState := 0;    //frame recibido
  end;
end;

function tHL7.MSH(sFrame: string): string;
begin
  result := GetTokenLine('MSH',sFrame);
end;

function tHL7.ORC(sFrame: string): string;
begin
  result := GetTokenLine('ORC',sFrame);
end;

function tHL7.GetTokenLine(sToken, sFrame: string): string;
var
  sBuf, sType: string;
  j, toksCount, linesCount: integer;
begin
  result := '';
  sFrame := SacaPipesDobles(sFrame);
  linesCount := WordCount(sFrame,[#13]);
  for j := 1 to linesCount do begin
    sBuf := ExtractWord(j,sFrame,[#13]);
    toksCount := WordCount(sBuf,['|']);
    if toksCount>=1 then begin
      sType := ExtractWord(1,sBuf,['|']);
      if (UpperCase(trim(sType))=UpperCase(trim(sToken))) then begin
        result := sBuf;
      end;
    end;
  end
end;


function tHL7.MessageType(sMSH: string): string;
var
  toksCount: integer;
begin
  result := '';
  sMSH := SacaPipesDobles(sMSH);
  toksCount := WordCount(sMSH,['|']);
  if toksCount>=9 then begin
    result := ExtractWord(9,sMSH,['|']);
  end;

////>>>>: MSH|^~\&|||||20180510172401||QRY^Q02|1|P|2.3.1||||||ASCII|||QRD|20180510172401|R|D|9|||RD||OTH|||T|QRF||||1111|1111|RCT|COR|ALL||
//MSH|^~\&|||||20180510172945||QRY^Q02|1|P|2.3.1||||||ASCII|||
//QRD|20180510172945|R|D|10|||RD||OTH|||T|//QRF||||1111|1111|RCT|COR|ALL||

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
  result := GetLineField(sORC,4);
//MSH|^~\&|||||20180510172945||QRY^Q02|1|P|2.3.1||||||ASCII|||
//QRD|20180510172945|R|D|10|||RD||OTH|||T|//QRF||||1111|1111|RCT|COR|ALL||
end;

function tHL7.GetLineField(sLine: string; iField:integer): string;
var
  toksCount: integer;
begin
  result := '';
  sLine := SacaPipesDobles(sLine);
  toksCount := WordCount(sLine,['|']);
  if toksCount>=iField then begin
    result := trim(ExtractWord(iField,sLine,['|']));
  end;
end;


procedure tHL7.SendDataAnswer(sMSH,sORC,sFileName: string);
var
  sAns, sMsgID: string;
begin
  sAns := Char(SB_CHAR) + MakeHL7Header(sMSH);
  if length(sAns)>1 then begin
    sMsgID := MessageID(sMSH);
    sAns := sAns + Char(CR_CHAR);
    sAns := sAns + 'MSA|AA|'+sMsgId+ Char(CR_CHAR);
    sAns := sAns + GetFileText(sFileName)+Char(CR_CHAR);
    sAns := sAns + Char(EB_CHAR)+Char(CR_CHAR);
    fOutputFrameBuffer := sAns;
  end;
end;

procedure tHL7.SendDataAnswerQRY(sMSH,sORC,sFileName: string);
var
  sAns, sMsgID: string;
begin
  if FileExists(sFileName) then begin
    sAns := Char(SB_CHAR) + MakeHL7Header(sMSH);
    if length(sAns)>1 then begin
      sMsgID := MessageID(sMSH);
      sAns := sAns + Char(CR_CHAR);
      sAns := sAns + 'MSA|AA|'+sMsgId+'|Message accepted|||0|'+Char(CR_CHAR);
      sAns := sAns + 'ERR|0|'+Char(CR_CHAR);
      sAns := sAns + 'QAK|SR|OK|'+Char(CR_CHAR);
      sAns := sAns + Char(EB_CHAR)+Char(CR_CHAR);
      sAns := sAns + Char(SB_CHAR) + GetFileText(sFileName)+Char(CR_CHAR);
      sAns := sAns + Char(EB_CHAR)+Char(CR_CHAR);
      fOutputFrameBuffer := sAns;
    end;
  end
  else begin
    sAns := Char(SB_CHAR) + MakeHL7Header(sMSH);
    if length(sAns)>1 then begin
      sMsgID := MessageID(sMSH);
      sAns := sAns + Char(CR_CHAR);
      sAns := sAns + 'MSA|AA|'+sMsgId+'|Message accepted|||0|'+Char(CR_CHAR);
      sAns := sAns + 'ERR|0|'+Char(CR_CHAR);
      sAns := sAns + 'QAK|SR|NF|'+Char(CR_CHAR);
      sAns := sAns + Char(EB_CHAR) + Char(CR_CHAR);
      fOutputFrameBuffer := sAns;
    end;
  end;
end;

{
When receiving the message, the LIS returns the QCK^Q02 message and replies
as follows if the sample of the bar code exists:
<SB>MSH|^~\&|||||20120508104700||QCK^Q02|4|P|2.3.1||||||ASCII|||<CR>
MSA|AA|4|Message accepted|||0|<CR>
ERR|0|<CR>
QAK|SR|OK|<CR>
<EB><CR>
If the sample of the bar code does not exist, the LIS replies as follows:
<SB>MSH|^~\&|||||20120508104700||QCK^Q02|4|P|2.3.1||||||ASCII|||<CR>
MSA|AA|4|Message accepted|||0|<CR>
ERR|0|<CR>
QAK|SR|NF|<CR>
<EB><CR>

}


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
  LinesCount: integer;
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
      fOutputFrameBuffer := fOutputFrameBuffer + sAns;
    end;
  end;

end;

function tHL7.MakeHL7Header(sMSH: string): string;
var
  sType, sMsgId, sMsgType, sSender, sReceiver, sEncodChars, sProcID, sVersion, sResto: string;
  sTok5, sTok6, sTok7, sTok8: string;
  toksCount, j: integer;
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
      if sMsgType = 'QRY^Q02' then begin
        sMsgType := 'QCK^Q02';
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

procedure tHL7.DoOnError(Value: string);
begin
	if Assigned(fOnError) then begin
		fOnInput(Value);
	end;
end;

procedure tHL7.DoOnMessage(Value: string);
begin
	if Assigned(fOnMessage) then begin
		fOnMessage(Value);
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
  DoOnError('-->  '+sFrame);
  if sFrame[1]=SB_CHAR then begin
    sFrame := copy(sFrame,2,length(sFrame)-2);
  end;
  DoFrameReceived(sFrame);
  Application.ProcessMessages;
  if length(fOutputFrameBuffer)>0 then begin
//    Socket.SendText(Char(SB_CHAR)+fOutputFrameBuffer+Char(EB_CHAR)+Char(CR_CHAR));
    Socket.SendText(fOutputFrameBuffer);
    DoOnError('<--  '+fOutputFrameBuffer);
    fOutputFrameBuffer := '';
  end;

end;

procedure tHL7.ServerSocket1ClientWrite(Sender: TObject; Socket: TCustomWinSocket);
var
  sFrame: string;
begin
{  sFrame := Socket.ReceiveText;
  if sFrame[1]=SB_CHAR then begin
    sFrame := copy(sFrame,2,length(sFrame)-2);
  end;
  //debug
  DoFrameReceived(sFrame);}
{  if length(fOutputFrameBuffer)>0 then begin
    Socket.SendText(Char(SB_CHAR)+fOutputFrameBuffer+Char(EB_CHAR)+Char(CR_CHAR));
    DoOnInput(fOutputFrameBuffer);
    fOutputFrameBuffer := '';
  end;
}
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

procedure tHL7.ServerSocket1ClientError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
  if Assigned(FOnError) then begin
    FOnError('Error: '+IntToStr(ErrorCode));
    ErrorCode := 0;
  end;
end;

procedure tHL7.SetOnError(const Value: TGetStrProc);
begin
  FOnError := Value;
end;

procedure tHL7.SetOnMessage(const Value: TGetStrProc);
begin
  FOnMessage := Value;
end;

end.
