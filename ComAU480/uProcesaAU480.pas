unit uProcesaAU480;

{
recibir resultados
DB	INICIO
(1)	D_
	System_num  	00
	rack_num    	54
	cup_posit   	01
	sample_Type 	U   (orina)
	sample_Number 	0001
	sample_ID   	'___89542-O'   (nro boleta)
	dummy       	'____'
	data_class_nro  E
	sexo            0    (sin sexo)
	Patient_data    77 blancos o algo asi...
	test_number     003  (crea)
	diluyente       0    (normal)
	resultado       033.2
	flag            __

	itera (1)
DE ETX CRC      (EL CRC SE PUEDE IGNORAR SI SE CONFIGURA EL EQUIPO PARA NO USARLO)

mandar pedidos

S_
	rack_num    	00
	cup_posit   	00
	sample_Type 	U   (orina)  o _ Suero
	sample_Number 0001
	sample_ID   	'___89542-O'   (nro boleta)
	dummy       	'____'
	data_class_nro  E
	sexo            0    (sin sexo)
	Patient_data    77 blancos o algo asi...
(1)
	test_number     003  (crea)
	diluyente       0    (normal)
	itera (1)

SE ETX CRC   (EL CRC SE PUEDE IGNORAR SI SE CONFIGURA EL EQUIPO PARA NO USARLO)

---- ejemplos ----------

DB
D 005401U0001   89542-O    E0                                                                            0030033.2  
D 005402U0002   89564-O    E0                                                                            0030052.7  
D 005403U0003  148448-B    E0                                                                            0180004.4  
D 005404U0004  148449-B    E0                                                                            0170024.9  0180003.1  
D 005405U0005  148450-B    E0                                                                            0160005.2  0170047.7  0180005.3  
DE
DB
D 001101 0001     37866    E0                                                                            004000519n 005000024n 006000028n 008000.24n 010000.75n 0200003.6  
D 001102 0002     37869    E0                                                                            008000.47n 010002.05n 012000120  0270037.6  0970140.8  098003.44  099000103  
D 001103 0003     37870    E0                                                                            008000.18n 010000.81n 0270039.7
D 001104 0004     37872    E0                                                                            008000.24n 010000.82n 0200002.4  0970130.4  098003.95  099000092  
D 001105 0005     37874    E0                                                                            0110003.6  012000205  013006.67  0200006.6  0270048.6  
DE


003 crea  33.2
003 52.7
018 CAL  4.4
017 FOSF 24.9

016 MAG 5.02
017 FOSF 47.7
018 CALCIO 5.3

004 alp  fosf res 519
005 alt  tgp       24
006 ast  tgo       28

011 alb  3.6
012 col  205
013 pr tot 6.67
020 ac ur  6.6
027 col hdsl 48.6

}




interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
	udmComm480, Dialogs, StdCtrls, Grids, Wwdbigrd, Wwdbgrid, Mask, wwdbedit,
  strUtils, Wwdotdot, Wwdbcomb, Db, RxMemDS, Menus, ComCtrls,
  JvJCLUtils,  OoMisc, AdPort, Buttons, ExtCtrls, RxGIF, jpeg,
  UnitComp_LogToFile, JvMemoryDataset;

type

	TfrmProcesaAU480 = class(TForm)
    GroupBox2: TGroupBox;
    Label2: TLabel;
    Label4: TLabel;
    Panel1: TPanel;
    GroupBox3: TGroupBox;
    GroupBox1: TGroupBox;
    PopupMenu1: TPopupMenu;
    Salir1: TMenuItem;
    edtCom: TwwDBComboBox;
    edtVelocidad: TwwDBComboBox;
    memolista: TMemo;
    Memo1: TMemo;
    chkSalir: TCheckBox;
    log: TLogToFile;
    OpenDialog1: TOpenDialog;
    GroupBox4: TGroupBox;
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
    Label5: TLabel;
    edtSegs: TEdit;
    Label7: TLabel;
    edtcomando: TEdit;
    edtespera: TEdit;
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
	private
		function ChequeaComm: boolean;
    function CheckCom(AComNumber: Integer): Integer;
    function ExtComName(ComNr: DWORD): string;
    procedure LlenaComboCOMMs;
    procedure ActualizaLogFecha(S: string);
    procedure Actualizalog(S: string);
    function CodError(Cod: integer): string;
    procedure limpiamemos;
    procedure SwitchPedido;
	public
		{ Public declarations }
	end;

