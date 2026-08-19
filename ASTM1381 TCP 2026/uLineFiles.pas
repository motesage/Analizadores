unit uLineFiles;
{ This unit contains a class definition useful for working with text files

// se usa sin cambios en SQL
 }
interface
  uses SysUtils, Classes, Windows, JvJCLUtils, Forms, Dialogs;
type
  // indicates the open mode
  tOpenMode = (tlfRead, tlfWrite, tlfReadWrite);

  tLineFile = class
    private
      fFile: TextFile;
      FOverwrite: boolean;
      FActive: boolean;
      FName: string;
      fMode: tOpenMode;
      procedure SetName(const Value: string);
      procedure SetOverwrite(const Value: boolean);
      function GetEof: boolean;
    public
      constructor Create; overload;
      constructor Create(sFileName: string); overload;
      destructor Destroy; override;
      function Read: string;
      procedure Write(s: string);
      procedure OpenForRead;
      procedure OpenForWrite;
      procedure Close;
      property Overwrite: boolean read FOverwrite write SetOverwrite;
      property Eof: boolean read GetEof;
      property FileName: string read FName write SetName;
      property Active: boolean read fActive;
  end;

implementation

{ tLineFile }

procedure tLineFile.Close;
begin
  if fActive then begin
    if (fMode = tlfWrite) then begin
      Flush(fFile);  	// flush the buffers to disk
    end;
    CloseFile(fFile);
  end;
  fMode := tlfRead;
  fActive := false;
end;

constructor tLineFile.Create;
begin
  inherited;
  fMode := tlfRead;
  FActive := false;
  FOverwrite := false;
end;

destructor tLineFile.Destroy;
begin
  Close;
  inherited;
end;

function tLineFile.Read: string;
begin
  result := '';
  if (fActive and (fMode = tlfRead)) then begin
    ReadLn(fFile,result);
  end;
end;

function tLineFile.GetEof: boolean;
begin
  result := true;
  try
    result := System.Eof(fFile);
  except
  end;
end;


procedure tLineFile.OpenForRead;
begin
  if not fActive then begin
    if (not IsEmptyStr(fName,[' '])) and FileExists(fName) then begin
  		AssignFile(fFile, fName);
      Reset(fFile);
      fActive := true;
      fMode := tlfRead;
    end;
  end;
end;

procedure tLineFile.OpenForWrite;
begin
  if not fActive then begin
    if (not IsEmptyStr(fName,[' '])) then begin
  		AssignFile(fFile, fName);
      if FOverwrite then begin
        ReWrite(fFile);
      end
      else begin
        if not FileExists(fName) then begin
          ReWrite(fFile);
          CloseFile(fFile);
        end;
        Append(fFile);
      end;
      fActive := true;
      fMode := tlfWrite;
    end;
  end;
end;

procedure tLineFile.Write(s: string);
begin
  if (fActive and (fMode <> tlfRead)) then begin
    Writeln(fFile,s);
  end
end;


procedure tLineFile.SetName(const Value: string);
begin
  FName := Value;
end;

procedure tLineFile.SetOverwrite(const Value: boolean);
begin
  FOverwrite := Value;
end;

constructor tLineFile.Create(sFileName: string);
begin
  self.Create;
  FileName := sFileName;
end;

end.
