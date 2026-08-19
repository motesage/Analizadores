unit SgRafDataSet;

interface

uses
  SysUtils, Classes, Db, uRafInterface;

type

  TRafDataSet = class(TDataSet)
    protected
      FStream: TStream; // the physical table
      FTableName: string; // table path and file name

      // record data
      FRecordCount, // current number of record
      FRecordSize, // the size of the actual data (como datos delphi)
      FRafRecordSize, // the size of the actual data (en el archivo)
      FRecordBufferSize, // data + housekeeping (TRecInfo)
      FRecordInfoOffset, // offset of RecInfo in record buffer
      FCurrentRecord, // current record (0 to FRecordCount - 1)
      BofCrack, // before the first record (crack)
      EofCrack: Integer; // after the last record (crack)

      // file header size (optionally used by subclasses)
      FDataFileHeaderSize: Integer;

      // status
      FIsTableOpen: Boolean;

      // field offsets in record
      FFieldOffset: TList;

      // informacion interna de los campos
      FRafFieldList: TStringList;

      // nombre del archivo de ini
      fIniName: string;

      // TDataSet virtual abstract method
      function AllocRecordBuffer: PChar; override;
      function AllocRafRecordBuffer: PChar;
      procedure FreeRecordBuffer(var Buffer: PChar); override;
      procedure GetBookmarkData(Buffer: PChar;Data: Pointer); override;
      function GetBookmarkFlag(Buffer: PChar):TBookmarkFlag; override;
      function GetRecord(Buffer: PChar; GetMode: TGetMode;DoCheck: Boolean): TGetResult; override;
      function GetRecordSize: Word; override;
      procedure InternalAddRecord(Buffer: Pointer;Append: Boolean); override;
      procedure InternalClose; override;
      procedure InternalDelete; override;
      procedure InternalFirst; override;
      procedure InternalGotoBookmark(Bookmark: Pointer); override;
      procedure InternalHandleException; override;
      procedure InternalInitFieldDefs; override;
      procedure InternalInitRecord(Buffer: PChar); override;
      procedure InternalLast; override;
      procedure InternalOpen; override;
      procedure InternalPost; override;
      procedure InternalSetToRecord(Buffer: PChar); override;
	    function InternalGetRecNumber: integer;
      function IsCursorOpen: Boolean; override;
      procedure SetBookmarkFlag(Buffer: PChar;Value: TBookmarkFlag); override;
      procedure SetBookmarkData(Buffer: PChar;Data: Pointer); override;
      procedure SetFieldData(Field: TField;Buffer: Pointer); override;

      function GetRecordCount: Integer; override;


    private
      FAllowInvalidSize: boolean;
      //cambia los datos de un tipo al otro
      procedure ConvertDelphiToRaf(Buffer, BufferRaf: PChar);
      procedure ConvertRafToDelphi(BufferRaf, Buffer: PChar);
      procedure SetAllowInvalidSize(const Value: boolean);

    public
      procedure CreateTable;
      // TDataSet virtual method (optional)
      procedure SetRecNo(Value: Integer); override;
      procedure GotoRecord(Value: Integer);
      function GetRecNo: Integer; override;
      function GetFieldData(Field: TField;Buffer: Pointer): Boolean; override;
    published
      property IniName: string read fIniName write fIniName;
      property RecordCount: integer read GetRecordCount;
      property TableName: string read FTableName write FTableName;
			property AllowInvalidSize: boolean read FAllowInvalidSize write SetAllowInvalidSize;

      // propiedades redeclaradas
      property Active;
      property BeforeOpen;
      property AfterOpen;
      property BeforeClose;
      property AfterClose;
      property BeforeInsert;
      property AfterInsert;
      property BeforeEdit;
      property AfterEdit;
      property BeforePost;
      property AfterPost;
      property BeforeCancel;
      property AfterCancel;
      property BeforeDelete;
      property AfterDelete;
      property BeforeScroll;
      property AfterScroll;
      property OnCalcFields;
      property OnDeleteError;
      property OnEditError;
      property OnFilterRecord;
      property OnNewRecord;
      property OnPostError;
  end;



procedure Register;

implementation

uses
  TypInfo, Dialogs, Windows, Forms, Controls, IniFiles, uSage3ToDelphi;

/////////////////////////////////////////////////
////// Part I:
////// Initialization, opening, and closing
/////////////////////////////////////////////////

// I: open the table/file
procedure TRafDataSet.InternalOpen;
var
  fHandle: file of byte;
