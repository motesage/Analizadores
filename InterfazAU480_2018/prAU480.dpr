program prAU480;

uses
//  ExceptionLog,
  Forms,
  uInterfaz in 'uInterfaz.pas' {frmAU480};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmAU480, frmAU480);
  Application.Run;
end.
