unit udmNomenclador;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	Db, DBTables, uSage3ToDelphi,rxFileUtil, wwDialog, wwidlg, Wwintl,
	strUtils,SgRafDataSet;

type

	trecNomenclador = record
    estado: string;
    Analisis: string;
	end;

	TdmNomenclador = class(TDataModule)
		procedure dmNomencladorCreate(Sender: TObject);
		procedure dmNomencladorDestroy(Sender: TObject);
	private
	public
		tblNomencladorRaf: tRafDataSet;
		function LargoNomencladorRaf: integer;
    function GetRecord(const Registro: Integer): tRecNomenclador;
	end;

var
	dmNomenclador: TdmNomenclador;

implementation

uses udmParamLab;


{$R *.DFM}

procedure TdmNomenclador.dmNomencladorCreate(Sender: TObject);
begin
	tblNomencladorRaf := tRafDataSet.Create(self);
	tblNomencladorRaf.TableName := appPars.PathArchivos + 'analis2.raf';
	tblNomencladorRaf.IniName := appPars.PathArchivos + 'analis2.ini';
	tblNomencladorRaf.Open;
end;

procedure TdmNomenclador.dmNomencladorDestroy(Sender: TObject);
begin
	tblNomencladorRaf.close;
end;

function TdmNomenclador.LargoNomencladorRaf: integer;
begin
	if not tblNomencladorRaf.Active then begin
		tblNomencladorRaf.Open;
  end;
	result := tblNomencladorRaf.recordCount;
end;    //

function TdmNomenclador.GetRecord(const Registro: Integer): tRecNomenclador;
begin
	result.Estado := '@';  // para indicar que no la encontró
	if ((Registro > 0) and tblNomencladorRaf.Active) then
		begin
			try
				tblNomencladorRaf.GotoRecord(Registro);
				with Result do begin
					Analisis := tblNomencladorRaf.FieldByName('Analisis').AsString;
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
