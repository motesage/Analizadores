program Comm_Std;

uses
//  ExceptionLog,
  ExceptionLog,
  Forms,
  uInterfaz_Std in 'uInterfaz_Std.pas' {frmIono_Std};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Comm_Std';
  Application.CreateForm(TfrmInterfaz_Std, frmInterfaz_Std);
  Application.Run;
end.
