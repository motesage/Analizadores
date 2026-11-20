program CommASTM;

uses
  ExceptionLog,
  Windows, Forms, SysUtils, Dialogs,
  uCommASTM in 'uCommASTM.pas' {frmCommASTM},
  udmParamsASTM in 'udmParamsASTM.pas' {dmParametrosASTM: TDataModule},
  uASTM1381 in 'uASTM1381.pas',
  uCommBuffer in 'uCommBuffer.pas',
  uMultiConfig in 'uMultiConfig.pas',
  uMultiQueue in 'uMultiQueue.pas',
  uMultiMain in 'uMultiMain.pas';

{$R *.res}

var LegacyLock: THandle;

begin
  LegacyLock := INVALID_HANDLE_VALUE;
  Application.Initialize;
  try
    if ParamCount = 0 then begin
      LegacyLock := AcquireModeLock(ExtractFilePath(Application.ExeName) + 'Interfaces\Architec', False);
      Application.Title := 'CommASTM - Sage SRL - www.sage.com.ar';
      Application.CreateForm(TfrmCommASTM, frmCommASTM);
      Application.CreateForm(TdmParametrosASTM, dmParametrosASTM);
    end
    else begin
      if ParamCount <> 1 then raise Exception.Create('Uso: CommASTM.exe Equipo=Ar1');
      Application.CreateForm(TMultiForm, MultiForm);
    end;
    Application.Run;
  except
    on E: Exception do begin
      MessageDlg(E.Message, mtError, [mbOK], 0);
      ExitCode := 1;
    end;
  end;
  if LegacyLock <> INVALID_HANDLE_VALUE then CloseHandle(LegacyLock);
end.
