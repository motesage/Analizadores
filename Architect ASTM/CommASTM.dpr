program CommASTM;

uses
  ExceptionLog,
  Forms,
  Windows,
  Controls,
  uCommASTM in 'uCommASTM.pas' {frmCommASTM},
  udmParamsASTM in 'udmParamsASTM.pas' {dmParametrosASTM: TDataModule},
  uASTM1381 in 'uASTM1381.pas',
  uCommBuffer in 'uCommBuffer.pas';

{$R *.res}
var
	hMutex: THandle;

begin
    Application.Initialize;
    Application.Title := 'CommASTM - Sage SRL - www.sage.com.ar';
    Application.CreateForm(TfrmCommASTM, frmCommASTM);
    Application.CreateForm(TdmParametrosASTM, dmParametrosASTM);
    Application.Run;
end.

