program MindrayTest;

uses
  ExceptionLog,
  Forms,
  uLecturaBase in 'uLecturaBase.pas' {frmLectura},
  udmParamsMindray in 'udmParamsMindray.pas' {dmParametrosMindray: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmLectura, frmLectura);
  Application.CreateForm(TdmParametrosMindray, dmParametrosMindray);
  Application.Run;
end.
