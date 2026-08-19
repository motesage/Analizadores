unit uComSyl;
{ Esta unidad define un objeto que imnplementa las comunicaciones con
	un TW3500 ya sea por IP o por puerta Serie

  02/Mar/2010
  Agrego la posibilidad de trabajar con AR725 con una salvedad (por el momento)
  Uso (como si fuera la misma) la lectora embebida y la lectora 0 y como adicional la lectora 1
  para evitar la necesidad, por el momento, de agregar pestañas a la pantalla de
  controladores

  }
interface
uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, NMUDP,
  JvStrUtils,
  AdPort, uCommBuffer, udmSeriales, uIPUtils, ScktComp;

type

	tBuffStatus3500 = (stVacio3, stOk3, stAck3, stNak3, stError3, stTimeOut3, stInProc3, stInexistente3);   //estados posibles de un buffer

	tEvento3500 = record
		Data: string;             //datos en bruto
		Reloj: Integer;           //para tener referencia de donde vino
		Id: string;               //twID (resultado de un B)
		Cantidad: integer;        //cant de registraciones (de un B)
		CodEvento: integer;       //donde se ponen los datos de los eventos ampliados
		Lect: integer;            //lectora
		FechaHora: tDateTime;     //fecha y hora varia
		Tarj: integer;            //nro de tarjeta
	end;

	tBuffDatos3500 = record
		Status: tBuffStatus3500;      //resultado de la comunicacion (nuevo mgm Pride)
		AccesoOK: boolean;
		Data: string;
    TipoReg: integer;
	end;

	tDB3500 = record
    Ok: boolean;
		Site: word;
		Card: word;
		PIN: word;
		Mode: word;
		tZone: word;
		Group1: word;
		Group2: word;
		Year: byte;
		Month: byte;
		Day: byte;
		Level: byte;
		Option: byte;
    Datos: array[0..23] of char;
	end;

	TOnInputString = procedure(CP : TObject;
														InputString: string) of object;

	tSylCom = class(tComponent)
		private
			fInputBuffer: tCommBuffer;
			fComPort: TApdComPort;
			FIPAddress: string;
			FNodo: integer;
			FOnInputString: tOnInputString;
      fModelo: integer;
      UdpSocket: TNMUDP;
      TCPSocket: tClientSocket;
      procedure udpDataReceived(Sender: TComponent;	NumberBytes: Integer; FromIP: String; Port: Integer);
      procedure AR725Read(Sender: TObject;  Socket: TCustomWinSocket);
      procedure SetIPAddress(const Value: string);
			procedure SetComNumber(const Value: integer);
			function GetComNumber: integer;
			procedure SetActive(const Value: boolean);
			procedure SetBauds(const Value: integer);
			function GetBauds: integer;
			procedure ComPortTriggerAvail(CP: TObject; Count: Word);
			procedure SetNodo(const Value: integer);
			procedure SetOnInputString(const Value: tOnInputString);
			procedure DoOnInputString(InputString: string);
			function WaitInputChar(InputChar: char): boolean;
			function GetInputDatos: string;
			procedure SendFrame(funcion: char; data: string);
			function GetMensaje: string;
			procedure SetMensaje(const Value: string);
			function GetAnswer: String;
			function GetCharTO: integer;
			function SendFrameWA(funcion: char; datos: string): string;
			function GetActive: boolean;
			procedure SetHora(const Value: tDateTime);
			function GetHora: tDateTime;
	    procedure SetLocalPort(const Value: Integer);
  	  procedure SetRemotePort(const Value: integer);
	    function GetLocalPort: Integer;
  	  function GetRemotePort: integer;
			function GetModo: integer;
      function db3500Nulo: tDb3500;
      function IntToStringMSB(Value: integer; Byte8: boolean): string;
      procedure ClientSocketOnError(Sender: TObject; Socket: TCustomWinSocket;
                      ErrorEvent: TErrorEvent; var ErrorCode: Integer);
		public
			constructor Create(AOwner: TComponent); override;
			destructor Destroy; override;
			function GetEventCounter: integer;
			function GetUserCard(User: integer): integer;
			function Access(Funcion: Char): boolean;
			function GetStatus: boolean;
			function AccionaRele(Puerta: integer = 0): boolean;
			function GetEvent: tBuffDatos3500;
	    function DeleteEvent: tBuffStatus3500;
			function GetEventAmpliado: tBuffDatos3500;
			function BorraCardDefs: boolean;
			function GetOneCardDef(User: integer; Cantidad: word): string;
			function GetOneCardDefDB(User: integer): tDB3500;
			function PutOneCardDef(User, Site, Card, Pin: integer; Modo,	Zona: word): boolean;
			function ClearCardDef: boolean;
			function ReadData(Posicion: integer; Largo: word): string;
	    function WriteData(Posicion: integer; Data: string): string;
			procedure SetNewNodo(NewNodo: Integer);
	    procedure SetPassword(Passw: integer);
			property Hora: tDateTime read GetHora write SetHora;
			property IPAddress: string read FIPAddress write SetIPAddress;
			property LocalPort: Integer read GetLocalPort write SetLocalPort;
      property RemotePort: integer read GetRemotePort write SetRemotePort;
  		property ComNumber: integer read GetComNumber write SetComNumber;
			property Active: boolean read GetActive write SetActive;
			property Bauds: integer read GetBauds write SetBauds;
			property Nodo: integer read FNodo write SetNodo;
			property OnInputString: tOnInputString read FOnInputString write SetOnInputString;
			property InputDatos: string read GetInputDatos;
			property Mensaje: string read GetMensaje write SetMensaje ;
			property Modo: integer read GetModo;
      property Modelo: integer read fModelo write fModelo;    //el numero de modelo de Soyal/Sage (3100, 3500, 725)
		end;

