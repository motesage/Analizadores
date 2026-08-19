unit uCommHL7_PT1000;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Menus, ExtCtrls,  udmParamsHL7, uHL7_PT1000, IniFiles, JvJclUtils,
  ScktComp, Sockets, JclFileUtils, UnitComp_LogToFile;

const
  wm_RefreshClients = wm_User;
	cIniFilename = 'CommHL7_PT1000.ini';	//archivo de inicializacion

type
  TfrmCommHL7_PT1000 = class(TForm)
    Panel1: TPanel;
    PopupMenu1: TPopupMenu;
    Guarda2: TMenuItem;
    Panel2: TPanel;
    memFiles: TMemo;
    memOutput: TMemo;
    Panel3: TPanel;
    Label1: TLabel;
    Splitter1: TSplitter;
    memMsgs: TMemo;
    Panel4: TPanel;
    memData: TMemo;
    logOUT: TLogToFile;
    LogData: TLogToFile;
    LogMensajes: TLogToFile;
    lblManuf: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    procedure ProcessIdle(Sender: TObject);
    procedure ProcessInput(const S: string);
    procedure LeeConf;
    function GeneraNewFileName(sFileName: string): string;
    procedure GrabaInput(InLines: tStringList);
    procedure ProcesaProcesados;
    procedure ProcessConnect(const S: string);
    procedure ProcessDisconnect(const S: string);
    procedure ProcessError(const S: string);
  public
    { Public declarations }
  end;

var
  frmCommHL7_PT1000: TfrmCommHL7_PT1000;
  HL7_PT1000: tHL7_PT1000;
  InputLines: tStringList;
  sManufacturer: string;
  sModel: string;

implementation

var
  PathResultados, PathPedidos: string;
  FileOut: string;
  port: integer;
  GeneraLog: boolean;

{$R *.dfm}

procedure TfrmCommHL7_PT1000.FormShow(Sender: TObject);
begin
  LeeConf;
  if not Assigned(HL7_PT1000) then begin
    HL7_PT1000 := tHL7_PT1000.Create(Self);
  end;
  HL7_PT1000.OnIdle := ProcessIdle;
  HL7_PT1000.OnInput := ProcessInput;
  HL7_PT1000.OnError := ProcessError;
  HL7_PT1000.OnMessage := ProcessConnect;
  HL7_PT1000.OnConnect := ProcessConnect;
  HL7_PT1000.OnDisconnect := ProcessDisconnect;
  HL7_PT1000.Port := port;
  HL7_PT1000.Manufacturer := sManufacturer;
  HL7_PT1000.Model := sModel;

  // verifica (y crea los directorios de intercambio)
  ExisteDirectorio(PathResultados,true); //IN
  ExisteDirectorio(PathPedidos,true);    //OUT

  FileOut := PathResultados+'\default.res';
  self.Caption := self.Caption + ' - Puerto: '+IntToStr(port);
  lblManuf.Caption := 'Manufacturer / Model = |' + sManufacturer + '|' + sModel + '|';
  ProcesaProcesados;
end;

procedure TfrmCommHL7_PT1000.FormCreate(Sender: TObject);
begin
  InputLines := TStringList.Create;
  PathPedidos := AppPath+'Pedidos';
  PathResultados := AppPath+'Resultados';

	logOUT.LogFileName := AppPath + 'HL7_PT1000_Output.log';
	logOUT.IncDateTime := true;
	logOUT.IncSeparator:= true;
	logOUT.Separator:= ' : ';

	LogData.LogFileName := AppPath + 'HL7_PT1000_Data.log';
	LogData.IncDateTime := true;
	LogData.IncSeparator:= true;
	LogData.Separator:= ' : ';

	LogMensajes.LogFileName := AppPath + 'HL7_PT1000_Mensajes.log';
	LogMensajes.IncDateTime := true;
	LogMensajes.IncSeparator:= true;
	LogMensajes.Separator:= ' : ';

end;

procedure TfrmCommHL7_PT1000.ProcessIdle(Sender: TObject);
var
  S: string;
begin
  if Assigned(InputLines) then begin
    InputLines.Clear;
    while HL7_PT1000.Count>0 do begin
      s := HL7_PT1000.Data;
      InputLines.Add(s);
      memData.Lines.Add(s);
      if GeneraLog then LogData.WriteToLogFile(s);
    end;    // while
    GrabaInput(InputLines);
  end;
end;

