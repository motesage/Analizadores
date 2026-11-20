program QueueTests;
{$APPTYPE CONSOLE}
uses Windows, SysUtils, Classes, IniFiles, uMultiConfig, uMultiQueue;

var Root, IniName, Job, Job2: string;
    C1, C2: TMultiConfig;
    Q1, Q2: TMultiQueue;
    L: TStringList;
    Ini: TIniFile;
    H, H2: THandle;
    Failed: Boolean;
    Checks: Integer;

procedure Check(Value: Boolean; const Message: string);
begin
  if not Value then raise Exception.Create('FAIL: ' + Message);
  Inc(Checks);
  Writeln('PASS: ', Message);
end;

procedure MakeOrder(const Name, Text: string);
begin
  L.Text := Text;
  SaveAtomic(L, C1.Pedidos + Name + '.res');
  WriteMarker(C1.Pedidos + Name + '.ok');
end;

procedure BadConfig(const Arg: string);
var C: TMultiConfig; Failed: Boolean;
begin
  Failed := False;
  try
    C := TMultiConfig.Create(IniName, Arg);
    C.Free;
  except
    on E: Exception do Failed := True;
  end;
  Check(Failed, 'Reject invalid config: ' + Arg);
end;

begin
  try
    Root := ExtractFilePath(ParamStr(0)) + 'runs\' + NewID + '\';
    ForceDirectories(Root);
    IniName := Root + 'test.ini';
    Ini := TIniFile.Create(IniName);
    try
      Ini.WriteString('MultiEquipo','Equipos','Ar1,Ar2');
      Ini.WriteString('MultiEquipo','Carpeta','exchange');
      Ini.WriteInteger('Ar1','Port',2);
      Ini.WriteInteger('Ar1','Bauds',9600);
      Ini.WriteInteger('Ar2','Port',3);
      Ini.WriteInteger('Ar2','Bauds',9600);
    finally
      Ini.Free;
    end;
    C1 := TMultiConfig.Create(IniName,'Equipo=ar1');
    C2 := TMultiConfig.Create(IniName,'Equipo=Ar2');
    Q1 := TMultiQueue.Create(C1);
    Q2 := TMultiQueue.Create(C2);
    L := TStringList.Create;
    try
      Check(C1.Equipo = 'Ar1', 'Canonical profile name');
      Check(C1.Pedidos = Root + 'exchange\Pedidos\', 'Relative paths use INI directory');
      BadConfig('Equipo=Unknown');
      BadConfig('Equipo=..\Ar1');
      BadConfig('Port=2');
      H := AcquireModeLock(Root + 'mode', True);
      try
        H2 := AcquireModeLock(Root + 'mode', True);
        CloseHandle(H2);
        Check(True, 'Two multi instances may share a directory');
        Failed := False;
        try H2 := AcquireModeLock(Root + 'mode', False); CloseHandle(H2);
        except on E: Exception do Failed := True; end;
        Check(Failed, 'Legacy mode blocked while multi is active');
      finally CloseHandle(H); end;
      H := AcquireModeLock(Root + 'mode', False);
      try
        Failed := False;
        try H2 := AcquireModeLock(Root + 'mode', True); CloseHandle(H2);
        except on E: Exception do Failed := True; end;
        Check(Failed, 'Multi mode blocked while legacy is active');
      finally CloseHandle(H); end;
      MakeOrder('batch1','H|first'#13#10'L|1');
      Check(Q1.Next(Job,L) and (Job='batch1.ok'), 'First analyzer gets batch');
      Check(L[0]='H|first', 'Payload is preserved');
      Check(Q2.Next(Job2,L) and (Job2=Job), 'Second analyzer gets same batch');
      Check(not FileExists(C1.Pedidos+'MultiEquipo\batch1.ok\Ar1.sent'), 'Loading is not delivery');
      Q1.Delivered(Job);
      Check(not Q1.Next(Job,L), 'Acknowledged batch not sent again');
      Check(FileExists(C1.Pedidos+'batch1.ok'), 'Offline analyzer prevents cleanup');
      Q1.Free;
      Q1 := TMultiQueue.Create(C1);
      Check(not Q1.Next(Job,L), 'Delivery survives process recreation');
      Check(Q2.Next(Job2,L), 'Unacknowledged batch remains available');
      Q2.Delivered(Job2);
      Check(not Q2.Next(Job2,L), 'Both deliveries retire batch');
      Check(not FileExists(C1.Pedidos+'batch1.ok'), 'Source marker cleaned after both');
      Check(not FileExists(C1.Pedidos+'batch1.res'), 'Source payload cleaned after both');
      Check(FileExists(C1.Pedidos+'MultiEquipo\Entregados\batch1.ok\retired'), 'Durable delivery audit');
      MakeOrder('batch2','H|second');
      H := CreateFile(PChar(C1.Pedidos+'MultiEquipo\queue.lock'), GENERIC_READ or GENERIC_WRITE,
        0,nil,OPEN_ALWAYS,FILE_ATTRIBUTE_NORMAL,0);
      Check(H<>INVALID_HANDLE_VALUE, 'Acquire competing queue lock');
      try
        Check(not Q1.Next(Job,L), 'Busy lock defers work without taking a batch');
      finally
        CloseHandle(H);
      end;
      Check(Q1.Next(Job,L), 'Queue resumes after lock release');
      DeleteFile(C1.Pedidos+'batch2.ok');
      DeleteFile(C1.Pedidos+'batch2.res');
      Q1.Free;
      Q1 := TMultiQueue.Create(C1);
      Check(Q1.Next(Job,L) and (L[0]='H|second'), 'Snapshot recovers missing source after restart');
      Q1.Delivered(Job);
      Check(Q2.Next(Job2,L), 'Other analyzer also uses persisted snapshot');
      Q2.Delivered(Job2);
      Check(not Q1.Next(Job,L), 'Recovered batch completes normally');
      MakeOrder('batch3','H|third');
      Check(Q1.Next(Job,L), 'New batch');
      C1.Equipos.Add('Ar3');
      Q1.Delivered(Job);
      Check(Q2.Next(Job2,L), 'Original recipients retained');
      Q2.Delivered(Job2);
      Check(not Q1.Next(Job,L), 'Adding profile does not change captured recipients');
      C1.Equipos.Delete(2);
      MakeOrder('batch4','H|fourth');
      Check(Q1.Next(Job,L), 'Prepare cleanup recovery');
      Q1.Delivered(Job);
      Q2.Delivered(Job);
      DeleteFile(C1.Pedidos+'batch4.res');
      Check(not Q1.Next(Job,L), 'Interrupted cleanup recovered');
      Check(not FileExists(C1.Pedidos+'batch4.ok'), 'Cleanup finishes after interruption');
      MakeOrder('batch1', 'H|reused-name');
      Failed := False;
      try Q1.Next(Job,L); except on E: Exception do Failed := True; end;
      Check(Failed, 'Reused completed batch name rejected explicitly');
      Check(FileExists(C1.Pedidos+'batch1.res'), 'Rejected new source is not deleted');
      Ini := TIniFile.Create(IniName);
      try Ini.WriteInteger('Ar2','Port',2); finally Ini.Free; end;
      BadConfig('Equipo=Ar1');
      Ini := TIniFile.Create(IniName);
      try
        Ini.WriteInteger('Ar2','Port',3);
        Ini.WriteString('MultiEquipo','Equipos','Ar1,ar1');
      finally Ini.Free; end;
      BadConfig('Equipo=Ar1');
      Writeln('SUCCESS: ',Checks,' checks. Fixtures: ', Root);
    finally
      L.Free;
      Q1.Free;
      Q2.Free;
      C1.Free;
      C2.Free;
    end;
  except
    on E: Exception do begin Writeln(E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
