unit uMultiMain;

interface

uses Windows, SysUtils, Classes, Forms, Controls, StdCtrls, Dialogs,
  uASTM1381, uMultiConfig, uMultiQueue;

type
  TMultiForm = class(TForm)
  private
    FConfig: TMultiConfig;
    FQueue: TMultiQueue;
    FASTM: tASTM;
    FLog: TMemo;
    FJob, FLastJob: string;
    FMutex, FModeLock: THandle;
    FReceived: TStringList;
    procedure Idle(Sender: TObject);
    procedure Sent(Sender: TObject);
    procedure AppException(Sender: TObject; E: Exception);
    procedure Closing(Sender: TObject; var Action: TCloseAction);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var MultiForm: TMultiForm;

implementation

constructor TMultiForm.Create(AOwner: TComponent);
var MutexName: string;
begin
  inherited CreateNew(AOwner);
  FModeLock := INVALID_HANDLE_VALUE;
  Width := 720;
  Height := 480;
  Position := poScreenCenter;
  FLog := TMemo.Create(Self);
  FLog.Parent := Self;
  FLog.Align := alClient;
  FLog.ReadOnly := True;
  FLog.ScrollBars := ssBoth;
  FReceived := TStringList.Create;
  FConfig := TMultiConfig.Create(ExtractFilePath(Application.ExeName) + 'CommASTM.ini', ParamStr(1));
  { Global namespace prevents a duplicate profile in another Windows session. }
  MutexName := 'Global\SageCommASTM.MultiEquipo.' + UpperCase(FConfig.Equipo);
  FMutex := CreateMutex(nil, False, PChar(MutexName));
  if FMutex = 0 then RaiseLastOSError;
  if GetLastError = ERROR_ALREADY_EXISTS then
    raise Exception.Create('Ya esta abierto el equipo ' + FConfig.Equipo);
  FModeLock := AcquireModeLock(ExtractFileDir(ExcludeTrailingPathDelimiter(FConfig.Pedidos)), True);
  if not ForceDirectories(FConfig.Resultados) then
    raise Exception.Create('No se puede crear ' + FConfig.Resultados);
  FQueue := TMultiQueue.Create(FConfig);
  Caption := Format('Architect MultiEquipo - %s - COM%d - %d bauds',
    [FConfig.Equipo, FConfig.Port, FConfig.Bauds]);
  Application.Title := Caption;
  FASTM := tASTM.Create(Self);
  FASTM.ComNumber := FConfig.Port;
  FASTM.Bauds := FConfig.Bauds;
  FASTM.OnIdle := Idle;
  FASTM.OnSent := Sent;
  FASTM.Active := True;
  OnClose := Closing;
  Application.OnException := AppException;
  FLog.Lines.Add('Pedidos: ' + FConfig.Pedidos);
  FLog.Lines.Add('Resultados: ' + FConfig.Resultados);
end;

procedure TMultiForm.Closing(Sender: TObject; var Action: TCloseAction);
begin
  FASTM.Stop;
  Application.Terminate;
end;

procedure TMultiForm.AppException(Sender: TObject; E: Exception);
begin
  if Assigned(FASTM) then FASTM.Stop;
  Application.Terminate;
  ExitCode := 1;
  MessageDlg('Se detuvo ' + FConfig.Equipo + ': ' + E.Message + #13#10 +
    'Los pedidos pendientes se conservan. Corrija el problema y reinicie.', mtError, [mbOK], 0);
end;

procedure TMultiForm.Idle(Sender: TObject);
var Lines: TStringList; I: Integer; Base: string;
begin
  if FLog.Lines.Count > 1000 then FLog.Clear;
  while FASTM.Count > 0 do FReceived.Add(FASTM.Data);
  if FReceived.Count > 0 then begin
    if FLastJob = '' then Base := 'default'
    else Base := ChangeFileExt(FLastJob, '');
    Base := FConfig.Resultados + FConfig.Equipo + '_' + Base + '_' + NewID;
    SaveAtomic(FReceived, Base + '.res');
    WriteMarker(Base + '.ok');
    FLog.Lines.Add('Resultado: ' + ExtractFileName(Base));
    FReceived.Clear;
  end;
  if FJob <> '' then Exit;
  Lines := TStringList.Create;
  try
    if FQueue.Next(FJob, Lines) then begin
      FLastJob := FJob;
      FLog.Lines.Add('Enviando: ' + FJob);
      for I := 0 to Lines.Count - 1 do FASTM.Data := Lines[I];
    end;
  finally
    Lines.Free;
  end;
end;

procedure TMultiForm.Sent(Sender: TObject);
begin
  if FJob = '' then Exit;
  FQueue.Delivered(FJob);
  FLog.Lines.Add('Entrega ASTM completada: ' + FJob);
  FJob := '';
end;

destructor TMultiForm.Destroy;
begin
  Application.OnException := nil;
  FreeAndNil(FASTM);
  FQueue.Free;
  FConfig.Free;
  FReceived.Free;
  if FMutex <> 0 then CloseHandle(FMutex);
  if FModeLock <> INVALID_HANDLE_VALUE then CloseHandle(FModeLock);
  inherited;
end;

end.