procedure TfrmCommHL7_PT1000.GrabaInput(InLines: tStringList);
begin
  // este es un resultado tipo
  //MSH|^~\&|Mindray|BS-400|||20190731141421||ORU^R01|1|P|2.3.1||||0||ASCII|||
  //PID|2||||321 ROSSI||19000101000000||||||||||||||||||||||||
  //OBR|2||9001|Mindray^BS-400|Y||20190731083552|||||||20190731082045|Suero|||||||||||||||||||||||||||||||||
  //OBX|1|NM|COLE-WB|COLE-WB|276.623882|mg/dL|-|N|||F||276.623882|20190731083552||||
  //OBX|2|NM|TG-W|TG-W|145.864836|mg/dL|-|N|||F||145.864836|20190731083552||||
  //OBX|3|NM|HDL-MONO-W|HDL-MONO-W|32.410670|mg/dL|-|N|||F||32.410670|20190731083552||||

  if InLines.Count>0 then begin
    // las que tienen resultados tienen al menos 3 lineas de largo !!
    // estaba grabando archivos como este:
    // MSH|^~\&|||||20190731130616||ACK^Q03|4|P|2.3.1||||||ASCII|||
    // MSA|AA|4|Message accepted|||0|
    // ERR|0|
    if InLines.Count > 3 then begin
      FileOut := GeneraNewFileName(FileOut);
      InLines.SaveToFile(FileOut+'.res');
      InLines.Clear;
      InLines.Add('ok');
      InLines.SaveToFile(FileOut+'.ok');
    end
    else begin
      InLines.Clear;
    end;
  end;
end;

function TfrmCommHL7_PT1000.GeneraNewFileName(sFileName: string): string;
var
  sPath, sPathBase: string;
  iFile: integer;
begin
  sPath := sFileName;
  if WordCount(sFileName,['.'])>1 then begin
    sPath := ExtractWord(1,sFileName,['.']);
  end;
  sPathBase := sFileName;
  if WordCount(sFileName,['_'])>1 then begin
    sPathBase := ExtractWord(1,sFileName,['_']);
  end;
  iFile := 0;
  while FileExists(sPath+'.res') do begin
    sPath := format('%s_%5.5d',[sPathBase,iFile]);
    inc(iFile);
  end;
  result := sPath;
end;

procedure TfrmCommHL7_PT1000.ProcesaProcesados;
var
  lstFiles: TStringList;
  sFilePed: string;
  j: Integer;
begin
  //leo los archivos del directorio okp (ya procesados)
  memFiles.Lines.Clear;
  lstFiles := TStringList.Create;
  try
    GetFilesList(PathPedidos+'\*.ped',lstFiles);
    for j := 0 to lstFiles.Count-1 do begin
      memFiles.Lines.Add(lstFiles.Strings[j]);
    end;
    for j := 0 to memFiles.Lines.Count-1 do begin    // Iterate
      sFilePed := PathPedidos+'\'+ExtractFileName(memFiles.Lines[j]);
      if (FileDateTime(sFilePed)<Date-30) then begin
        DeleteFile(sFilePed);
      end;
    end;    // for
  finally
    lstFiles.Free;
  end;
end;

procedure TfrmCommHL7_PT1000.LeeConf;
var
	IniFile: tInifile;
  sFile: string;
begin
  sFile := AppPath + 'CommHL7_PT1000.ini';
	IniFile := TIniFile.Create(sFile);
  try
    port := IniFile.ReadInteger('Generales','port',50);
    generaLog := IniFile.ReadBool('Generales','GeneraLogComm',false);
    sManufacturer:= IniFile.ReadString('Generales','Manufacturer','');
    sModel:= IniFile.ReadString('Generales','Model','');
  finally
    IniFile.Free;
	end;
end;

procedure TfrmCommHL7_PT1000.FormDestroy(Sender: TObject);
begin
  FreeAndNil(InputLines);
end;

procedure TfrmCommHL7_PT1000.ProcessInput(const S: string);
begin
  memOutput.Lines.Append(s);
  if GeneraLog then LogOUT.WriteToLogFile(s);
end;

procedure TfrmCommHL7_PT1000.ProcessError(const S: string);
begin
  memData.Lines.Append('<<<<'+s);
  if GeneraLog then LogData.WriteToLogFile(s);
end;

procedure TfrmCommHL7_PT1000.ProcessConnect(const S: string);
begin
 memMsgs.Lines.Append(s);
 if GeneraLog then LogMensajes.WriteToLogFile(s);
end;

procedure TfrmCommHL7_PT1000.ProcessDisconnect(const S: string);
begin
 memMsgs.Lines.Append(s);
 if GeneraLog then LogMensajes.WriteToLogFile(s);
end;

end.
