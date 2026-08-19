unit uLecturaBase;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Sockets, StdCtrls, JvJCLUtils, Inifiles, cTCPClient;

type
  TfrmLectura = class(TForm)
    Memo1: TMemo;
    edtIP: TEdit;
    btnConnect: TButton;
    tcpClient: TfndTCPClient;
    Label1: TLabel;
    Memo2: TMemo;
    Label2: TLabel;
    edtCarpeta: TEdit;
    procedure btnConnectClick(Sender: TObject);
    procedure tcpClientConnected(Sender: ATCPClient);
    procedure tcpClientDataAvailable(Sender: ATCPClient);
    procedure tcpClientClose(Sender: ATCPClient);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    procedure ProcesoChar(sBuff: integer);
    procedure ProcesaDato(sBuff: string);
    function TagValid(sTag: string): boolean;
    procedure ChequeaIni;
    procedure GrabaIni;
    procedure GrabaMemo;
    function AppPath: string;
    function ExisteDirectorio(strTarget: string;  CrearSiNoExiste: boolean): boolean;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmLectura: TfrmLectura;

implementation
const
  cIniDefiniciones = 'mindray.ini';

var
  MsgLeyendo: boolean;
  MsgBuff: string;
{$R *.dfm}

procedure TfrmLectura.btnConnectClick(Sender: TObject);
begin
  tcpClient.Host := edtIP.Text;
  if tcpClient.Active then begin
    tcpclient.active := false;
    btnConnect.Caption := 'Conectar';
  end
  else begin
    tcpclient.active := true;
    btnConnect.Caption := 'Desconectar';
  end;
end;

procedure TfrmLectura.tcpClientConnected(Sender: ATCPClient);
begin
  btnConnect.Caption := 'Desconectar';
end;

procedure TfrmLectura.tcpClientDataAvailable(Sender: ATCPClient);
var
  S: string;
  j: Integer;
begin
//  ShowMessage('mensaje');
  s := Sender.Socket.ReadAvailable;
  for j := 1 to length(s) do begin    // Iterate
    ProcesoChar(ord(s[j]));
  end;    // for
end;

function TfrmLectura.TagValid(sTag: string): boolean;
begin
  result := false;
  result := result or (sTag = 'PATINFO');
  result := result or (sTag = 'WBC');
  result := result or (sTag = 'NEU%');
  result := result or (sTag = 'LYMPH%');
  result := result or (sTag = 'MON%');
  result := result or (sTag = 'EOS%');
  result := result or (sTag = 'BAS%');
  result := result or (sTag = 'RBC');
  result := result or (sTag = 'HGB');
  result := result or (sTag = 'HCT');
  result := result or (sTag = 'PLT');
end;


procedure TfrmLectura.ProcesaDato(sBuff: string);
var
  sdataType: string;
begin
  if sBuff='CTR' then begin
//    GrabaMemo;
//    memo1.lines.clear; //lines.add('--------------------------');
//    memo1.lines.add('--------------------------');
    msgBuff := '';
  end
  else begin
    sdataType := UpperCase(ExtractWord(1,sBuff,[' ']));
    if TagValid(sdataType) then begin
      memo1.lines.add(msgBuff);
      msgBuff := '';
    end;
    if (sdataType = 'PATINFO') then begin
      GrabaMemo;
      memo1.lines.clear; //lines.add('--------------------------');
    end;
  end;
end;

procedure TfrmLectura.GrabaMemo;
var
  j: Integer;
  HayPaciente: boolean;
  s, sGraba, Clave, Dato, Valor: string;
  fNameBase, fName, fNameOk: string;
