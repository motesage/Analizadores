object frmCommASTM: TfrmCommASTM
  Left = 282
  Top = 181
  BorderStyle = bsDialog
  Caption = 'Interfaz de comunicaciones ASTM 1381/1394'
  ClientHeight = 538
  ClientWidth = 595
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
    Width = 595
    Height = 538
    Align = alClient
    BevelOuter = bvSpace
    BorderStyle = bsSingle
    TabOrder = 0
    object Label1: TLabel
      Left = 5
      Top = 5
      Width = 77
      Height = 13
      Caption = 'Pedidos al Ruby'
    end
    object Label3: TLabel
      Left = 5
      Top = 114
      Width = 65
      Height = 13
      Caption = 'LIS <=> Ruby'
    end
    object Label2: TLabel
      Left = 5
      Top = 468
      Width = 45
      Height = 13
      Caption = 'Mensajes'
    end
    object memInput: TMemo
      Left = 5
      Top = 20
      Width = 575
      Height = 89
      PopupMenu = PopupMenu1
      TabOrder = 0
    end
    object memOutput: TMemo
      Left = 5
      Top = 128
      Width = 575
      Height = 337
      PopupMenu = PopupMenu1
      TabOrder = 1
    end
    object memFiles: TMemo
      Left = 376
      Top = 96
      Width = 185
      Height = 89
      TabOrder = 2
      Visible = False
    end
    object memMsgs: TMemo
      Left = 5
      Top = 485
      Width = 575
      Height = 45
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