begin
  // check if the file exists
  if not FileExists (FTableName) then begin
    AssignFile(fHandle, fTableName);
    Rewrite(fHandle);
    CloseFile(fHandle);
  end;

  // create a stream for the file
  FStream := TFileStream.Create (FTableName, fmOpenReadWrite or fmShareDenyNone);

  // initialize the field definitions
  // (another virtual abstract method of TDataSet)
  InternalInitFieldDefs;

  // if there are no persistent field objects,
  // create the fields dynamically
  if DefaultFields then begin
    CreateFields;
  end;

  // connect the TField objects with the actual fields
  BindFields (True);

  // get the number of records and check size
  FRecordCount := FStream.Size div FRafRecordSize;
  if not fAllowInvalidSize and ((FStream.Size mod FRafRecordSize) <> 0) then begin
    raise EDataSetOneError.Create ('Open '+fTableName+': Tamaño inválido de la tabla');
  end;

  // sets cracks and record position
  BofCrack := -1;
  EofCrack := FRecordCount;
  FCurrentRecord := BofCrack;

  FRecordInfoOffset := FRecordSize;
  FRecordBufferSize := FRecordSize + sizeof (TRecInfo);

  // the file of this version has no header
  FDataFileHeaderSize := 0;

  // set the bookmark size
  BookmarkSize := sizeOf (Integer);

  // everything OK: table is now open
  FIsTableOpen := True;

  // ShowMessage ('InternalOpen: RecCount: ' + IntToStr (FRecordCount));
end;

function TRafDataSet.InternalGetRecNumber: integer;
var
  lfStream: tStream;
begin
	result := 0;
	if FIsTableOpen then begin
	  // create a stream for the file
  	lfStream := TFileStream.Create (FTableName, fmOpenReadWrite or fmShareDenyNone);
    try
		  // get the number of records and check size
		  result := lfStream.Size div FRafRecordSize;
    finally // wrap up
    	lfStream.Free;
    end;    // try/finally
  end;
end;



// I: define the fields
procedure TRafDataSet.InternalInitFieldDefs;
var
  IniFileName, FieldName: string;
  IniFile: TIniFile;
  nFields, I, TmpFieldOffset,TmpRafFieldOffset, nSize: Integer;
  FieldType: TFieldType;
  RafFieldType: TRafFieldType;
  RafFieldInfo: tRafFieldInfo;
begin
  FFieldOffset := TList.Create;
  FRafFieldList := TStringList.Create;
  FieldDefs.Clear;
  TmpFieldOffset := 0;
  TmpRafFieldOffset := 0;
  if fIniName = '' then begin
    IniFilename := ChangeFileExt(FTableName, '.ini');
  end
  else begin
    IniFilename := ChangeFileExt(FIniName, '.ini');
  end;
  Inifile := TIniFile.Create (IniFilename);
  // protect ini file
  try
    nFields := IniFile.ReadInteger ('Campos', 'Cantidad', 0);
    if nFields = 0 then
      raise EDataSetOneError.Create ('InitFieldsDefs: No hay campos?');
    for I := 1 to nFields do begin
      // create the field
      FieldType := TFieldType (GetEnumValue(TypeInfo(TFieldType),IniFile.ReadString('Campo' + IntToStr (I), 'Tipo', '')));
      RafFieldType := TRafFieldType (GetEnumValue(TypeInfo(TRafFieldType),IniFile.ReadString('Campo' + IntToStr (I), 'TipoBasic', '')));
      FieldName := IniFile.ReadString ('Campo' + IntToStr (I), 'Nombre', '');
      if FieldName = '' then begin
        raise EDataSetOneError.Create ('InitFieldsDefs: Falta el nombre del campo '+IntToStr (I));
      end;
      nSize := IniFile.ReadInteger('Campo' + IntToStr (I), 'Largo', 0);
      FieldDefs.Add (FieldName,FieldType, nSize, False);

      //guardo el tipo raf interno
      RafFieldInfo := tRafFieldInfo.Create;
      RafFieldInfo.Nombre := FieldName;
      RafFieldInfo.TipoDelphi := FieldType;
      RafFieldInfo.TipoRaf := RafFieldType;
      RafFieldInfo.Largo := nSize;

      FRafFieldList.AddObject('',RafFieldInfo);

      case RafFieldType of
        rftString:
          Inc (TmpRafFieldOffset, nSize);
        rftAsc:
          Inc (TmpRafFieldOffset, 1);
        rftInteger, rftIx, rftDate, rftSI:
          Inc (TmpRafFieldOffset, 2);
        rftCVIV:
          inc (TmpRafFieldOffset, 3);  // nuevo Lab mgm
        rftIr,rftCVS:
          Inc (TmpRafFieldOffset, 4);
      else
        raise EDataSetOneError.Create('InitFieldsDefs: Campo '+ FieldName +' basic Data type desconocido');
      end;

      // showmessage('Campo ' + fieldname + ' tamanio acumulado = ' + inttostr(TmpRafFieldOffset));

      FFieldOffset.Add (Pointer (TmpFieldOffset));
      case FieldType of
        ftString:
          Inc (TmpFieldOffset, nSize + 1);
        ftSmallInt, ftWord:
          Inc (TmpFieldOffset, 2);
        ftInteger, ftDate, ftTime:
          Inc (TmpFieldOffset, 4);
        ftFloat, ftCurrency, ftDateTime:
          Inc (TmpFieldOffset, 8);
      else
        raise EDataSetOneError.Create (
           'InitFieldsDefs: Unsupported field type');
      end;
    end; // for
  finally
    IniFile.Free;
  end;
  FRecordSize := TmpFieldOffset;
  FRafRecordSize := TmpRafFieldOffset;