begin
  HayPaciente := false;
  fNameBase := '';
  fName := '';
  fNameOk := '';
  if (memo1.lines.count>0) then begin
    for j := 0 to memo1.lines.Count - 1 do begin    // Iterate
      s := memo1.lines[j];
      Clave := ExtractWord(1,s,[' ']);
      if (trim(UpperCase(Clave)) = 'PATINFO') then begin
        Dato := ExtractWord(2,s,[' ']);
        Clave := trim(ExtractWord(1,Dato,['=']));
        Valor := trim(ExtractWord(2,Dato,['=']));
        if (trim(UpperCase(Clave)) = 'SAMPLEID') then begin
          fNameBase := AppPath + edtCarpeta.Text + '\' + Valor;
          fName := fNameBase + '.res';
          fNameOk := fNameBase + '.ok';
          HayPaciente := true;
          memo2.Lines.Add('-> ' + s);
          break;
        end;
      end;
    end;
    if HayPaciente then begin
      memo1.Lines.SavetoFile(fName);
      memo1.Lines.SavetoFile(fNameOk);
    end;
  end;
end;


procedure TfrmLectura.ProcesoChar(sBuff: integer);
begin
  if sBuff = 5 then begin
    MsgLeyendo := true;
  end
  else if sBuff = 3 then begin
    ProcesaDato(msgBuff);
    msgBuff := '';
  end
  else if sBuff = $0c then begin
    msgBuff := msgBuff + ' ';
  end
  else if sBuff = $08 then begin
    msgBuff := msgBuff + ' ';
  end
  else if sBuff = $16 then begin
    msgBuff := msgBuff + '=';
  end
  else if sBuff = $04 then begin
    ProcesaDato(msgBuff);
    msgBuff := '';
  end
  else if sBuff = $0a then begin
//    memo1.lines.add('++++++++++++++++++++++++');
    //fin del mensaje
    MsgLeyendo := false;
  end
  else if msgLeyendo then begin
    msgBuff := msgBuff + char(sBuff);
  end;
end;

procedure TfrmLectura.tcpClientClose(Sender: ATCPClient);
begin
  btnConnect.Caption := 'Conectar';
end;

procedure TfrmLectura.FormShow(Sender: TObject);
begin
  MsgLeyendo := false;
  ExisteDirectorio(AppPath + edtCarpeta.Text,true);
  btnConnect.click;
end;

procedure TfrmLectura.ChequeaIni;
var
	ArchivoIni: string;
	LineasIni: tStringList;
	i: integer;
	IniFile: tInifile;
begin
	ArchivoIni := ExtractFilePath(Application.ExeName)+ cIniDefiniciones;
  try
	  IniFile := TIniFile.Create(ExtractFilePath(Application.ExeName)+ cIniDefiniciones);
		if not(IniFile.SectionExists('mindray')) then begin
			// si no existe la seccion TimeTech, la agrega
			IniFile.WriteString('mindray','IP','10.110.110.1');
      IniFile.UpdateFile;
    end;
    edtIP.Text := IniFile.ReadString('mindray','IP','10.110.110.1');
    edtCarpeta.Text := IniFile.ReadString('mindray','carpeta','IN');
	finally
		IniFile.Free;
	end;
end;


procedure TfrmLectura.GrabaIni;
var
	ArchivoIni: string;
	LineasIni: tStringList;
	i: integer;
	IniFile: tInifile;
begin
	ArchivoIni := ExtractFilePath(Application.ExeName)+ cIniDefiniciones;
  try
	  IniFile := TIniFile.Create(ExtractFilePath(Application.ExeName)+ cIniDefiniciones);
    IniFile.WriteString('mindray','IP',edtIP.Text);
    IniFile.WriteString('mindray','carpeta',edtCarpeta.Text);
	finally
		IniFile.Free;
	end;
end;

function TfrmLectura.AppPath: string;
begin
  result := ExtractFilePath(ParamStr(0));
end;

function TfrmLectura.ExisteDirectorio(strTarget: string; CrearSiNoExiste: boolean):boolean;
begin
	result := false;
	if DirectoryExists(strTarget) then begin
		result:= true;
	end
	else begin
		if CrearSiNoExiste then begin
			ForceDirectories(strTarget);
			result := DirectoryExists(strTarget);
		end;
	end;
end;

procedure TfrmLectura.FormCreate(Sender: TObject);
begin
  ChequeaINI;
end;

procedure TfrmLectura.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  GrabaIni;
end;

end.
