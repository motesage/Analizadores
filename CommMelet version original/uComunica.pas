unit uComunica;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, usage3ToDelphi,
	udmCommMelet, Dialogs, StdCtrls, Grids, Wwdbigrd, Wwdbgrid, Mask, wwdbedit,
  strUtils, Wwdotdot, Wwdbcomb, Db, RxMemDS, Menus, ComCtrls, JvJCLUtils, 
  OoMisc, AdPort, Buttons, ExtCtrls, RxGIF, jpeg, rxToolEdit;

type

	TfrmComunica = class(TForm)
    GroupBox2: TGroupBox;
    Label2: TLabel;
    Label4: TLabel;
    Panel1: TPanel;
    GroupBox3: TGroupBox;
    btnCheck: TBitBtn;
    btnPideAnalisis: TBitBtn;
    edtSecuencia: TEdit;
    GroupBox1: TGroupBox;
    Memo1: TMemo;
    btnSalir: TBitBtn;
    PopupMenu1: TPopupMenu;
    Salir1: TMenuItem;
    btnPorFecha: TBitBtn;
    edtFecha: TDateEdit;
    edtCom: TwwDBComboBox;
    edtVelocidad: TwwDBComboBox;
    Image1: TImage;
    btnGuardar: TBitBtn;
    Memo2: TMemo;
    memoboletas: TMemo;
    memolista: TMemo;
		procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCheckClick(Sender: TObject);
    procedure edtVelocidadChange(Sender: TObject);
    procedure btnSalirClick(Sender: TObject);
    procedure Salir1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnPorFechaClick(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnPideAnalisisClick(Sender: TObject);
	private
		function ChequeaComm: boolean;
    procedure ActualizaLog(S: string);
    procedure LimpiaLog;
    function CheckCom(AComNumber: Integer): Integer;
    function ExtComName(ComNr: DWORD): string;
    procedure LlenaComboCOMMs;
    procedure ActualizaLogFecha(S: string);
    procedure LeeBoleta(secuencia, Boleta: string);
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
		dmCommMelet.CloseCom; // primero la cierro (no da error si estaba cerrada)
		Application.ProcessMessages;
		if not dmCommMelet.OpenCom(strtointdef(edtCom.text,1),strtointdef(edtVelocidad.text,9600)) then begin
			ActualizaLog('Error en apertura de port Com' + edtCom.text);
			result := false;
		end
		else begin
			ActualizaLog('Iniciando comunicaciones Com' + edtCom.text +' speed: '+ edtVelocidad.text);
			CommAbierto := true;
		end;
	end
  else begin
		ActualizaLog('Comunicaciones ya iniciadas ...');
  end;
end;

procedure TfrmComunica.ActualizaLog(S: string);
var
 tramo: string;
 j: Integer;
begin
  tramo := '';
  for j := 1 to length(s) do begin    // Iterate
    if s[j] = #13 then begin
      if length(tramo)>0 then begin
        memo1.lines.add(tramo);
        tramo := '';
      end;
    end
    else begin
      tramo := tramo + s[j];
    end;
  end;    // for
  // escribo el ultimo tramo
  memo1.lines.add(tramo);
end;

procedure TfrmComunica.ActualizaLogFecha(S: string);
var
 tramo: string;
 Posicion: string;
 j: Integer;
 Boleta: string;
 cantidad, inicial: integer;
begin
  memolista.clear;
  tramo := '';
  for j := 1 to length(s) do begin    // Iterate
    if s[j] = #13 then begin
      if length(tramo)>0 then begin
        memoLista.lines.add(tramo);
        tramo := '';
      end;
    end
    else begin
      tramo := tramo + s[j];
    end;
  end;    // for
  // ahora analizo la lista de boletas de esa fecha y la rep...
  for j := 0 to (memolista.lines.count -1) do begin    // Iterate
    tramo := memolista.lines[j];
    if pos('#D',tramo)>0 then begin
      cantidad := strtoIntDef(memolista.lines[j+1],0);
      inicial := j + 2;
      break;
    end;
  end;    // for
  // ahora copio la lista de boletas y sus respectivos items
  memoboletas.clear;
  for j := 1 to cantidad do begin    // Iterate
    // guardo "Posicion : Boleta"
    tramo := trim(memolista.lines[inicial + (j-1)*12]) + ':'+ trim(memolista.lines[inicial + 9 + (j-1)*12]);
    memoBoletas.Lines.add(tramo);
  end;    // for

  // finalmente, recorro los analisis de la lista, uno por uno.
  for j := 1 to memoBoletas.lines.count do begin    // Iterate
    tramo := memoboletas.lines[j-1];
    Posicion := trim(extractWord(1,tramo,[':']));
    Boleta := trim(extractWord(2,tramo,[':']));
    edtSecuencia.text := Posicion;
    leeBoleta(Posicion,Boleta);
    sleep(200);
  end;    // for

end;

procedure TfrmComunica.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	frmComunica := nil;
	action := cafree;
end;

procedure TfrmComunica.btnCheckClick(Sender: TObject);
var
	Lectura: tBuffDatos;
begin
	if ChequeaComm = true then begin
		lectura := dmCommMelet.GetVersion;
		if (lectura.Status = stOK) then begin
			actualizaLog('Lectura de version ok!');
			actualizaLog('Versión ' + lectura.Data);
		end
		else begin
			actualizaLog('Error de comunicaciones');
		end;
	end
	else begin
		showMessage('No se pudo inicializar la comunicación');
	end;
end;

procedure TfrmComunica.edtVelocidadChange(Sender: TObject);
begin
	commAbierto := false;
end;

procedure TfrmComunica.LeeBoleta(secuencia, Boleta: string);
var
  lectura: tBuffDatos;
  sec: integer;
begin
  // limpialog;
  sec := strtointdef(secuencia,0);
	if ChequeaComm = true then begin
    if (sec < 0) or (sec > 9999) then begin
      showmessage('Ingresar un valor entre 1 y 9999');
    end
    else begin
  		ActualizaLog('Leyendo item ' + secuencia);
      if boleta <> '' then begin
    		ActualizaLog('BOLETA :' + Boleta);
      end;
  		lectura := dmCommMelet.LeeAnalisis(compl(Sec,4));
      if (lectura.Status = stOk) then begin
  			ActualizaLog(Lectura.Data);
  		end
  		else begin
  			ActualizaLog('Error al leer datos');
  		end;
    end;
	end
	else begin
		ActualizaLog('No se pudo inicializar la comunicación');
	end;
end;


procedure TfrmComunica.btnSalirClick(Sender: TObject);
begin
  close;
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
begin
  edtFecha.date := date;
  llenacombocomms;
end;

procedure TfrmComunica.btnPorFechaClick(Sender: TObject);
var
  lectura: tBuffDatos;
begin
  // limpialog;
	if ChequeaComm = true then begin
 		ActualizaLog('Leyendo por fecha ');
    lectura := dmCommMelet.LeeAnalisisPorFecha(edtFecha.date);
    if (lectura.Status = stOk) then begin
      ActualizaLogFecha(Lectura.Data);
    end
    else begin
      ActualizaLog('Error al leer datos');
    end;
	end
	else begin
		ActualizaLog('No se pudo inicializar la comunicación');
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
VAR
 i: Integer;
 S, sfecha: string;
 boleta, blancos,rojos,hto,rdw,hg,plaq: string;
begin
  Memo2.lines.clear;
  for i := 1 to MEMO1.Lines.Count do begin    // Iterate
    s := memo1.lines[i-1];
    if pos('BOLETA',s)>0 then begin
      boleta := extractWord(2,s,[':']);
    end;
    if pos('WBC',s)>0 then begin
      blancos := copy(s,5,7);
    end;
    if pos('RBC',s)>0 then begin
      rojos := copy(s,5,7);
    end;
    if pos('Hto',s)>0 then begin
      hto := copy(s,5,7);
    end;
    if pos('RDW',s)>0 then begin
      rdw := copy(s,5,7);
    end;
    if pos('Hgb',s)>0 then begin
      hg := copy(s,5,7);
    end;
    if pos('PLT',s)>0 then begin
      plaq := copy(s,5,7);
      memo2.lines.add('Boleta ='+ trim(boleta));
      memo2.lines.add('Blanc  ='+ trim(blancos));
      memo2.lines.add('Rojos  ='+ trim(rojos));
      memo2.lines.add('Hto    ='+ trim(hto));
      memo2.lines.add('RDW    ='+ trim(rdw));
      memo2.lines.add('Hb     ='+ trim(hg));
      memo2.lines.add('Plaq   ='+ trim(plaq));
      boleta := '';
      blancos := '';
      rojos := '';
      hto := '';
      rdw := '';
      hg := '';
      plaq := '';
    end;
  end;    // for
  sFecha := FormatDateTime('ddmmyyyy',edtFecha.date);
  memo1.lines.SaveToFile('Lectura_' + sFecha + '.txt');
  // guardo una copia local y otra en la red
  try
    memo2.lines.SaveToFile(sFecha + '.txt');
  except
    showmessage('No puedo grabar en el disco F:\. Verificar la red!');
  end;
  memo2.lines.SaveToFile(sFecha + '.txt');
  showmessage('Datos guardados.');

end;

procedure TfrmComunica.btnPideAnalisisClick(Sender: TObject);
begin
  leeBoleta(edtSecuencia.text,'0');
end;

end.
