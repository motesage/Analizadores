object frmMain: TfrmMain
  Left = 192
  Top = 107
  Width = 940
  Height = 670
  Caption = 'SageLab_Comm_Analizer - ABL90'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 21
    Width = 24
    Height = 13
    Caption = 'Port:'
  end
  object Label2: TLabel
    Left = 648
    Top = 21
    Width = 179
    Height = 13
    Caption = 'Config: ABL90.INI junto al ejecutable'
  end
  object Label3: TLabel
    Left = 368
    Top = 21
    Width = 42
    Height = 13
    Caption = 'Framing:'
  end
  object Label4: TLabel
    Left = 16
    Top = 51
    Width = 38
    Height = 13
    Caption = 'Output:'
  end
  object Label5: TLabel
    Left = 648
    Top = 51
    Width = 220
    Height = 13
    Caption = 'Archivos: ABL90_yyyymmdd_hhnnss_zzz.RES'
  end
  object MemoLog: TMemo
    Left = 8
    Top = 80
    Width = 905
    Height = 545
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
  end
  object btnStart: TButton
    Left = 184
    Top = 16
    Width = 75
    Height = 25
    Caption = 'Start'
    Enabled = False
    TabOrder = 1
    OnClick = btnStartClick
  end
  object btnStop: TButton
    Left = 272
    Top = 16
    Width = 75
    Height = 25
    Caption = 'Stop'
    Enabled = False
    TabOrder = 2
    OnClick = btnStopClick
  end
  object edtPort: TEdit
    Left = 56
    Top = 18
    Width = 97
    Height = 21
    Enabled = False
    TabOrder = 3
    Text = '5655'
  end
  object chkOnlyAnalyzer: TCheckBox
    Left = 648
    Top = 0
    Width = 145
    Height = 17
    Caption = 'Log solo analizador'
    Checked = True
    Enabled = False
    State = cbChecked
    TabOrder = 4
    OnClick = chkOnlyAnalyzerClick
  end
  object cmbFraming: TComboBox
    Left = 416
    Top = 17
    Width = 205
    Height = 21
    Style = csDropDownList
    Enabled = False
    ItemHeight = 13
    TabOrder = 5
    OnChange = cmbFramingChange
  end
  object chkAutoACK: TCheckBox
    Left = 800
    Top = 0
    Width = 97
    Height = 17
    Caption = 'Auto ACK'
    Checked = True
    Enabled = False
    State = cbChecked
    TabOrder = 6
    OnClick = chkAutoACKClick
  end
  object chkLogASC: TCheckBox
    Left = 184
    Top = 48
    Width = 97
    Height = 17
    Caption = 'Log ASC'
    Checked = True
    Enabled = False
    State = cbChecked
    TabOrder = 7
    OnClick = chkLogASCClick
  end
  object chkLogHEX: TCheckBox
    Left = 280
    Top = 48
    Width = 97
    Height = 17
    Caption = 'Log HEX'
    Enabled = False
    TabOrder = 8
    OnClick = chkLogHEXClick
  end
  object edtOutFolder: TEdit
    Left = 72
    Top = 48
    Width = 105
    Height = 21
    Enabled = False
    TabOrder = 9
    Text = 'RES'
  end
end
