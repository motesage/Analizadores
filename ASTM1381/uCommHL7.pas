unit uCommHL7;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Menus, ExtCtrls,  udmParamsHL7, uHL7, IniFiles, JvJclUtils,
  ScktComp, Sockets, JclFileUtils;

const
  wm_RefreshClients = wm_User;
	cIniFilename = 'CommHL7.ini';	//archivo de inicializacion


type
  TfrmCommHL7 = class(TForm)
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
  frmCommHL7: TfrmCommHL7;
  HL7: tHL7;
  InputLines: tStringList;


implementation

var
  PathResultados, PathPedidos: string;
  FileOut: string;
  port: integer;
{$R *.dfm}

procedure TfrmCommHL7.FormShow(Sender: TObject);
begin
  LeeConf;
  if not Assigned(HL7) then begin
    HL7 := tHL7.Create(Self);
  end;
  HL7.OnIdle := ProcessIdle;
  HL7.OnInput := ProcessInput;
  HL7.OnError := ProcessError;
  HL7.OnMessage := ProcessConnect;
  HL7.OnConnect := ProcessConnect;
  HL7.OnDisconnect := ProcessDisconnect;
  HL7.Port := port;

  // verifica (y crea los directorios de intercambio)
  ExisteDirectorio(PathResultados,true); //IN
  ExisteDirectorio(PathPedidos,true);    //OUT

  FileOut := PathResultados+'\default.res';
  self.Caption := self.Caption + ' - Puerto: '+IntToStr(port);
  ProcesaProcesados;
end;

procedure TfrmCommHL7.FormCreate(Sender: TObject);
begin
  InputLines := TStringList.Create;
  PathPedidos := AppPath+'Pedidos';
  PathResultados := AppPath+'Result';
end;

procedure TfrmCommHL7.ProcessIdle(Sender: TObject);
var
  S: string;
begin
  if Assigned(InputLines) then begin
    InputLines.Clear;
    while HL7.Count>0 do begin
      s := HL7.Data;
      InputLines.Add(s);
      memData.Lines.Add(s);
    end;    // while
    GrabaInput(InputLines);
  end;
end;

procedure TfrmCommHL7.GrabaInput(InLines: tStringList);
begin
  if InLines.Count>0 then begin
    FileOut := GeneraNewFileName(FileOut);
    InLines.SaveToFile(FileOut+'.res');
    InLines.Clear;
    InLines.Add('ok');
    InLines.SaveToFile(FileOut+'.ok');
  end;
end;


function TfrmCommHL7.GeneraNewFileName(sFileName: string): string;
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


//----------------------   revisados




procedure TfrmCommHL7.ProcesaProcesados;
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


procedure TfrmCommHL7.LeeConf;
var
	IniFile: tInifile;
  sFile: string;
begin
  sFile := AppPath + 'CommHL7.ini';
	IniFile := TIniFile.Create(sFile);
  try
    port := IniFile.ReadInteger('Generales','port',50);
  finally
    IniFile.Free;
	end;
end;


procedure TfrmCommHL7.FormDestroy(Sender: TObject);
begin
  FreeAndNil(InputLines);
end;

procedure TfrmCommHL7.ProcessInput(const S: string);
begin
//  if Pos('MSH',S)>0 then begin
//    memOutput.Lines.Clear;
//  end;
  memOutput.Lines.Append(s);
end;

procedure TfrmCommHL7.ProcessError(const S: string);
begin
//  if Pos('MSH',S)>0 then begin
//    memOutput.Lines.Clear;
//  end;
  memData.Lines.Append('<<<<'+s);
end;

procedure TfrmCommHL7.ProcessConnect(const S: string);
begin
 memMsgs.Lines.Append(s);
end;
procedure TfrmCommHL7.ProcessDisconnect(const S: string);
begin
 memMsgs.Lines.Append(s);
end;


end.
