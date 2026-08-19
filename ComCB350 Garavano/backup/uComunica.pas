unit uComunica;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
	udmComm350, Dialogs, StdCtrls, Grids, Wwdbigrd, Wwdbgrid, Mask, wwdbedit,
  strUtils, Wwdotdot, Wwdbcomb, Db, RxMemDS, Menus, ComCtrls, 
  OoMisc, AdPort, Buttons, ExtCtrls, RxGIF, jpeg,
  UnitComp_LogToFile;

type

	TfrmComunica = class(TForm)
    GroupBox2: TGroupBox;
    Label2: TLabel;
    Label4: TLabel;
    Panel1: TPanel;
    GroupBox3: TGroupBox;
    GroupBox1: TGroupBox;
    PopupMenu1: TPopupMenu;
    Salir1: TMenuItem;
    btnLeer: TBitBtn;
    edtCom: TwwDBComboBox;
    edtVelocidad: TwwDBComboBox;
    btnGuardar: TBitBtn;
    memolista: TMemo;
    Memo1: TMemo;
    chkSalir: TCheckBox;
    log: TLogToFile;
    logRed: TLogToFile;
    btnMandaLista: TBitBtn;
    chkSig: TRadioButton;
    chkPrimero: TRadioButton;
    chkRepite: TRadioButton;
    chkLoop: TRadioButton;
		procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure edtVelocidadChange(Sender: TObject);
    procedure Salir1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnLeerClick(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnMandaListaClick(Sender: TObject);
	private
		function ChequeaComm: boolean;
    procedure LimpiaLog;
    function CheckCom(AComNumber: Integer): Integer;
    function ExtComName(ComNr: DWORD): string;
    procedure LlenaComboCOMMs;
    procedure ActualizaLogFecha(S: string);
    procedure Actualizalog(S: string);
    function CodError(Cod: integer): string;
	public
		{ Public declarations }
	end;

var
	frmComunica: TfrmComunica;

implementation

{$R *.DFM}

var
	CommAbierto: boolean = false;

function TfrmComunica.ChequeaComm: boolean;
begin
	result := true;
	if not(commAbierto) then begin
		dmComm350.CloseCom; // primero la cierro (no da error si estaba cerrada)
		Application.ProcessMessages;
		if not dmComm350.OpenCom(strtointdef(edtCom.text,1),strtointdef(edtVelocidad.text,9600)) then begin
			ActualizaLogFecha('Error en apertura de port Com' + edtCom.text);
			result := false;
		end
		else begin
			ActualizaLogFecha('Iniciando comunicaciones Com' + edtCom.text +' speed: '+ edtVelocidad.text);
			CommAbierto := true;
		end;
	end
  else begin
		ActualizaLogFecha('Comunicaciones ya iniciadas ...');
  end;
end;

procedure TfrmComunica.ActualizaLogFecha(S: string);
begin
  memolista.Lines.add(s);
//  btnGuardar.click;
end;

procedure TfrmComunica.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	frmComunica := nil;
	action := cafree;
end;

procedure TfrmComunica.edtVelocidadChange(Sender: TObject);
begin
	commAbierto := false;
end;

procedure TfrmComunica.LimpiaLog;
begin
  memo1.clear;
end;
procedure TfrmComunica.Salir1Click(Sender: TObject);
begin
  close;
end;

procedure TfrmComunica.FormShow(Sender: TObject);
var
	sFecha: string;
begin
  llenacombocomms;
  sFecha := FormatDateTime('yyyymmdd',date);
  log.LogFileName := sFecha + '.txt';
  // logRed.LogFileName := sFecha + '.txt';
end;

procedure TfrmComunica.Actualizalog(S: string);
begin
	memo1.lines.add(s);
end;

procedure TfrmComunica.btnLeerClick(Sender: TObject);
var
  Continua: boolean;
  Inicial: boolean;
  lectura: tBuffDatos;
begin
  // limpialog;
  Inicial := true;
  Continua := true;
	if (ChequeaComm = true) then begin
 		ActualizaLogFecha('Leyendo datos ');
		// while (lectura.Status <> stOk) do begin
    if chkLoop.checked then begin
      while continua and not(ChkSalir.Checked) do begin
        if inicial then begin
          lectura := dmComm350.Procesa('A', false); // primero
          Inicial := not(Inicial);
        end
        else begin
          lectura := dmComm350.Procesa('R', false); // siguiente
        end;
        if (lectura.Status = stOk) then begin
          ActualizaLogFecha(Lectura.Data);
        end
        else if (lectura.Status = stNak) then begin
          ActualizaLogFecha(Lectura.Data);
          Continua := false; // sale !
        end
        else if (lectura.Status = stTimeout) then begin
          ActualizaLogFecha(Lectura.Data);
          Continua := false; // sale !
        end
        else if (lectura.Status = stError) then begin
          ActualizaLogFecha(Lectura.Data);
        end;
        Application.ProcessMessages;
        if chkSalir.Checked then close;
      end;    // while
    end;

    if chkPrimero.checked then begin
      lectura := dmComm350.Procesa('A', false); // primero
      ActualizaLogFecha(Lectura.Data);
      Application.ProcessMessages;
    end;
    if chkSig.checked then begin
      lectura := dmComm350.Procesa('R', false); // siguiente
      ActualizaLogFecha(Lectura.Data);
      Application.ProcessMessages;
    end;
    if chkRepite.checked then begin
      lectura := dmComm350.Procesa('L', false); // repite
      ActualizaLogFecha(Lectura.Data);
      Application.ProcessMessages;
    end;

	end
	else begin
		ActualizaLogFecha('No se pudo inicializar la comunicación');
	end;
end;

function TfrmComunica.ExtComName(ComNr: DWORD): string;
begin
  if ComNr > 9 then
    Result := Format('.COM%d', [ComNr])
  else
    Result := Format('COM%d', [ComNr]);
end;

function TfrmComunica.CheckCom(AComNumber: Integer): Integer;
var
  FHandle: THandle;
begin
  Result := 0;
  FHandle := CreateFile(PChar(ExtComName(AComNumber)),
    GENERIC_READ or GENERIC_WRITE,
    0, {exclusive access}
    nil, {no security attrs}
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0);
  if FHandle <> INVALID_HANDLE_VALUE then
    CloseHandle(FHandle)
  else
    Result := GetLastError;
end;

procedure TfrmComunica.LlenaComboCOMMs;
var
  i, Err: Integer;
begin
	edtCom.Items.Clear; // inicializa
  for i := 1 to 20 do begin
    Err := CheckCom(i);
    if (Err = 0) then begin
			// El puerto existe
      edtCom.Items.add(inttostr(i));
		end
		else if (Err = ERROR_ACCESS_DENIED) then begin
       // El puerto existe pero está en uso
      edtCom.Items.add(inttostr(i)+ ':En uso');
		end
    else if (Err = ERROR_FILE_NOT_FOUND) then begin
      // the Port does not exists
		end
    else begin
      // another Error
    end;
  end;
  edtCom.ItemIndex := 0;
end;

procedure TfrmComunica.btnGuardarClick(Sender: TObject);
var
 i: Integer;
 S: string;
 begin
  memolista.Lines.SaveToFile('CB350' + formatdatetime('yyyymmdd_hhnn', date)+'.txt');
  for i := 1 to MEMOlista.Lines.Count do begin    // Iterate
    s := memolista.lines[i-1];
	  log.WriteToLogFile(s);
    memo1.lines.add('protocolo ' + copy(s,15,7)+ ' OK');
  end;    // for
end;

procedure TfrmComunica.btnMandaListaClick(Sender: TObject);
var
  i: integer;
  s: string;
  resultado: tBuffDatos;
begin
	if (ChequeaComm = true) then begin
    for i := 0 to Memo1.Lines.count-1 do begin
      s := Memo1.Lines[i];
      ActualizaLogFecha('mandando datos '+ s);
      resultado := dmComm350.Procesa(s, true);
      if length(resultado.Data) = 2 then begin
        // respuesta a un pasaje de lista de pedidos
        // Y[bandeja] o N[coderror]
        if resultado.Data[1] = 'Y' then begin
          ActualizaLogFecha('Insertado en bandeja ' + Format('%.3d',[ord(resultado.Data[2])]));
        end
        else if resultado.Data[1] = 'N' then begin
          ActualizaLogFecha('Error ' + CodError(ord(resultado.Data[2])));
        end
        else begin
          ActualizaLogFecha('Error en tamaño de respuesta');
        end;
      end
      else begin
        ActualizaLogFecha('Error en envio del pedido...');
      end;
      Application.ProcessMessages;
    end;
  end;
end;

function TfrmComunica.CodError(Cod:integer): string;
begin
  result := 'Desconocido';
  case Cod of
    1: Result := 'Error en la suma de verificación';
    2: Result := 'Comando desconocido';
    3: Result := 'Error en el campo de Rutina/STAT';
    4: Result := 'Error en el campo de Suero/Orina';
    5: Result := 'Error en el campo Clon Sí/No';
    6: Result := 'Error en la posición del contenedor';
    7: Result := 'Error en el campo Número de análisis';
    8: Result := 'Número de test erróneo';
    9: Result := 'Posición ya en ejecución';
    10: Result := 'Imposible clonar';
    11: Result := 'Código duplicado';
    12: Result := 'Uno o más análisis no están presentes en el analizador';
    13: Result := 'Uno o más análisis no están presentes en la bandeja actual';
    14: Result := 'Demasiados análisis para el paciente';
    15: Result := 'No hay pacientes para repetir';
    16: Result := 'El campo de suero en el paciente a repetirse es diferente al que se encuentra en memoria.';
    17: Result := 'Paciente a repetirse, pero la lista está llena';
    18: Result := 'Paciente a repetirse, pero la lista es diferente';
    19: Result := 'La posición asignada ya está en uso';
    20: Result := 'Paciente ya existente o analizado; no es un clon y pertenece a una lista suplementaria (extra)';
    21: Result := 'Paciente ya analizado, pero no hay repeticiones o clones activos';
  end;
end;


end.