const

	SYL_SEND_GETCARD = #$13;
	SYL_SEND_ACKNOWLDEDGE = #$04;
	SYL_SEND_UNACKNOWLDEDGE = #$05;
	SYL_POLLING_STATUS = #$18;
	SYL_SET_LCD = #$27;

	SYL_GET_DATA = #$12;
	SYL_PUT_DATA = #$20;

	SYL_SET_NODE = #$80;

	// NUEVO MGM Mayo 2007
  SYL_3500_ACCIONA_RELE = #$84;
  SYL_725_ACCIONA_RELE = #$21;

	SYL_SET_TIME = #$23;
	SYL_GET_TIME = #$24;
	SYL_GET_EVENTS = #$25;
	SYL_DELETE_LAST_EVENT = #$37;
	SYL_DELETE_ALL_EVENTS = #$2D;

	SYL_GET_ONECARD_DEF = #$87;
	SYL_SET_ONECARD_DEF = #$83;
	SYL_725_SET_ONECARD_DEF = #$84;
	SYL_DELETE_ALL_DEFS = #$86;  // no usar 85 en version V3 o supetrior !!

	SYL_GET_VERSION = #$21;
  SYL_TIMEOUT = 3000;

	// Tipos de Evento
	EVNT_ERR_PIN  =  #$01; //PIN Code Error
	EVNT_ERR_CARD =  #$03; // Invalid Card
	EVNT_ERR_TZ   =  #$04; //Time Zone Error
	EVNT_OK =  #$0B; 			//Normal Access
	EVNT_EGR =  #$10; 	 	//Egress (decimal 16)
	EVNT_ALARM =  #$11; 	//Alarm Event  (decimal 17)
	EVNT_ERR_APB =  #$1E;  //Anti-pass-back Error (decimal 30)

	// Posiciones de Memoria
	ADDR_CFG_MODO = $0B;

	// Modo de acceso
	MOD_SUSP = 0;
	MOD_CRD = 1;
	MOD_CRD_O_PIN = 2;
	MOD_CRD_Y_PIN = 3;

	MODO_MAPA = 6;
	MODO_PIN = 8;  // (UTI) EN Modo 8, puedo usar el equipo con PIN Only.
                 // en este caso, uso el numero de USER como Credencial !!!!!

	MODO_TABLA = 4; // Es el modo que tiene User + Card

  // Codigos de "DUTY" segun las teclas de funcion.
  DT_DUTY_ON = 0;
  DT_DUTY_OFF = 32;
  DT_BREAK_ON = 128;
  DT_BREAK_OFF = 160;
  DT_OVERTIME_ON = 64;
  DT_OVERTIME_OFF = 96;
	DT_GO_OUT = 192;
	DT_RETURN = 224;

{
  Acceso OK
	EVNT_OK =  #$0B; 			//Normal Access
		tipoReg:
		  DT_DUTY_ON = 0;
		  DT_DUTY_OFF = 32;
		  DT_BREAK_ON = 128;
		  DT_BREAK_OFF = 160;
		  DT_OVERTIME_ON = 64;
		  DT_OVERTIME_OFF = 96;
			DT_GO_OUT = 192;
			DT_RETURN = 224;
  Acceso denegado:
		tipoReg:
			EVNT_ERR_PIN  =  #$01; //PIN Code Error
			EVNT_ERR_CARD =  #$03; // Invalid Card
			EVNT_ERR_TZ   =  #$04; //Time Zone Error
			EVNT_EGR =  #$10;    //Egress (decimal 16)
			EVNT_ALARM =  #$11;  //Alarm Event  (decimal 17)
			EVNT_ERR_APB =  #$1E;  //Anti-pass-back Error (decimal 30)
}


implementation

{ tSylCom }

