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
    chkLogASC: TCheckBox;
    chkLogHEX: TCheckBox;
    Label4: TLabel;
    edtOutFolder: TEdit;
    Label5: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure chkOnlyAnalyzerClick(Sender: TObject);
    procedure cmbFramingChange(Sender: TObject);
    procedure chkAutoACKClick(Sender: TObject);
    procedure chkLogASCClick(Sender: TObject);
    procedure chkLogHEXClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
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

  cmbFraming.Items.Clear;
  cmbFraming.Items.Add('Auto');
  cmbFraming.Items.Add('MLLP 0B ... 1C 0D');
  cmbFraming.Items.Add('Radiometer TCP SOH/EOT 01 ... 04');
  cmbFraming.ItemIndex := 2;

  FServer.LoadConfig;
  edtPort.Text := IntToStr(FServer.Port);

  case FServer.FramingMode of
    fmAuto: cmbFraming.ItemIndex := 0;
    fmMLLP: cmbFraming.ItemIndex := 1;
    fmRadiometerTCP: cmbFraming.ItemIndex := 2;
  end;

  chkOnlyAnalyzer.Checked := FServer.LogOnlyAnalyzerData;
  chkAutoACK.Checked := FServer.AutoACK;
  chkLogASC.Checked := FServer.GenerateLogASC;
  chkLogHEX.Checked := FServer.GenerateLogHEX;
  edtOutFolder.Text := FServer.OutputFolder;
  ApplyOptions;
  // autostart Marcelo
  FServer.Start(FServer.Port);

end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FServer.SaveConfig;
  FServer.Free;
end;

procedure TfrmMain.ApplyOptions;
begin
  FServer.Port := StrToIntDef(edtPort.Text, 5655);
  FServer.LogOnlyAnalyzerData := chkOnlyAnalyzer.Checked;
  FServer.AutoACK := chkAutoACK.Checked;
  FServer.GenerateLogASC := chkLogASC.Checked;
  FServer.GenerateLogHEX := chkLogHEX.Checked;
  FServer.OutputFolder := edtOutFolder.Text;
  case cmbFraming.ItemIndex of
    0: FServer.FramingMode := fmAuto;
    1: FServer.FramingMode := fmMLLP;
  else
    FServer.FramingMode := fmRadiometerTCP;
  end;
end;

procedure TfrmMain.btnStartClick(Sender: TObject);
begin
  ApplyOptions;
  FServer.SaveConfig;
  FServer.Start(FServer.Port);
end;

procedure TfrmMain.btnStopClick(Sender: TObject);
begin
  FServer.Stop;
end;

procedure TfrmMain.chkOnlyAnalyzerClick(Sender: TObject); begin ApplyOptions; end;
procedure TfrmMain.cmbFramingChange(Sender: TObject); begin ApplyOptions; end;
procedure TfrmMain.chkAutoACKClick(Sender: TObject); begin ApplyOptions; end;
procedure TfrmMain.chkLogASCClick(Sender: TObject); begin ApplyOptions; end;
procedure TfrmMain.chkLogHEXClick(Sender: TObject); begin ApplyOptions; end;

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

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // autoStop: Marcelo
  FServer.Stop;
end;

end.
