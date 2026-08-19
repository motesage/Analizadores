program CommASTM_Ruby;

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
	//para que se ejecute una sola instancia del programa (MD4 Cap.20 p.913)
	hMutex := CreateMutex (nil, False, 'CommRubyUnaCopia');
	if WaitForSingleObject (hMutex, 0) <> wait_TimeOut then begin
    Application.Initialize;
//		try
	    Application.Title := 'CommASTM - RUBY - Sage SRL - www.sage.com.ar';
      Application.CreateForm(TfrmCommASTM, frmCommASTM);
  //  Application.CreateForm(TfrmLogin, frmLogin);
//  if (frmLogin.ShowModal = mrOk) then begin
        Application.CreateForm(TdmParametrosASTM, dmParametrosASTM);
        Application.Run;
//      end
//      else begin
//        Application.Terminate;
//      end;
//    finally
//  		frmLogin.Free;
//    end;
  end;
end.