constructor tSylCom.Create(AOwner: TComponent);
begin
	inherited;
	fInputBuffer := tCommBuffer.Create(self);
  fModelo := 3500;
  try
    UdpSocket := TNMUDP.Create(nil);
    UdpSocket.RemotePort := 99; 		// asas mgm Por ahora es siempre 99
    UdpSocket.LocalPort := 101;
    UdpSocket.OnDataReceived := udpDataReceived;
   except
    // no se pudo crear el socket
  end;
  //este es el socket TCP para el AR725
  try
    TCPSocket := TClientSocket.Create(nil);
    TCPSocket.Port := 1621;
    TCPSocket.OnRead := AR725Read;
    TCPSocket.OnError := ClientSocketOnError;
    TCPSocket.ClientType := ctNonBlocking;
//    TCPSocket.ClientType := ctBlocking;
   except
    on e: exception do ;
  end;
  try
  	fComPort := nil;
    self.SetComNumber(1);
  except
    // no se pudo abrir el COM
  end;

end;

procedure tSylCom.udpDataReceived(Sender: TComponent; NumberBytes: Integer;  FromIP: String; Port: Integer);

const
	MAX_BUFF_LEN = 1024;
var
	TmpStr: array [0..MAX_BUFF_LEN] of char;
  j, bytesLen: Integer;
begin
	try
		bytesLen := NumberBytes;
		if bytesLen>MAX_BUFF_LEN then begin
      bytesLen := MAX_BUFF_LEN;
    end;
    udpSocket.ReadBuffer(TmpStr,bytesLen);
		if bytesLen>0 then begin
			for j := 0 to bytesLen-1 do begin   // Iterate
				fInputBuffer.AddChar(TmpStr[j]);
			end;    // for
    end;
	except
		showMessage('Destino inaccesible (IP: ' + udpSocket.RemoteHost +
										' Port: '+ inttostr(udpSocket.RemotePort) + ')');
	end;
end;

procedure tSylCom.AR725Read(Sender: TObject;  Socket: TCustomWinSocket);
var
  s: string;
  j: Integer;
begin
  try
  	s := Socket.ReceiveText;
  except
    on e: exception do ;
  end;
  for j := 1 to length(s) do  begin
    fInputBuffer.AddChar(s[j]);
  end;    // for
end;



function tSylCom.GetBauds: integer;
begin
	result := fComPort.Baud;
end;

function tSylCom.GetComNumber: integer;
begin
	result := fComPort.ComNumber;
end;

procedure tSylCom.SetActive(const Value: boolean);
var
  TimeOut: tDateTime;
begin
  try
    if (fComPort.ComNumber>0) then begin
  		if (fComPort.Open <> Value) then begin
  			fComPort.Open := Value;
      end;
    end
    else begin
      if (Modelo = 725) then begin
        if not Value then begin
          tcpSocket.Close;
          TimeOut := Now + 2 * SYL_TIMEOUT * (1/(86400*1000));
          while (Now<TimeOut) and (tcpSocket.Socket.Connected) do begin
            sleep(5); // era 10
            Application.ProcessMessages;
          end;    // while
        end
        else begin
          tcpSocket.Open;
          TimeOut := Now + 2 * SYL_TIMEOUT * (1/(86400*1000));
          while (Now<TimeOut) and (not tcpSocket.Socket.Connected) do begin
            sleep(5); // era 10
            Application.ProcessMessages;
          end;    // while
        end;
        //TCPSocket.Active := Value;
        // el active se setea al poner el IP
      end;
    end;
  except
    if (fComPort.ComNumber>0) then begin
      showmessage('Imposible abrir puerta serie en esta PC');
    end
    else begin
      showmessage('Imposible abrir conexion IP');
    end;
  end;
end;

procedure tSylCom.SetIPAddress(const Value: string);
var
	TimeOut: tDateTime;
begin
	// Nuevo mgm UTI, 3500 por puerta serie.
	// si viene un COMx|ssss, paso el IP a ''
	if pos('COM',uppercase(Value))>0 then begin
	  FIPAddress := '';
  end
  else begin
	  FIPAddress := ParseIP(Value);
	  self.RemotePort := ParsePort(Value);
    udpSocket.RemoteHost := FIPAddress;
    udpSocket.RemotePort := self.RemotePort;
    if Modelo = 725 then begin
      if (FIPAddress<>tcpSocket.Address) or not(tcpSocket.Socket.Connected) then begin
        try
          tcpSocket.Close;
        except
          on e:exception do ;
        end;
        tcpSocket.Address := FIPAddress;       //el puerto lo fijo en 1621 para TCP (por ahora)
        tcpSocket.Port := 1621;       //el puerto lo fijo en 1621 para TCP (por ahora)
        try
          tcpSocket.Open;
        except
          on e:exception do ;
        end;
        TimeOut := Now + 2 * SYL_TIMEOUT * (1/(86400*1000));
        while (Now<TimeOut) and (not tcpSocket.Socket.Connected) do begin
          sleep(5); // era 10
          Application.ProcessMessages;
        end;    // while
      end;
    end;
  end;
end;

procedure tSylCom.SetBauds(const Value: integer);
begin
  fComPort.Baud := Value;
end;

