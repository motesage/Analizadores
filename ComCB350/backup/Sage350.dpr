program Sage350;

uses
  ExceptionLog,
  Forms,
  uComunica in 'uComunica.pas' {frmComunica},
  udmComm350 in 'udmComm350.pas' {dmComm350: TDataModule};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Comunicaciones Sage <-> CB350';
  Application.CreateForm(TfrmComunica, frmComunica);
  Application.CreateForm(TdmComm350, dmComm350);
  Application.Run;
end.
