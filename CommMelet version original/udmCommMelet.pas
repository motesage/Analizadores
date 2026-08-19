unit udmCommMelet;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	OoMisc, AdPort, Db, DBTables, UnitComp_LogToFile;

type
	tBuffStatus = (stVacio, stOk, stAck, stNak, stError, stTimeOut, stInProc, stInexistente);   //estados posibles de un buffer
	tStArray = array[tBuffStatus] of string;
	MethodPointerType = procedure(Txt: string) of object;

	// bufdatos tiene el conjunto de datos que se pueden obtener de una
	// comunicacion con el reloj

	tBuffDatos = record
		Status: tBuffStatus;      //resultado de la comunicacion
		Data: string;             //datos en bruto
  end;

  TdmCommMelet = class(TDataModule)
    SerialPort: TApdComPort;
		procedure SerialPortTriggerAvail(CP: TObject; Count: Word);
	private
		function GetComChar: char;
		function CommReady:boolean;
		procedure LogError(Msg: string);
    function PutData(Msg: string): tBuffStatus;
    procedure CommOut(Txt: string);
    function GetData: tBuffDatos;
    function GetDataMotele: tBuffDatos;
		function BufDatosNulo: tBuffDatos;
		function FrameInNoTOut: tBuffDatos;    //frame in sin timeout
		function FrameIn(mSecsTimeOut: integer): tBuffDatos;   //frame in con TimeOut
		procedure CommInAbort(mSecsTimeOut: integer); //espera TimeOut milisegundos y borra el buffer de entrada
		procedure CommClear;
    function FrameInMotele(mSecsTimeOut: integer): tBuffDatos;
	public
    function GetVersion: tBuffDatos;
    function LeeAnalisis(numero: string): tBuffDatos;
    function LeeAnalisisPorFecha(fecha: tDate): tBuffDatos;
		function OpenCom(NroCom: integer; Speed: integer):Boolean;    //abre la puerta serial
  	procedure CloseCom;
	end;

const
	// caracteres de control de la comunicacion
	STX = #2;
	ETX = #3;

  StringCero = #0;
  MSecsFrac = (1 / MSecsPerDay); // fraccion de dia correspondiente a 1msec
  VezPutData = 5;
  VezGetData = 5;
  VezPutAccess = 5;
	WaitTimer = 3000; // expresado en milisegundos

  cStArray: tStArray = ('<Vacio>','<Ok>','<Ack>','<Nak>','<Error>','<TimeOut>','<InProc>','<Inexistente>');

var
  dmCommMelet: TdmCommMelet;

implementation
{$R *.DFM}
uses StrUtils, uComunica; //, udmLocks;

var
  InputBuffer: string = '';
  FrameBuffer: string = '';
  LogErrorProcedure: MethodPointerType ;

function TdmCommMelet.GetComChar: char;
begin
	result := InputBuffer[1];
	InputBuffer := copy(InputBuffer,2,Length(InputBuffer)-1);
end;    //


function TdmCommMelet.CommReady: boolean;
begin
  result := (Length(InputBuffer)>0);
end;

procedure TdmCommMelet.CommInAbort(mSecsTimeOut: integer);
var
  TimeNow,TimeOut: TDateTime;
begin
  TimeOut := mSecsTimeOut * mSecsFrac;
  TimeNow := Now;
  repeat
    if CommReady then begin
      CommClear;
      TimeNow := Now;
    end;
    Application.ProcessMessages;      //doy tiempo a que los mensajes se procesen
  until ((Now - TimeNow) > TimeOut);
  CommClear;      //limpia el buffer de comunicaciones
end;

procedure TdmCommMelet.CommClear;
begin
  InputBuffer := '';
end;

procedure TdmCommMelet.CloseCom;
begin
  if SerialPort.Open then
    SerialPort.Open := false;     //quiero la puerta serie cerrada por default
end;

function TdmCommMelet.OpenCom(NroCom: integer;Speed: integer):Boolean;
begin
	SerialPort.ComNumber := NroCom;
	SerialPort.Baud := Speed;
	try
		SerialPort.Open := true;
		Result := true;
	except
		// MessageDlg('No se pudo abrir la puerta serie COM'+IntToStr(NroCom), mtError,[mbOk],0);
		Result := false;
	end;
end;

procedure TdmCommMelet.SerialPortTriggerAvail(CP: TObject; Count: Word);
var
	i: integer;
begin
	for i := 1 to Count do begin
		InputBuffer := InputBuffer + SerialPort.GetChar;
  end;
end;

procedure TdmCommMelet.LogError(Msg: string);
// si hay un procedimiento no standard registrado para el log de errores
// lo utilizo, si no solo da un mensaje
begin
  LogErrorProcedure(Msg);
end;


function TdmCommMelet.GetData: tBuffDatos;
var
	Intentos: integer;
	Buf: tBuffDatos;
begin
	Intentos := VezGetData;     //cuantos tries
	repeat
		Buf := FrameIn(WaitTimer);
		case Buf.Status of    //
			stError:
				begin
					CommInAbort(WaitTimer);
				end;
			stVacio, stInProc, stNAK, stTimeOut:
		end;    // case
		Dec(Intentos)
	until ((Intentos<=0) or (Buf.Status = stOk));
	result := Buf;
