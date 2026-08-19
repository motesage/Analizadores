program HL7MiniServerDemo;

uses
  ExceptionLog,
  Forms,
  UnitMain in 'UnitMain.pas' {frmMain},
  uHL7Server in 'uHL7Server.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
