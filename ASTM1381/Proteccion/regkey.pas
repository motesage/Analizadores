{$J+}
unit regkey;

// version para ASTMComm

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TfrmRegKey = class(TForm)
    lCode: TLabel;
    btnRegOk: TButton;
    btnRegCancel: TButton;
    btnRegPaste: TButton;
    Button4: TButton;
    Edit1: TEdit;
    Label2: TLabel;
    edtCodigo: TEdit;
    lName: TLabel;
    edtEmpresa: TEdit;
    procedure btnRegPasteClick(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnRegOkClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnRegCancelClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmRegKey: TfrmRegKey;

implementation

uses
  ShellAPI,
  aspr_api;

var
  LocalHardwareID : PChar;

{$R *.DFM}

//------------------------------------------------------------------------------

procedure TfrmRegKey.btnRegPasteClick(Sender: TObject);
begin
  edtCodigo.Clear;
  edtCodigo.PasteFromClipboard;
end;

//------------------------------------------------------------------------------

procedure TfrmRegKey.Button4Click(Sender: TObject);
begin
  ShellExecute(GetDesktopWindow(), 'open', PChar('mailto:software@sage.com.ar?subject=Registracion%20de%20CommASTM&body=El%20código%20de%20hardware%20es%20:%20'+Edit1.Text+
                                                 '%0d%0aEmpresa%20a%20registrar%20:'+edtEmpresa.Text), nil, nil, SW_SHOWNORMAL);
end;

//------------------------------------------------------------------------------

procedure TfrmRegKey.FormCreate(Sender: TObject);
begin
  LocalHardwareID := GetHardwareID;
  Edit1.Text      := StrPas( LocalHardwareID );
end;

//------------------------------------------------------------------------------

procedure TfrmRegKey.btnRegOkClick(Sender: TObject);
begin
  If CheckKeyAndDecrypt( PChar(trim(edtCodigo.Text)), PChar(Trim(edtEmpresa.Text)), True ) then
  begin
    MessageBox(Handle, 'Gracias por registrar el producto', 'Registración', MB_ICONINFORMATION);
    Close;
  end
  else begin
    MessageBox(Handle, 'La clave es inválida. Por favor comuníquese con Sage (www.sage.com.ar)','Registración', MB_ICONWARNING);
  end;
end;

//------------------------------------------------------------------------------

procedure TfrmRegKey.FormShow(Sender: TObject);
begin
	edtEmpresa.Text := '';
end;

procedure TfrmRegKey.btnRegCancelClick(Sender: TObject);
begin
  self.Close;
end;

end.
