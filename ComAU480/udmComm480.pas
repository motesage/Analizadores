unit udmComm480;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	JvJCLUtils, OoMisc, AdPort, Db, DBTables, UnitComp_LogToFile, ExtCtrls;

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

  TdmComm480 = class(TDataModule)
    SerialPort: TApdComPort;
		procedure SerialPortTriggerAvail(CP: TObject; Count: Word);
	private
		function CommReady:boolean;
		procedure LogError(Msg: string);
		function BufDatosNulo: tBuffDatos;
		procedure CommClear;
    function chequeo(buf, control: string): boolean;
	public
    function Procesa(Secuencia:string; WaitTimer: integer): tBuffDatos;
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

  cStArray: tStArray = ('<Vacio>','<Ok>','<Ack>','<Nak>','<Error>','<TimeOut>','<InProc>','<Inexistente>');

var
  dmComm480: TdmComm480;

implementation
{$R *.DFM}
uses StrUtils; //, udmLocks;

var
  InputBuffer: string = '';
  FrameBuffer: string = '';
  LogErrorProcedure: MethodPointerType ;
  TimeNow :TDateTime;

function TdmComm480.CommReady: boolean;
begin
  result := (Length(InputBuffer)>0);
end;

procedure TdmComm480.CommClear;
begin
  InputBuffer := '';
end;

procedure TdmComm480.CloseCom;
begin
  if SerialPort.Open then
    SerialPort.Open := false;     //quiero la puerta serie cerrada por default
end;

function TdmComm480.OpenCom(NroCom: integer;Speed: integer):Boolean;
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

procedure TdmComm480.SerialPortTriggerAvail(CP: TObject; Count: Word);
var
	i: integer;
begin
	for i := 1 to Count do begin
		InputBuffer := InputBuffer + SerialPort.GetChar;
  end;
	TimeNow := Now;
end;

procedure TdmComm480.LogError(Msg: string);
begin
  LogErrorProcedure(Msg);
end;

function TdmComm480.BufDatosNulo: tBuffDatos;
begin
  with result do begin
    Status := stVacio;
    Data := '';
  end;
end;

function  TdmComm480.Procesa(Secuencia:string; WaitTimer: integer): tBuffDatos;
var
  j: integer;
  s: string;
	TimeOut: TDateTime;
  Respuesta:tBuffDatos;
begin
	TimeOut := WaitTimer * 1000 * mSecsFrac;
	TimeNow := Now;
  Respuesta.Data := 'No hay puerta serie';
  Respuesta.Status := stVacio;
  Result := Respuesta;

	if SerialPort.Open then begin
    Respuesta.Status := stTimeOut;
    Respuesta.Data := 'Tiempo de espera finalizado';
    while ((Now - TimeNow) < TimeOut) and (Respuesta.Status = stTimeOut) do begin
      if Secuencia = '' then begin
        if Pos('DE', InputBuffer) > 1 then begin
          Respuesta.Status := stOk;
          Respuesta.Data := InputBuffer;
          InputBuffer := '';
        end;
        // corto en el ETX
        if pos(ETX, InputBuffer) >0  then begin
          Respuesta.Status := stInProc;
          Respuesta.Data := extractword(1,InputBuffer,[ETX]);
          InputBuffer := extractword(2,InputBuffer, [ETX]);
        end;
      end
      else begin
        // mando un paciente
        Secuencia := STX + Secuencia + ETX;
        Application.ProcessMessages;      //doy tiempo a que los mensajes se procesen
        for j := 1 to Length(Secuencia) do begin
          SerialPort.PutChar(Secuencia[j]);
          Application.ProcessMessages;      //doy tiempo a que los mensajes se procesen
        end;
        //  espero un EOT o un NAK
        while ((Now - TimeNow) < TimeOut) and (not(chequeo(InputBuffer, ETX))) and (not(chequeo(InputBuffer, NAK))) do begin
          Application.ProcessMessages;      //doy tiempo a que los mensajes se procesen
          Sleep(10);
        end;
        if length(InputBuffer) = 1 then begin
          // esto solo puede corresponder a un NAK
          Respuesta.Data := InputBuffer;
          InputBuffer := '';
          Respuesta.Status := stNak;
        end
        else if length(InputBuffer) > 1 then begin
          // Respuesta.Data := copy(InputBuffer,1,length(InputBuffer)-1);
          Respuesta.Data := InputBuffer;
          InputBuffer := '';
          Respuesta.Status := stOK;
        end
        else begin
          Respuesta.Data := 'Error de lectura o timeout';
          InputBuffer := '';
          Respuesta.Status := stError;
        end;
      end;
    end;
    result := respuesta;
  end;
end;

function TdmComm480.chequeo(buf, control: string): boolean;
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