end;


function TdmCommMelet.GetDataMotele: tBuffDatos;
var
	Buf: tBuffDatos;
begin
  Buf.Status := STok;
  Sleep(100);
  application.ProcessMessages;
  while CommReady do begin
  	Buf.data := Buf.data + InputBuffer;
    InputBuffer := '';
    Sleep(100);
    application.ProcessMessages;
  end;
	result := Buf;
end;

function TdmCommMelet.BufDatosNulo: tBuffDatos;
begin
  with result do begin
    Status := stVacio;
    Data := '';
  end;
end;

function TdmCommMelet.PutData(Msg: string):tBuffStatus;
begin
	CommClear;    //borro el buffer de entrada
	CommOut(Msg);   //saco el mensaje
	Result := stOk;
end;

procedure TdmCommMelet.CommOut(Txt: string);
var
	j: integer;
begin
	if SerialPort.Open then begin
		// armo el paquete Melet
		txt := '$$' + txt + #13;  // agrega $$ y CR
		for j := 1 to Length(txt) do begin
			if (SerialPort.OutBuffFree >= 1) then begin
				SerialPort.PutChar(txt[j]);
			end;
		end;
	end
	else begin
		LogError('La puerta COM'+Format('%1d',[SerialPort.ComNumber])+' no esta abierta.'
			+ CrLf + 'Mensaje: '+ Txt + ' perdido.');
	end;
end;

function TdmCommMelet.FrameIn(mSecsTimeOut: integer): tBuffDatos;   //frame in con TimeOut
var
	Buf: tBuffDatos;
//	TimeNow,TimeOut: TDateTime;
begin
//	TimeOut := mSecsTimeOut * mSecsFrac;
//	TimeNow := Now;
//	repeat
		// Buf := FrameInNoTOut;
		Buf := FrameInMotele(2000);  // 2 segundos ...
//		if not (Buf.Status in [stVacio,stInProc]) then begin
//			break;
//		end;
		// sleep(10);
		// Application.ProcessMessages;      //doy tiempo a que los mensajes se procesen
//	until ((Now - TimeNow) > TimeOut);
//	if (Buf.Status in [stInProc, stVacio]) then begin
//		Buf.Status := stTimeOut;
//	end;
	result := Buf;
end;

function TdmCommMelet.FrameInNoTOut: tBuffDatos;
var
	Stat: tBuffStatus;
	Buf: tBuffDatos;
	m: char;
	lenData: integer;
begin
	Stat := stVacio;
	Buf := BufDatosNulo;
	while CommReady do begin
		Stat := stInProc;
		// extraigo un caracter
		m := GetComChar;    //lo saca del input buffer

		lenData := Length(FrameBuffer);
		if (lenData>0) and (FrameBuffer[lenData] = ETX) then begin
			Stat := stOk;
			Buf.Data := copy(FrameBuffer,2,Lendata-2);
		end
		else if m = STX then begin
			FrameBuffer := m;
		end
		else if (lenData>0) and (FrameBuffer[1] <> STX) then begin
			Stat := stError;
		end
		else begin
			FrameBuffer := FrameBuffer + m;
		end;
		if (Stat<>stInProc) then begin
			FrameBuffer := '';
			break;
		end;
	end;

	Result.Status := Stat;
	Result.Data := Buf.Data;
end;    //

function TdmCommMelet.FrameInMotele(mSecsTimeOut: integer): tBuffDatos;
var
	Stat: tBuffStatus;
	Buf: tBuffDatos;
	m: char;
	lenData: integer;
	TimeNow,TimeOut: TDateTime;
begin
	TimeOut := mSecsTimeOut * mSecsFrac;
	TimeNow := Now;
	Stat := stOk;
	Buf := BufDatosNulo;
	repeat
  	while CommReady do begin
  		Stat := stInProc;
  		// extraigo un caracter
  		m := GetComChar;    //lo saca del input buffer
  		buf.data := buf.data + m;
      if (m = ETX) then begin
        break; // fin del paquete
      end;
  	end;
    if (m = ETX) then begin
      break; // fin del paquete
    end;
    sleep(10);
    application.ProcessMessages;
	until ((Now - TimeNow) > TimeOut);

	Result.Status := Stat;
	Result.Data := Buf.Data;
end;    //

function TdmCommMelet.LeeAnalisis(numero: string): tBuffDatos;
begin
	result := BufDatosNulo;
	result.Status := PutData('HC' + numero);
	if (result.Status = stOk) then begin
    result := GetDataMotele;
	end;
end;

function TdmCommMelet.LeeAnalisisPorFecha(fecha: tDate): tBuffDatos;
begin
	result := BufDatosNulo;
	result.Status := PutData('AD' + datetimetostr(fecha));
	if (result.Status = stOk) then begin
    result := GetDataMotele;
	end;
end;    //


function TdmCommMelet.GetVersion: tBuffDatos;
begin
	result := BufDatosNulo;
	result.Status := PutData('SP');
	if (result.Status = stOk) then begin
    result := GetDataMotele;
	end;
end;

end.


