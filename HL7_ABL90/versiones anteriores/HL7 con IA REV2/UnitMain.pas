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
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure chkOnlyAnalyzerClick(Sender: TObject);
  private
    FServer : THL7Server;
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
  edtPort.Text := '5000';
  chkOnlyAnalyzer.Checked := False;
  FServer.LogOnlyAnalyzerData := chkOnlyAnalyzer.Checked;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FServer.Free;
end;

procedure TfrmMain.btnStartClick(Sender: TObject);
begin
  FServer.LogOnlyAnalyzerData := chkOnlyAnalyzer.Checked;
  FServer.Start(StrToInt(edtPort.Text));
end;

procedure TfrmMain.btnStopClick(Sender: TObject);
begin
  FServer.Stop;
end;

procedure TfrmMain.chkOnlyAnalyzerClick(Sender: TObject);
begin
  FServer.LogOnlyAnalyzerData := chkOnlyAnalyzer.Checked;
end;

procedure TfrmMain.ServerLog(Sender: TObject; const Texto : AnsiString);
begin
  MemoLog.Lines.Add(Texto);
end;

procedure TfrmMain.ServerHL7(Sender: TObject; AContext : TIdContext; const Msg : AnsiString);
begin
  MemoLog.Lines.Add('');
  MemoLog.Lines.Add('===== HL7 =====');
  MemoLog.Lines.Add(Msg);
  MemoLog.Lines.Add('===============');
end;

end.
