program prCelldyn;

uses
//  ExceptionLog,
  ExceptionLog,
  Forms,
  uInterfazCelldyn in 'uInterfazCelldyn.pas' {frmCelldyn};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmCelldyn, frmCelldyn);
  Application.Run;
end.
