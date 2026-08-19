object frmAU480: TfrmAU480
  Left = 220
  Top = 152
  Width = 1152
  Height = 669
  Caption = 'Interfaz AU480 - SageLabWin (2016)'
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
  object Panel1: TPanel
    Left = 539
    Top = 0
    Width = 597
    Height = 631
    Align = alClient
    Caption = 'Panel1'
    TabOrder = 0
    object wwDBGrid1: TwwDBGrid
      Left = 1
      Top = 1
      Width = 595
      Height = 629
      ControlType.Strings = (
        'Estado;CheckBox;true;false')
      Selected.Strings = (
        'Estado'#9'5'#9'Procec'
        'Empresa'#9'2'#9'Emp'#9'F'
        'Boleta'#9'10'#9'Boleta'
        'Muestra'#9'1'#9'M'
        'Paciente'#9'20'#9'Paciente'
        'Tests'#9'120'#9'Tests')
      IniAttributes.Delimiter = ';;'
      TitleColor = clBtnFace
      FixedCols = 0
      ShowHorzScrollBar = True
      Align = alClient
      DataSource = dsPedidos
      TabOrder = 0
      TitleAlignment = taLeftJustify
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      TitleLines = 1
      TitleButtons = False
    end
  end
  object panel2: TPanel
    Left = 0
    Top = 0
    Width = 539
    Height = 631
    Align = alLeft
    TabOrder = 1
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
    object lblsueros: TLabel
      Left = 192
      Top = 16
      Width = 50
      Height = 16
      Caption = 'Sueros'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblorinas: TLabel
      Left = 291
      Top = 16
      Width = 46
      Height = 16
      Caption = 'Orinas'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object AdTerminal1: TAdTerminal
      Left = 22
      Top = 314
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
    object memProceso: TMemo
      Left = 4
      Top = 43
      Width = 536
      Height = 271
      Lines.Strings = (
        'Resultado del procesamiento')
      ScrollBars = ssBoth
      TabOrder = 1
      WordWrap = False
    end
    object edtCom: TwwDBComboBox
      Left = 90
      Top = 13
      Width = 75
      Height = 21
      ShowButton = True
      Style = csDropDownList
      MapList = False
      AllowClearKey = False
      DropDownCount = 8
      ItemHeight = 0
      Items.Strings = (
        '9')
      Sorted = False
      TabOrder = 2
      UnboundDataType = wwDefault
      OnChange = edtComChange
    end
    object memPedidos: TMemo
      Left = 387
      Top = 451
      Width = 304
      Height = 154
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      Lines.Strings = (
        'Pedidos generados desde LAB')
      ParentFont = False
      ReadOnly = True
      TabOrder = 3
      Visible = False
      WordWrap = False
    end
    object memResult: TMemo
      Left = 3
      Top = 326
      Width = 532
      Height = 284
      Lines.Strings = (
        'Resultado del procesamiento')
      ScrollBars = ssBoth
      TabOrder = 4
      WordWrap = False
    end
  end
  object mtblPedidos: TJvMemoryData
    Active = True
    FieldDefs = <
      item
        Name = 'Estado'
        DataType = ftBoolean
      end
      item
        Name = 'Empresa'
        DataType = ftString
        Size = 2
      end
      item
        Name = 'Boleta'
        DataType = ftInteger
      end
      item
        Name = 'Muestra'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'Paciente'
        DataType = ftString
        Size = 20
      end
      item
        Name = 'Tests'
        DataType = ftString
        Size = 120
      end>
    Left = 752
    Top = 200
    object mtblPedidosEstado: TBooleanField
      DisplayLabel = 'Procec'
      DisplayWidth = 5
      FieldName = 'Estado'
    end
    object mtblPedidosEmpresa: TStringField
      DisplayLabel = 'Emp'
      DisplayWidth = 2
      FieldName = 'Empresa'
      Size = 2
    end
    object mtblPedidosBoleta: TIntegerField
      DisplayWidth = 10
      FieldName = 'Boleta'
    end
    object mtblPedidosMuestra: TStringField
      DisplayLabel = 'M'
      DisplayWidth = 1
      FieldName = 'Muestra'
      Size = 1
    end
    object mtblPedidosPaciente: TStringField
      DisplayWidth = 20
      FieldName = 'Paciente'
    end
    object mtblPedidosTests: TStringField
      DisplayWidth = 120
      FieldName = 'Tests'
      Size = 120
    end
  end
  object dsPedidos: TDataSource
    DataSet = mtblPedidos
    Left = 792
    Top = 304
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
  object logAU480: TLogToFile
    LogFileName = 'LogFile.Txt'
    OverwriteExistingFile = False
    ClearonCreate = False
    IncDateTime = False
    IncPrefix = False
    IncSeparator = False
    IncSuffix = False
    DateTimeFormatStr = 'c'
    Left = 655
    Top = 368
  end
end
