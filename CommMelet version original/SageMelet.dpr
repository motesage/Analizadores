program SageMelet;

uses
  Forms,
  uComunica in 'uComunica.pas' {frmComunica},
  udmCommMelet in 'udmCommMelet.pas' {dmCommMelec: TDataModule};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Comunicaciones Sage <-> Melec';
  Application.CreateForm(TfrmComunica, frmComunica);
  Application.CreateForm(TdmCommMelet, dmCommMelet);
  Application.Run;
end.
