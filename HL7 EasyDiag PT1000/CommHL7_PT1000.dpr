program CommHL7_PT1000;

uses
  ExceptionLog,
  Forms,
  Windows,
  Controls,
  uCommHL7_PT1000 in 'uCommHL7_PT1000.pas' {frmCommHL7_PT1000},
  udmParamsHL7 in 'udmParamsHL7.pas' {dmParametrosHL7: TDataModule},
  uCommBuffer in 'uCommBuffer.pas',
  rpVersionInfo in 'rpVersionInfo.pas',
  uHL7_PT1000 in 'uHL7_PT1000.pas',
  uLineFiles in 'uLineFiles.pas';

{$R *.res}
var
	hMutex: THandle;

begin
	//para que se ejecute una sola instancia del programa (MD4 Cap.20 p.913)
	hMutex := CreateMutex (nil, False, 'HL7_PT1000UnaCopia');
	if WaitForSingleObject (hMutex, 0) <> wait_TimeOut then begin
    Application.Initialize;
    Application.Title := 'CommHL7_PT1000 - Sage SRL - www.sage.com.ar';
    Application.CreateForm(TfrmCommHL7_PT1000, frmCommHL7_PT1000);
  Application.CreateForm(TdmParametrosHL7, dmParametrosHL7);
  Application.Run;
  end;
end.


