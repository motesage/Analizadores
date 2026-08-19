unit udmDeterminaciones;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	Db, DBTables, uSage3ToDelphi,rxFileUtil, wwDialog, wwidlg, Wwintl,
	strUtils,SgRafDataSet;

type

	trecDeterminacion = record
    estado: string;
    Determinacion: string;
	end;

	TdmDeterminaciones = class(TDataModule)
		procedure dmDeterminacionesCreate(Sender: TObject);
		procedure dmDeterminacionesDestroy(Sender: TObject);
	private
	public
		tblDeterminacionesRaf: tRafDataSet;
		function LargoDeterminacionesRaf: integer;
    function GetRecord(const Registro: Integer): tRecDeterminacion;
	end;

var
	dmDeterminaciones: TdmDeterminaciones;

implementation

uses udmParamLab;


{$R *.DFM}

procedure TdmDeterminaciones.dmDeterminacionesCreate(Sender: TObject);
begin
	tblDeterminacionesRaf := tRafDataSet.Create(self);
	tblDeterminacionesRaf.TableName := appPars.PathArchivos + 'analis3.raf';
	tblDeterminacionesRaf.IniName := appPars.PathArchivos + 'analis3.ini';
	tblDeterminacionesRaf.Open;
end;

procedure TdmDeterminaciones.dmDeterminacionesDestroy(Sender: TObject);
begin
	tblDeterminacionesRaf.close;
end;

function TdmDeterminaciones.LargoDeterminacionesRaf: integer;
begin
	if not tblDeterminacionesRaf.Active then begin
		tblDeterminacionesRaf.Open;
  end;
	result := tblDeterminacionesRaf.recordCount;
end;    //

function TdmDeterminaciones.GetRecord(const Registro: Integer): tRecDeterminacion;
begin
	result.Estado := '@';  // para indicar que no la encontró
	if ((Registro > 0) and tblDeterminacionesRaf.Active) then
		begin
			try
				tblDeterminacionesRaf.GotoRecord(Registro);
				with Result do begin
					Determinacion := tblDeterminacionesRaf.FieldByName('Determinacion').AsString;
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
