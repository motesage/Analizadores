unit uLogin;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, Buttons, RXCtrls, jpeg, UnitComp_LogToFile, rpVersionInfo;

type
  TfrmLogin = class(TForm)
    Image1: TImage;
    RxLabel1: TRxLabel;
    btnAceptar: TBitBtn;
    btnCancelar: TBitBtn;
    RxLabel2: TRxLabel;
    Bevel1: TBevel;
    btnRegistrar: TBitBtn;
    LogFile: TLogToFile;
    procedure btnCancelarClick(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnRegistrarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    rpVersion: tRpVersionInfo;
  public
    { Public declarations }
    function TestRegistration: boolean;
  end;

var
  frmLogin: TfrmLogin;
  MuestraAvanzadas: boolean = false;

implementation

uses regkey,  ShellAPI,  aspr_api;

var

  UserKey        : PChar  = nil;
  UserName       : PChar  = nil;

  ModeName       : PChar  = nil;

  TrialDaysTotal : DWORD  = DWORD(-1);
  TrialDaysLeft  : DWORD  = DWORD(-1);


{$R *.DFM}

procedure TfrmLogin.btnCancelarClick(Sender: TObject);
begin
	self.ModalResult := mrCancel;
  Application.Terminate;
end;

procedure TfrmLogin.btnAceptarClick(Sender: TObject);
begin
	self.ModalResult := mrOk;
end;

procedure TfrmLogin.btnRegistrarClick(Sender: TObject);
begin
  Hide;
  With TfrmRegKey.Create(Application) do
  try
    ShowModal;
  finally
    Close;
    Free;
  end;
  self.ModalResult := mrNone;
  Show;
  TestRegistration;
end;

function TfrmLogin.TestRegistration: boolean;
begin
	MuestraAvanzadas := false;
	result := false;
  GetRegistrationInformation( 0, UserKey, UserName );
  if (UserKey <> nil) AND (StrLen(UserKey) > 0) then  begin
    {$I include\aspr_crypt_begin1.inc}
      btnRegistrar.Visible := False;
      self.Caption := 'CommASTM - Login - '+StrPas(UserName);
      if (Pos('SAGE',UpperCase(UserName))<>0) then begin
        MuestraAvanzadas := true;
      end;
      btnAceptar.OnClick := btnAceptarClick;
      result := true;
    {$I include\aspr_crypt_end1.inc}
  end
  else begin
    {$I include\aspr_crypt_begin2.inc}
  	btnRegistrar.Visible:= True;
    If GetTrialDays( 0, TrialDaysTotal, TrialDaysLeft ) then begin
      If TrialDaysLeft = 0 then begin
				if ParamCount > 0  then begin
					LogFile.WriteToLogFile('CommASTM Cancelado. Periodo de prueba vencido');
					Application.Terminate;
        end
        else begin
					self.Caption := 'CommASTM Demo - Periodo de prueba vencido';
					btnAceptar.OnClick := btnCancelarClick;
        end;
      end
      else begin
				self.Caption := 'CommASTM Demo - Login - '+IntToStr(TrialDaysLeft)+' dias';
				btnAceptar.OnClick := btnAceptarClick;
				result := true;
      end;
    {$I include\aspr_crypt_end2.inc}
    end;
	end;
end;


procedure TfrmLogin.FormShow(Sender: TObject);
begin
  rxLabel1.Caption := 'CommASTM v'+rpVersion.FileVersion+stringOfChar(' ',30);
  TestRegistration;
end;

procedure TfrmLogin.FormCreate(Sender: TObject);
begin
  rpVersion := TrpVersionInfo.Create(self);
end;

end.
