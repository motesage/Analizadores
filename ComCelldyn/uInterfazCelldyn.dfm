object frmCelldyn: TfrmCelldyn
  Left = 339
  Top = 193
  Width = 555
  Height = 646
  Caption = 'Interfaz Celldyn - SageLabWin (2021)'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object panel2: TPanel
    Left = 0
    Top = 0
    Width = 539
    Height = 608
    Align = alClient
    TabOrder = 0
    object AdTerminal1: TAdTerminal
      Left = 22
      Top = 235
      Width = 458
      Height = 183
      CaptureFile = 'APROTERM.CAP'
      Columns = 255
      ComPort = SerialPort
      Scrollback = False
      Color = clBlack
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clSilver
      Font.Height = -12
      Font.Name = 'Terminal'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      TabOrder = 0
      Visible = False
    end
    object memResult: TMemo
      Left = 1
      Top = 123
      Width = 537
      Height = 484
      Align = alBottom
      Lines.Strings = (
        'Resultado del procesamiento')
      ScrollBars = ssBoth
      TabOrder = 1
      WordWrap = False
    end
    object GroupBox1: TGroupBox
      Left = 1
      Top = 1
      Width = 537
      Height = 45
      Align = alTop
      TabOrder = 2
      object Label2: TLabel
        Left = 16
        Top = 17
        Width = 69
        Height = 13
        Caption = 'Puerta serie'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label1: TLabel
        Left = 314
        Top = 16
        Width = 184
        Height = 16
        Caption = 'Par'#225'metros : 9600  N   8   1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGreen
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object edtCom: TLabel
        Left = 96
        Top = 16
        Width = 65
        Height = 16
        AutoSize = False
        Caption = '?????'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGreen
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label3: TLabel
        Left = 218
        Top = 17
        Width = 82
        Height = 13
        Caption = '(CommCelldyn.ini)'
      end
    end
    object memProceso: TMemo
      Left = 1
      Top = 46
      Width = 537
      Height = 77
      Align = alClient
      Lines.Strings = (
        'Comandos')
      ScrollBars = ssBoth
      TabOrder = 3
      WordWrap = False
    end
  end
  object SerialPort: TApdComPort
    ComNumber = 9
    Baud = 9600
    TraceName = 'APRO.TRC'
    LogName = 'APRO.LOG'
    Left = 376
    Top = 88
  end
  object Paquete1: TApdDataPacket
    Enabled = True
    EndCond = [ecString]
    StartString = #2
    EndString = #3
    ComPort = SerialPort
    PacketSize = 0
    IncludeStrings = False
    OnStringPacket = Paquete1StringPacket
    OnTimeout = Paquete1Timeout
    Left = 424
    Top = 80
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 10000
    OnTimer = Timer1Timer
    Left = 480
    Top = 96
  end
  object logCelldyn: TLogToFile
    LogFileName = 'LogFile.Txt'
    OverwriteExistingFile = False
    ClearonCreate = False
    IncDateTime = False
    IncPrefix = False
    IncSeparator = False
    IncSuffix = False
    DateTimeFormatStr = 'c'
    Left = 399
    Top = 200
  end
end
