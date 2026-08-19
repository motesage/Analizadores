unit udmLinDet;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	Db, DBTables, uSage3ToDelphi,rxFileUtil, wwDialog, wwidlg, Wwintl,
	strUtils,SgRafDataSet;

type
	trecLineaDet = record
    Estado: string;
    Boleta: integer;
    CodNom: string;
    Norden: integer;
    Resultado: string;
    ListaEmitida: string;
    ProtocoloEmitido: string;
    RecordObs: integer;
    Multiplo: integer;
    Abreviatura: string;
    RecArea: integer;
    RecMaestDet: integer;
	end;

	TdmLinDet = class(TDataModule)
		procedure dmLinDetCreate(Sender: TObject);
		procedure dmLinDetDestroy(Sender: TObject);
	private
		tblLinDetRaf: tRafDataSet;
	public
		function LargoLinDetRaf: integer;
    function GetRecord(const Registro: Integer): tRecLineaDet;
	end;

var
	dmLinDet: TdmLinDet;

implementation

uses udmParamLab;

{$R *.DFM}

procedure TdmLinDet.dmLinDetCreate(Sender: TObject);
begin
	tblLinDetRaf := tRafDataSet.Create(self);
	tblLinDetRaf.TableName := appPars.PathArchivos + 'analis4c.raf';
	tblLinDetRaf.IniName := appPars.PathArchivos + 'analis4c.ini';
	tblLinDetRaf.Open;
end;

procedure TdmLinDet.dmLinDetDestroy(Sender: TObject);
begin
	tblLinDetRaf.close;
end;

function TdmLinDet.LargoLinDetRaf: integer;
begin
	if not tblLinDetRaf.Active then begin
		tblLinDetRaf.Open;
  end;
	result := tblLinDetRaf.recordCount;
end;    //

function TdmLinDet.GetRecord(const Registro: Integer): tRecLineaDet;
begin
	result.Estado := '@';  // para indicar que no la encontró
	if ((Registro > 0) and tblLinDetRaf.Active) then
		begin
			try
				tblLinDetRaf.GotoRecord(Registro);
				with Result do begin
					Estado := tblLinDetRaf.FieldByName('Estado').AsString;
					Boleta := tblLinDetRaf.FieldByName('Boleta').AsInteger;
          CodNom:= tblLinDetRaf.FieldByName('CodNom').AsString;
          Norden:= tblLinDetRaf.FieldByName('Norden').AsInteger;
          Resultado:= tblLinDetRaf.FieldByName('Resultado').AsString;
          ListaEmitida:= tblLinDetRaf.FieldByName('ListaEmitida').AsString;
          ProtocoloEmitido := tblLinDetRaf.FieldByName('ProtocoloEmitido').AsString;
          RecordObs:= tblLinDetRaf.FieldByName('RecordObs').AsInteger;
          Multiplo:= tblLinDetRaf.FieldByName('Multiplo').AsInteger;
          Abreviatura:= tblLinDetRaf.FieldByName('Abreviatura').AsString;
          RecArea:= tblLinDetRaf.FieldByName('RecArea').AsInteger;
          RecMaestDet:= tblLinDetRaf.FieldByName('RecMaestDet').AsInteger;
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
