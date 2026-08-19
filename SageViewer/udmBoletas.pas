unit udmBoletas;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	Db, DBTables, uSage3ToDelphi,rxFileUtil, wwDialog, wwidlg, Wwintl,
	strUtils,SgRafDataSet;

type

	trecBoleta = record
		Estado: string;
    Empresa: string;
		NroBol: integer;			//numero de Boleta
    Fecha: tDateTime;
    CodMed: integer;
    NumeroHHCC_CVD: string;
    Direccion: string;
    Telefono: string;
    RecSint: integer;
    NuLineas: integer;
    Nuaf_parte2: string;
    Senia_CVD: string;
    AutC: string;
    Fent1: tDateTime;
    Fent2: tDateTime;
    Edad: integer;
    Como: string;
    Nombre: string;
    Nuaf_Parte1: string;
    CodOs: string;
    RecReng: integer;
    Total: double;
    ImporteMedico: double;
    RecHHCC: integer;
    Sexo: string;
    Medico: string;
    TrajoReceta: string;
    fum: tDateTime;
    AntBol: integer;
    antFecha: tDateTime;
	end;

	TdmBoletas = class(TDataModule)
		procedure dmBoletasCreate(Sender: TObject);
		procedure dmBoletasDestroy(Sender: TObject);
	private
		tblBoletasRaf: tRafDataSet;
	public
		function LargoBoletasRaf: integer;
    function GetRecord(const Registro: Integer): tRecBoleta;
	end;

var
	dmBoletas: TdmBoletas;

implementation

uses udmParamLab;


{$R *.DFM}

procedure TdmBoletas.dmBoletasCreate(Sender: TObject);
begin
	tblBoletasRaf := tRafDataSet.Create(self);
	tblBoletasRaf.TableName := appPars.PathArchivos + 'analis4.raf';
	tblBoletasRaf.IniName := appPars.PathArchivos + 'analis4.ini';
	tblBoletasRaf.Open;
end;

procedure TdmBoletas.dmBoletasDestroy(Sender: TObject);
begin
	tblBoletasRaf.close;
end;

function TdmBoletas.LargoBoletasRaf: integer;
begin
	if not tblBoletasRaf.Active then begin
		tblBoletasRaf.Open;
  end;
	result := tblBoletasRaf.recordCount;
end;    //

function TdmBoletas.GetRecord(const Registro: Integer): tRecBoleta;
begin
	result.Estado := '@';  // para indicar que no la encontró
	if ((Registro > 0) and tblBoletasRaf.Active) then
		begin
			try
				tblBoletasRaf.GotoRecord(Registro);
				with Result do begin
					Estado := tblBoletasRaf.FieldByName('Estado').AsString;
					NroBol := tblBoletasRaf.FieldByName('Boleta').AsInteger;
          Empresa:= tblBoletasRaf.FieldByName('Empresa').AsString;
          Fecha:= Dn1(tblBoletasRaf.FieldByName('Fecha').AsInteger);
          CodMed := tblBoletasRaf.FieldByName('CodMed').AsInteger;
          NumeroHHCC_CVD:= tblBoletasRaf.FieldByName('NumeroHHCC_CVD').AsString;
          Direccion:= tblBoletasRaf.FieldByName('Direccion').AsString;
          Telefono:= tblBoletasRaf.FieldByName('Telefono').AsString;
          RecSint:= tblBoletasRaf.FieldByName('RecSint').AsInteger;
          NuLineas:= tblBoletasRaf.FieldByName('NuLineas').AsInteger;
          Nuaf_parte2 := tblBoletasRaf.FieldByName('Nuaf_Parte2').AsString;

          Senia_CVD := tblBoletasRaf.FieldByName('Senia_CVD').AsString;
          AutC := tblBoletasRaf.FieldByName('AutC').AsString;
          Fent1 := Dn1(tblBoletasRaf.FieldByName('Fent1').AsInteger);
          Fent2 := Dn1(tblBoletasRaf.FieldByName('Fent2').AsInteger);
          Edad := tblBoletasRaf.FieldByName('Edad').AsInteger;
          Como := tblBoletasRaf.FieldByName('Como').AsString;
          Nombre := tblBoletasRaf.FieldByName('Nombre').AsString;
          Nuaf_Parte1 := tblBoletasRaf.FieldByName('Nuaf_Parte1').AsString;
          CodOs := tblBoletasRaf.FieldByName('Codos').AsString;
          RecReng := tblBoletasRaf.FieldByName('RecReng').AsInteger;
          total := tblBoletasRaf.FieldByName('total').AsFloat;
          ImporteMedico := tblBoletasRaf.FieldByName('ImporteMedico').AsFloat;
          RecHHCC := tblBoletasRaf.FieldByName('RecHHCC').AsInteger;
          Sexo := tblBoletasRaf.FieldByName('Sexo').AsString;
          Medico := tblBoletasRaf.FieldByName('Medico').AsString;
          TrajoReceta := tblBoletasRaf.FieldByName('TrajoReceta').AsString;
          fum := Dn1(tblBoletasRaf.FieldByName('Fum').AsInteger);
          AntBol := tblBoletasRaf.FieldByName('AntBol').AsInteger;
          antFecha := dn1(tblBoletasRaf.FieldByName('antFecha').AsInteger);
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
