unit uHL7_PT1000;

interface

uses
   Windows, Messages, SysUtils, Classes,Forms,Dialogs,
   uCommBuffer, OoMisc, AdPort, ExtCtrls, JvJCLUtils, ScktComp, Sockets, udmParamsHL7, uLineFiles;

type
  tHL7_PT1000 = class(tComponent)
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
      fManufacturer: string;
      fModel: string;
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
      function MakeHL7_PT1000Header(sMSH: string): string;
      function MessageType(sMSH: string): string;
      function MSH(sFrame: string): string;
      function ORC(sFrame: string): string;
      function OBR(sFrame: string): string;
      function SampleID(sORC: string): string;
      procedure SendDataAnswer(sMSH,sFileName: string);
      procedure SendDataAnswerQRY(sMSH, sFileName, QRDid: string);
      procedure SendDataAnswerORU(sMSH: string);
      function MessageID(sMSH: string): string;
      function GetFileText(sFileName:string): string;
      function PonePipesDobles(s: string): string;
      function SacaPipesDobles(s: string): string;
      procedure SetOnReadData(const Value: TGetStrProc);
      procedure SetOnError(const Value: TGetStrProc);
      procedure DoOnError(Value: string);
      function GetTokenLine(sToken, sFrame: string): string;
      function GetLineField(sLine: string;iField: integer): string;
      procedure SetOnMessage(const Value: TGetStrProc);
      procedure DoOnMessage(Value: string);
      function MakeHL7_PT1000HeaderQRY2(sfileBoleta, sMSH, QRDid: string): string;
      function MakeHL7_PT1000HeaderORU(sMSH: string): string;
    function MakeHL7_PT1000HeaderQRY(sMSH: string): string;
    procedure SetManufacturer(const Value: string);
    procedure SetModel(const Value: string);
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
      property Manufacturer: string read fManufacturer write SetManufacturer;
      property Model: string read fModel write SetModel;
  end;

  procedure GetFilesList(sPath: string; lstFiles: TStringList);
  function ExtraeNumBoleta(sNombreArchivo: string): String;

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

function ExtraeNumBoleta(sNombreArchivo: string): String;
begin
  result := extractword(1,ExtractFileName(sNombreArchivo),['.']);
end;


{ tHL7_PT1000 }

constructor tHL7_PT1000.Create(AOwner: TComponent);
begin
  inherited;
  fActive := false;
  FOnIdle := nil;
  fRetryCount := 0;
  fInputBuffer := tCommBuffer.Create(self);
  fFrameInputList := TStringList.Create;
  fFrameOutputList := TStringList.Create;
  fServerSocket := TServerSocket.Create(self);
  fServerSocket.Port := 5050;    // CLINICA MONTE GRANDE (VER PORQUE NO ANDA DESDE EL ini)
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


procedure tHL7_PT1000.SetActive(const Value: boolean);
begin
  FActive := Value;
end;

{
 BS600 ROCATTI (desde/hasta)
   MSH|^~\&|||||20180510172945||QRY^Q02|1|P|2.3.1||||||ASCII|||
   QRD|20180510172945|R|D|10|||RD||OTH|||T|
   QRF||||1111|1111|RCT|COR|ALL||
   QRF|sample ini / fin en los campos 4 y 5
 BS400 CLINICA MONTE GRANDE
   pido una a mano *O PIDE CODIGO DE BARRAS !!!*
   MSH|^~\&|Mindray|BS-400|||20190515135448||QRY^Q02|1|P|2.3.1||||||ASCII|||
   QRD|20190515135448|R|D|1|||RD|815025|OTH|||T|
   QRF|BS-400|||||RCT|COR|ALL||
   pido todas o ultimas
   MSH|^~\&|Mindray|BS-400|||20190515144049||QRY^Q02|1|P|2.3.1||||||ASCII|||
   QRD|20190515144049|R|D|1|||RD||OTH|||T|
   QRF|BS-400|20190515000000|20190515144049|||
   QRF|fecha  ini / fin en los campos 2 y 3
}

