unit uCommBuffer;
{
	Este objeto implementa un buffer standard para usar en comunicaciones
  seriales y de red

  Deberia subclasearse para los distintos tipos de objetos de comunicaciones
  Fanuc, S5,HandPunch, etc, de forma de implementar los codigos de redundancia
  y las verificaciones de paridad de una forma mas razonable.

 }


interface
uses Windows, Messages, SysUtils, Classes;

const
  MAX_COMM_BUFFER_SIZE = 2 * 4096;

type
  tCommBuffer = class(TComponent)
    private
      fcount: integer;
	    function GetEmpty: boolean;
    public
      Buffer: array[1..MAX_COMM_BUFFER_SIZE] of char;
      constructor Create(AOwner: TComponent); override;
      procedure Clear;
      procedure Add(c: byte); overload;
      procedure Add(c: byte; posicion: integer); overload;
      procedure AddChar(c: char); overload;
      procedure AddChar(c: char; posicion: integer); overload;
      property Count: integer read fCount;
      property Empty: boolean read GetEmpty;
      function GetChar:integer;
      function PeekChar:integer;
      function bcc: integer;
      function AsString: string;
  end;

implementation
procedure tCommBuffer.AddChar(c: char);
begin
  self.Add(Ord(c));
end;

procedure tCommBuffer.Add(c: byte);
begin
	if fCount<MAX_COMM_BUFFER_SIZE then begin
    inc(fcount);
    self.Buffer[fcount] := char(c);
  end;
end;

procedure tCommBuffer.AddChar(c: char; posicion: integer);
begin
  self.Add(Ord(c),posicion);
end;

procedure tCommBuffer.Add(c: byte; posicion: integer);
begin
  if ((posicion>0) and (posicion<=MAX_COMM_BUFFER_SIZE))  then begin
    if posicion>fcount then begin
      fcount := posicion;
    end;
    Buffer[posicion] := char(c);
  end;
end;

procedure tCommBuffer.Clear;
var
  I: Integer;
begin
  fcount := 0;
  for I := 1 to MAX_COMM_BUFFER_SIZE do begin
    self.Buffer[i] := #0;
  end;    // for
end;

constructor tCommBuffer.Create(AOwner: TComponent);
begin
  inherited;
  self.Clear;
end;

function tCommBuffer.bcc: integer;
var
  j,BlockCheck: integer;
begin
  BlockCheck := 0;
  for j := 1 to fCount do begin    // Iterate
    BlockCheck := BlockCheck xor ord(self.Buffer[j]);
    BlockCheck := 2 * BlockCheck;
    if (BlockCheck>$ff) then begin
      BlockCheck := (BlockCheck or 1) and $ff;
    end;
  end;    // for
  result := BlockCheck;
end;

function tCommBuffer.GetChar: integer;
var
  j: integer;
begin
  result := -1;
  if (self.fCount>0) then begin
    result := Ord(self.buffer[1]);
    for j := 2 to self.fCount do begin   // Iterate
      self.Buffer[j-1] := self.Buffer[j];
    end;    // for
    self.Buffer[self.fCount] := #0;
    dec(self.fCount);
  end;
end;

function tCommBuffer.PeekChar: integer;
var
  j: integer;
begin
  result := -1;
  if (self.fCount>0) then begin
    result := Ord(self.buffer[1]);
  end;
end;

function tCommBuffer.GetEmpty: boolean;
begin
  result := (self.fCount>0);
end;

function tCommBuffer.AsString: string;
var
	j: Integer;
  S: string;
begin
	s := '';
  for j := 1 to self.Count do begin
    s := s + self.Buffer[j];
  end;    // for
  result := s;
end;



end.
