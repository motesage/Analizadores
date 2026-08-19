unit uInterfazCelldyn;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, OoMisc, ADTrmEmu, AdPacket, AdPort, Mask, wwdbedit,
  Wwdotdot, inifiles, Wwdbcomb, ExtCtrls, AdStatLt, JvExStdCtrls, JvEdit,
  JvJCLUtils, JvValidateEdit, DB, JvMemoryDataset, Grids, Wwdbigrd, Wwdbgrid,
  UnitComp_LogToFile;

type
  TfrmCelldyn = class(TForm)
    panel2: TPanel;
    AdTerminal1: TAdTerminal;
    SerialPort: TApdComPort;
    Paquete1: TApdDataPacket;
    Timer1: TTimer;
    memResult: TMemo;
    logCelldyn: TLogToFile;
    GroupBox1: TGroupBox;
    Label2: TLabel;
    Label1: TLabel;
    memProceso: TMemo;
    edtCom: TLabel;
    Label3: TLabel;
    procedure Paquete1StringPacket(Sender: TObject; Data: String);
    procedure FormShow(Sender: TObject);
    procedure Paquete1Timeout(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnProcesaClick(Sender: TObject);
  private
    procedure Procesa;
    procedure LeeConf;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmCelldyn: TfrmCelldyn;

implementation

{$R *.dfm}


procedure TfrmCelldyn.Procesa;
begin
  memResult.Lines.Clear;
  try
    SerialPort.ComNumber := strtointdef(edtCom.Caption,1);
    SerialPort.Open := true;
    memProceso.Lines.add('Com' + edtCom.Caption + ' abierto OK');
    memProceso.Lines.add('Inicio de recepción de resultados');
  except
    memProceso.Lines.add('Error abriendo Com');
  end;
end;

procedure TfrmCelldyn.Paquete1StringPacket(Sender: TObject; Data: String);
begin
  memResult.Lines.add(Data);
  if Length(Data) > 2 then begin
    logCelldyn.WriteToLogFile(Data);
  end;
end;

procedure TfrmCelldyn.FormShow(Sender: TObject);
begin
  LeeConf;
  logCelldyn.LogFileName := ExtractFilePath(ParamStr(0)) +'Interfaces\Celldyn\Resultados\Celldyn.txt';
  //  Timer1.Interval := edtTimeout.Value * 1000;  // segundos
  Paquete1.TimeOut := 100; // aprox 6 segundos
  Procesa;
end;


procedure TfrmCelldyn.LeeConf;
var
  IniFile: tInifile;
  sFile: string;
begin
  sFile := ExtractFilePath(ParamStr(0)) + 'CommCelldyn.ini';
	IniFile := TIniFile.Create(sFile);
  try
    edtcom.Caption := inttostr(IniFile.ReadInteger('Generales','port',1));
  finally
    IniFile.Free;
  end;
end;



procedure TfrmCelldyn.Paquete1Timeout(Sender: TObject);
begin
  memProceso.Lines.add('Tiempo de espera del paquete - 100 ticks / 6 segundos - superado');
  SerialPort.Open := false;
end;

procedure TfrmCelldyn.Timer1Timer(Sender: TObject);
begin
  memProceso.Lines.add('Tiempo de espera global superado');
//  Timer1.Enabled := false;
  SerialPort.Open := false;
end;

procedure TfrmCelldyn.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SerialPort.Open := false;
end;

procedure TfrmCelldyn.btnProcesaClick(Sender: TObject);
begin
  procesa;
end;

end.
