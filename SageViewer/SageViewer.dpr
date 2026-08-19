program SageViewer;

uses
  Forms,
  uAntecedentes in 'uAntecedentes.pas' {frmMiraAntecedentes},
  SgBtrDataSet in 'SgBtrDataSet.pas',
  btrapi32 in 'btrapi32.pas',
  uRafInterface in 'uRafInterface.pas',
  SgRafDataSet in 'SgRafDataSet.pas',
  btrconst in 'btrconst.pas',
  udmBoletas in 'udmBoletas.pas' {dmBoletas: TDataModule},
  uSage3ToDelphi in 'uSage3ToDelphi.pas',
  udmHistorias in 'udmHistorias.pas' {dmHistorias: TDataModule},
  udmLineas in 'udmLineas.pas' {dmLineas: TDataModule},
  udmLinDet in 'udmLinDet.pas' {dmLinDet: TDataModule},
  udmDeterminaciones in 'udmDeterminaciones.pas' {dmDeterminaciones: TDataModule},
  udmNomenclador in 'udmNomenclador.pas' {dmNomenclador: TDataModule},
  udmSintomas in 'udmSintomas.pas' {dmSintomas: TDataModule},
  udmParamLab in 'udmParamLab.pas' {dmParametros: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TdmParametros, dmParametros);
  Application.CreateForm(TdmDeterminaciones, dmDeterminaciones);
  Application.CreateForm(TdmHistorias, dmHistorias);
  Application.CreateForm(TdmBoletas, dmBoletas);
  Application.CreateForm(TdmLineas, dmLineas);
  Application.CreateForm(TdmLinDet, dmLinDet);
  Application.CreateForm(TfrmMiraAntecedentes, frmMiraAntecedentes);
  Application.CreateForm(TdmNomenclador, dmNomenclador);
  Application.CreateForm(TdmSintomas, dmSintomas);
  Application.Run;
end.
