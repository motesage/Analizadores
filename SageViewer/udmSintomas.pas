unit udmSintomas;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	Db, DBTables, uSage3ToDelphi,rxFileUtil, wwDialog, wwidlg, Wwintl,
	strUtils,SgRafDataSet;

type

	trecSintomas = record
    estado: string;
    boleta: integer;
    sint1: string;
    sint2: string;
    sint3: string;
    sint4: string;
    sint5: string;
	end;

	TdmSintomas = class(TDataModule)
		procedure dmSintomasCreate(Sender: TObject);
		procedure dmSintomasDestroy(Sender: TObject);
	private
	public
		tblSintomasRaf: tRafDataSet;
		function LargoSintomasRaf: integer;
    function GetRecord(const Registro: Integer): tRecSintomas;
	end;

var
	dmSintomas: TdmSintomas;

implementation

uses udmParamLab;

{$R *.DFM}

procedure TdmSintomas.dmSintomasCreate(Sender: TObject);
begin
	tblSintomasRaf := tRafDataSet.Create(self);
	tblSintomasRaf.TableName := appPars.PathArchivos + 'analis20.raf';
	tblSintomasRaf.IniName := appPars.PathArchivos + 'analis20.ini';
	tblSintomasRaf.Open;
end;

procedure TdmSintomas.dmSintomasDestroy(Sender: TObject);
begin
	tblSintomasRaf.close;
end;

function TdmSintomas.LargoSintomasRaf: integer;
begin
	if not tblSintomasRaf.Active then begin
		tblSintomasRaf.Open;
  end;
	result := tblSintomasRaf.recordCount;
end;    //

function TdmSintomas.GetRecord(const Registro: Integer): tRecSintomas;
begin
	result.Estado := '@';  // para indicar que no la encontró
	if ((Registro > 0) and tblSintomasRaf.Active) then
		begin
			try
				tblSintomasRaf.GotoRecord(Registro);
				with Result do begin
          boleta:= tblSintomasRaf.FieldByName('Boleta').AsInteger;
					sint1 := tblSintomasRaf.FieldByName('Sint1').AsString;
					sint2 := tblSintomasRaf.FieldByName('Sint2').AsString;
					sint3 := tblSintomasRaf.FieldByName('Sint3').AsString;
					sint4 := tblSintomasRaf.FieldByName('Sint4').AsString;
					sint5 := tblSintomasRaf.FieldByName('Sint5').AsString;
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
