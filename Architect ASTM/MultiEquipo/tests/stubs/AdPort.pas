unit AdPort;
interface
uses Classes, SysUtils;
type
  TTriggerAvail = procedure(CP: TObject; Count: Word) of object;
  TApdComPort = class(TComponent)
  public
    AutoOpen, Open: Boolean;
    ComNumber, Baud, InSize, OutSize: Integer;
    OnTriggerAvail: TTriggerAvail;
    Written, Incoming: string;
    procedure PutChar(C: Char);
    procedure PutString(const S: string);
    function GetChar: Char;
    procedure Receive(const S: string);
  end;
implementation
procedure TApdComPort.PutChar(C: Char);
begin Written := Written + C; end;
procedure TApdComPort.PutString(const S: string);
begin Written := Written + S; end;
function TApdComPort.GetChar: Char;
begin Result := Incoming[1]; Delete(Incoming,1,1); end;
procedure TApdComPort.Receive(const S: string);
begin Incoming := Incoming + S; OnTriggerAvail(Self, Length(S)); end;
end.