end;

// I: close the table/file
procedure TRafDataSet.InternalClose;
var
  j: integer;
begin
  // free the internal list field offsets
  if Assigned (FFieldOffset) then
    FFieldOffset.Free;

  // free the internal list field offsets
  if Assigned (FRafFieldList) then begin
    for j := 0 to FRafFieldList.Count-1 do begin    // Iterate
      FRafFieldList.Objects[j].free;
    end;    // for
    FRafFieldList.Free;
  end;

  // disconnet field objects
  BindFields (False);
  // destroy field object (if not persistent)
  if DefaultFields then
    DestroyFields;

  // close the file
  FIsTableOpen := False;
  FStream.Free;
end;

// I: is table open
function TRafDataSet.IsCursorOpen: Boolean;
begin
  Result := FIsTableOpen;
end;

// I: Create a new table/file
procedure TRafDataSet.CreateTable;
begin
  CheckInactive;
  InternalInitFieldDefs;

  // create the new file
  if FileExists (FTableName) and
    (MessageDlg ('File ' + FTableName + ' already exists. OK to override?',
      mtConfirmation, [mbYes, mbNo], 0) = mrNo) then
    Exit;
  FStream := TFileStream.Create (FTableName, fmCreate or fmShareExclusive);
  // close the file
  FStream.Free;
  FAllowInvalidSize := false;
end;

////////////////////////////////////////
////// Part II:
////// Bookmarks management and movement
////////////////////////////////////////

// II: set the requested bookmark as current record
procedure TRafDataSet.InternalGotoBookmark (Bookmark: Pointer);
var
  ReqBookmark: Integer;
begin
  ReqBookmark := PInteger (Bookmark)^;
//  ShowMessage ('InternalGotoBookmark: ' +
//    IntToStr (ReqBookmark));
  if (ReqBookmark >= 0) and (ReqBookmark < RecordCount) then
    FCurrentRecord := ReqBookmark
  else
    raise EDataSetOneError.Create ('Bookmark ' +
      IntToStr (ReqBookmark) + ' not found');
end;

// II: same as above (but passes a buffer)
procedure TRafDataSet.InternalSetToRecord (Buffer: PChar);
var
  ReqBookmark: Integer;
begin
//  ShowMessage ('InternalSetToRecord');
  ReqBookmark := PRecInfo(Buffer + FRecordInfoOffset).Bookmark;
  InternalGotoBookmark (@ReqBookmark);
end;

// II: retrieve bookmarks flags from buffer
function TRafDataSet.GetBookmarkFlag (
  Buffer: PChar): TBookmarkFlag;
begin
//  ShowMessage ('GetBookmarkFlag');
  Result := PRecInfo(Buffer + FRecordInfoOffset).BookmarkFlag;
end;

// II: change the bookmark flags in the buffer
procedure TRafDataSet.SetBookmarkFlag (Buffer: PChar;
  Value: TBookmarkFlag);
begin
//  ShowMessage ('SetBookmarkFlag');
  PRecInfo(Buffer + FRecordInfoOffset).BookmarkFlag := Value;
end;

// II: read the bookmark data from record buffer
procedure TRafDataSet.GetBookmarkData (
  Buffer: PChar; Data: Pointer);
