object frmCommHL7: TfrmCommHL7
  Left = 431
  Top = 295
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
  OnClose = FormClose
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
      Height = 551
      Align = alClient
      TabOrder = 0
      object Splitter1: TSplitter
        Left = 1
        Top = 441
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
        Height = 440
        Align = alTop
        PopupMenu = PopupMenu1
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
      end
      object memMsgs: TMemo
        Left = 1
        Top = 444
        Width = 588
        Height = 106
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
      object chkLog: TCheckBox
        Left = 256
        Top = 8
        Width = 97
        Height = 17
        Caption = 'Guarda LOG'
        TabOrder = 0
        OnClick = chkLogClick
      end
    end
    object Panel4: TPanel
      Left = 1
      Top = 584
      Width = 590
      Height = 41
      Align = alBottom
      TabOrder = 2
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 104
    Top = 176
    object Guarda2: TMenuItem
      Caption = 'Guarda'
    end
  end
  object LogHL7: TLogToFile
    LogFileName = 'LogHL7.Txt'
    OverwriteExistingFile = False
    ClearonCreate = False
    IncDateTime = True
    IncPrefix = False
    IncSeparator = True
    IncSuffix = False
    Separator = '*'
    DateTimeFormatStr = 'c'
    Left = 233
    Top = 153
  end
end
