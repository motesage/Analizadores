object frmCommASTM: TfrmCommASTM
  Left = 282
  Top = 181
  BorderStyle = bsDialog
  Caption = 'Interfaz de comunicaciones ASTM 1381/1394'
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
      Height = 245
      PopupMenu = PopupMenu1
      TabOrder = 0
    end
    object memOutput: TMemo
      Left = 10
      Top = 268
      Width = 575
      Height = 181
      PopupMenu = PopupMenu1
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
    object memMsgs: TMemo
      Left = 10
      Top = 453
      Width = 575
      Height = 78
      PopupMenu = PopupMenu1
      ScrollBars = ssVertical
      TabOrder = 3
    end
  end
  object mnuMain: TMainMenu
    Left = 272
    Top = 72
    object Archivo1: TMenuItem
      Caption = 'Archivo'
      object guarda1: TMenuItem
        Caption = 'guarda'
        OnClick = guarda1Click
      end
    end
    object N1: TMenuItem
      Caption = '?'
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 104
    Top = 176
    object Guarda2: TMenuItem
      Caption = 'Guarda'
      OnClick = Guarda2Click
    end
  end
end
