unit uInterfaz;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, OoMisc, ADTrmEmu, AdPacket, AdPort, Mask, wwdbedit,
  Wwdotdot, Wwdbcomb, ExtCtrls, AdStatLt, JvExStdCtrls, JvEdit,
  JvJCLUtils, JvValidateEdit, DB, JvMemoryDataset, Grids, Wwdbigrd, Wwdbgrid,
  UnitComp_LogToFile;

type
  TfrmAU480 = class(TForm)
    mtblPedidos: TJvMemoryData;
    dsPedidos: TDataSource;
    mtblPedidosBoleta: TIntegerField;
    mtblPedidosMuestra: TStringField;
    mtblPedidosPaciente: TStringField;
    mtblPedidosTests: TStringField;
    mtblPedidosEstado: TBooleanField;
    Panel1: TPanel;
    wwDBGrid1: TwwDBGrid;
    panel2: TPanel;
    Label2: TLabel;
    AdTerminal1: TAdTerminal;
    memProceso: TMemo;
    edtCom: TwwDBComboBox;
    memPedidos: TMemo;
    SerialPort: TApdComPort;
    Paquete1: TApdDataPacket;
    Timer1: TTimer;
    memResult: TMemo;
    logAU480: TLogToFile;
    lblsueros: TLabel;
    lblorinas: TLabel;
    mtblPedidosEmpresa: TStringField;
    procedure Paquete1StringPacket(Sender: TObject; Data: String);
    procedure FormShow(Sender: TObject);
    procedure Paquete1Timeout(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure btnLeeListaClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure edtComChange(Sender: TObject);
    procedure btnProcesaClick(Sender: TObject);
  private
    procedure LlenaComboCOMMs;
    procedure ProcesaPedido(muestra: string);
    function CheckCom(AComNumber: Integer): Integer;
    function ExtComName(ComNr: DWORD): string;
    procedure LeePedidos;
    procedure Procesa;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmAU480: TfrmAU480;

implementation

{$R *.dfm}


procedure TfrmAU480.Procesa;
begin
  memProceso.Lines.Clear;
  memResult.Lines.Clear;
  try
    SerialPort.ComNumber := strtointdef(edtCom.text,1);
    SerialPort.Open := true;
    memProceso.Lines.add('Com' + edtCom.text + ' abierto OK');
    memProceso.Lines.add('Inicio de recepción de resultados');
  except
    memProceso.Lines.add('Error abriendo Com');
  end;
end;

procedure TfrmAU480.Paquete1StringPacket(Sender: TObject; Data: String);
begin
  if Copy(Data,1,2) = 'R ' then begin
    memProceso.Lines.add(Data);
    if Length(Data) > 6 then begin
      ProcesaPedido(Copy(Data,4,4)) // extraigo el numero de muestra
    end;
  end
  else begin
    memResult.Lines.add(Data);
    if Length(Data) > 2 then begin
      logAU480.WriteToLogFile(Data);
    end;
  end;

  //  Timer1.Enabled := false;
//  Timer1.Enabled := true; // lo reseteo
end;

procedure TfrmAU480.FormShow(Sender: TObject);
begin
  LlenaComboCOMMs;
  logAU480.LogFileName := '\au480\RESAU480.txt';  // solo los del dia. debe borrarlo el programa que los lee !!

  //  Timer1.Interval := edtTimeout.Value * 1000;  // segundos
  Paquete1.TimeOut := 100; // aprox 6 segundos
  LeePedidos;
  Procesa;
end;

procedure TfrmAU480.LlenaComboCOMMs;
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

function TfrmAU480.CheckCom(AComNumber: Integer): Integer;
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

function TfrmAU480.ExtComName(ComNr: DWORD): string;
begin
  if ComNr > 9 then
    Result := Format('.COM%d', [ComNr])
  else
    Result := Format('COM%d', [ComNr]);
end;

procedure TfrmAU480.Paquete1Timeout(Sender: TObject);
begin
  memProceso.Lines.add('Tiempo de espera del paquete - 100 ticks / 6 segundos - superado');
  SerialPort.Open := false;
end;

procedure TfrmAU480.Timer1Timer(Sender: TObject);
begin
  memProceso.Lines.add('Tiempo de espera global superado');
//  Timer1.Enabled := false;
  SerialPort.Open := false;
end;

procedure TfrmAU480.ProcesaPedido(muestra: string);
var
  scmd: string;
  boleta: Integer;
  sBole, empresa, pedidos, material: string;
begin
  boleta := 0;
  empresa := '';
  pedidos := '';
  material := '';
  scmd := '';
  with mtblPedidos do begin
    First;
    while not Eof do begin
      if FieldByName('estado').AsBoolean = False then begin
        boleta := FieldByName('boleta').AsInteger;
        empresa := trim(FieldByName('empresa').AsString);
        material := FieldByName('muestra').AsString;
        pedidos := FieldByName('tests').AsString;
        Edit;
        FieldByName('estado').AsBoolean := True;
        Post;
        Break;
      end;
    Next;
    end;
  end;

  //ok (sin empresa)
  //R  0036
  //S  0036164630        E008010015012003004001019098097006005002

  // ver con empresa !
  //R  0036
  //L_S  00361    E001

  if boleta > 0 then begin
    scmd := 'S '; // pedido
    if Trim(material) = '' then begin
      scmd := scmd + ' '; // sample type SUERO
    end
    else begin
      scmd := scmd + 'U'; // sample type URINE
    end;
    scmd := scmd + muestra; // sample no

    // agrega "Empresa_"
    if empresa <>'' then begin
      sBole := empresa + '+' + inttostr(boleta);
    end
    else begin
      sBole := inttostr(boleta);
    end;

    if Trim(material) = '' then begin
      scmd := scmd + Copy(sBole + '          ',1,10); // + muestra; // sample id LARGO 10 !!!
    end
    else begin
      // pongo el material como parte del nro de boleta
      scmd := scmd + Copy(sBole +  '-' + material + '          ',1,10); // + muestra; // sample id LARGO 10 !!!
    end;

    scmd := scmd + '    '; // dummy
    scmd := scmd + 'E'; // DATA CLASSIF
    scmd := scmd + pedidos; //'004'; // ALP
    SerialPort.PutString(#2 + scmd + #3);
    memProceso.Lines.add(scmd);
  end;
end;

procedure TfrmAU480.btnLeeListaClick(Sender: TObject);
begin
  LeePedidos;
end;

procedure TfrmAU480.LeePedidos;
var
  i: integer;
  sueros,orinas: Integer;
  s, sBol, sEmp: string;
begin
  sueros := 0;
  orinas := 0;
  try
    // NUEVO 2018 EMPRESA _ BOLETA - MATERIAL  E_BBBBB-M
    {
    L_107;A;SARMIENTO MELODY    ;018
    L_108; ;NOGUERA ESPINOZA CRI;001002003004005006008010012020027
    L_109; ;TORTORELLI SOFIA    ;001002003004005006008010012020027
    L_110; ;VAZQUEZ RAMONA      ;001
    L_111; ;FERNANDEZ CHAVEZ NAH;001002003004005006008010011012013026027097098099
    }

    if fileexists('\au480\AU480.req') then begin
      memPedidos.Lines.LoadFromFile('\au480\AU480.req');
    end
    else if fileexists('\au480\AU480_AU480.req') then begin
      memPedidos.Lines.LoadFromFile('\au480\AU480_AU480.req');
    end
    else begin
      ShowMessage('No encuentro el archivo con los pedidos' + #10+#13 + 'Chequee el nombre, debe ser AU480.req o AU480_AU480.Procese desde el LAB');
    end;
    mtblPedidos.EmptyTable;
    for i := 0 to memPedidos.Lines.Count - 1 do begin
      s := memPedidos.lines[i];
      if ExtractWord(1,s,[';']) <> '' then begin
        mtblPedidos.Insert;
        mtblPedidos.FieldByName('Estado').AsBoolean := false;
        sBol := ExtractWord(1,s,[';']);
        if pos('+',sBol) > 0 then begin
          sEmp := ExtractWord(1,sBol,['+']);
          sBol := ExtractWord(2,sBol,['+']);
        end
        else begin
          sEmp := '';
        end;
        mtblPedidos.FieldByName('Boleta').AsInteger := strtointDef(sBol,0);
        mtblPedidos.FieldByName('Empresa').AsString := sEmp;
        mtblPedidos.FieldByName('Muestra').AsString := ExtractWord(2,s,[';']);
        if (Trim(mtblPedidos.FieldByName('Muestra').AsString) = '') then begin
          inc(sueros);
        end
        else begin
          Inc(orinas);
        end;
        mtblPedidos.FieldByName('Paciente').AsString := ExtractWord(3,s,[';']);
        mtblPedidos.FieldByName('Tests').AsString := ExtractWord(4,s,[';']);
        mtblPedidos.Post;
      end;
    end;
    mtblPedidos.SortOnFields('Muestra;Empresa;Boleta');
    mtblPedidos.First;
    lblsueros.Caption := inttostr(sueros) + ' Sueros';
    lblorinas.Caption := inttostr(orinas) + ' Orinas';
  except
    ShowMessage('No encuentro el archivo AU480.Req con los pedidos' + #10+#13 + 'Procese desde el LAB');
  end;
end;


procedure TfrmAU480.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SerialPort.Open := false;
end;

procedure TfrmAU480.edtComChange(Sender: TObject);
begin
  SerialPort.ComNumber := strtointdef(edtCom.text,1);
  SerialPort.Open := false;
  SerialPort.Open := true;
end;

procedure TfrmAU480.btnProcesaClick(Sender: TObject);
begin
  procesa;
end;

end.
