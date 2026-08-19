unit udmHistorias;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	Db, DBTables, uSage3ToDelphi, wwDialog, wwidlg, Wwintl, RxFileUtil,
	strUtils,SgRafDataSet;

type

	trecHistoria = record
    Estado: string;
    Hicli: integer;
    Nombre: string;
    Codos: string;
    NuAf: string;
    FeNac: tDateTime;
    Sexo: string;
    FechBol: tDateTime;
    Boleta: integer;
    Direccion: string;
    Telefono: string;
	end;

	TdmHistorias = class(TDataModule)
		procedure dmHistoriasCreate(Sender: TObject);
		procedure dmHistoriasDestroy(Sender: TObject);
	private
		tblHistoriasRaf: tRafDataSet;
	public
		function LargoHistoriasRaf: integer;
    function GetRecord(const Registro: Integer): tRecHistoria;
	end;

var
	dmHistorias: TdmHistorias;

implementation

uses udmParamLab;

{$R *.DFM}

procedure TdmHistorias.dmHistoriasCreate(Sender: TObject);
begin
	tblHistoriasRaf := tRafDataSet.Create(self);
	tblHistoriasRaf.TableName := appPars.PathArchivos + 'analis5.raf';
	tblHistoriasRaf.IniName := appPars.PathArchivos + 'analis5.ini';
	tblHistoriasRaf.Open;
end;

procedure TdmHistorias.dmHistoriasDestroy(Sender: TObject);
begin
	tblHistoriasRaf.close;
end;

function TdmHistorias.LargoHistoriasRaf: integer;
begin
	if not tblHistoriasRaf.Active then begin
		tblHistoriasRaf.Open;
  end;
	result := tblHistoriasRaf.recordCount;
end;    //

function TdmHistorias.GetRecord(const Registro: Integer): tRecHistoria;
begin
	result.Estado := '@';  // para indicar que no la encontró
	if ((Registro > 0) and tblHistoriasRaf.Active) then
		begin
			try
				tblHistoriasRaf.GotoRecord(Registro);
				with Result do begin
					Estado := tblHistoriasRaf.FieldByName('Estado').AsString;
					Hicli := tblHistoriasRaf.FieldByName('Hicli').AsInteger;
          Nombre:= tblHistoriasRaf.FieldByName('Nombre').AsString;
          Codos:= tblHistoriasRaf.FieldByName('CodOs').AsString;
          NuAf:= tblHistoriasRaf.FieldByName('Nuaf').AsString;
          FeNac:= LabDn1(tblHistoriasRaf.FieldByName('FeNac').AsInteger);
          Sexo := tblHistoriasRaf.FieldByName('Sexo').AsString;
          FechBol:= Dn1(tblHistoriasRaf.FieldByName('FechBol').AsInteger);
          Boleta:= tblHistoriasRaf.FieldByName('Boleta').AsInteger;
          Direccion:= tblHistoriasRaf.FieldByName('Direccion').AsString;
          Telefono:= tblHistoriasRaf.FieldByName('Telefono').AsString;
				end;    // with
			except
				Result.Estado := '@';
			end;
		end
	else begin
				Result.Estado := '@';
	end;
end;

end.
