program CommASTM;

uses
  ExceptionLog,
  Forms,
  Windows,
  Controls,
  uASTM1381 in 'uASTM1381.pas',
  uCommASTM in 'uCommASTM.pas' {frmCommASTM},
  udmParamsASTM in 'udmParamsASTM.pas' {dmParametrosASTM: TDataModule},
  uCommBuffer in 'uCommBuffer.pas',
  rpVersionInfo in 'rpVersionInfo.pas';

{$R *.res}
var
	hMutex: THandle;

begin
	//para que se ejecute una sola instancia del programa (MD4 Cap.20 p.913)
	hMutex := CreateMutex (nil, False, 'SGCommUnaCopia');
	if WaitForSingleObject (hMutex, 0) <> wait_TimeOut then begin
    Application.Initialize;
		try
	    Application.Title := 'CommASTM - Sage SRL - www.sage.com.ar';
      Application.CreateForm(TfrmCommASTM, frmCommASTM);
      Application.CreateForm(TdmParametrosASTM, dmParametrosASTM);
      Application.Run;
    finally
  		// frmLogin.Free;
    end;
  end;
end.


