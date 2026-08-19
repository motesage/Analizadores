object frmCommHL7: TfrmCommHL7
  Left = 196
  Top = 292
  BorderStyle = bsDialog
  Caption = 'Interfaz de comunicaciones HL7'
  ClientHeight = 630
  ClientWidth = 596
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
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
    Height = 630
    Align = alClient
    BevelOuter = bvSpace
    BorderStyle = bsSingle
    TabOrder = 0
    object Panel2: TPanel
      Left = 1
      Top = 33
      Width = 590
      Height = 471
      Align = alClient
      TabOrder = 0
      object Splitter1: TSplitter
        Left = 1
        Top = 329
        Width = 588
        Height = 3
        Cursor = crVSplit
        Align = alTop
      end
      object memFiles: TMemo
        Left = 176
        Top = 23
        Width = 185
        Height = 89
        TabOrder = 0
        Visible = False
      end
      object memOutput: TMemo
        Left = 1
        Top = 1
        Width = 588
        Height = 328
        Align = alTop
        PopupMenu = PopupMenu1
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
      end
      object memMsgs: TMemo
        Left = 1
        Top = 332
        Width = 588
        Height = 138
        Align = alClient
        Color = clMoneyGreen
        PopupMenu = PopupMenu1
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 2
      end
    end
    object Panel3: TPanel
      Left = 1
      Top = 1
      Width = 590
      Height = 32
      Align = alTop
      TabOrder = 1
      object Label1: TLabel
        Left = 11
        Top = 5
        Width = 37
        Height = 13
        Caption = 'Entrada'
      end
    end
    object Panel4: TPanel
      Left = 1
      Top = 504
      Width = 590
      Height = 121
      Align = alBottom
      TabOrder = 2
      object memData: TMemo
        Left = 1
        Top = 1
        Width = 588
        Height = 119
        Align = alClient
        Color = 13490933
        PopupMenu = PopupMenu1
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 104
    Top = 176
    object Guarda2: TMenuItem
      Caption = 'Guarda'
    end
  end
end
