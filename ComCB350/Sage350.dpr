program Sage350;

uses
  Forms,
  uProcesaCB350 in 'uProcesaCB350.pas' {frmProcesaCB350},
  udmComm350 in 'udmComm350.pas' {dmComm350: TDataModule};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Comunicaciones Sage <-> CB350';
  Application.CreateForm(TfrmProcesaCB350, frmProcesaCB350);
  Application.CreateForm(TdmComm350, dmComm350);
  Application.Run;
end.
