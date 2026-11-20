unit uCommASTM_Arch2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Menus, ExtCtrls,  udmParamsASTM, uASTM1381, IniFiles, JvJclUtils;


type
  TfrmCommASTM_Arch2 = class(TForm)
    mnuMain: TMainMenu;
    Archivo1: TMenuItem;
    N1: TMenuItem;
    Panel1: TPanel;
    memInput: TMemo;
    memOutput: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    memFiles: TMemo;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
    procedure ProcessIdle(Sender: TObject);
    procedure ProcessInput(const S: string);
    procedure ProcesaOutputs;
    procedure LeeConf;
    function GeneraNewFileName(sFileName: string): string;
    procedure GrabaInput(InLines: tStringList);
    procedure ProcesaProcesados;
  public
    { Public declarations }
  end;

var
  frmCommASTM_Arch2: TfrmCommASTM_Arch2;
  ASTM: tASTM;
  OutputReady: boolean;
  InputLines: tStringList;


implementation
//uses
//  aspr_api, regkey;
var
  FileOut: string;
  bauds: integer;
  port: integer;
//  LocalHardwareID : PChar;
//  HardwareKey: string;
{$R *.dfm}

procedure TfrmCommASTM_Arch2.FormShow(Sender: TObject);
begin
  LeeConf;
  if not Assigned(ASTM) then begin
    ASTM := tASTM.Create(Self);
  end;
  ASTM.Bauds := bauds;
  ASTM.ComNumber := port;
  ASTM.OnIdle := ProcessIdle;
  ASTM.OnInput := ProcessInput;
  ExisteDirectorio(AppPath+'Interfaces\Architec2\Resultados',true);
  ExisteDirectorio(AppPath+'Interfaces\Architec2\Pedidos',true);
  FileOut := AppPath+'Interfaces\Architec2\Resultados\default.res';
  OutputReady := false;
  ASTM.Bauds := bauds;
  ASTM.ComNumber := port;
  self.Caption := self.Caption + ' - Bauds: '+IntToStr(bauds)+' ComPort: '+IntToStr(port);
  ProcesaProcesados;
end;

procedure TfrmCommASTM_Arch2.FormCreate(Sender: TObject);
begin
  InputLines := TStringList.Create;
end;

procedure TfrmCommASTM_Arch2.Button3Click(Sender: TObject);
begin
  OutputReady := true;
end;

procedure TfrmCommASTM_Arch2.ProcessIdle(Sender: TObject);
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

procedure TfrmCommASTM_Arch2.GrabaInput(InLines: tStringList);
var
  j: Integer;
begin
  if InLines.Count>0 then begin
    FileOut := GeneraNewFileName(FileOut);
    InLines.SaveToFile(FileOut+'.res');
    InLines.Clear;
    InLines.Add('ok');
    InLines.SaveToFile(FileOut+'.ok');
    memOutput.Lines.Clear;
    for j := 0 to InLines.Count-1 do begin    // Iterate
      memOutput.Lines.Append(InLines.Strings[j]);
    end;    // for
  end;
end;

function TfrmCommASTM_Arch2.GeneraNewFileName(sFileName: string): string;
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

procedure TfrmCommASTM_Arch2.ProcesaOutputs;
var
  Path, sFileIn, sFileOkp, sFileOk: string;
  Rec: tSearchRec;
  j: Integer;
begin
  //leo los archivos del directorio "Interfaces\Architec2\Pedidos" (van al equipo)
  memFiles.Lines.Clear;
  Path := AppPath+'Interfaces\Architec2\Pedidos';
  if FindFirst(Path+'\*.ok',faAnyFile - faDirectory,Rec)=0 then begin
    try
      repeat
        memFiles.Lines.Add(Rec.Name) ;
      until FindNext(Rec) <> 0;
    finally
      FindClose(Rec) ;
    end;
  end;

//  for j := 0 to memFiles.Lines.Count-1 do begin    // Iterate
  if memFiles.Lines.Count >0 then begin
    for j := 0 to 0 do begin    // Iterate
      sFileOk := Path+'\'+ExtractFileName(memFiles.Lines[j]);
      sFileIn := ChangeFileExt(sFileOk,'.res');
      sFileOkp := ChangeFileExt(sFileOk,'.okp');
      if FileExists(sFileIn) then begin
        FileOut := AppPath+'Interfaces\Architec2\Resultados'+'\'+ExtractFileName(memFiles.Lines[j]);
        memInput.Lines.Clear;
        memInput.Lines.LoadFromFile(sFileIn);
        if FileExists(sFileOkp) then begin
          DeleteFile(sFileOkp);
        end;
        RenameFile(sFileOk, sFileOkp);
        OutputReady := true;
        //sleep(1000);
      end;
    end;    // for
  end;
end;
procedure TfrmCommASTM_Arch2.ProcesaProcesados;
var
  Path, sFileIn, sFileOkp, sFileOk: string;
  Rec: tSearchRec;
  j: Integer;
begin
  //leo los archivos del directorio okp (ya procesados)
  memFiles.Lines.Clear;
  Path := AppPath+'Interfaces\Architec2\Pedidos';
  if FindFirst(Path+'\*.okp',faAnyFile - faDirectory,Rec)=0 then begin
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

procedure TfrmCommASTM_Arch2.LeeConf;
var
	IniFile: tInifile;
  sFile: string;
begin
  sFile := AppPath + 'CommASTM_Arch2.ini';
	IniFile := TIniFile.Create(sFile);
  try
    bauds := IniFile.ReadInteger('parametros','bauds',9600);
    port := IniFile.ReadInteger('parametros','port',4);
  finally
    IniFile.Free;
	end;
end;

procedure TfrmCommASTM_Arch2.FormDestroy(Sender: TObject);
begin
  FreeAndNil(InputLines);
end;

procedure TfrmCommASTM_Arch2.ProcessInput(const S: string);
begin
 memOutput.Lines.Append(s);
end;

procedure TfrmCommASTM_Arch2.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
//  CanClose := false;
end;

end.
