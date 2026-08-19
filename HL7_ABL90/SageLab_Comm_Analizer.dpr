program SageLab_Comm_Analizer;

uses
  ExceptionLog,
  Forms,
  UnitMain in 'UnitMain.pas' {frmMain},
  uHL7Server in 'uHL7Server.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'SageLab_Comm_Analizer';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
