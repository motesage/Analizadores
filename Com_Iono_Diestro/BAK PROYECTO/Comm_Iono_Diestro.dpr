program Comm_Iono_Diestro;

uses
//  ExceptionLog,
  ExceptionLog,
  Forms,
  uInterfazIono_Diestro in 'uInterfazIono_Diestro.pas' {frmIono_Diestro};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Comm_Iono_Diestro';
  Application.CreateForm(TfrmIono_Diestro, frmIono_Diestro);
  Application.Run;
end.
