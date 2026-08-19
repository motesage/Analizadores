unit udmParamsMindray;
{ Esta unidad se ocupa del mantenimiento del archivo INI de parámetros
}

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	IniFiles, JvFileUtil, OoMisc, AdPort, ExtCtrls;

const
	cIniFilename = 'mindray.ini';	//archivo de inicializacion

type
	tParams = record
    debug : boolean;
		Empresa: string;          //nombre de la empresa

		IP: string;

		GeneraLogServer: boolean;
		GeneraLogComm: boolean;

	end;


	TdmParametrosMindray = class(TDataModule)
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
	dmParametrosMindray: TdmParametrosMindray;
	iniFile: TIniFile;
	AppPars: tParams;

implementation

{$R *.DFM}
procedure TdmParametrosMindray.GrabaIni(Pars: tParams);
var
	j: Integer;
	IniFilename, s: string;
begin
	try
		IniFileName := ExtractFilePath(Application.ExeName)+ cIniFileName;
		IniFile := TIniFile.Create(IniFileName);

		IniFile.WriteString('Empresa','Nombre',AppPars.Empresa);

		IniFile.WriteString('Generales','IP', Pars.IP);

		IniFile.WriteBool('Generales','GeneraLogServer', Pars.GeneraLogServer);
		IniFile.WriteBool('Generales','GeneraLogComm', Pars.GeneraLogComm);
		IniFile.WriteBool('Generales','Debug', Pars.Debug);

		IniFile.UpdateFile;
	finally // wrap up
		IniFile.Free;
	end;    // try/finally
	CargaIni(AppPars);
end;


procedure TdmParametrosMindray.CargaIni(var Pars: tParams);
var
	IniFilename, s: string;
	j: integer;


begin
	try
		IniFileName := ExtractFilePath(Application.ExeName)+ cIniFileName;
		IniFile := TIniFile.Create(IniFileName);

    Pars.Empresa := IniFile.ReadString('Empresa','Nombre',Nulo.Empresa);

		// puerta serie
		Pars.IP := IniFile.ReadString('Generales','IP',Nulo.IP);

		Pars.Debug := IniFile.ReadBool('Generales','Debug', false);

		Pars.GeneraLogServer := IniFile.ReadBool('Generales','GeneraLogServer',Nulo.GeneraLogServer);
		Pars.GeneraLogComm := IniFile.ReadBool('Generales','GeneraLogComm',Nulo.GeneraLogComm);
	finally
		IniFile.Free;
	end;
end;


procedure TdmParametrosMindray.dmParametrosCreate(Sender: TObject);
begin
	CargaIni(AppPars);
end;

function TdmParametrosMindray.Nulo: tParams;
var
	j: Integer;
begin
	with Result do begin
		Empresa := 'Sage SRL';
		IP := '10.110.110.1';
    debug := false;
		GeneraLogServer := false;
		GeneraLogComm := false;
	end;    // with
end;


function ExisteDirectorio(strTarget: string; CrearSiNoExiste: boolean):boolean;
begin
	result := false;
	if DirExists(strTarget) then begin
		result:= true;
	end
	else begin
		if CrearSiNoExiste then begin
			ForceDirectories(strTarget);
			result := DirExists(strTarget);
		end;
	end;
end;


function AppPath: string;
begin
	AppPath := ExtractFilePath(ParamStr(0));
end;


end.
