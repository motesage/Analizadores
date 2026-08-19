program Comm_Iono_Diestro2;

uses
//  ExceptionLog,
  ExceptionLog,
  Forms,
  uInterfazIono_Diestro2 in 'uInterfazIono_Diestro2.pas' {frmIono_Diestro2};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Comm_Iono_Diestro2';
  Application.CreateForm(TfrmIono_Diestro2, frmIono_Diestro2);
  Application.Run;
end.