begin
//  ShowMessage ('GetBookmarkData: ' + IntToStr (PRecInfo(Buffer + FRecordInfoOffset).Bookmark));
  PInteger(Data)^ :=
    PRecInfo(Buffer + FRecordInfoOffset).Bookmark;
end;

// II: set the bookmark data in the buffer
procedure TRafDataSet.SetBookmarkData (
  Buffer: PChar; Data: Pointer);
begin
//  ShowMessage ('SetBookmarkData: ' + IntToStr (PInteger(Data)^));
  PRecInfo(Buffer + FRecordInfoOffset).Bookmark :=
    PInteger(Data)^;
end;

// II: Go to a special position before the first record
procedure TRafDataSet.InternalFirst;
begin
  FCurrentRecord := BofCrack;
end;

// II: Go to a special position after the last record
procedure TRafDataSet.InternalLast;
begin
//  EofCrack := fRecordCount;

  EofCrack := RecordCount;
  FCurrentRecord := EofCrack;
end;

// II (optional): Record count
function TRafDataSet.GetRecordCount: Longint;
begin
//  CheckActive;
  Result := InternalGetRecNumber;
end;

// II (optional): Get the number of the current record
function TRafDataSet.GetRecNo: Longint;
begin
  UpdateCursorPos;
  if FCurrentRecord < 0 then
    Result := 1
  else
    Result := FCurrentRecord + 1;
end;

// II (optional): Move to the given record number
procedure TRafDataSet.SetRecNo(Value: Integer);
begin
  CheckBrowseMode;
  // asas MGM 3:15 AM martes 14 de junio de 2005
  // if (Value > 1) and (Value <= FRecordCount) then
  if (Value > 0) and (Value <= RecordCount) then
  begin
    FCurrentRecord := Value - 1;
    Resync([]);
  end;
end;

//////////////////////////////////////////
////// Part III:
////// Record buffers and field management
//////////////////////////////////////////

/// III: Determine the size of each record buffer in memory
function TRafDataSet.GetRecordSize: Word;
begin
  Result := FRecordSize; // data only
end;

/// III: Allocate a buffer for the record
function TRafDataSet.AllocRecordBuffer: PChar;
begin
  Result := StrAlloc(FRecordBufferSize);
end;

/// esta funcion sirve para obtener un array de memoria para la lectura real
/// del buffer del string antes de la conversion a elementos Delphi y lo
//  inicializa a zeros
function TRafDataSet.AllocRafRecordBuffer: PChar;
begin
  Result := StrAlloc(FRafRecordSize);
  FillChar(Result^, FRafRecordSize, 0);
end;

// III: Initialize the record (set to zero)
procedure TRafDataSet.InternalInitRecord(Buffer: PChar);
begin
  FillChar(Buffer^, FRecordBufferSize, 0);
end;

// III: Free the buffer
procedure TRafDataSet.FreeRecordBuffer (var Buffer: PChar);
begin
  StrDispose(Buffer);
end;

// III: Retrieve data for current, previous, or next record
// (eventually moving to it) and return the status
function TRafDataSet.GetRecord(Buffer: PChar; GetMode: TGetMode; DoCheck: Boolean): TGetResult;
var
  BufferRaf: PChar;
begin
  try
    BufferRaf := AllocRafRecordBuffer;
    if RecordCount < 1 then
      Result := grEOF
    else
    begin
      Result := grOK;
      case GetMode of
        gmNext:
        begin
          // ShowMessage ('GetRecord Next');
          // if next record is not out of range...
          if FCurrentRecord >= RecordCount - 1 then
            Result := grEOF
          else
            Inc (FCurrentRecord);
        end;
        gmPrior:
        begin
          // ShowMessage ('GetRecord Prior');
          // if previous message is not out of range
          if FCurrentRecord <= 0 then
            Result := grBOF
          else
            Dec (FCurrentRecord);
        end;
        gmCurrent:
        begin
          // ShowMessage ('GetRecord Current');
          if (FCurrentRecord >= RecordCount) or
              (FCurrentRecord < 0) then
            Result := grError;
        end;
      end;
      // load the data
      if Result = grOK then begin
        FStream.Position := FDataFileHeaderSize + FRafRecordSize * FCurrentRecord;
        FStream.ReadBuffer (BufferRaf^, FRafRecordSize);
        ConvertRafToDelphi(BufferRaf, Buffer);   // pasa al buffer como delphi

        with PRecInfo(Buffer + FRecordInfoOffset)^ do begin
          BookmarkFlag := bfCurrent;
          Bookmark := FCurrentRecord;
        end;
      end
      else
        if (Result = grError) and DoCheck then
          raise EDataSetOneError.Create (
            'GetRecord: Invalid record');
    end;
  finally
    FreeRecordBuffer(BufferRaf);
  end;
