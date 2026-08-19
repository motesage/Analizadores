unit udmComm350;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	OoMisc, AdPort, Db, DBTables, UnitComp_LogToFile, ExtCtrls;

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

  TdmComm350 = class(TDataModule)
    SerialPort: TApdComPort;
		procedure SerialPortTriggerAvail(CP: TObject; Count: Word);
	private
		function CommReady:boolean;
		procedure LogError(Msg: string);
		function BufDatosNulo: tBuffDatos;
		procedure CommClear;
    function chequeo(buf, control: string): boolean;
    function CRC(s: string): string;
	public
    function Procesa(Secuencia:string; AddCRC: boolean): tBuffDatos;
		function OpenCom(NroCom: integer; Speed: integer):Boolean;    //abre la puerta serial
  	procedure CloseCom;
	end;

const
	// caracteres de control de la comunicacion
	STX = #2;
	ETX = #3;
  EOT = #4;
	ACK = #6;
  NAK = #21;

  StringCero = #0;
  MSecsFrac = (1 / MSecsPerDay); // fraccion de dia correspondiente a 1msec
	WaitTimer = 1000; // expresado en milisegundos

  cStArray: tStArray = ('<Vacio>','<Ok>','<Ack>','<Nak>','<Error>','<TimeOut>','<InProc>','<Inexistente>');

var
  dmComm350: TdmComm350;

implementation
{$R *.DFM}
uses StrUtils, uComunica; //, udmLocks;

var
  InputBuffer: string = '';
  FrameBuffer: string = '';
  LogErrorProcedure: MethodPointerType ;

function TdmComm350.CommReady: boolean;
begin
  result := (Length(InputBuffer)>0);
end;

procedure TdmComm350.CommClear;
begin
  InputBuffer := '';
end;

procedure TdmComm350.CloseCom;
begin
  if SerialPort.Open then
    SerialPort.Open := false;     //quiero la puerta serie cerrada por default
end;

function TdmComm350.OpenCom(NroCom: integer;Speed: integer):Boolean;
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

procedure TdmComm350.SerialPortTriggerAvail(CP: TObject; Count: Word);
var
	i: integer;
begin
	for i := 1 to Count do begin
		InputBuffer := InputBuffer + SerialPort.GetChar;
  end;
end;

procedure TdmComm350.LogError(Msg: string);
// si hay un procedimiento no standard registrado para el log de errores
// lo utilizo, si no solo da un mensaje
begin
  LogErrorProcedure(Msg);
end;


function TdmComm350.BufDatosNulo: tBuffDatos;
begin
  with result do begin
    Status := stVacio;
    Data := '';
  end;
end;

function  TdmComm350.Procesa(Secuencia:string; AddCRC: boolean): tBuffDatos;
var
  j: integer;
  s: string;
	TimeNow,TimeOut: TDateTime;
  Respuesta:tBuffDatos;
begin

	TimeOut := 1000 * mSecsFrac;
	TimeNow := Now;
  Respuesta.Data := 'No hay puerta serie';
  Respuesta.Status := stVacio;
  Result := Respuesta;

	if SerialPort.Open then begin
    Respuesta.Status := stTimeOut;
    Respuesta.Data := 'Tiempo de espera finalizado';
    while ((Now - TimeNow) < TimeOut) and (Respuesta.Status = stTimeOut) do begin
      InputBuffer := '';
      // mando STX y espero hasta ACK
      SerialPort.PutChar(STX);
      while ((Now - TimeNow) < TimeOut) and not chequeo(InputBuffer, ACK) do begin
        Application.ProcessMessages;      //doy tiempo a que los mensajes se procesen
        Sleep(10);
      end;
      InputBuffer := '';
      Application.ProcessMessages;      //doy tiempo a que los mensajes se procesen
      // mando el mensaje mas un EOT y espero hasta un EOT
      if AddCRC then begin
        Secuencia := Secuencia + CRC(Secuencia);
      end;
      Secuencia :=  Secuencia + EOT;
      for j := 1 to Length(Secuencia) do begin
        SerialPort.PutChar(Secuencia[j]);
        Application.ProcessMessages;      //doy tiempo a que los mensajes se procesen
      end;
      //  espero un EOT o un NAK
      while ((Now - TimeNow) < TimeOut) and (not(chequeo(InputBuffer, EOT))) and (not(chequeo(InputBuffer, NAK))) do begin
        Application.ProcessMessages;      //doy tiempo a que los mensajes se procesen
        Sleep(10);
      end;
      if length(InputBuffer) = 1 then begin
        // esto solo puede corresponder a un NAK
        Respuesta.Data := 'No hay mas datos';
        Respuesta.Status := stNak;
      end
      else if length(InputBuffer) = 2 then begin
        // respuesta a un pasaje de lista de pedidos
        // Y[bandeja] o N[coderror]
        Respuesta.Data := InputBuffer;
        Respuesta.Status := stOk;
      end
      else if length(InputBuffer) > 1 then begin
        Respuesta.Data := copy(InputBuffer,1,length(InputBuffer)-1);
        Respuesta.Status := stOK;
      end
      else begin
        Respuesta.Data := 'Error de lectura';
        Respuesta.Status := stError;
      end;
      InputBuffer := '';
    end;
    InputBuffer := '';
    result := respuesta;
  end;
end;


function TdmComm350.CRC(s: string): string;
var
  i, suma: integer;
begin
  // 000000000000001RSN0003GLY BUN CHO 134
  suma := 0;
  for i := 1 to length(s) do begin
      suma := suma + ord(s[i]);
  end;
  suma := suma mod 256;
  result := Format('%.3d',[suma]);
end;


function TdmComm350.chequeo(buf, control: string): boolean;
var
  largo: integer;
begin
  result := false;
  largo := Length(Buf);
  if largo > 0 then begin
    if buf[largo] = control then begin
      result := true;
    end;
  end;
end;


end.


