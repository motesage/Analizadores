program recovery_test;
{$APPTYPE CONSOLE}
uses Windows, SysUtils, Forms, Classes, WinSock, ScktComp, uHL7 in 'uHL7.pas';
var
  H: tHL7;
  C: TSocket;
  Addr: TSockAddrIn;
  WS: TWSAData;
  Started: DWORD;
  Server: TCustomWinSocket;
  Session: THL7Session;
  Err, Size, FirstPending, LastPending, Received, N, I: Integer;
  NonBlocking: Longint;
  Buf: array[0..16383] of Char;
procedure Pump(MS: DWORD);
var T: DWORD;
begin
  T := GetTickCount;
  repeat Application.ProcessMessages; Sleep(1);
  until GetTickCount - T >= MS;
end;
procedure Check(OK: Boolean; const Msg: string);
begin
  if not OK then raise Exception.Create(Msg);
end;
procedure OpenClient;
begin
  C := WinSock.socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  FillChar(Addr, SizeOf(Addr), 0);
  Addr.sin_family := AF_INET;
  Addr.sin_addr.S_addr := inet_addr('127.0.0.1');
  Addr.sin_port := htons(15051);
  Check(WinSock.connect(C, Addr, SizeOf(Addr)) = 0, 'connect');
  Pump(30);
end;
begin
  WSAStartup($0101, WS);
  H := tHL7.Create(nil);
  try
    H.fRunTimer.Enabled := False;
    H.Port := 15051;
    OpenClient;
    Check(H.fServerSocket.Socket.ActiveConnections = 1, 'cliente inicial');
    Server := H.fServerSocket.Socket.Connections[0];
    Err := 10053;
    H.ServerSocket1ClientError(nil, Server, eeDisconnect, Err);
    Check(Err = 0, 'error manejado');
    Check(THL7Session(Server.Data).Failed, 'sesion marcada');
    Pump(500);
    Check(H.fServerSocket.Active, 'escucha conservada');
    Check(H.fServerSocket.Socket.ActiveConnections = 0, 'socket liberado');
    Check(not H.ServerConnected, 'estado desconectado');
    closesocket(C);
    OpenClient;
    Check(H.fServerSocket.Socket.ActiveConnections = 1, 'reconexion');
    Server := H.fServerSocket.Socket.Connections[0];
    Session := THL7Session(Server.Data);
    Size := 1024;
    setsockopt(Server.SocketHandle, SOL_SOCKET, SO_SNDBUF, PChar(@Size), SizeOf(Size));
    Size := 2 * 1024 * 1024;
    Session.OutputBuffer := StringOfChar('X', Size);
    TestSendLimit := 1024;
    H.SendPendingOutput(Server);
    FirstPending := Length(Session.OutputBuffer);
    Writeln('Pending=', FirstPending, ' connected=', Server.Connected);
    Check((FirstPending > 0) and (FirstPending < Size), 'envio parcial simulado');
    TestWouldBlock := True;
    H.SendPendingOutput(Server);
    TestWouldBlock := False;
    TestSendLimit := 0;
    Check(not Session.Failed, 'WOULDBLOCK no es fallo fatal');
    LastPending := Length(Session.OutputBuffer);
    NonBlocking := 1;
    ioctlsocket(C, FIONBIO, NonBlocking);
    Received := 0;
    Started := GetTickCount;
    repeat
      N := recv(C, Buf, SizeOf(Buf), 0);
      if N > 0 then begin
        for I := 0 to N - 1 do Check(Buf[I] = 'X', 'contenido TX');
        Inc(Received, N);
      end;
      Application.ProcessMessages;
      Sleep(1);
    until (Received = Size) or (GetTickCount - Started > 20000);
    Check(Received = Size, 'todos los bytes recibidos');
    Check(Length(Session.OutputBuffer) = 0, 'cola vacia');
    Writeln('PASS: 10053 diferido, escucha, limpieza y reconexion');
    Writeln('PASS: envio parcial 2 MiB, pendiente inicial=', FirstPending,
      ' segundo=', LastPending, ' recibidos=', Received);
    closesocket(C);
    Pump(30);
  finally
    H.Free;
    WSACleanup;
  end;
end.

