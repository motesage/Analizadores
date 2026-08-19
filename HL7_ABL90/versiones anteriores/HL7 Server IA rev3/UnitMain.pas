unit UnitMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls,
  IdContext,
  uHL7Server;

type
  TfrmMain = class(TForm)
    MemoLog: TMemo;
    btnStart: TButton;
    btnStop: TButton;
    edtPort: TEdit;
    Label1: TLabel;
    chkOnlyAnalyzer: TCheckBox;
    Label2: TLabel;
    cmbFraming: TComboBox;
    Label3: TLabel;
    chkAutoACK: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure chkOnlyAnalyzerClick(Sender: TObject);
    procedure cmbFramingChange(Sender: TObject);
    procedure chkAutoACKClick(Sender: TObject);
  private
    FServer : THL7Server;
    procedure ApplyOptions;
    procedure ServerLog(Sender: TObject; const Texto : AnsiString);
    procedure ServerHL7(Sender: TObject; AContext : TIdContext; const Msg : AnsiString);
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FServer := THL7Server.Create;
  FServer.OnLog := ServerLog;
  FServer.OnHL7Message := ServerHL7;

  edtPort.Text := '5655'; // Gases CLinica

  cmbFraming.Items.Clear;
  cmbFraming.Items.Add('Auto');
  cmbFraming.Items.Add('MLLP 0B ... 1C 0D');
  cmbFraming.Items.Add('SOH/EOT 01 ... 04');
  cmbFraming.ItemIndex := 2;  // era 0, pero pongo 2 para probar Gases CLinica

  chkOnlyAnalyzer.Checked := true; // para que genere el log similar a "resultado.txt"
  chkAutoACK.Checked := True;

  ApplyOptions;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FServer.Free;
end;

procedure TfrmMain.ApplyOptions;
begin
  FServer.LogOnlyAnalyzerData := chkOnlyAnalyzer.Checked;
  FServer.AutoACK := chkAutoACK.Checked;

  case cmbFraming.ItemIndex of
    1: FServer.FramingMode := fmMLLP;
    2: FServer.FramingMode := fmSOHEOT;
  else
    FServer.FramingMode := fmAuto;
  end;
end;

procedure TfrmMain.btnStartClick(Sender: TObject);
begin
  ApplyOptions;
  FServer.Start(StrToInt(edtPort.Text));
end;

procedure TfrmMain.btnStopClick(Sender: TObject);
begin
  FServer.Stop;
end;

procedure TfrmMain.chkOnlyAnalyzerClick(Sender: TObject);
begin
  ApplyOptions;
end;

procedure TfrmMain.cmbFramingChange(Sender: TObject);
begin
  ApplyOptions;
end;

procedure TfrmMain.chkAutoACKClick(Sender: TObject);
begin
  ApplyOptions;
end;

procedure TfrmMain.ServerLog(Sender: TObject; const Texto : AnsiString);
begin
  MemoLog.Lines.Add(Texto);
end;

procedure TfrmMain.ServerHL7(Sender: TObject; AContext : TIdContext; const Msg : AnsiString);
begin
  MemoLog.Lines.Add('');
  MemoLog.Lines.Add('===== HL7 MESSAGE =====');
  MemoLog.Lines.Add(Msg);
  MemoLog.Lines.Add('=======================');
end;

end.
