unit udmParamLab;
{ Esta unidad se ocupa del mantenimiento del archivo INI de parámetros
}

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	IniFiles, RxFileUtil;

const
	cIniFilename = 'SageLab.ini';	//archivo de inicializacion

type
	tParams = record
		Empresa: string;        //nombre de la empresa
		PathArchivos: string;   // Path completo del directorio de tablas del LabNue
	end;

	TdmParametros = class(TDataModule)
			procedure dmParametrosCreate(Sender: TObject);
		private
				{ Private declarations }
		public
			{ Public declarations }
			procedure CargaIni(var Pars: tParams);
	end;
var
	dmParametros: TdmParametros;
	iniFile: TIniFile;
	AppPars: tParams;

implementation

{$R *.DFM}

procedure TdmParametros.CargaIni(var Pars: tParams);
var
	IniFilename, s: string;
begin
	try
		IniFileName := ExtractFilePath(Application.ExeName)+ cIniFileName;
		IniFile := TIniFile.Create(IniFileName);

		Pars.Empresa := IniFile.ReadString('Empresa','Nombre','SageLab');
		Pars.PathArchivos := normalDir(IniFile.ReadString('Generales','PathArchivos',''));

	finally
		IniFile.Free;
	end;
end;


procedure TdmParametros.dmParametrosCreate(Sender: TObject);
begin
	CargaIni(AppPars);
end;

end.
