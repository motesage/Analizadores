object frmCommASTM_Arch2: TfrmCommASTM_Arch2
  Left = 321
  Top = 111
  BorderStyle = bsSingle
  Caption = 'Interfaz Architect plus i1000 (ASTM_Arch2) (C) Sage 2026'
  ClientHeight = 538
  ClientWidth = 596
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = mnuMain
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 596
    Height = 538
    Align = alClient
    BevelOuter = bvSpace
    BorderStyle = bsSingle
    TabOrder = 0
    object Label1: TLabel
      Left = 11
      Top = 5
      Width = 37
      Height = 13
      Caption = 'Entrada'
    end
    object Label2: TLabel
      Left = 11
      Top = 300
      Width = 31
      Height = 13
      Caption = 'Sallida'
    end
    object memInput: TMemo
      Left = 10
      Top = 20
      Width = 575
      Height = 275
      TabOrder = 0
    end
    object memOutput: TMemo
      Left = 10
      Top = 316
      Width = 575
      Height = 209
      TabOrder = 1
    end
    object memFiles: TMemo
      Left = 176
      Top = 144
      Width = 185
      Height = 89
      TabOrder = 2
      Visible = False
    end
  end
  object mnuMain: TMainMenu
    Left = 272
    Top = 72
    object Archivo1: TMenuItem
      Caption = 'Archivo'
    end
    object N1: TMenuItem
      Caption = '?'
    end
  end
end
