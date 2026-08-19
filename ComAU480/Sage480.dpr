program Sage480;

uses
  // ExceptionLog,
  ExceptionLog,
  Forms,
  uProcesaAU480 in 'uProcesaAU480.pas' {frmProcesaAU480},
  udmComm480 in 'udmComm480.pas' {dmComm480: TDataModule};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Comunicaciones Sage <-> AU480';
  Application.CreateForm(TfrmProcesaAU480, frmProcesaAU480);
  Application.CreateForm(TdmComm480, dmComm480);
  Application.Run;
end.
