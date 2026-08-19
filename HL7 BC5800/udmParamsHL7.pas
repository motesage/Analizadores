unit udmParamsHL7;
{ Esta unidad se ocupa del mantenimiento del archivo INI de parámetros
}

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	IniFiles, OoMisc, JvJCLutils, AdPort, ExtCtrls;

const
	cIniFilename = 'CommHL7_BC5800.ini';	//archivo de inicializacion

type
	tParams = record
    debug : boolean;
		Empresa: string;          //nombre de la empresa
		Port: integer;
    IP: String;
		GeneraLogServer: boolean;
		GeneraLogComm: boolean;

	end;


	TdmParametrosHL7 = class(TDataModule)
			procedure dmParametrosCreate(Sender: TObject);
		public
			{ Public declarations }
			function Nulo: tParams;
			procedure GrabaIni(Pars: tParams);
			procedure CargaIni(var Pars: tParams);
	end;

	function AppPath: string;
	function ExisteDirectorio(strTarget: string; CrearSiNoExiste: boolean):boolean;



var
	dmParametrosHL7: TdmParametrosHL7;
	iniFile: TIniFile;
	AppPars: tParams;

implementation

{$R *.DFM}
procedure TdmParametrosHL7.GrabaIni(Pars: tParams);
var
	IniFilename: string;
begin
	try
		IniFileName := ExtractFilePath(Application.ExeName)+ cIniFileName;
		IniFile := TIniFile.Create(IniFileName);

		IniFile.WriteString('Empresa','Nombre',AppPars.Empresa);

		IniFile.WriteBool('Generales','GeneraLogComm', Pars.GeneraLogComm);
		IniFile.WriteBool('Generales','Debug', Pars.Debug);
		IniFile.WriteInteger('Generales','Port', Pars.Port);
		IniFile.WriteString('Generales','IP',AppPars.IP);

		IniFile.UpdateFile;
	finally // wrap up
		IniFile.Free;
	end;    // try/finally
	CargaIni(AppPars);
end;


procedure TdmParametrosHL7.CargaIni(var Pars: tParams);
var
	IniFilename: string;


begin
	try
		IniFileName := ExtractFilePath(Application.ExeName)+ cIniFileName;
		IniFile := TIniFile.Create(IniFileName);

    Pars.Empresa := IniFile.ReadString('Empresa','Nombre',Nulo.Empresa);

		Pars.IP := IniFile.ReadString('Generales','IP',Nulo.IP);
		Pars.Port := IniFile.ReadInteger('Generales','Port',Nulo.Port);
		Pars.Debug := IniFile.ReadBool('Generales','Debug', false);

		Pars.GeneraLogServer := IniFile.ReadBool('Generales','GeneraLogServer',Nulo.GeneraLogServer);
		Pars.GeneraLogComm := IniFile.ReadBool('Generales','GeneraLogComm',Nulo.GeneraLogComm);
	finally
		IniFile.Free;
	end;
end;


procedure TdmParametrosHL7.dmParametrosCreate(Sender: TObject);
begin
	CargaIni(AppPars);
end;

function TdmParametrosHL7.Nulo: tParams;
begin
	with Result do begin
		Empresa := 'Sage SRL';
		Port :=  0;
    IP := '127.0.0.1';
    debug := false;
		GeneraLogServer := false;
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
