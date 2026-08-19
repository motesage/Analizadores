object frmMindrayHL7Sim: TfrmMindrayHL7Sim
  Left = 240
  Top = 120
  Width = 1000
  Height = 720
  Caption = 'Simulador Mindray HL7 v0.1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 984
    Height = 49
    Align = alTop
    TabOrder = 0
    object lblHost: TLabel
      Left = 12
      Top = 17
      Width = 22
      Height = 13
      Caption = 'Host'
    end
    object lblPort: TLabel
      Left = 211
      Top = 17
      Width = 24
      Height = 13
      Caption = 'Port'
    end
    object lblBarcode: TLabel
      Left = 594
      Top = 17
      Width = 39
      Height = 13
      Caption = 'Barcode'
    end
    object edtHost: TEdit
      Left = 42
      Top = 13
      Width = 155
      Height = 21
      TabOrder = 0
      Text = '127.0.0.1'
    end
    object edtPort: TEdit
      Left = 241
      Top = 13
      Width = 58
      Height = 21
      TabOrder = 1
      Text = '5050'
    end
    object btnConnect: TButton
      Left = 313
      Top = 10
      Width = 90
      Height = 27
      Caption = 'Conectar'
      TabOrder = 2
      OnClick = btnConnectClick
    end
    object btnDisconnect: TButton
      Left = 409
      Top = 10
      Width = 90
      Height = 27
      Caption = 'Desconectar'
      TabOrder = 3
      OnClick = btnDisconnectClick
    end
    object chkAutoACK: TCheckBox
      Left = 509
      Top = 15
      Width = 78
      Height = 17
      Caption = 'Auto ACK'
      Checked = True
      State = cbChecked
      TabOrder = 4
    end
    object edtBarcode: TEdit
      Left = 640
      Top = 13
      Width = 150
      Height = 21
      TabOrder = 5
      Text = '34567743'
    end
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 49
    Width = 984
    Height = 49
    Align = alTop
    TabOrder = 1
    object btnQRY: TButton
      Left = 8
      Top = 10
      Width = 110
      Height = 27
      Caption = 'Enviar QRY'
      TabOrder = 0
      OnClick = btnQRYClick
    end
    object btnORU: TButton
      Left = 124
      Top = 10
      Width = 110
      Height = 27
      Caption = 'Enviar ORU'
      TabOrder = 1
      OnClick = btnORUClick
    end
    object btnQRYFragmentado: TButton
      Left = 240
      Top = 10
      Width = 135
      Height = 27
      Caption = 'QRY fragmentado'
      TabOrder = 2
      OnClick = btnQRYFragmentadoClick
    end
    object btnDosQRY: TButton
      Left = 381
      Top = 10
      Width = 135
      Height = 27
      Caption = '2 QRY juntos'
      TabOrder = 3
      OnClick = btnDosQRYClick
    end
    object btnEnviarManual: TButton
      Left = 522
      Top = 10
      Width = 135
      Height = 27
      Caption = 'Enviar manual'
      TabOrder = 4
      OnClick = btnEnviarManualClick
    end
    object btnLimpiar: TButton
      Left = 663
      Top = 10
      Width = 90
      Height = 27
      Caption = 'Limpiar log'
      TabOrder = 5
      OnClick = btnLimpiarClick
    end
  end
  object memManual: TMemo
    Left = 0
    Top = 98
    Width = 984
    Height = 190
    Align = alTop
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 2
    WordWrap = False
  end
  object Splitter1: TSplitter
    Left = 0
    Top = 288
    Width = 984
    Height = 5
    Cursor = crVSplit
    Align = alTop
  end
  object memLog: TMemo
    Left = 0
    Top = 293
    Width = 984
    Height = 388
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 3
    WordWrap = False
  end
  object tmrFragment: TTimer
    Enabled = False
    Interval = 700
    OnTimer = tmrFragmentTimer
    Left = 912
    Top = 56
  end
end