end;

// III: Write the current data to the file
procedure TRafDataSet.InternalPost;
var
  BufferRaf: pChar;
begin
  CheckActive;
  try
    BufferRaf := AllocRafRecordBuffer;
    if State = dsEdit then begin
      // replace data with new data
      FStream.Position := FDataFileHeaderSize + FRafRecordSize * FCurrentRecord;
      ConvertDelphiToRaf(ActiveBuffer,BufferRaf);
      FStream.WriteBuffer (BufferRaf^, FRafRecordSize);
    end
    else begin
      // always append
      InternalLast;
      FStream.Seek (0, soFromEnd);
      ConvertDelphiToRaf(ActiveBuffer,BufferRaf);
      FStream.WriteBuffer (BufferRaf^, FRafRecordSize);
      Inc (FRecordCount);
    end;
  finally
    FreeRecordBuffer(BufferRaf);
  end;
end;

// III: Add the current data to the file
procedure TRafDataSet.InternalAddRecord(Buffer: Pointer; Append: Boolean);
var
  BufferRaf: PChar;
begin
  try
    BufferRaf := AllocRafRecordBuffer;
    // always append
    InternalLast;
    // add record at the end of the file
    FStream.Seek (0, soFromEnd);
    ConvertDelphiToRaf(ActiveBuffer,BufferRaf);
    FStream.WriteBuffer (BufferRaf^, FRecordSize);
    Inc (FRecordCount);
  finally
    FreeRecordBuffer(BufferRaf);
  end;
end;

// III: Delete the current record
procedure TRafDataSet.InternalDelete;
begin
  // not supported in this version
  raise EDataSetOneError.Create ('Delete: Operation not supported');
end;

// III: Move data from record buffer to field
function TRafDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  FieldOffset: Integer;
  Ptr: PChar;
begin
  Result := False;
  if not IsEmpty and (Field.FieldNo > 0) then
  begin
    FieldOffset := Integer (
      FFieldOffset [Field.FieldNo - 1]);
    Ptr := ActiveBuffer;
    Inc (Ptr, FieldOffset);
    Move (Ptr^, Buffer^, Field.DataSize);
    Result := True;
  end;
end;

// III: Move data from field to record buffer
procedure TRafDataSet.SetFieldData(Field: TField; Buffer: Pointer);
var
  FieldOffset: Integer;
  Ptr: PChar;
begin
  if Field.FieldNo >= 0 then
  begin
    FieldOffset := Integer(FFieldOffset [Field.FieldNo - 1]);
    Ptr := ActiveBuffer;
    Inc (Ptr, FieldOffset);
    if Assigned (Buffer) then begin
      Move (Buffer^, Ptr^, Field.DataSize)
    end
    else begin
      ShowMessage ('very bad error in setfield data');
    end;
    DataEvent (deFieldChange, Longint(Field));
  end;
end;

// default exception handling

procedure TRafDataSet.InternalHandleException;
begin
  // standard exception handling
  Application.HandleException(Self);
end;

procedure TRafDataSet.ConvertRafToDelphi(BufferRaf, Buffer: PChar);
{ Cambia los datos del formato de grabacion al formato que tendría si los
  grabara como un stream en delphi}
var
  pRafBuffer, pDelphiBuffer: integer;
  j: integer;
  CampoInfo: tRafFieldInfo;

  bString: string;
  bChar: char;
  bInteger: integer;
  bDateTime: tDateTime;
	bFloat: real;
  largo: integer;
  cvsbuf: array[0..3] of byte;

