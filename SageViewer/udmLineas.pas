unit udmLineas;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	Db, DBTables, uSage3ToDelphi,rxFileUtil, wwDialog, wwidlg, Wwintl,
	strUtils,SgRafDataSet;

type

	trecLinea = record
    Estado: string;
    Boleta: integer;
    CodNom: string;
    Observaciones: string;
    Aut: string;
    Muestra: string;
    FactOS: string;
    FactMed: string;
    Urg: string;
    RecNom: integer;
    NuDet: integer;
    RecDet: integer;
    Importe: real;
	end;

	TdmLineas = class(TDataModule)
		procedure dmLineasCreate(Sender: TObject);
		procedure dmLineasDestroy(Sender: TObject);
	private
	public
		tblLineasRaf: tRafDataSet;
		function LargoLineasRaf: integer;
    function GetRecord(const Registro: Integer): tRecLinea;
	end;

var
	dmLineas: TdmLineas;

implementation

uses udmParamLab;

{$R *.DFM}

procedure TdmLineas.dmLineasCreate(Sender: TObject);
begin
	tblLineasRaf := tRafDataSet.Create(self);
	tblLineasRaf.TableName :=  appPars.PathArchivos + 'analis4b.raf';
	tblLineasRaf.IniName :=  appPars.PathArchivos + 'analis4b.ini';
	tblLineasRaf.Open;
end;

procedure TdmLineas.dmLineasDestroy(Sender: TObject);
begin
	tblLineasRaf.close;
end;

function TdmLineas.LargoLineasRaf: integer;
begin
	if not tblLineasRaf.Active then begin
		tblLineasRaf.Open;
  end;
	result := tblLineasRaf.recordCount;
end;    //

function TdmLineas.GetRecord(const Registro: Integer): tRecLinea;
begin
	result.Estado := '@';  // para indicar que no la encontró
	if ((Registro > 0) and tblLineasRaf.Active) then
		begin
			try
				tblLineasRaf.GotoRecord(Registro);
				with Result do begin
					Estado := tblLineasRaf.FieldByName('Estado').AsString;
					Boleta := tblLineasRaf.FieldByName('Boleta').AsInteger;
          CodNom:= tblLineasRaf.FieldByName('CodNom').AsString;
          Observaciones:= tblLineasRaf.FieldByName('Observaciones').AsString;
          Aut:= tblLineasRaf.FieldByName('Aut').AsString;
          Muestra:= tblLineasRaf.FieldByName('Muestra').AsString;
          FactOS := tblLineasRaf.FieldByName('FactOs').AsString;
          FactMed:= tblLineasRaf.FieldByName('FactMed').AsString;
          Urg:= tblLineasRaf.FieldByName('Urg').AsString;
          RecNom:= tblLineasRaf.FieldByName('RecNom').AsInteger;
          NuDet:= tblLineasRaf.FieldByName('NuDet').AsInteger;
          RecDet:= tblLineasRaf.FieldByName('RecDet').AsInteger;
          Importe:= tblLineasRaf.FieldByName('Importe').AsFloat;
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
