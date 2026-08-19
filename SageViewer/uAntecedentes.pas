unit uAntecedentes;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  RxstrUtils, uSage3ToDelphi, RxDateUtil, Dialogs, StdCtrls, Grids, DBGrids, DB,
  udmHistorias, udmBoletas, udmLineas, udmLinDet, udmDeterminaciones,
  udmNomenclador, udmSintomas, Buttons, ComCtrls, ExtCtrls, DBCtrls, Mask,
  wwdbedit, Wwdotdot, Wwdbcomb;

type
  TfrmMiraAntecedentes = class(TForm)
    memHHCC: TRichEdit;
    memBoleta: TRichEdit;
    memResult: TRichEdit;
    Panel1: TPanel;
    Label3: TLabel;
    edtHHCC: TEdit;
    Label1: TLabel;
    edtEmpresa: TEdit;
    btnConsultar: TBitBtn;
    btnAnterior: TBitBtn;
    btnSalir: TBitBtn;
    edtLista: TwwDBComboBox;
    procedure FormCreate(Sender: TObject);
    procedure btnSalirClick(Sender: TObject);
    procedure btnConsultarClick(Sender: TObject);
    procedure btnSigClick(Sender: TObject);
    procedure BtnAntClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure btnAnteriorClick(Sender: TObject);
    procedure edtListaCloseUp(Sender: TwwDBComboBox; Select: Boolean);
  private
    procedure PoneHistoriaRaf(Hist: trecHistoria);
    procedure BuscaBoleta(Bol: integer);
    procedure PoneBoletaRaf(Bol: trecBoleta);
    procedure MuestraHHCC;
    procedure LimpiaMemos;
    procedure PoneResultados(Boleta, RecReng, Lineas: integer);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMiraAntecedentes: TfrmMiraAntecedentes;

implementation

uses udmParamLab, SgBtrDataSet;

var
	btrFileBoletas, btrFileHHCC: tBtrDataSet;
  boletaAnterior: integer;

{$R *.dfm}

procedure TfrmMiraAntecedentes.FormCreate(Sender: TObject);
begin
	btrFileHHCC := tBtrDataSet.Create(self);
 		btrFileHHCC.TableName := appPars.PathArchivos + 'analis5.ind';
		btrFileHHCC.KeyNUmber := 0;
    btrFileHHCC.BtrReadOnly := true;
  	btrFileHHCC.Open;

	btrFileBoletas := tBtrDataSet.Create(self);
		btrFileBoletas.TableName := appPars.PathArchivos + 'analis4.ind';
		btrFileBoletas.KeyNUmber := 0;
    btrFileHHCC.BtrReadOnly := true;
  	btrFileBoletas.Open;
end;

procedure TfrmMiraAntecedentes.BuscaBoleta(Bol: integer);
var
  RecBol: integer;
  Boleta: trecBoleta;
begin
  btrFileBoletas.FieldByname('empresa').AsString := edtEmpresa.text;
  btrFileBoletas.FieldByname('boleta').AsInteger := Bol;
  if btrFileBoletas.BtrLocate(0,0,4) then begin
    RecBol := btrFileBoletas.FieldByName('Registro').AsInteger;
    Boleta := dmBoletas.GetRecord(RecBol);
    if Boleta.Estado = '*' then begin
      PoneBoletaRaf(Boleta);
			edtLista.items.add(inttostr(Boleta.NroBol) + ' del ' + datetostr(Boleta.Fecha));
      edtLista.itemIndex := edtlista.Items.Count -1;
      edtLista.Repaint;
    end
    else begin
      memHHCC.lines.add('Boleta dada de BAJA !!!');
    end;
  end
  else begin
		LimpiaMemos;
    memResult.lines.add('No hay mas antecedentes disponibles (SORRY!)');
  end;
end;

procedure TfrmMiraAntecedentes.PoneHistoriaRaf(Hist: trecHistoria);
begin
  with memHHCC do begin
    SelAttributes.Color := clRed;
    lines.add('Paciente: ' + Hist.Nombre + '  O.Social: ' + Hist.Codos);
    SelAttributes.Color := clBlack;
    lines.add('Num Afil: ' + Hist.NuAf +  '            Sexo: ' + Hist.Sexo + ' Edad: '+ inttostr(edad(Hist.FeNac)));
    lines.add('Domicilio: ' + Hist.Direccion + ' Telefono: ' + Hist.Telefono);
    lines.add('Ultima Boleta: ' + inttostr(Hist.Boleta) + ' Del : ' + datetimetostr(Hist.FechBol));
  end;    // with
end;

procedure TfrmMiraAntecedentes.PoneBoletaRaf(Bol: trecBoleta);
var
  sint: tRecSintomas;
begin
  limpiamemos;
  with memBoleta do begin
    SelAttributes.Color := clBlue;
    SelAttributes.Height := SelAttributes.Height + 2;

    lines.add('Boleta: ' + inttostr(Bol.NroBol) + ' del ' + datetimetostr(Bol.Fecha));
    lines.add('Médico: ' + Bol.Medico);
    if  Bol.RecSint > 0 then begin
      sint := dmSintomas.GetRecord(bol.RecSint);
      if trim(sint.sint1) <> '' then begin
        SelAttributes.Color := clBlue;
        lines.add('Diagnostico  : ' + sint.sint1);
      end;
      if trim(sint.sint2) <> '' then begin
        SelAttributes.Color := clBlue;
        lines.add('             : ' + sint.sint2);
      end;
      if trim(sint.sint3) <> '' then begin
        SelAttributes.Color := clBlue;
        lines.add('Observaciones: ' + sint.sint3);
      end;

    end;
    SelAttributes.Color := clBlack;
    lines.add('Boleta anterior: ' + inttostr(Bol.AntBol) + ' Del : ' + datetimetostr(Bol.antFecha));

    boletaAnterior := Bol.AntBol;
    btnAnterior.enabled := (BoletaAnterior > 0);

  end;    // with

  if Bol.RecReng > 0 then begin
    PoneResultados(Bol.NroBol, Bol.RecReng, Bol.Nulineas);
  end
  else begin
    memResult.lines.add('Sin resultados');
  end;

