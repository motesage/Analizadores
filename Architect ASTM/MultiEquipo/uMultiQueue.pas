unit uMultiQueue;

interface

uses Windows, SysUtils, Classes, uMultiConfig;

type
  TMultiQueue = class
  private
    FConfig: TMultiConfig;
    FState, FArchive: string;
    function Lock: THandle;
    procedure Prepare(const Name: string);
    procedure Retire(const Name: string);
    function AllSent(const Dir: string): Boolean;
  public
    constructor Create(Config: TMultiConfig);
    function Next(var Job: string; Lines: TStrings): Boolean;
    procedure Delivered(const Job: string);
  end;

procedure SaveAtomic(Lines: TStrings; const Name: string);
procedure WriteMarker(const Name: string);

implementation

procedure SaveAtomic(Lines: TStrings; const Name: string);
var Temp: string; Stream: TFileStream; Data: string;
begin
  Temp := Name + '.' + NewID + '.tmp';
  try
    Stream := TFileStream.Create(Temp, fmCreate);
    try
      Data := Lines.Text;
      if Length(Data) > 0 then Stream.WriteBuffer(Data[1], Length(Data));
      if not FlushFileBuffers(Stream.Handle) then RaiseLastOSError;
    finally
      Stream.Free;
    end;
    if not MoveFileEx(PChar(Temp), PChar(Name), MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH) then
      RaiseLastOSError;
  finally
    if FileExists(Temp) then DeleteFile(Temp);
  end;
end;

procedure WriteMarker(const Name: string);
var L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Add('ok');
    SaveAtomic(L, Name);
  finally
    L.Free;
  end;
end;

constructor TMultiQueue.Create(Config: TMultiConfig);
begin
  inherited Create;
  FConfig := Config;
  FState := Config.Pedidos + 'MultiEquipo\';
  if not ForceDirectories(FState) then raise Exception.Create('No se puede crear ' + FState);
  FArchive := FState + 'Entregados\';
  if not ForceDirectories(FArchive) then raise Exception.Create('No se puede crear ' + FArchive);
end;

