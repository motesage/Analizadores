unit uMultiConfig;

interface

uses Windows, SysUtils, Classes, IniFiles;

type
  TMultiConfig = class
  public
    Equipo, Pedidos, Resultados: string;
    Port, Bauds: Integer;
    Equipos: TStringList;
    constructor Create(const IniName, Arguments: string);
    destructor Destroy; override;
  end;

function ValidID(const S: string): Boolean;
function NewID: string;
function AcquireModeLock(const Root: string; Multi: Boolean): THandle;

implementation

function AcquireModeLock(const Root: string; Multi: Boolean): THandle;
var Access, Share: DWORD; Name: string;
begin
  if not ForceDirectories(Root) then raise Exception.Create('No se puede crear ' + Root);
  Name := IncludeTrailingPathDelimiter(Root) + 'CommASTM.mode.lock';
  Access := GENERIC_READ;
  Share := FILE_SHARE_READ;
  if not Multi then begin Access := GENERIC_READ or GENERIC_WRITE; Share := 0; end;
  Result := CreateFile(PChar(Name), Access, Share, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if Result = INVALID_HANDLE_VALUE then
    raise Exception.Create('Carpeta en uso por un modo incompatible o inaccesible: ' + Root +
      '. ' + SysErrorMessage(GetLastError));
end;

function NewID: string;
var G: TGUID;
begin
  if CreateGUID(G) <> 0 then raise Exception.Create('No se pudo generar un identificador.');
  Result := Copy(GUIDToString(G), 2, 36);
end;

function ValidID(const S: string): Boolean;
var I: Integer;
begin
  Result := (Length(S) > 0) and (Length(S) <= 32);
  for I := 1 to Length(S) do
    if not (S[I] in ['a'..'z','A'..'Z','0'..'9','-']) then Result := False;
end;

constructor TMultiConfig.Create(const IniName, Arguments: string);
var Ini: TIniFile; I, J, P: Integer; ID, Root: string;
    Ports: TStringList;
begin
  inherited Create;
  Equipos := TStringList.Create;
  if not FileExists(IniName) then raise Exception.Create('No existe ' + IniName);
  if not SameText(Copy(Arguments, 1, 7), 'Equipo=') then
    raise Exception.Create('Uso: CommASTM.exe Equipo=Ar1');
  Equipo := Copy(Arguments, 8, MaxInt);
  if not ValidID(Equipo) then raise Exception.Create('Identificador de equipo invalido.');
  Ini := TIniFile.Create(IniName);
  Ports := TStringList.Create;
  try
    Equipos.CommaText := Ini.ReadString('MultiEquipo', 'Equipos', '');
    if Equipos.Count = 0 then raise Exception.Create('Falta la lista MultiEquipo/Equipos.');
    for I := 0 to Equipos.Count - 1 do begin
      ID := Trim(Equipos[I]);
      Equipos[I] := ID;
      if not ValidID(ID) then raise Exception.Create('Identificador invalido: ' + ID);
      for J := 0 to I - 1 do
        if SameText(ID, Equipos[J]) then raise Exception.Create('Equipo duplicado: ' + ID);
      P := Ini.ReadInteger(ID, 'Port', 0);
      if (P < 1) or (P > 256) then raise Exception.Create('Puerto invalido: ' + ID);
      if Ports.IndexOf(IntToStr(P)) >= 0 then raise Exception.Create('Puerto repetido: ' + ID);
      Ports.Add(IntToStr(P));
      if Ini.ReadInteger(ID, 'Bauds', 0) <= 0 then raise Exception.Create('Bauds invalidos: ' + ID);
    end;
    I := Equipos.IndexOf(Equipo);
    if I < 0 then raise Exception.Create('Equipo no registrado: ' + Equipo);
    Equipo := Equipos[I];
    Port := Ini.ReadInteger(Equipo, 'Port', 0);
    Bauds := Ini.ReadInteger(Equipo, 'Bauds', 0);
    Root := Trim(Ini.ReadString('MultiEquipo', 'Carpeta', 'Interfaces\Architec'));
    if Root = '' then raise Exception.Create('Carpeta compartida vacia.');
    if (ExtractFileDrive(Root) = '') and (Root[1] <> '\') then
      Root := ExtractFilePath(ExpandFileName(IniName)) + Root;
    Root := IncludeTrailingPathDelimiter(ExpandFileName(Root));
    Pedidos := Root + 'Pedidos\';
    Resultados := Root + 'Resultados\';
  finally
    Ports.Free;
    Ini.Free;
  end;
end;

destructor TMultiConfig.Destroy;
begin
  Equipos.Free;
  inherited;
end;

end.
