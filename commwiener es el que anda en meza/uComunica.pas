unit uComunica;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
	INIFILES, udmCommMelet, Dialogs, StdCtrls, Grids, Wwdbigrd, Wwdbgrid, Mask, wwdbedit,
  strUtils, Wwdotdot, Wwdbcomb, Db, RxMemDS, Menus, ComCtrls, usage3ToDelphi,
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
    btnPorFecha: TBitBtn;
    btnGuardar: TBitBtn;
    memolista: TMemo;
    Memo1: TMemo;
    chkSalir: TCheckBox;
    log: TLogToFile;
    logRed: TLogToFile;
    edtCom: TLabel;
    edtVelocidad: TLabel;
		procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure edtVelocidadChange(Sender: TObject);
    procedure Salir1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnPorFechaClick(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
	private
		function ChequeaComm: boolean;
    procedure LimpiaLog;
    function CheckCom(AComNumber: Integer): Integer;
    function ExtComName(ComNr: DWORD): string;
    procedure LlenaComboCOMMs;
    procedure ActualizaLogFecha(S: string);
    procedure Actualizalog(S: string);
    procedure LeeConf;
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
		if not dmCommMelet.OpenCom(strtointdef(edtCom.Caption,1),strtointdef(edtVelocidad.Caption,9600)) then begin
			ActualizaLog('Error en apertura de port Com' + edtCom.Caption);
			result := false;
		end
		else begin
			ActualizaLog('Iniciando comunicaciones Com' + edtCom.Caption +' speed: '+ edtVelocidad.Caption);
			CommAbierto := true;
		end;
	end
  else begin
		ActualizaLog('Comunicaciones ya iniciadas ...');
  end;
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
    if s[j] = #2 then begin
    	tramo := '';
    end
    else if s[j] = #26 then begin
      if length(tramo)>0 then begin
        memoLista.lines.add(copy(tramo,1,105));
        tramo := '';
      end;
    end
    else begin
      tramo := tramo + s[j];
    end;
  end;    // for
  btnGuardar.click;
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

procedure TfrmComunica.LeeConf;
var
  IniFile: tInifile;
  sFile: string;
begin
  sFile := ExtractFilePath(ParamStr(0)) + 'CommCounter.ini';
	IniFile := TIniFile.Create(sFile);
  try
    edtcom.Caption := inttostr(IniFile.ReadInteger('Generales','port',1));
    edtVelocidad.Caption := inttostr(IniFile.ReadInteger('Generales','velocidad',9600));
  finally
    IniFile.Free;
  end;
end;


procedure TfrmComunica.FormShow(Sender: TObject);
var
	sFecha: string;
begin
  LeeConf;
  // nuevo 2022 toma com y velocidad del INI
  sFecha := FormatDateTime('yyyymmdd',date);
  log.LogFileName := sFecha + '.txt';
  // logRed.LogFileName := sFecha + '.txt';
end;

procedure TfrmComunica.Actualizalog(S: string);
begin
	memo1.lines.add(s);
end;

procedure TfrmComunica.btnPorFechaClick(Sender: TObject);
var
  lectura: tBuffDatos;
begin
  // limpialog;
	if (ChequeaComm = true) then begin
 		ActualizaLog('Leyendo datos ');
		// while (lectura.Status <> stOk) do begin
		while not(ChkSalir.Checked) do begin
	    lectura := dmCommMelet.LeeAnalisis;
	    if (lectura.Status = stOk) then begin
	      ActualizaLogFecha(Lectura.Data);
	      Application.ProcessMessages;
	    end;
    	if chkSalir.Checked then close;
    end;    // while
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
//var
//  FHandle: THandle;
begin
//  Result := 0;
//  FHandle := CreateFile(PChar(ExtComName(AComNumber)),
//    GENERIC_READ or GENERIC_WRITE,
//    0, {exclusive access}
//    nil, {no security attrs}
//    OPEN_EXISTING,
//    FILE_ATTRIBUTE_NORMAL,
//    0);
//  if FHandle <> INVALID_HANDLE_VALUE then
//    CloseHandle(FHandle)
//  else
//    Result := GetLastError;
end;

procedure TfrmComunica.LlenaComboCOMMs;
//var
//  i, Err: Integer;
begin
//	edtCom.Items.Clear; // inicializa
//  for i := 1 to 20 do begin
//    Err := CheckCom(i);
//    if (Err = 0) then begin
//			// El puerto existe
//      edtCom.Items.add(inttostr(i));
//		end
//		else if (Err = ERROR_ACCESS_DENIED) then begin
//       // El puerto existe pero está en uso
//      edtCom.Items.add(inttostr(i)+ ':En uso');
//		end
//    else if (Err = ERROR_FILE_NOT_FOUND) then begin
//      // the Port does not exists
//		end
//    else begin
//      // another Error
//    end;
//  end;
//  edtCom.ItemIndex := 0;
end;

procedure TfrmComunica.btnGuardarClick(Sender: TObject);
var
 i: Integer;
 S: string;
 begin
  for i := 1 to MEMOlista.Lines.Count do begin    // Iterate
    s := memolista.lines[i-1];
	  log.WriteToLogFile(s);
 	  // logRed.WriteToLogFile(s);
    memo1.lines.add('protocolo ' + copy(s,15,7)+ ' OK');
  end;    // for
end;

end.