procedure tSylCom.SetComNumber(const Value: integer);
begin
	if ((not Assigned(fComPort)) or (Value<>fComPort.ComNumber)) then begin
    fComPort := dmSeriales.Port(Value);
    fComPort.AutoOpen := true;
    fComPort.OnTriggerAvail := ComPortTriggerAvail;
  	fComPort.InSize := 4096*2;
    fComPort.OutSize := 4096*2;
  	fComPort.Baud := 9600;
  end;
end;

// Recibo por COMM

procedure tSylCom.ComPortTriggerAvail(CP: TObject; Count: Word);
var
	j: integer;
begin
	for j := 1 to Count do begin   // Iterate
		fInputBuffer.AddChar(fComPort.GetChar);
	end;    // for
end;

// Recibo por UDP (Nuevo mgm Marzo 2006)


procedure tSylCom.SetNodo(const Value: integer);
begin
  FNodo := Value;
end;

function tSylCom.WaitInputChar(InputChar: char): boolean;
var
  TimeOut: TDateTime;
  cBuff: integer;
begin
	result := false;
	TimeOut := Now + SYL_TIMEOUT * (1/(86400*1000));
	while (Now<TimeOut) do begin
		Application.ProcessMessages;
    cBuff := fInputBuffer.GetChar;
    if (cBuff>=0) and (cBuff=ord(InputChar))then begin
			result := true;
			exit;
    end;
  end;    // while
end;

procedure tSylCom.SetOnInputString(const Value: tOnInputString);
begin
	FOnInputString := Value;
end;

procedure tSylCom.DoOnInputString(InputString: string);
begin
	if Assigned(fOnInputString) then begin
		fOnInputString(self,InputString);
	end;
end;

function tSylCom.GetInputDatos: string;
var
	S: string;
	j: integer;
begin
	s := '';
	for j := 1 to fInputBuffer.Count do begin   // Iterate
		s := s + fInputBuffer.Buffer[j];
	end;    // for
  result := s;
end;

procedure tSylCom.SendFrame(funcion: char; data: string);
var
  buff: array[0..260] of char;
	j, crc: integer;
  MyStream: TMemoryStream;
begin

	// sale COMM o UDP (mgm abril 2006)

	buff[0] := #$7e;
	buff[1] := char(4+length(data));
	buff[2] := char(fNodo and $ff);
	buff[3] := funcion;

	if length(data)>0 then begin
		for j := 1 to length(data) do begin   // Iterate
			buff[3+j] := data[j];
		end;    // for
	end;

	crc := $ff;
	for j := 2 to 3 + length(data) do begin   // Iterate
		crc := ((crc xor ord(buff[j])) and $ff);
	end;    // for
	buff[3+length(data)+1] := char(crc);

	crc := 0;
	for j := 2 to 3 + length(data) + 1 do begin   // Iterate
		crc := ((crc +ord(buff[j])) and $ff);
	end;    // for
	buff[3+length(data)+2] := char(crc);

	// manda el paquete por donde corresponda (COM o IP)
	if isEmptyStr(IPAddress,[' ']) then begin
		// sale por puerta serie
    fComPort.OnTriggerAvail := ComPortTriggerAvail;
		fComPort.PutBlock(buff,6 + length(data));
	end
  else begin
    // 3500 y 3100 van UDP con WebPorts
    if (self.Modelo<>725) then begin
      MyStream := TMemoryStream.Create;
      try
        MyStream.Write(buff[0], 6 + Length(data));
        udpSocket.SendStream(MyStream);
      finally
        MyStream.Free;
      end;
    end
    else begin
      // AR725 va TCP por conversor propio
//      TCPSocket.Address := IPAddress;
//      TCPSocket.Port := 1621;
      if TCPSocket.Socket.Connected then begin
        try
          TCPSocket.Socket.SendBuf(buff,6 + Length(data));
        except
          on e: Exception do begin
          end;
        end;
      end;
    end;
  end;
end;

function tSylCom.GetMensaje: string;
begin
	//
end;

procedure tSylCom.SetMensaje(const Value: string);
begin
  if (self.Modelo<>725) then begin
  	SendFrame(SYL_SET_LCD,char(32) + Value);
  end;
end;

function tSylCom.GetHora: tDateTime;
var
	dtBuf: tDateTime;
	s: string;
begin
	dtBuf := 0;
	s :=  sendFrameWA(SYL_GET_TIME,'');
	if Length(s)>11 then begin
		dtBuf := EncodeDate(2000+ord(s[12]),ord(s[11]),ord(s[10]));
		dtBuf := dtBuf + EncodeTime(ord(s[8]),ord(s[7]),ord(s[6]),0);
	end;
  result := dtBuf;
end;

function tSylCom.GetAnswer: string;
var
	Answer: string;
	cBuf, cLargo, j: integer;