function TMultiQueue.Lock: THandle;
var Err: DWORD;
begin
  Result := CreateFile(PChar(FState + 'queue.lock'), GENERIC_READ or GENERIC_WRITE,
    0, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if Result = INVALID_HANDLE_VALUE then begin
    Err := GetLastError;
    if (Err <> ERROR_SHARING_VIOLATION) and (Err <> ERROR_LOCK_VIOLATION) then
      raise Exception.Create('No se puede bloquear la cola: ' + SysErrorMessage(Err));
  end;
end;

procedure TMultiQueue.Prepare(const Name: string);
var Dir: string; L: TStringList;
begin
  Dir := FState + Name + '\';
  if FileExists(Dir + 'ready') then Exit;
  if not FileExists(FConfig.Pedidos + ChangeFileExt(Name, '.res')) then
    raise Exception.Create('Pedido sin archivo .res: ' + Name);
  if not ForceDirectories(Dir) then raise Exception.Create('No se puede crear ' + Dir);
  L := TStringList.Create;
  try
    L.LoadFromFile(FConfig.Pedidos + ChangeFileExt(Name, '.res'));
    if L.Count = 0 then raise Exception.Create('Pedido vacio: ' + Name);
    SaveAtomic(L, Dir + 'payload');
    SaveAtomic(FConfig.Equipos, Dir + 'targets');
    WriteMarker(Dir + 'ready');
  finally
    L.Free;
  end;
end;

function TMultiQueue.AllSent(const Dir: string): Boolean;
var L: TStringList; I: Integer;
begin
  Result := False;
  L := TStringList.Create;
  try
    L.LoadFromFile(Dir + 'targets');
    if L.Count = 0 then raise Exception.Create('Lote sin destinatarios: ' + Dir);
    for I := 0 to L.Count - 1 do begin
      if not ValidID(L[I]) then raise Exception.Create('Destinatario invalido en ' + Dir);
      if not FileExists(Dir + L[I] + '.sent') then Exit;
    end;
    Result := True;
  finally
    L.Free;
  end;
end;

procedure TMultiQueue.Retire(const Name: string);
var Dir, Source: string;
begin
  Dir := FState + Name + '\';
  if not AllSent(Dir) then Exit;
  { Keep a durable tombstone: batch names must be unique. A restarted process
    finishes an interrupted cleanup, but never dispatches an acknowledged batch. }
  if not FileExists(Dir + 'retired') then begin
    Source := FConfig.Pedidos + ChangeFileExt(Name, '.res');
    if FileExists(Source) and not DeleteFile(Source) then RaiseLastOSError;
    Source := FConfig.Pedidos + Name;
    if FileExists(Source) and not DeleteFile(Source) then RaiseLastOSError;
    WriteMarker(Dir + 'retired');
  end;
  { Historical batches do not participate in every two-second queue scan. }
  if not MoveFileEx(PChar(ExcludeTrailingPathDelimiter(Dir)),
    PChar(FArchive + Name), MOVEFILE_WRITE_THROUGH) then RaiseLastOSError;
end;

function TMultiQueue.Next(var Job: string; Lines: TStrings): Boolean;
var H: THandle; Rec: TSearchRec; Names, Targets: TStringList;
    I: Integer; Name, Dir: string;
begin
  Result := False;
  Job := '';
  H := Lock;
  if H = INVALID_HANDLE_VALUE then Exit;
  Names := TStringList.Create;
  Targets := TStringList.Create;
  try
    { Recover saved batches even if the producer removed their source marker. }
    if FindFirst(FState + '*', faDirectory, Rec) = 0 then begin
      try
        repeat
          if (Rec.Attr and faDirectory <> 0) and (Rec.Name <> '.') and (Rec.Name <> '..') then
            if FileExists(FState + Rec.Name + '\ready') then Names.Add(Rec.Name);
        until FindNext(Rec) <> 0;
      finally
        FindClose(Rec);
      end;
    end;
    if FindFirst(FConfig.Pedidos + '*.ok', faAnyFile, Rec) = 0 then begin
      try
        repeat
          if Rec.Attr and faDirectory = 0 then begin
            Dir := FState + Rec.Name + '\';
            if FileExists(Dir + 'retired') or FileExists(FArchive + Rec.Name + '\retired') then
              raise Exception.Create('SageLab reutilizo el nombre de un lote: ' + Rec.Name);
            Prepare(Rec.Name);
            if Names.IndexOf(Rec.Name) < 0 then Names.Add(Rec.Name);
          end;
        until FindNext(Rec) <> 0;
      finally
        FindClose(Rec);
      end;
    end;
    Names.Sort;
    for I := 0 to Names.Count - 1 do begin
      Name := Names[I];
      Dir := FState + Name + '\';
      Retire(Name);
      if not DirectoryExists(Dir) then Continue;
      Targets.LoadFromFile(Dir + 'targets');
      if (Targets.IndexOf(FConfig.Equipo) >= 0) and
         not FileExists(Dir + FConfig.Equipo + '.sent') then begin
        Lines.LoadFromFile(Dir + 'payload');
        Job := Name;
        Result := True;
        Exit;
      end;
    end;
  finally
    Targets.Free;
    Names.Free;
    CloseHandle(H);
  end;
end;

procedure TMultiQueue.Delivered(const Job: string);
begin
  { Each equipment owns its marker; atomic publication needs no queue lock.
    Cleanup is serialized by Next. Failed persistence must stop transmission. }
  if (ExtractFileName(Job) <> Job) or (Job = '') then
    raise Exception.Create('Identificador de lote invalido.');
  WriteMarker(FState + Job + '\' + FConfig.Equipo + '.sent');
end;

end.
