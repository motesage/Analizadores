object frmIono_Diestro2: TfrmIono_Diestro2
  Left = 412
  Top = 209
  Width = 555
  Height = 646
  Caption = 'Interfaz Iono_Diestro2 - SageLabWin (2021)'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object panel2: TPanel
    Left = 0
    Top = 0
    Width = 539
    Height = 607
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
      Top = 122
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
        Left = 192
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
      object edtCom: TEdit
        Left = 91
        Top = 15
        Width = 62
        Height = 21
        TabOrder = 0
        Text = '7'
        OnChange = edtComChange
      end
    end
    object memProceso: TMemo
      Left = 1
      Top = 46
      Width = 537
      Height = 76
      Align = alClient
      Lines.Strings = (
        'Comandos')
      ScrollBars = ssBoth
      TabOrder = 3
      WordWrap = False
    end
    object pruebas: TButton
      Left = 128
      Top = 176
      Width = 75
      Height = 25
      Caption = 'pruebas'
      TabOrder = 4
      Visible = False
      OnClick = pruebasClick
    end
  end
  object SerialPort: TApdComPort
    ComNumber = 3
    Baud = 9600
    TraceName = 'APRO.TRC'
    LogName = 'APRO.LOG'
    LogHex = False
    Left = 376
    Top = 112
  end
  object Paquete1: TApdDataPacket
    Enabled = True
    EndCond = [ecString, ecPacketSize]
    StartString = '#'
    EndString = #10#13
    ComPort = SerialPort
    PacketSize = 80
    IncludeStrings = False
    OnStringPacket = Paquete1StringPacket
    OnTimeout = Paquete1Timeout
    Left = 432
    Top = 64
  end
  object logIono_Diestro2: TLogToFile
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
