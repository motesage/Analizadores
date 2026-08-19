object frmMain: TfrmMain
  Left = 192
  Top = 107
  Width = 860
  Height = 620
  Caption = 'HL7 Mini Server - Logs ASC/HEX'
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
    Width = 28
    Height = 13
    Caption = 'Port:'
  end
  object Label2: TLabel
    Left = 520
    Top = 21
    Width = 286
    Height = 13
    Caption = 'Logs: LogASC.txt y LogHEX.txt junto al ejecutable'
  end
  object MemoLog: TMemo
    Left = 8
    Top = 48
    Width = 825
    Height = 525
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
    Text = '5000'
  end
  object chkOnlyAnalyzer: TCheckBox
    Left = 368
    Top = 19
    Width = 145
    Height = 17
    Caption = 'Log solo analizador'
    TabOrder = 4
    OnClick = chkOnlyAnalyzerClick
  end
end
