unit uCommASTM;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Menus, uASTM1381, ExtCtrls,  udmParamsASTM, uHL7, IniFiles, JvJclUtils,
  ScktComp, Sockets;

const
  wm_RefreshClients = wm_User;
  CommandSeparator = ':';
	cIniFilename = 'CommServer.ini';	//archivo de inicializacion
	CtrlChars: array[#1..#31] of string[5]
							= ('<SOH>','<STX>','<ETX>','<EOT>','<ENQ>','<ACK>','<BEL>',
								'<BS> ','<TAB>','<LF> ','<VT> ','<NP> ','<CR> ','<SO> ','<SI> ',
								'<DLE>','<DC1>','<DC2>','<DC3>','<DC4>','<NAK>','<SYN>','<ETB>',
								'<CAN>','<EM> ','<EOF>','<ESC>','<FS> ','<GS> ','<RS> ','<US> ');
	stx = #2;
	etx = #3;
	ack = #6;
	nak = #21;


type
  TfrmCommASTM = class(TForm)
    mnuMain: TMainMenu;
    Archivo1: TMenuItem;
    N1: TMenuItem;
    Panel1: TPanel;
    memInput: TMemo;
    memOutput: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    memFiles: TMemo;
    memMsgs: TMemo;
    guarda1: TMenuItem;
    PopupMenu1: TPopupMenu;
    Guarda2: TMenuItem;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure guarda1Click(Sender: TObject);
    procedure Guarda2Click(Sender: TObject);
  private
    { Private declarations }
    procedure ProcessIdle(Sender: TObject);
    procedure ProcessInput(const S: string);
    procedure ProcessOutput(const S: string);
    procedure ProcesaOutputs;
    procedure LeeConf;
    function GeneraNewFileName(sFileName: string): string;
    procedure GrabaInput(InLines: tStringList);
    procedure ProcesaProcesados;
    procedure ProcessConnect(const S: string);
    procedure ProcessDisconnect(const S: string);
  public
    { Public declarations }
  end;

var
  frmCommASTM: TfrmCommASTM;
  ASTM: tASTM;
  OutputReady: boolean;
  InputLines: tStringList;


implementation
var
  FileOut: string;
  Analizador: string;
  bauds: integer;
  port: integer;
{$R *.dfm}

procedure TfrmCommASTM.FormShow(Sender: TObject);
begin
  LeeConf;
  if not Assigned(ASTM) then begin
    ASTM := tASTM.Create(Self);
  end;
  ASTM.Bauds := bauds;
  ASTM.ComNumber := port;
  ASTM.OnIdle := ProcessIdle;
  ASTM.OnInput := ProcessInput;
  ASTM.OnOutput := ProcessOutput;
  ASTM.OnConnect := ProcessConnect;
  ASTM.OnDisconnect := ProcessDisconnect;

  ExisteDirectorio(AppPath+ 'Interfaces\' + trim(Analizador) + '\Pedidos',true);
  ExisteDirectorio(AppPath+ 'Interfaces\' + trim(Analizador) + '\Resultados',true);
  FileOut := AppPath+'Interfaces\' + trim(Analizador) + '\Resultados\default.res';

  OutputReady := false;
  ASTM.Bauds := bauds;
  ASTM.ComNumber := port;
  self.Caption := self.Caption + ' - Bauds: '+IntToStr(bauds)+' ComPort: '+IntToStr(port);
end;

procedure TfrmCommASTM.FormCreate(Sender: TObject);
begin
  InputLines := TStringList.Create;
end;

procedure TfrmCommASTM.Button3Click(Sender: TObject);
begin
  OutputReady := true;
end;

procedure TfrmCommASTM.ProcessIdle(Sender: TObject);
var
  j: Integer;
  S: string;
begin
  if Assigned(InputLines) then begin
    InputLines.Clear;
    while ASTM.Count>0 do begin
      s := ASTM.Data;
      memOutput.Lines.Append(s);
      InputLines.Add(s);
    end;    // while
    GrabaInput(InputLines);
  end;
  if OutputReady then begin
    for j := 0 to memInput.Lines.Count-1 do begin    // Iterate
      ASTM.Data := memInput.Lines[j];
    end;    // for
    OutputReady := false;
  end
  else begin
    ProcesaOutputs;
  end;
end;

procedure TfrmCommASTM.GrabaInput(InLines: tStringList);
var
  j: Integer;
begin
  if InLines.Count>0 then begin
    FileOut := GeneraNewFileName(FileOut);
    InLines.SaveToFile(FileOut+'.res');
    memOutput.Lines.Clear;
    for j := 0 to InLines.Count-1 do begin    // Iterate
      memOutput.Lines.Append(InLines.Strings[j]);
    end;    // for
  end;
end;

function TfrmCommASTM.GeneraNewFileName(sFileName: string): string;
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

procedure TfrmCommASTM.ProcesaOutputs;
var
  Path, sFileIn, sFileOkp, sFileOk: string;
  Rec: tSearchRec;
  j: Integer;
begin
  //leo los archivos del directorio pedidos (OUT) (van al equipo)
  memFiles.Lines.Clear;
  //  Path := AppPath+'Out';
  Path := AppPath+'Interfaces\' + trim(Analizador) + '\Pedidos';
  if FindFirst(Path+'\*.ok',faAnyFile - faDirectory,Rec)=0 then begin
    try
      repeat
        memFiles.Lines.Add(Rec.Name) ;
      until FindNext(Rec) <> 0;
    finally
      FindClose(Rec) ;
    end;
  end;
  if memFiles.Lines.Count >0 then begin
    for j := 0 to memFiles.Lines.Count do begin    // Iterate
      sFileOk := Path+'\'+ExtractFileName(memFiles.Lines[j]);
      sFileIn := ChangeFileExt(sFileOk,'.res');
      sFileOkp := ChangeFileExt(sFileOk,'.okp');
      if FileExists(sFileIn) then begin
        FileOut := AppPath+'In'+'\'+ExtractFileName(memFiles.Lines[j]);
        memInput.Lines.Clear;
        memInput.Lines.LoadFromFile(sFileIn);
        if FileExists(sFileOkp) then begin
          DeleteFile(sFileOkp);
        end;
        RenameFile(sFileOk, sFileOkp);
        OutputReady := true;
      end;
    end;    // for
  end;
end;

procedure TfrmCommASTM.ProcesaProcesados;
var
  Path, sFileIn, sFileOkp, sFileOk: string;
  Rec: tSearchRec;
  j: Integer;
begin
  //leo los archivos del directorio okp (ya procesados)
  memFiles.Lines.Clear;
  //  Path := AppPath+'Out';
  Path := AppPath+'Interfaces\' + trim(Analizador) + 'Resultados';
  if FindFirst(Path+'\*.ok',faAnyFile - faDirectory,Rec)=0 then begin
    try
      repeat
        memFiles.Lines.Add(Rec.Name) ;
      until FindNext(Rec) <> 0;
    finally
      FindClose(Rec) ;
    end;
  end;

  for j := 0 to memFiles.Lines.Count-1 do begin    // Iterate
    sFileOkp := Path+'\'+ExtractFileName(memFiles.Lines[j]);
    sFileIn := ChangeFileExt(sFileOkp,'.res');
    sFileOk := ChangeFileExt(sFileOkp,'.ok');
    if not FileExists(sFileOk) then begin
      if FileExists(sFileOkp) then begin
          DeleteFile(sFileOkp);
      end;
      if FileExists(sFileIn) then begin
          DeleteFile(sFileIn);
      end;
    end;
  end;    // for
end;

procedure TfrmCommASTM.LeeConf;
var
	IniFile: tInifile;
  sFile: string;
begin
  sFile := AppPath + 'CommASTM.ini';
	IniFile := TIniFile.Create(sFile);
  try
    bauds := IniFile.ReadInteger('SerialPort','speed',9600);
    port := IniFile.ReadInteger('SerialPort','Com',1);
    Analizador :=  IniFile.ReadString('Generales','Analizador','Ruby');
  finally
    IniFile.Free;
	end;
end;


procedure TfrmCommASTM.FormDestroy(Sender: TObject);
begin
  FreeAndNil(InputLines);
end;

procedure TfrmCommASTM.ProcessInput(const S: string);
begin
 memOutput.Lines.Append(s);
end;

procedure TfrmCommASTM.ProcessOutput(const S: string);
begin
 memOutput.Lines.Append('->'+s);
end;

procedure TfrmCommASTM.ProcessConnect(const S: string);
begin
 memMsgs.Lines.Append(s);
end;

procedure TfrmCommASTM.ProcessDisconnect(const S: string);
begin
 memMsgs.Lines.Append(s);
end;


procedure TfrmCommASTM.guarda1Click(Sender: TObject);
begin
  memInput.Lines.SaveToFile('inputASTM.txt');
  memOutput.Lines.SaveToFile('outputASTM.txt');
end;

procedure TfrmCommASTM.Guarda2Click(Sender: TObject);
begin
  memInput.Lines.SaveToFile('inputASTM.txt');
  memOutput.Lines.SaveToFile('outputASTM.txt');
end;

end.
