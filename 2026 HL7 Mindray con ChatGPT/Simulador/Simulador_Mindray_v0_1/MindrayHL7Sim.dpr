program MindrayHL7Sim;

uses
  ExceptionLog,
  Forms,
  uMindrayHL7Sim in 'uMindrayHL7Sim.pas' {frmMindrayHL7Sim};


begin
  Application.Initialize;
  Application.Title := 'Simulador Mindray HL7 - Sage';
  Application.CreateForm(TfrmMindrayHL7Sim, frmMindrayHL7Sim);
  Application.Run;
end.