begin
  // punteros a las posiciones de memoria en cada buffer
  pRafBuffer := 0;
  pDelphiBuffer := 0;
  for j := 0 to fRafFieldList.Count-1 do begin    // Iterate
    if Assigned(fRafFieldList.Objects[j]) then begin
      CampoInfo := fRafFieldList.Objects[j] as TRafFieldInfo;
      case CampoInfo.TipoRaf of    //
        rftString:
          begin
            if (CampoInfo.TipoDelphi = ftString) then begin
              Move(BufferRaf[pRafBuffer],Buffer[pDelphiBuffer],CampoInfo.Largo);
              Inc(pDelphiBuffer,CampoInfo.Largo);
              bChar := #0;
              Move(bChar,Buffer[pDelphiBuffer],SizeOf(bChar));
              Inc(pDelphiBuffer,SizeOf(bChar));
              Inc(pRafBuffer,CampoInfo.Largo);
            end
            else begin
              ShowMessage ('string cambiado de tipo');
            end;
          end;
        rftInteger,rftIx,rftSI:
          begin
            if (CampoInfo.TipoDelphi = ftInteger) then begin
              bString := '00';
              Move(BufferRaf[pRafBuffer],bString[1],2);
              if CampoInfo.TipoRaf = rftInteger then begin
                bInteger := cvi(bString);
              end
              else if CampoInfo.TipoRaf = rftIx  then begin
                bInteger := cvix(bString);
              end
              else begin
                // cvIS => es un entero de 2 bytes POSITIVO (0 .. 65000)
                bInteger := cvIS(bString);
              end;
              Move(bInteger,Buffer[pDelphiBuffer],SizeOf(bInteger));
              Inc(pDelphiBuffer,SizeOf(bInteger));
              Inc(pRafBuffer,2);
            end
            else begin
              ShowMessage ('integer cambiado de tipo');
            end;
          end;
        rftIr:
          begin
            if (CampoInfo.TipoDelphi = ftInteger) then begin
              bString := '0000';
              Move(BufferRaf[pRafBuffer],bString[1],4);
              bInteger := cvir(bString);
              Move(bInteger,Buffer[pDelphiBuffer],SizeOf(bInteger));
              Inc(pDelphiBuffer,SizeOf(bInteger));
              Inc(pRafBuffer,4);
            end
            else begin
              ShowMessage ('integer cambiado de tipo');
            end;
          end;
        rftCVS:
          begin
            if (CampoInfo.TipoDelphi = ftFloat) then begin
              Move(BufferRaf[pRafBuffer],cvsbuf,4);
							bFloat := MBFToFloatIEEE(cvsbuf);
              Move(bFloat,Buffer[pDelphiBuffer],SizeOf(bFloat));
              Inc(pDelphiBuffer,SizeOf(bFloat));
              Inc(pRafBuffer,4);
            end
            else begin
              ShowMessage ('integer cambiado de tipo');
            end;
          end;
        rftCVIV:
          begin
            if (CampoInfo.TipoDelphi = ftInteger) then begin
              bString := '000';
              Move(BufferRaf[pRafBuffer],bString[1],3);
              bInteger := cviv(bString);
              Move(bInteger,Buffer[pDelphiBuffer],SizeOf(bInteger));
              Inc(pDelphiBuffer,SizeOf(bInteger));
              Inc(pRafBuffer,3);
            end
            else begin
              ShowMessage ('integer cambiado de tipo');
            end;
          end;
        rftAsc: begin
            if (CampoInfo.TipoDelphi = ftInteger) then begin
              bChar := #0;
              Move(BufferRaf[pRafBuffer],bChar,1);
              bInteger := Ord(bChar);
              Move(bInteger,Buffer[pDelphiBuffer],SizeOf(bInteger));
              Inc(pDelphiBuffer,SizeOf(bInteger));
              Inc(pRafBuffer,1);
            end
            else begin
              ShowMessage ('string cambiado de tipo');
            end;
          end;
        rftDate:
          begin
            if (CampoInfo.TipoDelphi = ftDateTime) then begin
              bString := '00';
              Move(BufferRaf[pRafBuffer],bString[1],2);
              bDateTime := dn1(cvi(bString));
              if (bDateTime>36000) then  begin
                ShowMessage(FormatDateTime('c',bdateTime));
              end;
              largo := SizeOf(bDateTime);
              Move(bDateTime,Buffer[pDelphiBuffer],largo);
              Inc(pDelphiBuffer,SizeOf(bDateTime));
              Inc(pRafBuffer,2);
            end
            else begin
              ShowMessage ('date cambiado de tipo');
            end;
          end;
      end;    // case
    end;
  end;    // for
end;

procedure TRafDataSet.ConvertDelphiToRaf(Buffer, BufferRaf: PChar);
{ Cambia los datos del formato delphi (interno de los fields) al formato
  de grabacion como raf}
var
  pRafBuffer, pDelphiBuffer: integer;
  j: integer;
  CampoInfo: tRafFieldInfo;

	bFloat: real;
  bString: string;
  bChar: char;
  bInteger: integer;
  bDateTime: tDateTime;
	cvsbuf: array[0..3] of byte;
