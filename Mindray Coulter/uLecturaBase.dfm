object frmLectura: TfrmLectura
  Left = 444
  Top = 215
  BorderStyle = bsSingle
  Caption = 'Interfaz de comunicaciones MindRay (2025)'
  ClientHeight = 478
  ClientWidth = 611
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
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 11
    Top = 11
    Width = 110
    Height = 13
    Caption = 'IP MindRay Coulter'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 238
    Top = 10
    Width = 107
    Height = 13
    Caption = 'Carpeta resultados'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Memo1: TMemo
    Left = 8
    Top = 32
    Width = 598
    Height = 297
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object edtIP: TEdit
    Left = 126
    Top = 6
    Width = 95
    Height = 21
    TabOrder = 1
    Text = '10.110.110.1'
  end
  object btnConnect: TButton
    Left = 517
    Top = 4
    Width = 90
    Height = 25
    Caption = 'Conectar'
    TabOrder = 2
    OnClick = btnConnectClick
  end
  object Memo2: TMemo
    Left = 8
    Top = 336
    Width = 598
    Height = 136
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object edtCarpeta: TEdit
    Left = 353
    Top = 6
    Width = 152
    Height = 21
    TabOrder = 4
    Text = 'por defecto es '#39'IN'#39
  end
  object tcpClient: TfndTCPClient
    Host = '10.110.110.1'
    Port = '5500'
    OnConnected = tcpClientConnected
    OnDataAvailable = tcpClientDataAvailable
    OnClose = tcpClientClose
    Left = 120
    Top = 200
  end
end
