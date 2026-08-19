object frmMain: TfrmMain
  Left = 192
  Top = 107
  Width = 900
  Height = 640
  Caption = 'HL7 Mini Server - Framing MLLP / SOH-EOT'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
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
    Left = 600
    Top = 21
    Width = 210
    Height = 13
    Caption = 'Logs: LogASC.txt y LogHEX.txt junto al EXE'
  end
  object Label3: TLabel
    Left = 368
    Top = 21
    Width = 42
    Height = 13
    Caption = 'Framing:'
  end
  object MemoLog: TMemo
    Left = 8
    Top = 48
    Width = 865
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
    TabOrder = 1
    OnClick = btnStartClick
  end
  object btnStop: TButton
    Left = 272
    Top = 16
    Width = 75
    Height = 25
    Caption = 'Stop'
    TabOrder = 2
    OnClick = btnStopClick
  end
  object edtPort: TEdit
    Left = 56
    Top = 18
    Width = 97
    Height = 21
    TabOrder = 3
    Text = '5655'
  end
  object chkOnlyAnalyzer: TCheckBox
    Left = 600
    Top = 1
    Width = 145
    Height = 17
    Caption = 'Log solo analizador'
    TabOrder = 4
    OnClick = chkOnlyAnalyzerClick
  end
  object cmbFraming: TComboBox
    Left = 416
    Top = 17
    Width = 165
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 5
    OnChange = cmbFramingChange
  end
  object chkAutoACK: TCheckBox
    Left = 752
    Top = 1
    Width = 97
    Height = 17
    Caption = 'Auto ACK'
    Checked = True
    State = cbChecked
    TabOrder = 6
    OnClick = chkAutoACKClick
  end
end
