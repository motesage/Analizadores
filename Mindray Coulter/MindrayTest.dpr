program MindrayTest;

uses
  ExceptionLog,
  Forms,
  uLecturaBase in 'uLecturaBase.pas' {frmLectura};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmLectura, frmLectura);
  Application.Run;
end.
