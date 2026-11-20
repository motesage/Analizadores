program EngineTests;
{$APPTYPE CONSOLE}
uses SysUtils, Classes, Forms, uASTM1381;
type
  TObserver = class
    Count: Integer;
    procedure Sent(Sender: TObject);
  end;
procedure TObserver.Sent(Sender: TObject);
begin Inc(Count); end;
var A: tASTM; O: TObserver; Checks, I: Integer; FirstFrame: string;
procedure Check(Value: Boolean; const Msg: string);
begin
  if not Value then raise Exception.Create('FAIL: '+Msg);
  Inc(Checks); Writeln('PASS: ', Msg);
end;
procedure BeginSend;
begin
  A.fBusyTimer := 0;
  A.fState := 0;
  A.ProcessStateMachine;
  A.ProcessStateMachine;
  A.fCommPort.Receive(#6);
  A.ProcessStateMachine;
  A.ProcessStateMachine;
  A.ProcessStateMachine;
end;
begin
  try
    A := tASTM.Create(nil);
    O := TObserver.Create;
    try
      A.OnSent := O.Sent;
      Check(not A.fCommPort.AutoOpen, 'Port does not open before configuration');
      A.Data := 'H|batch';
      A.Data := 'L|1';
      BeginSend;
      Check(O.Count=0, 'No delivery before frame acknowledgement');
      FirstFrame := A.fOutputFrameBuffer;
      A.fCommPort.Receive(#6);
      A.ProcessStateMachine;
      A.ProcessStateMachine;
      A.ProcessStateMachine;
      Check(O.Count=0, 'First ACK is not whole batch delivery');
      A.fTimer := Now-1;
      A.ProcessStateMachine;
      Check((A.fFrameOutputList.Count=2) and (A.fFrameOutputList[0]='H|batch'#13),
        'Timeout restores entire batch including acknowledged prefix');
      Check(O.Count=0, 'Timeout does not mark delivery');
      BeginSend;
      Check(A.fOutputFrameBuffer=FirstFrame, 'Retry starts at first frame');
      A.fCommPort.Receive(#6);
      A.ProcessStateMachine;
      A.ProcessStateMachine;
      A.ProcessStateMachine;
      A.fCommPort.Receive(#6);
      A.ProcessStateMachine;
      Check(O.Count=0, 'Last ACK precedes end-of-transmission callback');
      A.ProcessStateMachine;
      Check(O.Count=1, 'Whole acknowledged batch reports exactly one delivery');
      Check(A.FOriginalOutput.Count=0, 'Completed retry buffer cleared');
      A.ProcessStateMachine;
      Check(O.Count=1, 'Idle does not report duplicate delivery');
      A.Data := StringOfChar('X',300);
      BeginSend;
      A.fCommPort.Receive(#6);
      A.ProcessStateMachine;
      A.ProcessStateMachine;
      A.ProcessStateMachine;
      A.fTimer := Now-1;
      A.ProcessStateMachine;
      Check(Length(A.fFrameOutputList[0])=301, 'Partial long record restored on timeout');
      BeginSend;
      for I := 1 to 7 do begin
        A.fCommPort.Receive(#21);
        A.ProcessStateMachine;
        A.ProcessStateMachine;
        if A.fState=1000 then A.ProcessStateMachine;
      end;
      Check(A.fState=0, 'Repeated NAK aborts current session');
      Check(Length(A.fFrameOutputList[0])=301, 'NAK abort preserves full pending batch');
      Check(O.Count=1, 'NAK abort never marks delivery');
      Check(not A.CheckFrame('',1), 'Short invalid frame rejected safely');
      Writeln('SUCCESS: ', Checks, ' engine checks (simulated serial transport).');
    finally
      A.Free;
      O.Free;
    end;
  except
    on E: Exception do begin Writeln(E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
