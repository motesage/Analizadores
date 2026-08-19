unit uInterfazIono_Diestro;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, OoMisc, ADTrmEmu, AdPacket, AdPort, Mask, wwdbedit,
  Wwdotdot, Wwdbcomb, ExtCtrls, AdStatLt, JvExStdCtrls, JvEdit,StrUtils,
  inifiles, JvJCLUtils, JvValidateEdit, DB, JvMemoryDataset, Grids, Wwdbigrd, Wwdbgrid,
  UnitComp_LogToFile;

type
  TfrmIono_Diestro = class(TForm)
    panel2: TPanel;
    AdTerminal1: TAdTerminal;
    SerialPort: TApdComPort;
    Paquete1: TApdDataPacket;
    memResult: TMemo;
    logIono_Diestro: TLogToFile;
    GroupBox1: TGroupBox;
    Label2: TLabel;
    Label1: TLabel;
    memProceso: TMemo;
    pruebas: TButton;
    edtCom: TEdit;
    procedure Paquete1StringPacket(Sender: TObject; Data: String);
    procedure FormShow(Sender: TObject);
    procedure Paquete1Timeout(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure edtComChange(Sender: TObject);
    procedure pruebasClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    procedure Procesa;
    procedure LeeConf;
    function AjustaCaracteres(s: string): String;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmIono_Diestro: TfrmIono_Diestro;

implementation

{$R *.dfm}

var
  s: string;

procedure TfrmIono_Diestro.Procesa;
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

{
la pinta del archivo que se genera con estos triggers es (*.OUT)

252167

Na=140.2mmol
K = 4.27mmol
Cl=101.2mmol

-------------------

251950o
Orina
NaO= 69.0mmol
K O= 11.10mmolv
ClO= 29.0mmolv

}

procedure TfrmIono_Diestro.Paquete1StringPacket(Sender: TObject; Data: String);
begin

  if length(Data) > 0 then begin
    memResult.Lines.add('=> ' + Data);
    logIono_Diestro.WriteToLogFile(AnsiReplaceStr(Data,#13,'|'));
    logIono_Diestro.OverwriteExistingFile := false; // para poder hacer overwrite del archivo !!
  end;

end;

procedure TfrmIono_Diestro.FormShow(Sender: TObject);
var
  sPath: string;
begin
  LeeConf;
  logIono_Diestro.OverwriteExistingFile := true;
  sPath := ExtractFilePath(ParamStr(0)) + 'Interfaces\Iono\';
  if not DirectoryExists(sPath) then begin
    CreateDir(sPath);
  end;
  sPath := ExtractFilePath(ParamStr(0)) + 'Interfaces\Iono\Resultados\';
  if not DirectoryExists(sPath) then begin
    CreateDir(sPath);
  end;
  logIono_Diestro.LogFileName := sPath + 'Iono.out';
  memProceso.Lines.add('Archivo de salida = ' + logIono_Diestro.LogFileName);
  Paquete1.TimeOut := 1000; // aprox 60 segundos
  Procesa;
end;

procedure TfrmIono_Diestro.Paquete1Timeout(Sender: TObject);
begin
  memProceso.Lines.add('Tiempo de espera del paquete - 1000 ticks / 60 segundos - superado');
  SerialPort.Open := false;
end;

procedure TfrmIono_Diestro.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // 2023: que no se pueda cerrar.
  // SerialPort.Open := false;
end;

procedure TfrmIono_Diestro.edtComChange(Sender: TObject);
begin
  SerialPort.ComNumber := strtointdef(edtCom.text,1);
  SerialPort.Open := false;
  SerialPort.Open := true;
  Procesa;
end;

procedure TfrmIono_Diestro.LeeConf;
var
  IniFile: tInifile;
  sFile: string;
begin
  sFile := ExtractFilePath(ParamStr(0)) + 'CommDiestro.ini';
	IniFile := TIniFile.Create(sFile);
  try
    edtcom.Text := inttostr(IniFile.ReadInteger('Generales','port',1));
    Paquete1.StartString := AjustaCaracteres(IniFile.ReadString('Generales','IniStr','Paciente:'));
    Paquete1.EndString := AjustaCaracteres(IniFile.ReadString('Generales','finstr','========================'));
  finally
    IniFile.Free;
  end;
end;

function TfrmIono_Diestro.AjustaCaracteres(s: string):String;
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
//        sver := result;
//        showmessage(sver);
      end;
    end;
  end;
end;

procedure TfrmIono_Diestro.pruebasClick(Sender: TObject);
begin
  memResult.Lines.LoadFromFile('iono.out');
  memProceso.Lines.add(AnsiReplaceStr(memResult.Text,#13+#10,'|')+ #13+#10);
  logIono_Diestro.WriteToLogFile(AnsiReplaceStr(memResult.Text,#13+#10,'|')+ #13+#10);
end;

procedure TfrmIono_Diestro.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose := false; // que no se pueda cerrar.
end;

end.