var
	frmProcesaAU480: TfrmProcesaAU480;

implementation

{$R *.DFM}

var
	CommAbierto: boolean = false;

function TfrmProcesaAU480.ChequeaComm: boolean;
begin
	result := true;
	if not(commAbierto) then begin
		dmComm480.CloseCom; // primero la cierro (no da error si estaba cerrada)
		Application.ProcessMessages;
		if not dmComm480.OpenCom(strtointdef(edtCom.text,1),strtointdef(edtVelocidad.text,9600)) then begin
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

procedure TfrmProcesaAU480.ActualizaLogFecha(S: string);
begin
  memolista.Lines.add(s);
end;

procedure TfrmProcesaAU480.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	frmProcesaAU480 := nil;
	action := cafree;
end;

procedure TfrmProcesaAU480.edtVelocidadChange(Sender: TObject);
begin
	commAbierto := false;
end;

procedure TfrmProcesaAU480.Salir1Click(Sender: TObject);
begin
  chkSalir.Checked := true;
  close;
end;

procedure TfrmProcesaAU480.FormShow(Sender: TObject);
var
	sFecha: string;
begin
//  btnMandaLista.Enabled := false;
  llenacombocomms;
  sFecha := FormatDateTime('yyyymmdd',date);
  log1.LogFileName := 'RESAU480_' + sFecha + '.txt';  // por fecha .....
  log.LogFileName := 'RESAU480.txt';  // solo los del dia. debe borrarlo el programa que los lee !!
end;

procedure TfrmProcesaAU480.Actualizalog(S: string);
begin
	memo1.lines.add(s);
end;

procedure TfrmProcesaAU480.btnLeerClick(Sender: TObject);
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
        lectura := dmComm480.Procesa('',strtointdef(edtSegs.Text,1)); // siguiente
        if (lectura.Status = stOk) then begin
          // terminó la comunicacion
          ActualizaLogFecha(Lectura.Data);
      	  log.WriteToLogFile(Lectura.Data);
      	  log1.WriteToLogFile(Lectura.Data);
          Continua := False;
        end
        else if (lectura.Status = stInProc) then begin
          // manda un paquete
          ActualizaLogFecha(Lectura.Data);
      	  log.WriteToLogFile(Lectura.Data);
      	  log1.WriteToLogFile(Lectura.Data);
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
          Continua := false; // sale !
        end;
        Application.ProcessMessages;
        if chkSalir.Checked then close;
      end;    // while
    end;
	end
	else begin
		ActualizaLogFecha('No se pudo inicializar la comunicación');
	end;
end;

function TfrmProcesaAU480.ExtComName(ComNr: DWORD): string;
begin
  if ComNr > 9 then
    Result := Format('.COM%d', [ComNr])
  else
    Result := Format('COM%d', [ComNr]);
end;

function TfrmProcesaAU480.CheckCom(AComNumber: Integer): Integer;
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

procedure TfrmProcesaAU480.LlenaComboCOMMs;
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

procedure TfrmProcesaAU480.btnMandaListaClick(Sender: TObject);
var
  i,j: integer;
  sBoleta: string;
  cantidad: integer;
  s, s1: string;
  resultado: tBuffDatos;
	TimeNow,TimeOut: TDateTime;