begin
	result := '';
	Answer := '';
	cBuf := GetCharTO;				//inicio
  if cBuf<>$7e then exit;
	Answer := Answer + #$7e;
	cLargo := GetCharTO;				//largo
  if cLargo<0 then exit;
	Answer := Answer + char(cLargo);
	for j := 1 to cLargo do begin
		cBuf := GetCharTO;				//inicio
		if cBuf<0 then exit;
		Answer := Answer + char(cBuf);
	end;    // for
	result := Answer;
end;

function tSylCom.GetCharTO:integer;
var
	TimeOut: tDateTime;
begin
	result := -1;
  TimeOut := Now + SYL_TIMEOUT * (1/(86400*1000));
  while (Now<TimeOut) and (result<0) do begin
		sleep(5); // era 10
    Application.ProcessMessages;
		result := fInputBuffer.GetChar;
	end;    // while
end;


function tSylCom.Access(Funcion: Char): boolean;
begin
	sendFrameWA(SYL_GET_VERSION, Funcion);
	result := true;
end;

function tSylCom.GetStatus: boolean;
begin
	sendFrameWA(SYL_POLLING_STATUS,'');
	result := true;
end;


function tSylCom.ReadData(Posicion: integer; Largo: word): string;
var
	PosL,PosH: word;
	S: string;
begin
	PosH := (Posicion div 256);
	PosL := (Posicion mod 256);
	s := char(PosH)+ char(PosL) + char(Largo);
	result := sendFrameWA(SYL_GET_DATA, s);
end;


function tSylCom.WriteData(Posicion: integer; Data: string): string;
var
	PosL,PosH: word;
	Largo: Word;
  s: string;
begin
	PosH := (Posicion div 256);
	PosL := (Posicion and $FF);
	Largo := length(Data);
	s := char(PosH)+ char(PosL) + char(Largo) + data;
	result := sendFrameWA(SYL_PUT_DATA, s);
end;    //


function tSylCom.SendFrameWA(funcion: char; datos: string): string;
var
	Respuesta: string;
begin
	fInputBuffer.Clear;
	sendFrame(funcion,Datos);
 	Respuesta := GetAnswer;
	DoOnInputString(Respuesta);
	result := Respuesta;
end;

function tSylCom.GetActive: boolean;
begin
	if isEmptyStr(IPAddress,[' ']) then begin
		result := fComPort.Open;
  end
  else begin
    if Modelo = 725 then begin
      result := TCPSocket.Socket.Connected; // en tcp me fijo si esta activo
    end
    else begin
      result := true; // asas mgm para UDP asumo siempre activo
    end;
  end;
end;

procedure tSylCom.SetHora(const Value: tDateTime);
var
	s: string;
	Mes,Dia,ano,sem,hora,min,seg,mseg: word;
begin
	DecodeDate(Value,ano,mes,dia);
	DecodeTime(Value,hora,min,seg,mseg);
	sem := DayOfWeek(Value);
	s := char(seg)+ char(min)+char(hora)+char(sem)+char(dia)+char(mes)+char((ano mod 100) and $ff) ;
	sendFrameWA(SYL_SET_TIME,s);
end;

function tSylCom.BorraCardDefs: boolean;
var
	ans: string;
begin
	result := false;
  //no se si est ecomando funciona o no en el AR725
  if (Modelo<>725) then begin
    ans := sendFrameWA(SYL_DELETE_ALL_DEFS,'');
    if length(ans)>5 then result := true;
  end;
end;

function tSylCom.AccionaRele(Puerta: integer = 0): boolean;
var
  cPuerta: char;
