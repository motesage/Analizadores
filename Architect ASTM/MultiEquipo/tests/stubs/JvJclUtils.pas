unit JvJclUtils;
interface
uses SysUtils;
function Dec2Hex(Value, Digits: Integer): string;
implementation
function Dec2Hex(Value, Digits: Integer): string;
begin Result := IntToHex(Value, Digits); end;
end.
