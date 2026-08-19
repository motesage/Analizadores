unit udmParamsASTM;
{ Esta unidad se ocupa del mantenimiento del archivo INI de parámetros
}

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	IniFiles, OoMisc, JvJCLutils, AdPort, ExtCtrls;

const
	cIniFilename = 'CommASTM.ini';	//archivo de inicializacion

type
	tParams = record
    debug : boolean;
		Empresa: string;          //nombre de la empresa
		ComPort: integer;
		Speed: integer;
		GeneraLogComm: boolean;
	end;


	TdmParametrosASTM = class(TDataModule)
    ApdComPort1: TApdComPort;
			procedure dmParametrosCreate(Sender: TObject);
		private
				{ Private declarations }
		public
			{ Public declarations }
			function Nulo: tParams;
			procedure GrabaIni(Pars: tParams);
			procedure CargaIni(var Pars: tParams);
	end;

	function AppPath: string;
	function ExisteDirectorio(strTarget: string; CrearSiNoExiste: boolean):boolean;



var
	dmParametrosASTM: TdmParametrosASTM;
	iniFile: TIniFile;
	AppPars: tParams;

implementation

{$R *.DFM}
procedure TdmParametrosASTM.GrabaIni(Pars: tParams);
var
	j: Integer;
	IniFilename, s: string;
begin
	try
		IniFileName := ExtractFilePath(Application.ExeName)+ cIniFileName;
		IniFile := TIniFile.Create(IniFileName);

		IniFile.WriteString('Empresa','Nombre',AppPars.Empresa);

		// puerta serie
		IniFile.WriteInteger('SerialPort','Com', Pars.ComPort);
		IniFile.WriteInteger('SerialPort','Speed', Pars.Speed);


		IniFile.WriteBool('Generales','GeneraLogComm', Pars.GeneraLogComm);
		IniFile.WriteBool('Generales','Debug', Pars.Debug);

		IniFile.UpdateFile;
	finally // wrap up
		IniFile.Free;
	end;    // try/finally
	CargaIni(AppPars);
end;


procedure TdmParametrosASTM.CargaIni(var Pars: tParams);
var
	IniFilename, s: string;
	j: integer;


begin
	try
		IniFileName := ExtractFilePath(Application.ExeName)+ cIniFileName;
		IniFile := TIniFile.Create(IniFileName);

    Pars.Empresa := IniFile.ReadString('Empresa','Nombre',Nulo.Empresa);

		// puerta serie
		Pars.ComPort := IniFile.ReadInteger('SerialPort','Com',Nulo.ComPort);
		Pars.Speed := IniFile.ReadInteger('SerialPort','Speed',Nulo.Speed);
		Pars.Debug := IniFile.ReadBool('Generales','Debug', false);
		Pars.GeneraLogComm := IniFile.ReadBool('Generales','GeneraLogComm',Nulo.GeneraLogComm);
	finally
		IniFile.Free;
	end;
end;


procedure TdmParametrosASTM.dmParametrosCreate(Sender: TObject);
begin
	CargaIni(AppPars);
end;

function TdmParametrosASTM.Nulo: tParams;
var
	j: Integer;
begin
	with Result do begin
		Empresa := 'Sage SRL';
		ComPort := 0;
		Speed :=  0;
    debug := false;
		GeneraLogComm := false;
	end;    // with
end;


function ExisteDirectorio(strTarget: string; CrearSiNoExiste: boolean):boolean;
begin
	result := false;
	if DirectoryExists(strTarget) then begin
		result:= true;
	end
	else begin
		if CrearSiNoExiste then begin
			ForceDirectories(strTarget);
			result := DirectoryExists(strTarget);
		end;
	end;
end;


function AppPath: string;
begin
	AppPath := ExtractFilePath(ParamStr(0));
end;


end.
