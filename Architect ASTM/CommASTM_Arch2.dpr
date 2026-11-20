program CommASTM_Arch2;

uses
  ExceptionLog,
  Forms,
  Windows,
  Controls,
  uCommASTM_Arch2 in 'uCommASTM_Arch2.pas' {frmCommASTM_Arch2},
  udmParamsASTM in 'udmParamsASTM.pas' {dmParametrosASTM: TDataModule},
  uASTM1381 in 'uASTM1381.pas',
  uCommBuffer in 'uCommBuffer.pas';

{$R *.res}
var
	hMutex: THandle;

begin
    Application.Initialize;
    Application.Title := 'CommASTM_Arch2 - Sage SRL - www.sage.com.ar';
    Application.CreateForm(TfrmCommASTM_Arch2, frmCommASTM_Arch2);
    Application.CreateForm(TdmParametrosASTM, dmParametrosASTM);
    Application.Run;
end.