procedure tHL7_PT1000.DoFrameReceived(sFrame: string);
var
  LinesCount, j: integer;
  vanTodas: boolean;
  sOBR, sMSH, sORC, sMsgType, sQRF, sQRD, sBarCode, sFileName, sFileNameInicial, sFileNameFinal: string;
  sIDUnico, sIDInicial, sIDFinal, sDTInicial, sDTFinal, sMSHId: string;
  lstFiles: TStringList;
  QRD_id: string; //  new dic 2019
begin
  sIDUnico := '';
  sIDInicial := '';
  sIDFinal:= '';
  sDTInicial:= '';
  sDTFinal:= '';
  QRD_id := '';
  //acumulo lo recibido
  fIntFrameData := sFrame;   //fIntFrameData + fInputFrameBuffer;
  // a partir de aca me fijo que tipo de cosa vino
  sMSH := SacaPipesDobles(MSH(fIntFrameData));
  if length(sMSH)>1 then begin
    sMsgType := MessageType(sMSH);
    if sMsgType = 'ORM^O01' then begin   //este es un pedido de datos  BC5380 (MesaLeis)
      sORC := ORC(fIntFrameData);
      sIDInicial := SampleID(sORC);
      if length(sIDInicial)>1 then begin
        sFileName := AppPath + 'Pedidos\'+sIDInicial+'.PED';
        if FileExists(sFileName) then begin
          SendDataAnswer(sMSH,sFileName);
        end;
      end;
    end
    else if sMsgType = 'QRY^Q02' then begin   //este es un pedido de datos  BS400 scaglia o BS600 Rocatti
      sQRD := GetTokenLine('QRD',fIntFrameData);
      //  pedido de un numero de boleta
      //  QRD|20190515135448|R|D|1|||RD|815025|OTH|||T|
      if length(sQRD)>1 then begin
        sIDUnico := GetLineField(sQRD,9); // ES EL ID
        QRD_id := GetLineField(sQRD,5); // ES EL id del mensaje QRD  (|R|D|nnn)
      end;
      sQRF := GetTokenLine('QRF',fIntFrameData);
      //   QRF|fecha  ini / fin en los campos 2 y 3
      //   QRF|BS-400|20190515000000|20190515144049|||
      if length(sQRF)>1 then begin
        sIDInicial := GetLineField(sQRF,5); // id inicial
        sIDFinal := GetLineField(sQRF,6);   // id final
        sDTInicial := GetLineField(sQRF,3);  // fecha inicial
        sDTFinal := GetLineField(sQRF,3);  // fecha inicial
        // parche para BS400 clinica (marcelo mayo 2019)
        if (length(sDTInicial)> 10) and (length(sDTFinal)> 10) then begin
          vanTodas := true;
          sIDInicial := 'Primer-ID';
          sIDFinal := 'Ultimo-ID';
        end
        else begin
          vanTodas := false;
        end;
      end;
      if sIDUnico <> '' then begin
        sIDInicial := sIDUnico;
        sIDFinal := sIDUnico;
      end;
      DoOnMessage('Inicial ' + sIDInicial + ' final ' + sIDFinal + ' QRD_Id ' + QRD_id);
      // ya defini cuales son las ordenes pedidas (una, rango o rango de fecha que se procesa como TODAS)
      if (length(sIDInicial)>0) then begin
        if ((length(sIDFinal)=0) or (sIDInicial = sIDFinal)) then begin
          // esto es para pedir uno solo
          sFileName := AppPath + 'Pedidos\'+sIDInicial+'.PED';
          DoOnMessage('Mindray pide Orden: '+sFileName);
          DoOnMessage('Enviando: '+sFileName);
          SendDataAnswerQRY(sMSH,sFileName, QRD_id);
        end
        else begin
          lstFiles := TStringList.Create;
          // toma toooda la lista de archivos de la carpeta
          try
            sFileNameInicial := AppPath + 'Pedidos\'+sIDInicial+'.PED';
            sFileNameFinal := AppPath + 'Pedidos\'+sIDFinal+'.PED';
            GetFilesList(AppPath + 'Pedidos\*.PED',lstFiles);
            for j := 0 to lstFiles.Count-1 do begin
              // sFileName := lstFiles.Strings[j];
              sFileName := AppPath + 'Pedidos\' + lstFiles.Strings[j];
              DoOnMessage('Mindray pide Orden: '+sFileName);
              if vanTodas or ((sFileName>=sFileNameInicial) and (sFileName<=sFileNameFinal)) then begin
                DoOnMessage('Enviando: '+sFileName);
                SendDataAnswerQRY(sMSH,sFileName, QRD_id);
              end;
            end
          finally
            lstFiles.Free;
          end;
        end;
      end;
    end
    else if sMsgType = 'ORU^R01' then begin   //este es un set de resultados
      sOBR := OBR(fIntFrameData); // OBR|1|(BARCODE) => 2822726|1|Mindray^BS-400|N||20190807094443|||||||20190807090320|Suero|||||||||||||||||||||||||||||||||
      sBarCode := GetLineField(sOBR,3);
      DoOnMessage('ORU Set de results ORDEN ' + sBarcode);
      sMSHId := GetLineField(sMSH,10);
      LinesCount := WordCount(fIntFrameData,[#13]);
      for j := 1 to LinesCount do begin
        fFrameInputList.Add(ExtractWord(j,fIntFrameData,[#13]));
      end;
      SendDataAnswerORU(sMSH);
      // se hace en ServerSocket1ClientRead
      // DoOnInput(fIntFrameData);
    end
    else begin
      LinesCount := WordCount(fIntFrameData,[#13]);
      for j := 1 to LinesCount do begin
        fFrameInputList.Add(ExtractWord(j,fIntFrameData,[#13]));
      end;
        // se hace en ServerSocket1ClientRead
        // DoOnInput(fIntFrameData);
    end;
    fIntFrameData := '';
    fInputFrameBuffer := '';   //limpio le buffer de entrada
    fState := 0;    //frame recibido
  end;
end;

function tHL7_PT1000.MSH(sFrame: string): string;
begin
  result := GetTokenLine('MSH',sFrame);
end;

function tHL7_PT1000.ORC(sFrame: string): string;
begin
  result := GetTokenLine('ORC',sFrame);
end;
function tHL7_PT1000.OBR(sFrame: string): string;
begin
  result := GetTokenLine('OBR',sFrame);
end;

function tHL7_PT1000.GetTokenLine(sToken, sFrame: string): string;
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

function tHL7_PT1000.MessageType(sMSH: string): string;
var
  toksCount: integer;
begin
  result := '';
  sMSH := SacaPipesDobles(sMSH);
  toksCount := WordCount(sMSH,['|']);
  if toksCount>=9 then begin
    result := ExtractWord(9,sMSH,['|']);
  end;

// BS600 ROCATTI
//   MSH|^~\&|||||20180510172945||QRY^Q02|1|P|2.3.1||||||ASCII|||
//   QRD|20180510172945|R|D|10|||RD||OTH|||T|
//   QRF||||1111|1111|RCT|COR|ALL||


// BS400 CLINICA MONTE GRANDE
// pido 1 boleta
//   MSH|^~\&|Mindray|BS-400|||20190515135448||QRY^Q02|1|P|2.3.1||||||ASCII|||
//   QRD|20190515135448|R|D|1|||RD|815025|OTH|||T|
//   QRF|BS-400|||||RCT|COR|ALL||
// pido todas o ultimas boletas
//   MSH|^~\&|Mindray|BS-400|||20190515135448||QRY^Q02|1|P|2.3.1||||||ASCII|||
//   MSH|^~\&|Mindray|BS-400|||20190515144347||QRY^Q02|1|P|2.3.1||||||ASCII|||
//   QRD|20190515144347|R|D|3|||RD||OTH|||T|
//   QRF|BS-400|20190515144144|20190515144347|||RCT|COR|ALL||


end;

function tHL7_PT1000.MessageID(sMSH: string): string;
var
  toksCount: integer;
begin
  result := '';
  toksCount := WordCount(sMSH,['|']);
  if toksCount>=10 then begin
    result := ExtractWord(10,sMSH,['|']);
  end;
end;


function tHL7_PT1000.SampleID(sORC: string): string;
var
  toksCount: integer;
begin
  result := GetLineField(sORC,4);
//MSH|^~\&|||||20180510172945||QRY^Q02|1|P|2.3.1||||||ASCII|||
//QRD|20180510172945|R|D|10|||RD||OTH|||T|
//QRF||||1111|1111|RCT|COR|ALL||
end;

function tHL7_PT1000.GetLineField(sLine: string; iField:integer): string;
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

procedure tHL7_PT1000.SendDataAnswer(sMSH,sFileName: string);
var
  sAns, sMsgID: string;
begin
  sAns := Char(SB_CHAR) + MakeHL7_PT1000Header(sMSH);
  if length(sAns)>1 then begin
    sMsgID := MessageID(sMSH);
    sAns := sAns + Char(CR_CHAR);
    sAns := sAns + 'MSA|AA|'+sMsgId+ Char(CR_CHAR);
    sAns := sAns + GetFileText(sFileName)+Char(CR_CHAR);
    sAns := sAns + Char(EB_CHAR)+Char(CR_CHAR);
    fOutputFrameBuffer := sAns;
  end;
end;

procedure tHL7_PT1000.SendDataAnswerQRY(sMSH,sFileName, QRDid: string);
var
  sAns, sMsgID: string;
begin

  // diciembre 2019 ..... agregado el id del mensaje

  //MSH|^~\&|Mindray|BS-400|||20190807153921||QRY^Q02|1|P|2.3.1||||||ASCII|||
  //QRD|20190807153921|R|D|10|||RD|1609001|OTH|||T|
  //QRF|BS-400|||||RCT|COR|ALL||

  if FileExists(sFileName) then begin
    sAns := Char(SB_CHAR) + MakeHL7_PT1000HeaderQRY(sMSH);
    // MakeHL7_PT1000HeaderQRY ==>
    // MSH|^~\&|||Manufacturer|Model|20070723170707||QCK^Q02|1|P|2.3.1||||||ASCII|||

    if length(sAns)>1 then begin
      sMsgID := MessageID(sMSH);
      sAns := sAns + Char(CR_CHAR);
      sAns := sAns + 'MSA|AA|'+sMsgId+'|Message accepted|||0|'+Char(CR_CHAR);
      sAns := sAns + 'ERR|0|'+Char(CR_CHAR);
      sAns := sAns + 'QAK|SR|OK|'+Char(CR_CHAR);
      sAns := sAns + Char(EB_CHAR)+Char(CR_CHAR);
      sAns := sAns + Char(SB_CHAR) + MakeHL7_PT1000HeaderQRY2(sFilename, sMSH, QRDid);

      // MakeHL7_PT1000HeaderQRY2 ==>
      //MSH|^~\&|||(manufact)|(model)|20190807162248||DSR^Q03|1|P|2.3.1||||||ASCII|||
      //MSA|AA|1|Message accepted|||0|
      //ERR|0|
      //QAK|SR|OK|
      //QRD|20190807162248|R|D|1|||RD|1609001|OTH|||T|
      //QRF|(model)|(datetime)|(datetime)|||RCT|COR|ALL||
      sAns := sAns + GetFileText(sFileName) + Char(CR_CHAR);
      // para pedidos de mas de un archivo, debe ir incrementando el DSC
      // DSC|1|<CR>
      // DSC|2|<CR>
      // ...
      // DSC||<CR>  (ultimo)
      sAns := sAns + Char(EB_CHAR)+Char(CR_CHAR);
      fOutputFrameBuffer := sAns;
    end;
  end
  else begin
    sAns := Char(SB_CHAR) + MakeHL7_PT1000HeaderQRY(sMSH);
    // MakeHL7_PT1000HeaderQRY ==>
    // MSH|^~\&|||Manufacturer|Model|20070723170707||QCK^Q02|1|P|2.3.1||||||ASCII|||
    if length(sAns)>1 then begin
      sMsgID := MessageID(sMSH);
      sAns := sAns + Char(CR_CHAR);
      sAns := sAns + 'MSA|AA|' + sMsgID + '|Message accepted|||0|'+Char(CR_CHAR);
      sAns := sAns + 'ERR|0|' + Char(CR_CHAR);
      sAns := sAns + 'QAK|SR|NF|' + Char(CR_CHAR);
      sAns := sAns + Char(EB_CHAR) + Char(CR_CHAR);
      fOutputFrameBuffer := sAns;
    end;
  end;
end;

function tHL7_PT1000.GetFileText(sFileName:string): string;
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

procedure tHL7_PT1000.SendFrameAnswer(sInput: string);
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
    sAns := MakeHL7_PT1000Header(sMSH);
    if length(sAns)>1 then begin
      sMsgID := MessageID(sMSH);
      sAns := sAns + Char(CR_CHAR) + 'MSA|AA|'+sMsgId;
      fOutputFrameBuffer := fOutputFrameBuffer + sAns;
    end;
  end;
end;

function tHL7_PT1000.MakeHL7_PT1000Header(sMSH: string): string;
var
  sType, sMsgId, sMsgType, sSender, sReceiver, sEncodChars, sProcID, sVersion, sResto: string;
  sTok5, sTok6, sTok7, sTok8: string;
  toksCount, j: integer;
begin
    // solo para este comando (mezaleis)  'ORM^O01'
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


procedure tHL7_PT1000.SendDataAnswerORU(sMSH: string);
var
  sAns, sMsgID: string;
begin
  // El manual del EasyDiagnostics dice:
  // LIS acknowledgment
  // MSH|^~\&|LIS|Gateway|MD|QMT800|20160119104836||ACK|00001|P|2.5
  // MSA|AA|00002

  sMsgID := MessageID(sMSH);
  sAns := Char(SB_CHAR) + MakeHL7_PT1000HeaderORU(sMSH) + Char(CR_CHAR);
  // MSH|^~\&|LIS|Gateway|MD|QMT800|20160119104836||ACK|00001|P|2.5
  sAns := sAns + 'MSA|AA|' + sMsgID + Char(CR_CHAR);
  // MSA|AA|00002
  fOutputFrameBuffer := sAns;
end;

function tHL7_PT1000.MakeHL7_PT1000HeaderQRY2(sfileBoleta, sMSH, QRDid: string): string;
var
  sAns, sType, sMsgId, sMsgType, sSender, sReceiver, sEncodChars, sProcID, sVersion, sResto: string;
  sTok5, sTok6, sTok7, sTok8: string;
  sFecha: string;
  toksCount, j: integer;
begin
  // el header 2 tiene este cacho
  //MSH|^~\&|||(manufact)|(model)|20190807162248||DSR^Q03|1|P|2.3.1||||||ASCII|||
  //MSA|AA|1|Message accepted|||0|
  //ERR|0|
  //QAK|SR|OK|
  //QRD|20190807162248|R|D|1|||RD|1609001|OTH|||T|
  //QRF|(model)|(datetime)|(datetime)|||RCT|COR|ALL||
  sAns := '';
  sType := ExtractWord(1,sMSH,['|']);
  toksCount := WordCount(sMSH,['|']);
  if (sType='MSH') and (toksCount>=12) then begin
    sFecha := FormatDateTime('yyyymmddhhmmss',Now);
    sEncodChars := ExtractWord(2,sMSH,['|']);
    sSender := ExtractWord(3,sMSH,['|']);
    sReceiver := ExtractWord(4,sMSH,['|']);
    sMsgType := ExtractWord(9,sMSH,['|']);
    sMsgId := ExtractWord(10,sMSH,['|']);
    sProcID := ExtractWord(11,sMSH,['|']);
    sVersion := ExtractWord(12,sMSH,['|']);

    // sAns := 'MSH|^~\&|||Mindray|BS-400|' + sFecha +'||DSR^Q03|' + sMsgId + '|' + sProcID + '|' + sVersion+'||||||ASCII|||' + Char(CR_CHAR);
    sAns := 'MSH|^~\&|||' + fManufacturer + '|' + fModel + '|' + sFecha +'||DSR^Q03|' + sMsgId + '|' + sProcID + '|' + sVersion+'||||||ASCII|||' + Char(CR_CHAR);

    sAns := sAns + 'MSA|AA|'+sMsgId+'|Message accepted|||0|' + Char(CR_CHAR);
    sAns := sAns + 'ERR|0|' + Char(CR_CHAR);
    sAns := sAns + 'QAK|SR|OK|' + Char(CR_CHAR);

    // sAns := sAns + 'QRD|' + sFecha +'|R|D|' +sMsgId+'|||RD|' + ExtraeNumBoleta(sfileBoleta)  + '|OTH|||T|' + Char(CR_CHAR);
    // nuevo 31 dic 2019 : le manda el QRD id del pedido !
    sAns := sAns + 'QRD|' + sFecha +'|R|D|' + QRDid + '|||RD|' + ExtraeNumBoleta(sfileBoleta)  + '|OTH|||T|' + Char(CR_CHAR);

    // sAns := sAns + 'QRF|BS-400|' + sFecha + '|' + sFecha + '|||RCT|COR|ALL||' + Char(CR_CHAR);
    sAns := sAns + 'QRF|' + fModel +'|' + sFecha + '|' + sFecha + '|||RCT|COR|ALL||' + Char(CR_CHAR);
    result := sAns;
  end;
end;

function tHL7_PT1000.MakeHL7_PT1000HeaderORU(sMSH: string): string;
var
  sMsgId, sProcID, sVersion: string;
begin
  // El manual del EasyDiagnostics dice:
  // LIS acknowledgment
  // MSH|^~\&|LIS|Gateway|MD|QMT800|20160119104836||ACK|00001|P|2.5
  // MSA|AA|00002
  sMsgId := ExtractWord(10,sMSH,['|']);
  sProcID := ExtractWord(11,sMSH,['|']);
  sVersion := ExtractWord(12,sMSH,['|']);
  result := 'MSH|^~\&|LIS|Gateway|MD|QMT800|' + FormatDateTime('yyyymmddhhmmss',Now)+'||ACK|' + sMsgId+'|P|'+sVersion;
end;

function tHL7_PT1000.MakeHL7_PT1000HeaderQRY(sMSH: string): string;
var
  sMsgId, sProcID, sVersion: string;
begin
  // responde al  'QRY^Q02'
  // MSH|^~\&|||Manufacturer|Model|20070723170707||QCK^Q02|1|P|2.3.1||||||ASCII|||
  sMsgId := ExtractWord(10,sMSH,['|']);
  sProcID := ExtractWord(11,sMSH,['|']);
  sVersion := ExtractWord(12,sMSH,['|']);
  // result := 'MSH|^~\&|||Mindray|BS-400|' + FormatDateTime('yyyymmddhhmmss',Now)+'||QCK^Q02|' + sMsgId+'|'+sProcID+'|'+sVersion+ '||||||ASCII|||';
  result := 'MSH|^~\&|||'+ fManufacturer + '|' + fmodel + '|' + FormatDateTime('yyyymmddhhmmss',Now)+'||QCK^Q02|' + sMsgId+'|'+sProcID+'|'+sVersion+ '||||||ASCII|||';
end;

procedure tHL7_PT1000.Run;
begin
  self.Active := true;
  while (fActive and not Application.Terminated) do  begin
    Application.ProcessMessages;
    sleep(10);
    DoOnIdle;
  end;    // while
  ShowMessage('sali del proceso');
end;

procedure tHL7_PT1000.Stop;
begin
  fActive := false;
end;

procedure tHL7_PT1000.SetOnIdle(const Value: tNotifyEvent);
begin
  FOnIdle := Value;
end;

procedure tHL7_PT1000.DoOnIdle;
begin
	if Assigned(fOnIdle) then begin
		fOnIdle(self);
	end;
end;

function tHL7_PT1000.GetData: string;
begin
  result := '';
  if fFrameInputList.Count>0 then begin
    result := fFrameInputList.Strings[0];
    fFrameInputList.Delete(0);
  end;
end;

procedure tHL7_PT1000.SetData(const Value: string);
begin
  fFrameOutputList.Add(Value+CR_CHAR)
end;


procedure tHL7_PT1000.ServerSocket1ClientConnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  FServerConnected := true;
  if Assigned(FOnConnect) then begin
    FOnConnect('Conectado: ' +  Socket.RemoteHost + ' (' +  Socket.RemoteAddress + ':'+IntToStr(Socket.RemotePort) + ')' );
  end;
end;


// -----------       revisados

procedure tHL7_PT1000.SetPort(const Value: integer);
begin
  FPort := Value;
end;

procedure tHL7_PT1000.SetServerConnected(const Value: boolean);
begin
  FServerConnected := Value;
end;

procedure tHL7_PT1000.ServerSocket1ClientDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  FServerConnected := false;
  if Assigned(FOnDisconnect) then begin
    FOnConnect('Desconectado: ' + Socket.RemoteHost + ' (' + Socket.RemoteAddress + ')' );
  end;
end;

procedure tHL7_PT1000.SetOnConnect(const Value: TGetStrProc);
begin
  FOnConnect := Value;
end;

procedure tHL7_PT1000.SetOnDisconnect(const Value: TGetStrProc);
begin
  FOnDisconnect := Value;
end;

procedure tHL7_PT1000.RunTimer(Sender: TObject);
begin
  fRunTimer.Enabled := false;
  self.Run;
end;

procedure tHL7_PT1000.SetOnInput(const Value: TGetStrProc);
begin
  FOnInput := Value;
end;

procedure tHL7_PT1000.DoOnInput(Value: string);
begin
	if Assigned(fOnInput) then begin
		fOnInput(Value);
	end;
end;

procedure tHL7_PT1000.DoOnError(Value: string);
begin
	if Assigned(fOnError) then begin
		fOnInput('<<error>> ' + Value);
	end;
end;

procedure tHL7_PT1000.DoOnMessage(Value: string);
begin
	if Assigned(fOnMessage) then begin
		fOnMessage(Value);
	end;
end;

function tHL7_PT1000.GetCount: integer;
begin
  result := fFrameInputList.Count;
end;

procedure tHL7_PT1000.ServerSocket1ClientRead(Sender: TObject; Socket: TCustomWinSocket);
var
  sFrame: string;
begin
  sFrame := Socket.ReceiveText;
  DoOnInput('-->  '+sFrame);
  if sFrame[1]=SB_CHAR then begin
    sFrame := copy(sFrame,2,length(sFrame)-2);
  end;
  DoFrameReceived(sFrame);
  Application.ProcessMessages;
  if length(fOutputFrameBuffer)>0 then begin
    // Socket.SendText(Char(SB_CHAR)+fOutputFrameBuffer+Char(EB_CHAR)+Char(CR_CHAR));
    Socket.SendText(fOutputFrameBuffer);
    DoOnInput('<--  '+fOutputFrameBuffer);
    fOutputFrameBuffer := '';
  end;
end;

procedure tHL7_PT1000.ServerSocket1ClientWrite(Sender: TObject; Socket: TCustomWinSocket);
var
  sFrame: string;
begin
//  sFrame := Socket.ReceiveText;
//  if sFrame[1]=SB_CHAR then begin
//    sFrame := copy(sFrame,2,length(sFrame)-2);
//  end;
  //debug
  DoOnInput('<==  ');
  DoFrameReceived(sFrame);
//  if length(fOutputFrameBuffer)>0 then begin
//    Socket.SendText(Char(SB_CHAR)+fOutputFrameBuffer+Char(EB_CHAR)+Char(CR_CHAR));
//    DoOnInput(fOutputFrameBuffer);
//    fOutputFrameBuffer := '';
//  end;
end;

destructor tHL7_PT1000.Destroy;
begin
  fFrameInputList.Free;
  inherited;
end;

function tHL7_PT1000.GetActive: boolean;
begin
  result :=  fActive;
end;

function tHL7_PT1000.SacaPipesDobles(s: string):string;
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

function tHL7_PT1000.PonePipesDobles(s: string):string;
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

procedure tHL7_PT1000.SetOnReadData(const Value: TGetStrProc);
begin
  FOnOnReadData := Value;
end;

procedure tHL7_PT1000.ServerSocket1ClientError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
  if Assigned(FOnError) then begin
    FOnError('Error: '+IntToStr(ErrorCode));
    ErrorCode := 0;
  end;
end;

procedure tHL7_PT1000.SetOnError(const Value: TGetStrProc);
begin
  FOnError := Value;
end;

procedure tHL7_PT1000.SetOnMessage(const Value: TGetStrProc);
begin
  FOnMessage := Value;
end;

procedure tHL7_PT1000.SetManufacturer(const Value: string);
begin
  fManufacturer := Value;
end;

procedure tHL7_PT1000.SetModel(const Value: string);
begin
  fModel := Value;
end;

end.