begin
  TimeOut := strtointdef(edtSegs.Text,1) * 1000 * mSecsFrac;
	TimeNow := Now;

  edtespera.text := 'Esperando';
  while ((Now - TimeNow) < TimeOut) do begin
    // espero para que se presione el boton en el equipo
  end;
  edtespera.text := 'Procesando';


	if (ChequeaComm = true) then begin
    resultado := dmComm480.Procesa(edtcomando.text,strtointdef(edtSegs.Text,1));
    if resultado.Status = stOK then begin
      ActualizaLogFecha('Proceso ok. ' + #13#10 + resultado.Data);
      resultado := dmComm480.Procesa('SE',strtointdef(edtSegs.Text,1));
    end
    else begin
      ActualizaLogFecha('error ' + #13#10 + resultado.Data);
    end;
//    with mtblPedidos do begin
//      first;
//      while not eof do begin
//        //OUT 000000000642004 TSN00 06ALB TGO FAL TBILTP  LDH
//        if FieldByName('Pedir').AsBoolean then begin
//          sBoleta := fieldbyname('Boleta').AsString;
//          cantidad := fieldbyname('CantTest').AsInteger;
//          s := Format('%15s',[sboleta]) + 'TSN00' + Format('%.2d',[cantidad]) + fieldbyname('Tests').AsString;
//          s1 := Format('%10s',[sboleta]) + ' ' + fieldbyname('Tests').AsString;
//          ActualizaLogFecha('Envío => '+ s1);
//          resultado := dmComm480.Procesa(strtointdef(edtSegs.Text,1));
//          if length(resultado.Data) = 2 then begin
//            // respuesta a un pasaje de lista de pedidos
//            // Y[bandeja] o N[coderror]
//            if resultado.Data[1] = 'Y' then begin
//              ActualizaLogFecha('Insertado en bandeja ' + Format('%.3d',[ord(resultado.Data[2])]));
//            end
//            else if resultado.Data[1] = 'N' then begin
//              ActualizaLogFecha('Error ' + CodError(ord(resultado.Data[2])));
//            end
//            else begin
//              ActualizaLogFecha('Error en tamaño de respuesta');
//            end;
//          end
//          else begin
//            ActualizaLogFecha('Error en envio del pedido...');
//          end;
//          Application.ProcessMessages;
//          if (ChkSalir.Checked) then begin
//            ActualizaLogFecha('Proceso cancelado por el usuario.');
//            Break;
//          end;
//        end;
//        Next;
//      end;
//      ActualizaLogFecha('Envío finalizado');
//    end;
  end;
end;


function TfrmProcesaAU480.CodError(Cod:integer): string;
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

procedure TfrmProcesaAU480.limpiamemos;
begin
  memolista.lines.clear;
  memo1.lines.clear;
  mtblPedidos.EmptyTable;
end;

procedure TfrmProcesaAU480.btnSeleccionaClick(Sender: TObject);
var
  i,j: integer;
  adic: string;
  cantidad: integer;
  s, s1, cod: string;
begin
  limpiamemos;
  if trim(edtAdicional.Text)<> '' then begin
    adic := trim(edtAdicional.Text) + '-';
  end
  else begin
    adic := '';
  end;
  OpenDialog1.FileName := '*.ANA';
  OpenDialog1.InitialDir := edtCarpetaRes.Text;
  if OpenDialog1.Execute then begin
    if fileexists(OpenDialog1.FileName) then begin
      Memo1.Visible := false;
      grdPedidos.Visible := true;
      memo1.lines.LoadFromFile(OpenDialog1.FileName);
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
      showmessage('No se puede acceder al archivo ' + OpenDialog1.FileName);
    end;
  end;

end;

procedure TfrmProcesaAU480.grdPedidosTitleButtonClick(Sender: TObject;
  AFieldName: String);
begin
  if AFieldName = 'Pedir' then begin
    SwitchPedido;
  end;
end;


procedure TfrmProcesaAU480.SwitchPedido;
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

procedure TfrmProcesaAU480.edtAdicionalChange(Sender: TObject);
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

end.