end;

procedure TfrmMiraAntecedentes.LimpiaMemos;
begin
  memBoleta.clear;
  memResult.clear;
end;

procedure TfrmMiraAntecedentes.PoneResultados(Boleta, RecReng,Lineas: integer);
var
  j,k: Integer;
  linea: tRecLinea;
  linDet: tRecLineaDet;
  Deter: trecDeterminacion;
  Nomen: tRecNomenclador;
  obs: tRecSintomas;
begin
  for j := RecReng to (RecReng + Lineas - 1) do begin    // Iterate
    linea := dmLineas.GetRecord(j);
    if (linea.Boleta = boleta) then begin
      if linea.NuDet > 0 then begin
        memResult.SelAttributes.Color := clRed;
        Nomen := dmNomenclador.GetRecord(linea.RecNom);
        memResult.Lines.add(Nomen.Analisis);
        for k := linea.RecDet to (linea.RecDet + linea.NuDet - 1) do begin    // Iterate
          LinDet := dmLinDet.GetRecord(k);
          if (linDet.Boleta = boleta) then begin
            if (linDet.RecMaestDet > 0) then begin
              Deter := dmDeterminaciones.GetRecord(linDet.RecMaestDet);
              if LinDet.RecordObs > 0 then begin
                obs := dmSintomas.GetRecord(LinDet.RecordObs);
                memResult.SelAttributes.Color := clBlack;
                memResult.Lines.add(copy(Deter.Determinacion,1,30) + ':' + obs.sint1);
                if trim(obs.sint2)<>''  then begin
                  memResult.Lines.add('                              :' + obs.sint2);
                end;
                if trim(obs.sint3)<>''  then begin
                  memResult.Lines.add('                              :' + obs.sint3);
                end;
              end
              else begin
                memResult.SelAttributes.Color := clBlack;
                memResult.Lines.add(copy(Deter.Determinacion,1,30) + ':' + lindet.Resultado);
              end;
            end;
          end;
        end;    // for
      end;
    end;
  end;
end;

procedure TfrmMiraAntecedentes.btnSalirClick(Sender: TObject);
begin
  close;
end;

procedure TfrmMiraAntecedentes.btnConsultarClick(Sender: TObject);
begin
  if edtHHCC.text <> '' then begin
		edtLista.items.Clear;
    memHHCC.clear;
    memBoleta.clear;
		btrFileHHCC.FieldByname('hicli').AsInteger := strtointDef(edtHHCC.text,0);
		if btrFileHHCC.BtrLocate(1,25,28) then begin  // Busco Btrieve con Clave = 1)
      muestraHHCC;
    end
    else begin
      memHHCC.lines.add('No existe !');
    end;
  end
  else begin
    ShowMessage('Poné una Historia Clínica, chei !!');
  end;
end;

procedure TfrmMiraAntecedentes.MuestraHHCC;
var
  RecHist, RecBol: integer;
  Boleta: trecBoleta;
  Historia: trecHistoria;
begin
  edtHHCC.text := inttostr(btrFileHHCC.FieldByName('Hicli').AsInteger);
  RecHist := btrFileHHCC.FieldByName('Registro').AsInteger;
  Historia := dmHistorias.GetRecord(RecHist);
  if Historia.Estado = '*' then begin
    PoneHistoriaRaf(Historia);
    if Historia.Boleta >0 then begin
       BuscaBoleta(Historia.Boleta);
    end;
  end
  else begin
    memHHCC.clear;
    LimpiaMemos;
    memHHCC.lines.add('Histora dada de BAJA !!!');
  end;
end;

procedure TfrmMiraAntecedentes.btnSigClick(Sender: TObject);
begin
  if btrFileHHCC.BtrGetNext then begin  // Busco Btrieve con Clave = 1)
    muestraHHCC;
  end
  else begin
    memHHCC.clear;
    LimpiaMemos;
    memHHCC.lines.add('No existe !');
  end;
end;

procedure TfrmMiraAntecedentes.BtnAntClick(Sender: TObject);
begin
  if btrFileHHCC.BtrGetPrevious then begin  // Busco Btrieve con Clave = 1)
    muestraHHCC;
  end
  else begin
    LimpiaMemos;
    memHHCC.lines.add('No existe !');
  end;
end;

procedure TfrmMiraAntecedentes.Button1Click(Sender: TObject);
begin
  // DataSource1.dataset := dmLineas.tblLineasRaf;
end;

procedure TfrmMiraAntecedentes.btnAnteriorClick(Sender: TObject);
begin
  buscaBoleta(boletaAnterior);
end;

procedure TfrmMiraAntecedentes.edtListaCloseUp(Sender: TwwDBComboBox;
  Select: Boolean);
begin
  buscaBoleta(strtoint(extractword(1,edtLista.text,[' '])));
end;

end.