begin
  if (modelo <>725) then begin
  	sendFrameWA(SYL_3500_ACCIONA_RELE,'');
  end
  else begin
    //es un 725 hay que indicar que rele
    cPuerta := char(Puerta and $ff);
  	sendFrameWA(SYL_725_ACCIONA_RELE,#$84+cPuerta);
  end;
	result := true;
	// tw3500.Access(#$84);
end;

destructor tSylCom.Destroy;
begin
  try
		udpSocket.free;
		udpSocket := nil;
  except
    on e:Exception do;
  end;
  try
		TCPSocket.free;
		TCPSocket := nil;
  except
    on e:Exception do;
  end;
  inherited;
end;



// -------------------------------------------------------------------------------------

function tSylCom.GetEventCounter: integer;
var
	ans: string;
begin
	result := 0;
	ans := sendFrameWA(SYL_GET_EVENTS,#$FFFF);
	if length(ans) > 10 then begin
		result := 256*ord(ans[6])+ord(ans[7]);
	end;
end;    //

function tSylCom.GetEvent: tBuffDatos3500;
var
	ans: string;
  iLect: integer;
begin
	{(No Event)
	 7E Len 00 04 XOR SUM
	 1  2   3  4  5   6
	(With Event)                         (en pdf dice 65h)vvv (lectora)
	 7E Len 00h Event Node Sec Min Hour Weekday Day Month 05h [F0H/F1H] CardNum[H+L] Duty
	 1  2   3   4     5    6   7   8    9       10  11    12   13       14/15        16
	 ?	 ?	 ?		 PIN[H+L]
	 17  18  19    20/21	 }
{ AR725 El numero de lectora viene en los 2 primeros bits (LSB) del byte 22 del mensaje
  los 6 bits superiores tienen el numero de nodo - 1


 }


	result.Status := stVacio3;
	result.Data := '';
	result.AccesoOK := false;
	ans := sendFrameWA(SYL_GET_EVENTS,'');
// ojon debug marcelo mgm asas esto hasta 19 de set de 2007 chequeaba el numero del reloj del mensaje !!!
	if (length(ans)>20) then begin
//	if (length(ans)>20) then begin

		iLect := 0;
		// esta modificacion viene de la ultima descripcion dle protocolo de soyal (1.2 Dic26/2006)
		if ((Modelo <> 725) and (length(ans)>30) and (ORD(ans[5]) = fNodo)) then begin
	    if (ord(ans[19]) and $80)<>0 then begin
	      iLect := 1;
	    end;
		end
    else if (length(ans)>20) then begin
      if (Modelo = 725) then begin
  			iLect := (ord(ans[22]) and $02);
        if iLect = 2 then begin
          iLect := 1
        end
        else begin
          iLect := 0
        end;
      end
      else begin
  			iLect := (ord(ans[13]) and $01);
      end;
    end;
		result.Data := format('2%.1d%.2d%.2d%.2d%.2d%.5d',[iLect ,ord(ans[11]),ord(ans[10]),ord(ans[8]),
								ord(ans[7]),256*ord(ans[14])+ord(ans[15])]);

{		result.Data := format('2%.1d%.2d%.2d%.2d%.2d%.5d',[ 0 ,ord(ans[11]),ord(ans[10]),ord(ans[8]),
								ord(ans[7]),256*ord(ans[14])+ord(ans[15])]);
}    result.Status := stOk3; // lectura ok
		if (ans[4] = EVNT_OK) then begin
			// las credenciales suspendidas y las no definidas dan el mismo evento (EVNT_ERR_CARD)
			result.AccesoOK := true;
      result.TipoReg := ord(ans[16]);
		end
    else begin
			// Egress, error antipass, error pin, etc..
			result.AccesoOK := false;
      result.TipoReg := ord(ans[4]); // contiene el codigo del evento
    end;
    // (mayo 2006, Pride)
    // Get Event SOLO LEE.
    // El borrado se hace aparte, y solo en caso de que la lectura, y el get User den OK !!!
	end
  else begin
    result.Status := stVacio3; // no hay datos , largo de registro incorrecto o Numero de reloj incorrecto
  end;
end;



function tSylCom.DeleteEvent: tBuffStatus3500;
var
	ans: string;
begin
	ans :=  sendFrameWA(SYL_DELETE_LAST_EVENT,'');
   {la respuesta es:  (esto es lo que yo "VI", en el manual hay un byte menos (el que indico con rel)
	 estimo que ese caracter es el numero del relojito (me viene 01, 02, etc)
   7E Len 00 cc rel XOR SUM
   7E 05  00 cc 02  F9  FF
   CC: 04  ACK  (SYL_SEND_ACKNOWLDEDGE)
   CC: 05  NACK (SYL_SEND_UNACKNOWLDEDGE)}

  if (length(ans)>=6) then begin
	  if (ans[4] = SYL_SEND_ACKNOWLDEDGE) then begin
	    // pudo borrar.
	    result := stOk3;
	  end
	  else begin
	    result := stError3;
	  end;
  end
  else begin
    result := stError3;
  end;
end;


function tSylCom.IntToStringMSB(Value: integer; Byte8: boolean):string;
var
  j, nBytes, Nro: integer;
begin
  result := '';
  Nro := Value;
  nBytes := 4;
  if Byte8 then begin
    nBytes := 8;
  end;
  for j := 1 to nBytes do begin
    result :=  chr(Nro and $ff) + result;
    Nro := (Nro shr 8);
  end;    // for
end;

function tSylCom.db3500Nulo: tDb3500;
var
  j: integer;
begin
  result.Ok := false;
  result.Site := 0;
  result.Card := 0;
  result.PIN := 0;
  result.Mode := 0;
  result.tZone := 0;
  result.Group1 := 0;
  result.Group2 := 0;
  result.Year := 0;
  result.Month := 0;
  result.Day := 0;
  result.Level := 0;
  result.Option := 0;
  for j := 0 to 23 do begin    // Iterate
    result.Datos[j] := #0;
  end;    // for
end;


function tSylCom.PutOneCardDef(User, Site, Card, Pin: integer;	Modo, Zona: word): boolean;
var
	UserH, UserL, SiteH, SiteL, CardH, CardL, PinH, PinL : word;
	S: string;
  ans: string;
  Datos3500: tDB3500;
  Grupo2: byte;
begin
	{
	7e len 00 83h AddrH AddrL SiteH SiteL CardH CardL PIN-H PIN-L Mode Zone
	1  2   3  4   5     6     7     8      9     10    11   12    13   14
	Addr(H/L) User Address
	Site(H/L) Site code of Tag
	Card(H/L) Card Code of Tag
	PIN(H/L)  PIN code
	Mode:     0-> Invalid 1->Card Only 2-> Card Or PIN 3->Card and PIN
	Zone:     Time Zone
	}
  UserH := (User div 256);
  UserL := (User and $FF);
  SiteH := (Site div 256);
  SiteL := (Site and $FF);
  CardH := (Card div 256);
  CardL := (Card and $FF);
  PinH := (Pin div 256);
  PinL := (Pin and $FF);
  if (self.Modelo <> 725) then begin
    s := char(UserH)+ char(UserL)+char(SiteH)+char(SiteL)+char(CardH)+char(CardL)
        + char(PinH)+ char(PinL) + char(Modo)+ char(Zona) ;
    ans :=  sendFrameWA(SYL_SET_ONECARD_DEF, s);
  end
  else begin
    Datos3500 := self.GetOneCardDefDB(User);
    if Datos3500.Ok then begin
      Grupo2 := Datos3500.Group2 and $ff;
      if Modo>0 then begin
        if Zona = 0  then Grupo2 := (Grupo2 or $3);  // prende 011
        if Zona = 1  then Grupo2 := (Grupo2 or $4);  // prende 100
        if Zona = 2  then Grupo2 := (Grupo2 or $7);  // prende 111
      end
      else begin
        if Zona = 0  then Grupo2 := (Grupo2 and $FC);
        if Zona = 1  then Grupo2 := (Grupo2 and $FB);
        if Zona = 2  then Grupo2 := (Grupo2 and $F8);
      end;
      s := #$01 + char(UserH) + char(UserL) + StringOfChar(#0,4)+char(SiteH)+char(SiteL)+char(CardH)+char(CardL)
            + #0 + #0 + char(PinH) + char(PinL) + #$80 + #0 + #0 + char(Grupo2) + StringOfChar(#0,8);
      ans :=  sendFrameWA(SYL_725_SET_ONECARD_DEF, s);
    end;
  end;
	if length(ans)>= 7 then begin
    result := true;
  end
  else begin
    result := false;
  end;
end;


function tSylCom.GetOneCardDef(User: integer; Cantidad: word): string;
var
	ans: string;
	UserH, UserL: word;
	S: string;
begin

		{Send:
		7E LEN DID 87 Addr-H Addr-L Nums XOR SUM
		Echo:
		7E LEN 00 03 Node SiteH SiteL CardH CardL PINH PINL Mode Zone XOR
		1   2   3  4  5       6     7     8     9   10   11   12   13
		Example:
		Get two card data start from user 3. => 	7E 07 87 00 03 02 78 05	}

	result := '';
	UserH := (User div 256);
	UserL := (User and $FF);
	s := char(UserH)+ char(UserL) + char(Cantidad);
	ans := sendFrameWA(SYL_GET_ONECARD_DEF,s);
  if Modelo <> 725 then begin
    if length(ans)>14 then begin
      result := format('Site %.5d Card %.5d PIN %.5d Mode %.2d Zone %.2d',
      [256*ord(ans[6])+ord(ans[7]),
      256*ord(ans[8])+ord(ans[9]),
      256*ord(ans[10])+ord(ans[11]),
      ord(ans[12]),ord(ans[13])]);
    end;
  end
  else begin
    if length(ans)>20 then begin
      result := format('Site %.5d Card %.5d PIN %.5d Mode %.2d Zone %.2d',
      [256*ord(ans[10])+ord(ans[11]),
      256*ord(ans[12])+ord(ans[13]),
      256*ord(ans[16])+ord(ans[17]),
      ord(ans[18]),ord(ans[21])]);
    end;
  end;
end;

function tSylCom.GetOneCardDefDB(User: integer): tDB3500;
var
	ans: string;
	UserH, UserL: word;
	S: string;
  j: Integer;
begin
  result := db3500Nulo;
	UserH := (User div 256);
	UserL := (User and $FF);
	s := char(UserH)+ char(UserL) + char(1);
	ans := sendFrameWA(SYL_GET_ONECARD_DEF,s);

  if (self.Modelo = 725) then begin
    if length(ans)>30 then begin
      result.Ok := true;
      result.Site := 256*ord(ans[10])+ord(ans[11]);
      result.Card := 256*ord(ans[12])+ord(ans[13]);
      result.PIN := 256*ord(ans[16])+ord(ans[17]);
      result.Mode := ord(ans[18]);
      result.tZone := ord(ans[19]);
      result.Group1 := ord(ans[20]);
      result.Group2 := ord(ans[21]);
      for j := 0 to 23 do begin    // Iterate
        result.Datos[j] := ans[6+j];
      end;    // for
    end;
  end
  else begin
    if length(ans)>14 then begin
      result.Ok := true;
      result.Site := 256*ord(ans[6])+ord(ans[7]);
      result.Card := 256*ord(ans[8])+ord(ans[9]);
      result.PIN := 256*ord(ans[10])+ord(ans[11]);
      result.Mode := ord(ans[12]);
      result.tZone := ord(ans[13]);
    end;
  end;
end;

function tSylCom.GetUserCard(User: integer): integer;
var
	ans: string;
	UserH, UserL: word;
	S: string;
  db3500: tDB3500;
begin
	// result = credencial (user encontrado)
  // result = 0 (credencial cero = no existe el usuario)
  // result = -1 (ERROR)
	result := -1;
  if Modelo<>725 then begin
    UserH := (User div 256);
    UserL := (User and $FF);
    s := char(UserH)+ char(UserL) + char(1);
    ans := sendFrameWA(SYL_GET_ONECARD_DEF,s);
    if length(ans)>14 then begin
      result := 256*ord(ans[8])+ord(ans[9]);
    end;
  end
  else begin
    db3500 := GetOneCardDefDB(User);
    if db3500.Ok then begin
      result := db3500.Card;
    end;
  end;
end;


function tSylCom.GetEventAmpliado: tBuffDatos3500;
var
	usr, card: integer;
  db3500: tDB3500;
begin
	result := self.GetEvent;
	// si el acceso dio inválido, no necesito ir al ampliado,
  // ya que devuielve el nmumero de credencial (y no el numero de user)
	if result.AccesoOK then begin
    // AccesoOK ya garantiza Status = stOk
		// pido al 3500 que me dé la credencial de este usuario:
		Usr := strtointdef(copy(result.Data,11,5),0);
    db3500 := GetOneCardDefDB(usr);
		card := db3500.Card;
		if (card > 0) then begin
			result.AccesoOK := true;
			result.Data := copy(result.Data,1,10) + Format('%.5d',[card]);
		end
		else if (card = 0) then begin
			result.AccesoOK := false;
			// dejo el result con lo que tenía. (en card tendré lo que viene como user)
		end
    else begin
			result.AccesoOK := false;
			// mando error para no borrar el registro (lo vuelve a leer)
			result.Status := stError3;
			// dejo el result con lo que tenía. (en card tendré lo que viene como user)
    end;
	end
	else begin
		result.AccesoOK := false;
	end;
end;

function tSylCom.GetModo: Integer;
var
	S: string;
begin
	result := -1;
	s := readData(ADDR_CFG_MODO,1);
	if Length(S)>5 then begin
		result := ord(s[6]);
	end;
end;

procedure tSylCom.SetLocalPort(const Value: Integer);
begin
  udpSocket.LocalPort := Value;
end;

procedure tSylCom.SetRemotePort(const Value: integer);
begin
  udpSocket.RemotePort := Value;
end;

function tSylCom.GetLocalPort: Integer;
begin
  result := UdpSocket.LocalPort;
end;

function tSylCom.GetRemotePort: integer;
begin
  	result := UdpSocket.RemotePort;
end;

procedure tSylCom.SetNewNodo(NewNodo: Integer);
begin
  sendFrameWA(SYL_SET_NODE,chr(NewNodo));
end;

procedure tSylCom.SetPassword(Passw: integer);
begin
	//

end;

function tSylCom.ClearCardDef: boolean;
var
	UserH, UserL, SiteH, SiteL, CardH, CardL, PinH, PinL : word;
	S: string;
  ans: string;
  Grupo2: byte;
begin
  UserH := 0;
  UserL := 0;
  SiteH := 0;
  SiteL := 0;
  CardH := 0;
  CardL := 0;
  PinH := 0;
  PinL := 0;
  if (self.Modelo <> 725) then begin
//  s := char(UserH)+ char(UserL)+char(SiteH)+char(SiteL)+char(CardH)+char(CardL)
//      + char(PinH)+ char(PinL) + char(Modo)+ char(Zona) ;
//  ans :=  sendFrameWA(SYL_SET_ONECARD_DEF, s);
  end
  else begin
    s := #$00 + char(UserH) + char(UserL) + StringOfChar(#0,4)+char(SiteH)+char(SiteL)+char(CardH)+char(CardL)
          + #0 + #0 + char(PinH) + char(PinL) + char(0)+ char(0) + #$FF + #$FF  + #$99+ #$03+ #$01 + #$00 + #$80 + #$00 + #$00 + #$00;
    ans :=  sendFrameWA(SYL_725_SET_ONECARD_DEF, s);
  end;
	if length(ans)>= 7 then begin
    result := true;
  end
  else begin
    result := false;
  end;
end;


procedure tSylCom.ClientSocketOnError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
  inherited;
//  ShowMessage('Error '+IntToStr(ErrorCode));
  ErrorCode := 0;
  //
end;



end.


