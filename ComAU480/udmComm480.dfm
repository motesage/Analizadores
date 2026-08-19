object dmComm480: TdmComm480
  OldCreateOrder = False
  Left = 316
  Top = 155
  Height = 267
  Width = 259
  object SerialPort: TApdComPort
    ComNumber = 1
    Baud = 9600
    AutoOpen = False
    DTR = False
    RTS = False
    TraceName = 'APRO.TRC'
    LogName = 'APRO.LOG'
    OnTriggerAvail = SerialPortTriggerAvail
    Left = 32
    Top = 56
  end
end