begin
  // punteros a las posiciones de memoria en cada buffer
  pRafBuffer := 0;
  pDelphiBuffer := 0;
  for j := 0 to fRafFieldList.Count-1 do begin    // Iterate
    if Assigned(fRafFieldList.Objects[j]) then begin
      CampoInfo := fRafFieldList.Objects[j] as TRafFieldInfo;
      case CampoInfo.TipoDelphi of    //
        ftString:
          begin
            if (CampoInfo.TipoRaf = rftString) then begin
              bString := StringOfChar(' ',CampoInfo.Largo+1);
              StrLCopy(PChar(bString),Buffer+pDelphiBuffer,CampoInfo.Largo);
              Move(Buffer[pDelphiBuffer],BufferRaf[pRafBuffer],CampoInfo.Largo);
              Inc(pDelphiBuffer,CampoInfo.Largo+1);
              Inc(pRafBuffer,CampoInfo.Largo);
            end
            else begin
              ShowMessage ('string cambiado de tipo');
            end;
          end;
        ftSmallInt:
          begin

          end;
        ftWord:
          begin

          end;
				ftFloat:
        	begin
          	case CampoInfo.TipoRaf of    //
              rftCVS:
              	begin
                  bFloat := 0;
                  Move(Buffer[pDelphiBuffer],bFloat,SizeOf(bFloat));
  								FloatIEEEToMbf(bFloat,cvsbuf);
                  Move(cvsbuf,BufferRaf[pRafBuffer],4);
                  Inc(pDelphiBuffer,SizeOf(bFloat));
                  Inc(pRafBuffer,4);
                end;
              else begin
                ShowMessage ('float cambiado de tipo');
              end;
						end;
          end;
        ftInteger:
          begin
            case CampoInfo.TipoRaf of    //
              rftInteger, rftIx, rftSI: begin
                  bInteger := 0;
                  Move(Buffer[pDelphiBuffer],bInteger,SizeOf(bInteger));
                  if CampoInfo.TipoRaf = rftInteger then begin
                    bString := mki(bInteger);
                  end
                  else if CampoInfo.TipoRaf = rftIx  then begin
                    bString := mkix(bInteger);
                  end
                  else begin
                    // es rftSI
                    bString := cvSI(bInteger);
                  end;
                  Move(bString[1],BufferRaf[pRafBuffer],2);
                  Inc(pDelphiBuffer,SizeOf(bInteger));
                  Inc(pRafBuffer,2);
                end;
              rftIr: begin
                  bInteger := 0;
                  Move(Buffer[pDelphiBuffer],bInteger,SizeOf(bInteger));
                  bString := mkir(bInteger);
                  Move(bString[1],BufferRaf[pRafBuffer],4);
                  Inc(pDelphiBuffer,SizeOf(bInteger));
                  Inc(pRafBuffer,4);
                end;
              rftCVIV: begin
                  bInteger := 0;
                  Move(Buffer[pDelphiBuffer],bInteger,SizeOf(bInteger));
                  bString := mkiV(bInteger);
                  Move(bString[1],BufferRaf[pRafBuffer],3);
                  Inc(pDelphiBuffer,SizeOf(bInteger));
                  Inc(pRafBuffer,3);
                end;
              rftCVS: begin
									bFloat := 0;
                  Move(Buffer[pDelphiBuffer],bFloat,SizeOf(bFloat));
									FloatIEEEToMbf(bFloat,cvsbuf);
                  Move(cvsbuf,BufferRaf[pRafBuffer],4);
                  Inc(pDelphiBuffer,SizeOf(bFloat));
                  Inc(pRafBuffer,4);
                end;
              rftAsc: begin
                  bInteger := 0;
                  Move(Buffer[pDelphiBuffer],bInteger,SizeOf(bInteger));
                  bChar := char(bInteger mod 256);
                  Move(bChar,BufferRaf[pRafBuffer],SizeOf(bChar));
                  Inc(pDelphiBuffer,SizeOf(bInteger));
                  Inc(pRafBuffer,SizeOf(bChar));
                end;
              else begin
                ShowMessage ('integer cambiado de tipo');
              end;
            end;    // case
          end;
        ftDateTime:
          begin
            if (CampoInfo.TipoRaf = rftDate) then begin
              bDateTime := EncodeDate(1900,1,1);
              Move(Buffer[pDelphiBuffer],bDateTime,SizeOf(tDateTime));
              bString := mki(Undn1(bDateTime));
              Move(bString,BufferRaf[pRafBuffer],2);
              Inc(pDelphiBuffer,SizeOf(tDateTime));
              Inc(pRafBuffer,2);
            end
            else begin
              ShowMessage ('date cambiado de tipo');
            end;
          end;
      end;    // case
    end;
  end;    // for
