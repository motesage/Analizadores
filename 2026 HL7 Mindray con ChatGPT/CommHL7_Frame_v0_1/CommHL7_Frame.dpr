program CommHL7_Frame;

uses
  ExceptionLog,
  Forms,
  Windows,
  Controls,
  uCommHL7 in 'uCommHL7.pas' {frmCommHL7},
  udmParamsHL7 in 'udmParamsHL7.pas' {dmParametrosHL7: TDataModule},
  uCommBuffer in 'uCommBuffer.pas',
  rpVersionInfo in 'rpVersionInfo.pas',
  uHL7 in 'uHL7.pas',
  uLineFiles in 'uLineFiles.pas';

{$R *.res}
var
	hMutex: THandle;

begin
	//para que se ejecute una sola instancia del programa (MD4 Cap.20 p.913)
	hMutex := CreateMutex (nil, False, 'HL7UnaCopia');
	if WaitForSingleObject (hMutex, 0) <> wait_TimeOut then begin
    Application.Initialize;
    Application.Title := 'CommHL7 - Sage SRL - www.sage.com.ar';
    Application.CreateForm(TfrmCommHL7, frmCommHL7);
  Application.CreateForm(TdmParametrosHL7, dmParametrosHL7);
  Application.Run;
  end;
end.


