unit uInterfaz_Std;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  dateutils, Dialogs, StdCtrls, OoMisc, ADTrmEmu, AdPacket, AdPort, Mask, wwdbedit,
  Wwdotdot, Wwdbcomb, ExtCtrls, AdStatLt, JvExStdCtrls, JvEdit,StrUtils,
  inifiles, JvJCLUtils, JvValidateEdit, DB, JvMemoryDataset, Grids, Wwdbigrd, Wwdbgrid,
  UnitComp_LogToFile;

type
  TFrmInterfaz_Std = class(TForm)
    panel2: TPanel;
    AdTerminal1: TAdTerminal;
    SerialPort: TApdComPort;
    Paquete1: TApdDataPacket;
    memResult: TMemo;
    log_Std: TLogToFile;
    GroupBox1: TGroupBox;
    Label2: TLabel;
    Label1: TLabel;
    memProceso: TMemo;
    pruebas: TButton;
    edtCom: TEdit;
    lblInicio: TLabel;
    lblFin: TLabel;
    procedure Paquete1StringPacket(Sender: TObject; Data: String);
    procedure FormShow(Sender: TObject);
    procedure Paquete1Timeout(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure edtComChange(Sender: TObject);
    procedure pruebasClick(Sender: TObject);
  private
    procedure Procesa;
    procedure LeeConf;
    function AjustaCaracteres(s: string): String;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmInterfaz_Std: TFrmInterfaz_Std;

implementation

{$R *.dfm}

var
  s: string;
  sPath: string;

procedure TFrmInterfaz_Std.Procesa;
begin
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


procedure TFrmInterfaz_Std.Paquete1StringPacket(Sender: TObject; Data: String);
begin
  if length(Data) > 0 then begin
    memResult.Lines.add('=> ' + Data);
    log_Std.LogFileName := sPath + 'result' + FormatDateTime('ddmmyyyyhhnnss',now) + '.out';
    log_Std.WriteToLogFile(AnsiReplaceStr(Data,#13,'|'));
    log_Std.OverwriteExistingFile := false; // para poder hacer overwrite del archivo !!
  end;

end;

procedure TFrmInterfaz_Std.FormShow(Sender: TObject);
begin
  LeeConf;
  log_Std.OverwriteExistingFile := true;
  sPath := ExtractFilePath(ParamStr(0));
  if not DirectoryExists(sPath) then begin
    CreateDir(sPath);
  end;
  sPath := ExtractFilePath(ParamStr(0)) + 'Resultados\';
  if not DirectoryExists(sPath) then begin
    CreateDir(sPath);
  end;
  memProceso.Lines.add('Archivo de salida = ' + log_Std.LogFileName);
  Paquete1.TimeOut := 1000; // aprox 60 segundos
  Procesa;
end;

procedure TFrmInterfaz_Std.Paquete1Timeout(Sender: TObject);
begin
  memProceso.Lines.add('Tiempo de espera del paquete - 1000 ticks / 60 segundos - superado');
  SerialPort.Open := false;
end;

procedure TFrmInterfaz_Std.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SerialPort.Open := false;
end;

procedure TFrmInterfaz_Std.edtComChange(Sender: TObject);
begin
  SerialPort.ComNumber := strtointdef(edtCom.text,1);
  SerialPort.Open := false;
  SerialPort.Open := true;
  Procesa;
end;

procedure TFrmInterfaz_Std.LeeConf;
var
  IniFile: tInifile;
  sFile: string;
begin
  sFile := ExtractFilePath(ParamStr(0)) + 'Comm_Std.ini';
	IniFile := TIniFile.Create(sFile);
  try
    edtcom.Text := inttostr(IniFile.ReadInteger('Generales','port',1));
    Paquete1.StartString := AjustaCaracteres(IniFile.ReadString('Generales','IniStr','?'));
    Paquete1.EndString := AjustaCaracteres(IniFile.ReadString('Generales','finstr','?'));
    lblInicio.Caption := 'Inicio: ' + IniFile.ReadString('Generales','IniStr','?');
    lblFin.Caption :=    'Fin   : ' + IniFile.ReadString('Generales','FinStr','?')

  finally
    IniFile.Free;
  end;
end;

function TFrmInterfaz_Std.AjustaCaracteres(s: string):String;
var
  iValor: integer;
  sver: string;
begin
  result := s;
  if (length(s) >1) and  (pos('#',s) = 1) then begin
    //#10#13
    iValor := StrToInt(ExtractWord(1,s,['#']));
    if (iValor >0) and (iValor < 256) then begin
      result := chr(iValor);
    end;
    if ExtractWord(2,s,['#']) <> '' then begin
      iValor := StrToInt(ExtractWord(2,s,['#']));
      if (iValor >0) and (iValor < 256) then begin
        result := result + chr(iValor);
      end;
    end;
  end;
end;

procedure TFrmInterfaz_Std.pruebasClick(Sender: TObject);
begin
  memResult.Lines.LoadFromFile('iono.out');
  memProceso.Lines.add(AnsiReplaceStr(memResult.Text,#13+#10,'|')+ #13+#10);
  log_Std.WriteToLogFile(AnsiReplaceStr(memResult.Text,#13+#10,'|')+ #13+#10);
end;

end.