end;

procedure TRafDataSet.GotoRecord(Value: Integer);
// es un sinonimo para SetREcNo
begin
  SetRecNo(Value);
end;

function MBFToFloatIEEE(msbin: array of byte): real;
{ En esta funcion entra un array[0..3] of char con un numero sigle grabado en formato
	Microsoft Binary  y devuelve un float (IEEE real *8) }
var
	sign: byte;
  ieee_exp: byte;
  ieee: array[0..3] of byte;
  j: integer;
  sfValue: single;
  bString: string;
begin

	if (High(msbin)<>3) or (Low(msbin)<>0) then begin
    ShowMessage('conversion incorrecta de MBF')
  end
  else begin
		(* MS Binary Format                         *)
		(* byte order =>    m3 | m2 | m1 | exponent *)
		(* m1 is most significant byte => sbbb|bbbb *)
		(* m3 is the least significant byte         *)
		(*      m = mantissa byte                   *)
		(*      s = sign bit                        *)
		(*      b = bit                             *)
		sfValue := 0;
		sign := msbin[2] and $80;


    (* IEEE Single Precision Float Format       *)
    (*    m3        m2        m1     exponent   *)
    (* mmmm|mmmm mmmm|mmmm emmm|mmmm seee|eeee  *)
    (*          s = sign bit                    *)
    (*          e = exponent bit                *)
    (*          m = mantissa bit                *)

    for j := 0 to 3 do begin
    	ieee[j] := 0;
    end;    // for
		if msbin[3] <> 0 then begin		//
    	ieee[3] := ieee[3] or sign;

     (* MBF is bias 128 and IEEE is bias 1023. ALSO, MBF places  *)
     (* the decimal point before the assumed bit, while          *)
     (* IEEE places the decimal point after the assumed bit.     *)

			ieee_exp := msbin[3]-2;		//msbin[3] - 1 - 128 + 127

      // los primeros 7 bits del exponente en ieee[3]
      ieee[3] := ieee[3] or (ieee_exp shr 1);

      // el bit restante en el primer bit de ieee[2]
      ieee[2] := ieee[2] or (ieee_exp shl 7);

      // 01111111 sacan el bit del msb
      ieee[2]:= ieee[2] or (msbin[2] and $7f);
      ieee[1] := msbin[1];
      ieee[0] := msbin[0];

      move(ieee,sfValue,4);		//lo paso al single

    end;

  end;
  bString := FloatToStrF(sfValue,ffgeneral,7,0);
	result := StrToFloat(bString);
end;

function FloatIEEEToMBF(fValue: real; var msbin: array of byte): boolean;
var
	fSingle: single;
	bString: string;
	sign: byte;
  ieee: array[0..3] of byte;
  msbin_exp: byte;
  j: integer;

begin
	result := false;
	if (Low(msbin)=0) and (High(msbin)=3) then begin
		// lo cambio de precision para mandarlo a 4 bytes (en float ieee)
	  bString := FloatToStrF(fValue,ffgeneral,7,0);
	  fSingle := StrToFloat(bString);
	  move(fSingle, ieee,4);			//lo paso al buffer


	  sign := ieee[3] and $80;

	  msbin_exp := 0;
		msbin_exp := msbin_exp or (ieee[3] shl 1);
		msbin_exp := msbin_exp or (ieee[2] shr 7);
	
	  for j := 0 to 3 do begin
	  	msbin[j] := 0;
	  end;    // for
	  if (msbin_exp <> $fe) then begin		//este exponente es overflow en msb
	    msbin_exp := msbin_exp + 2;			//-127 +128  +1
			msbin[3] := msbin_exp;
	    msbin[2] := msbin[2] or sign;
	    msbin[2] := msbin[2] or (ieee[2] and $7f);
	    msbin[1] := ieee[1];
	    msbin[0] := ieee[0];
			result := true;
	  end;

  end;
end;


procedure Register;
begin
  RegisterComponents('Sage', [TRafDataSet]);
end;


procedure TRafDataSet.SetAllowInvalidSize(const Value: boolean);
begin
  FAllowInvalidSize := Value;
end;

end.
