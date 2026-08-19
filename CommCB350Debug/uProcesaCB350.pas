unit uProcesaCB350;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
	udmComm350, Dialogs, StdCtrls, Grids, Wwdbigrd, Wwdbgrid, Mask, wwdbedit,
  IniFiles, strUtils, Wwdotdot, Wwdbcomb, Db, RxMemDS, Menus, ComCtrls,
  JvJCLUtils,  OoMisc, AdPort, Buttons, ExtCtrls, RxGIF, jpeg,
  UnitComp_LogToFile, JvMemoryDataset;
type

	TfrmProcesaCB350 = class(TForm)
    grpTop: TGroupBox;
    Label2: TLabel;
    Label4: TLabel;
    Panel1: TPanel;
    GroupBox3: TGroupBox;
    GroupBox1: TGroupBox;
    PopupMenu1: TPopupMenu;
    Salir1: TMenuItem;
    memolista: TMemo;
    Memo1: TMemo;
    chkSalir: TCheckBox;
    log: TLogToFile;
    OpenDialog1: TOpenDialog;
    grpCabezal: TGroupBox;
    btnMandaLista: TBitBtn;
    btnLeer: TBitBtn;
    Label6: TLabel;
    edtCarpetaRes: TEdit;
    btnSelecciona: TBitBtn;
    Log1: TLogToFile;
    edtAdicional: TEdit;
    chkLoop: TRadioButton;
    chkPrimero: TRadioButton;
    chkSig: TRadioButton;
    chkRepite: TRadioButton;
    Label1: TLabel;
    mtblPedidos: TJvMemoryData;
    mtblPedidosBoleta: TStringField;
    mtblPedidosTipo: TStringField;
    mtblPedidosMaterial: TStringField;
    mtblPedidosEsClon: TStringField;
    mtblPedidosPosicion: TStringField;
    mtblPedidosTests: TStringField;
    grdPedidos: TwwDBGrid;
    dsPedidos: TDataSource;
    mtblPedidosPedir: TBooleanField;
    mtblPedidosCantTest: TIntegerField;
    Label3: TLabel;
    edtSerialPort: TEdit;
    edtVelocidad: TEdit;
    ChkAuto: TCheckBox;
    Timer1: TTimer;
		procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure edtVelocidadChange(Sender: TObject);
    procedure Salir1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnLeerClick(Sender: TObject);
    procedure btnMandaListaClick(Sender: TObject);
    procedure btnSeleccionaClick(Sender: TObject);
    procedure grdPedidosTitleButtonClick(Sender: TObject;
      AFieldName: String);
    procedure edtAdicionalChange(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
	private
		function ChequeaComm: boolean;
    procedure ActualizaLogFecha(S: string);
    procedure Actualizalog(S: string);
    function CodError(Cod: integer): string;
    procedure limpiamemos;
    procedure SwitchPedido;
    procedure LeeConf;
    procedure ProcesaAuto;
    procedure ProcesaPedidos(sFile, adic: string);
    procedure EnviaPedidos;
    procedure TraeResultados;

	public
		{ Public declarations }
	end;

var
	frmProcesaCB350: TfrmProcesaCB350;

implementation

{$R *.DFM}

var
	CommAbierto: boolean = false;
  FormShowed: boolean = false;

function TfrmProcesaCB350.ChequeaComm: boolean;
begin
	result := true;
	if not(commAbierto) then begin
		dmComm350.CloseCom; // primero la cierro (no da error si estaba cerrada)
		Application.ProcessMessages;
		if not dmComm350.OpenCom(strtointdef(edtSerialPort.text,1),strtointdef(edtVelocidad.text,9600)) then begin
			ActualizaLogFecha('Error en apertura de port Com' + edtSerialPort.text);
			result := false;
		end
		else begin
			ActualizaLogFecha('Iniciando comunicaciones Com' + edtSerialPort.text +' speed: '+ edtVelocidad.text);
			CommAbierto := true;
		end;
	end
  else begin
		ActualizaLogFecha('Comunicaciones ya iniciadas ...');
  end;
end;

procedure TfrmProcesaCB350.ActualizaLogFecha(S: string);
begin
  memolista.Lines.add(s);
  log.WriteToLogFile(s);
end;

procedure TfrmProcesaCB350.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	frmProcesaCB350 := nil;
	action := cafree;
end;

procedure TfrmProcesaCB350.edtVelocidadChange(Sender: TObject);
begin
	commAbierto := false;
end;

procedure TfrmProcesaCB350.Salir1Click(Sender: TObject);
begin
  chkSalir.Checked := true;
  close;
end;

procedure TfrmProcesaCB350.FormShow(Sender: TObject);
var
	sFecha: string;
begin
  btnMandaLista.Enabled := false;
  LeeConf;
  sFecha := FormatDateTime('yyyymmdd',date);
  log1.LogFileName := ExtractFilePath(ParamStr(0)) +'Interfaces\CB350\Resultados\RESCB350_' + sFecha + '.txt';  // por fecha .....
  log.LogFileName := ExtractFilePath(ParamStr(0)) +'Interfaces\CB350\Resultados\RESCB350.txt';  // solo los del dia. debe borrarlo el programa que los lee !!

  ShowMessage('Log en carpeta ' + log.LogFileName);
  if ChkAuto.Checked then begin
    grpCabezal.Visible := false;
  end;
  FormShowed := true;
end;

procedure TfrmProcesaCB350.ProcesaAuto;
var
  sFilePath: string;
  SR: TSearchRec;
begin
  while not(ChkSalir.Checked) do begin
    sFilePath := ExtractFilePath(ParamStr(0)) + '\Interfaces\CB350\Pedidos\';
    if FindFirst(sFilePath + '*.*', faArchive, SR) = 0 then begin
      repeat
        ProcesaPedidos(sFilePath + SR.Name, '');
        DeleteFile(sFilePath + SR.Name);
      until FindNext(SR) <> 0;
      FindClose(SR);
    end;
    sleep(3000);
    Application.ProcessMessages;
    EnviaPedidos;
    sleep(3000);
    Application.ProcessMessages;
    TraeResultados;
    sleep(4000);
    Application.ProcessMessages;
  end; // while
end;

procedure TfrmProcesaCB350.Actualizalog(S: string);
begin
	memo1.lines.add(s);
end;

procedure TfrmProcesaCB350.TraeResultados;
var
  Continua: boolean;
  Inicial: boolean;
  lectura: tBuffDatos;
begin
  limpiamemos;
  Memo1.Visible := true;
  grdPedidos.Visible := false;
  Inicial := true;
  Continua := true;
	if (ChequeaComm = true) then begin
 		ActualizaLogFecha('Leyendo datos ');
    if chkLoop.checked then begin
      while continua and not(ChkSalir.Checked) do begin
        lectura := dmComm350.Procesa('R', false); // siguiente
        if (lectura.Status = stOk) then begin
          ActualizaLogFecha(Lectura.Data);
        end
        else if (lectura.Status = stNak) then begin
          ActualizaLogFecha('Error stNak ' + Lectura.Data);
          Continua := false; // sale !
        end
        else if (lectura.Status = stTimeout) then begin
          ActualizaLogFecha('Error stTimeout ' + Lectura.Data);
          Continua := false; // sale !
        end
        else if (lectura.Status = stError) then begin
          ActualizaLogFecha('Error sTError ' + Lectura.Data);
          Continua := false;
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

procedure TfrmProcesaCB350.btnLeerClick(Sender: TObject);
begin
  TraeResultados;
end;

procedure TfrmProcesaCB350.LeeConf;
var
	IniFile: tInifile;
  sFile: string;
begin

  sFile := ExtractFilePath(ParamStr(0)) + 'CommCB350.ini';
	IniFile := TIniFile.Create(sFile);
  try
    edtVelocidad.Text := IntToStr(IniFile.ReadInteger('parametros','bauds',9600));
    edtSerialPort.Text := IntToStr(IniFile.ReadInteger('parametros','port',1));
  finally
    IniFile.Free;
	end;
end;

procedure TfrmProcesaCB350.EnviaPedidos;
var
  i,j: integer;
  sBoleta: string;
  cantidad: integer;
  s, s1: string;
  resultado: tBuffDatos;
begin
	if (ChequeaComm = true) then begin
    with mtblPedidos do begin
      first;
      while not eof do begin
        //OUT 000000000642004 TSN00 06ALB TGO FAL TBILTP  LDH
        if FieldByName('Pedir').AsBoolean then begin
          sBoleta := fieldbyname('Boleta').AsString;
          cantidad := fieldbyname('CantTest').AsInteger;
          s := Format('%15s',[sboleta]) + 'TSN00' + Format('%.2d',[cantidad]) + fieldbyname('Tests').AsString;
          s1 := Format('%10s',[sboleta]) + ' ' + fieldbyname('Tests').AsString;
          ActualizaLogFecha('Envío => '+ s1);
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
          if (ChkSalir.Checked) then begin
            ActualizaLogFecha('Proceso cancelado por el usuario.');
            Break;
          end;
        end;
        Next;
      end;
      ActualizaLogFecha('Envío finalizado');
    end;
  end;
end;

procedure TfrmProcesaCB350.btnMandaListaClick(Sender: TObject);
begin
  EnviaPedidos;
end;

function TfrmProcesaCB350.CodError(Cod:integer): string;
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

procedure TfrmProcesaCB350.limpiamemos;
begin
  memolista.lines.clear;
  memo1.lines.clear;
  mtblPedidos.EmptyTable;
end;

procedure TfrmProcesaCB350.btnSeleccionaClick(Sender: TObject);
var
  adic: string;
begin
  limpiamemos;
  if trim(edtAdicional.Text)<> '' then begin
    adic := trim(edtAdicional.Text) + '-';
  end
  else begin
    adic := '';
  end;
  OpenDialog1.FileName := ExtractFilePath(ParamStr(0)) +'Interfaces\CB350\Pedidos\*.ANA';
  OpenDialog1.InitialDir := ExtractFilePath(ParamStr(0)) +'Interfaces\CB350\Pedidos\';
  if OpenDialog1.Execute then begin
    ProcesaPedidos(OpenDialog1.FileName, adic);
  end;
end;

procedure TfrmProcesaCB350.ProcesaPedidos(sFile, adic: string);
var
  i,j: integer;
  cantidad: integer;
  s, s1, cod: string;
begin

  if fileexists(sFile) then begin
    Memo1.Visible := false;
    grdPedidos.Visible := true;
    memo1.lines.LoadFromFile(sFile);
    for i := 0 to Memo1.Lines.count-1 do begin
      s1 := Memo1.Lines[i];
      mtblPedidos.insert;
      mtblPedidos.FieldByName('Boleta').asString := adic + TRIM(extractword(1, s1,['!']));
      mtblPedidos.FieldByName('CantTest').AsInteger := strtointdef(TRIM(extractword(2, s1,['!'])),0);
      cantidad := StrToIntDef(TRIM(extractword(2, s1,['!'])),0);
      s := '';
      for j := 1 to cantidad do begin
        cod := copy(extractword(2+j,s1,['!'])+'    ',1,4); // completa a 4 caracteres
        s := s + cod;
      end;
      mtblPedidos.FieldByName('Tests').asString := s;
      mtblPedidos.FieldByName('Pedir').AsBoolean := true;
      mtblPedidos.FieldByName('Tipo').asString := 'T';
      mtblPedidos.FieldByName('Material').asString := 'S';
      mtblPedidos.FieldByName('EsClon').asString := 'N';
      mtblPedidos.FieldByName('Posicion').asString := '00';
      mtblPedidos.Post;
    end;
    mtblPedidos.SortOnFields('Boleta');
    mtblPedidos.First;
    btnMandaLista.Enabled := true;
  end
  else begin
    memolista.lines.add('No se puede acceder al archivo ' + sFile);
  end;
end;

procedure TfrmProcesaCB350.grdPedidosTitleButtonClick(Sender: TObject;
  AFieldName: String);
begin
  if AFieldName = 'Pedir' then begin
    SwitchPedido;
  end;
end;


procedure TfrmProcesaCB350.SwitchPedido;
var
  Pedido: boolean;
begin
  // desde set 2014 PONE TODO EN NO O TODO EN SI !
  with mtblPedidos do begin
    First;
    Pedido := not(fieldByName('Pedir').asBoolean); // toma el estado de la primera linea y lo INVIERTE
    DisableControls;
    while not Eof do begin
      edit;
      fieldByName('Pedir').asBoolean := Pedido;
      post;
      Next;
    end;
    First;
    EnableControls;
  end;    // with
end;

procedure TfrmProcesaCB350.edtAdicionalChange(Sender: TObject);
var
  s1: string;
begin
  mtblPedidos.First;
  while not mtblPedidos.eof do begin
    mtblPedidos.edit;
    s1 := mtblPedidos.FieldByName('Boleta').asString;
    if Trim(edtAdicional.Text) <>'' then begin
      if pos('-',s1) > 0 then begin
        mtblPedidos.FieldByName('Boleta').asString := edtAdicional.Text + '-' + extractword(2, s1,['-']);
      end
      else begin
        mtblPedidos.FieldByName('Boleta').asString := edtAdicional.Text + '-' + s1;
      end;
    end
    else begin
      mtblPedidos.FieldByName('Boleta').asString := extractword(2, s1,['-']);
    end;
    mtblPedidos.post;
    mtblPedidos.next;
  end;
  mtblPedidos.First;
end;

procedure TfrmProcesaCB350.Timer1Timer(Sender: TObject);
begin
  if ChkAuto.Checked then begin
    if FormShowed then begin
      Timer1.Enabled := false;
      ProcesaAuto;
    end;
  end
  else begin
    Timer1.Enabled := false;
  end;
end;

end.
