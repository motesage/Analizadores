unit SgBtrDataSet;

interface

uses
  SysUtils, Classes, Db, uRafInterface, btrApi32, btrconst;

const
	MAX_BTR_DATA_BUFFER = 8096;

type

  btr_client_id = packed record
    networkandnode : array[1..12] of char;
    applicationID  : array[1..3] of char;
    threadID       : smallint;
  end;

  btr_version_struct = packed record
    version   : smallint;
    revision  : smallint;
    MKDEId    : char;
  end;

{***************************************************************************
  Record type definitions for Stat and Create operations
****************************************************************************}
  FILE_SPECS = packed record
    recLength   : smallint;
    pageSize    : smallint;
    indexCount  : smallint;
    RecordCount : integer;
    flags       : smallint;
    dupPointers : byte;
    notUsed     : byte;
    allocations : smallint;
  end;

  KEY_SPECS = packed record
    position : smallint;
    length : smallint;
    flags : smallint;
    uniquevalues : integer;
    keyType : char;
    nullChar : char;
    notUsed : array[0..1] of char;
    manualKeyNumber : byte;
    acsNumber : byte;
  end;

  FILE_CREATE_BUF = packed record
    fileSpecs : FILE_SPECS;
    keySpecs  : array[0..118] of KEY_SPECS;
  end;


  tBtrDataSet = class(TDataSet)
    protected
      FTableName: string; // table path and file name

      // record data
      FRecordCount, // current number of record
      FRecordSize, // the size of the actual data (como datos delphi)
      FRafRecordSize, // the size of the actual data (en el archivo)
      FRecordBufferSize, // data + housekeeping (TRecInfo)
      FRecordInfoOffset: Integer; // offset of RecInfo in record buffer
      FCurrentRecord: LongInt; // current record (0 to FRecordCount - 1)
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

  		//variables para usar con los calls a BTRVID
      fStatus: integer;
			fPosBlock: string[128];
		  fDataBuffer: array[0..MAX_BTR_DATA_BUFFER] of char;
      fDataLen: word;
      fKeyBuf: string[255];
      fKeyNumber: smallint;
		  fVersionBuffer : array[1..3] of btr_version_struct;
      fPositionBuffer: array[0..3] of byte;   //integer;

      fFileCreateBuffer: FILE_CREATE_BUF;

      fInternalRecordBuffer: pChar;

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
      function IsCursorOpen: Boolean; override;
      procedure SetBookmarkFlag(Buffer: PChar;Value: TBookmarkFlag); override;
      procedure SetBookmarkData(Buffer: PChar;Data: Pointer); override;
      procedure SetFieldData(Field: TField;Buffer: Pointer); override;

      function GetRecordCount: Integer; override;

    private
      FAllowInvalidSize: boolean;
  	  FBtrReadOnly: boolean;
      //cambia los datos de un tipo al otro
      procedure ConvertDelphiToRaf(Buffer, BufferRaf: PChar);
      procedure ConvertRafToDelphi(BufferRaf, Buffer: PChar);
      procedure SetAllowInvalidSize(const Value: boolean);
	    function GetBtrieveLoaded: boolean;
	    function GetBtrVersion: integer;
	    function BtrOpen: boolean;
   		function BtrStat: boolean;
	    function BtrClose: boolean;
	    function BtrFirst: boolean;
	    procedure SetKeyNumber(const Value: integer);
	    function GetKeyNumber: integer;
	    function BtrGetPosition: boolean;
	    function BtrGotoPosition(btrPosition: integer): boolean;
  	  function GetCurrentRecordNo: integer;
	    function PositionToInt: integer;
	    function BtrLast: boolean;
  	  function BtrNext: boolean;
	    function BtrPrevious: boolean;
	    function GetIndexCount: integer;
	    function GetKeysAsText: string;
	    procedure SetBtrReadOnly(const Value: boolean);
    public
			constructor Create(AOwner: TComponent); override;
      procedure CreateTable;
      // TDataSet virtual method (optional)
	    function BtrLocate(clave,inicial,final: integer): boolean;
      function BtrGetNext: boolean;
      function BtrGetPrevious: boolean;
      procedure SetRecNo(Value: Integer); override;
      procedure GotoRecord(Value: Integer);
      function GetRecNo: Integer; override;
      function GetFieldData(Field: TField;Buffer: Pointer): Boolean; override;
    published
			property BtrReadOnly: boolean read FBtrReadOnly write SetBtrReadOnly;
			property KeysAsText: string read GetKeysAsText;
			property KeyNumber: integer read GetKeyNumber write SetKeyNumber;
      property IniName: string read fIniName write fIniName;
      property RecordCount: integer read GetRecordCount;
      property TableName: string read FTableName write FTableName;
			property AllowInvalidSize: boolean read FAllowInvalidSize write SetAllowInvalidSize;
			property Status: integer read fStatus;
      property BtrieveLoaded: boolean read GetBtrieveLoaded;
      property CurrentRecord: integer read GetCurrentRecordNo;
      property IndexCount: integer read GetIndexCount;

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
procedure tBtrDataSet.InternalOpen;
begin

  if (not self.BtrOpen) then begin
    raise EDataSetOneError.Create ('Open '+fTableName+': Error de apertura ('+IntToStr(fStatus)+')');
  end;

  // initialize the field definitions
  // (another virtual abstract method of TDataSet)
  InternalInitFieldDefs;

  // if there are no persistent field objects,
  // create the fields dynamically
  if DefaultFields then begin
    CreateFields;
  end;

  if not BtrStat then begin
    raise EDataSetOneError.Create ('Stat '+fTableName+': Error ('+IntToStr(fStatus)+')');
  end;

  // connect the TField objects with the actual fields
  BindFields (True);

  if ((not fAllowInvalidSize) and (fFileCreateBuffer.fileSpecs.recLength <> FRafRecordSize)) then begin
    raise EDataSetOneError.Create ('Open '+fTableName+': Tamaño inválido de la tabla');
  end;

  // sets cracks and record position
  BtrLast;
  EofCrack := PositionToInt;
  BtrFirst;
  BofCrack := PositionToInt;
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



// I: define the fields
procedure tBtrDataSet.InternalInitFieldDefs;
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
    IniFilename := ChangeFileExt(FTableName, '.DEF');
  end
  else begin
    IniFilename := ChangeFileExt(FIniName, '.DEF');
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
        rftInteger,rftIx,rftDate,rftSI:
          Inc (TmpRafFieldOffset, 2);
        rftIr,rftCVS:
          Inc (TmpRafFieldOffset, 4);
      else
        raise EDataSetOneError.Create('InitFieldsDefs: basic Data type desconocido');
      end;

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
procedure tBtrDataSet.InternalClose;
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
	btrClose;
  FIsTableOpen := False;
end;

// I: is table open
function tBtrDataSet.IsCursorOpen: Boolean;
begin
  Result := FIsTableOpen;
end;

// I: Create a new table/file
procedure tBtrDataSet.CreateTable;
begin
  CheckInactive;
  InternalInitFieldDefs;

  // create the new file
  if FileExists (FTableName) and
    (MessageDlg ('File ' + FTableName + ' already exists. OK to override?',
      mtConfirmation, [mbYes, mbNo], 0) = mrNo) then
    Exit;
  FAllowInvalidSize := false;
end;

////////////////////////////////////////
////// Part II:
////// Bookmarks management and movement
////////////////////////////////////////

// II: set the requested bookmark as current record
procedure tBtrDataSet.InternalGotoBookmark (Bookmark: Pointer);
var
  ReqBookmark: Integer;
begin
  ReqBookmark := PInteger (Bookmark)^;
//  ShowMessage ('InternalGotoBookmark: ' +
//    IntToStr (ReqBookmark));
  if BtrGotoPosition(ReqBookmark) then
    FCurrentRecord := ReqBookmark
  else
    raise EDataSetOneError.Create ('Bookmark ' +
      IntToStr (ReqBookmark) + ' not found');
end;

// II: same as above (but passes a buffer)
procedure tBtrDataSet.InternalSetToRecord (Buffer: PChar);
var
  ReqBookmark: Integer;
begin
//  ShowMessage ('InternalSetToRecord');
  ReqBookmark := PRecInfo(Buffer + FRecordInfoOffset).Bookmark;
  InternalGotoBookmark (@ReqBookmark);
end;

// II: retrieve bookmarks flags from buffer
function tBtrDataSet.GetBookmarkFlag (
  Buffer: PChar): TBookmarkFlag;
begin
//  ShowMessage ('GetBookmarkFlag');
  Result := PRecInfo(Buffer + FRecordInfoOffset).BookmarkFlag;
end;

// II: change the bookmark flags in the buffer
procedure tBtrDataSet.SetBookmarkFlag (Buffer: PChar;
  Value: TBookmarkFlag);
begin
//  ShowMessage ('SetBookmarkFlag');
  PRecInfo(Buffer + FRecordInfoOffset).BookmarkFlag := Value;
end;

// II: read the bookmark data from record buffer
procedure tBtrDataSet.GetBookmarkData (
  Buffer: PChar; Data: Pointer);
begin
//  ShowMessage ('GetBookmarkData: ' + IntToStr (PRecInfo(Buffer + FRecordInfoOffset).Bookmark));
  PInteger(Data)^ :=
    PRecInfo(Buffer + FRecordInfoOffset).Bookmark;
end;

// II: set the bookmark data in the buffer
procedure tBtrDataSet.SetBookmarkData (
  Buffer: PChar; Data: Pointer);
begin
//  ShowMessage ('SetBookmarkData: ' + IntToStr (PInteger(Data)^));
  PRecInfo(Buffer + FRecordInfoOffset).Bookmark :=
    PInteger(Data)^;
end;

// II: Go to a special position before the first record
procedure tBtrDataSet.InternalFirst;
begin
	btrFirst;
	fCurrentRecord := PositionToInt;
//  FCurrentRecord := BofCrack;
end;

// II: Go to a special position after the last record
procedure tBtrDataSet.InternalLast;
begin
	btrLast;
  FCurrentRecord := PositionToInt;
  EofCrack := fCurrentRecord;
end;

// II (optional): Record count
function tBtrDataSet.GetRecordCount: Longint;
begin
  Result := self.fFileCreateBuffer.fileSpecs.RecordCount;
end;

function tBtrDataSet.PositionToInt: integer;
begin
	result := fPositionBuffer[0]*65536+fPositionBuffer[1]*65536*256+fPositionBuffer[2]+fPositionBuffer[3]*256;
end;

// II (optional): Get the number of the current record
function tBtrDataSet.GetRecNo: Longint;
begin
  UpdateCursorPos;
	BtrGetPosition;
  fCurrentRecord := PositionToInt;     //fPositionBuffer);
  result := fCurrentRecord;
end;

// II (optional): Move to the given record number
procedure tBtrDataSet.SetRecNo(Value: Integer);
begin
  CheckBrowseMode;
  // asas MGM 3:15 AM martes 14 de junio de 2005
  // if (Value > 1) and (Value <= FRecordCount) then
  FCurrentRecord := Value;
  Resync([]);
end;

//////////////////////////////////////////
////// Part III:
////// Record buffers and field management
//////////////////////////////////////////

/// III: Determine the size of each record buffer in memory
function tBtrDataSet.GetRecordSize: Word;
begin
  Result := FRecordSize; // data only
end;

/// III: Allocate a buffer for the record
function tBtrDataSet.AllocRecordBuffer: PChar;
begin
  Result := StrAlloc(FRecordBufferSize);
  fInternalRecordBuffer := result;
end;

/// esta funcion sirve para obtener un array de memoria para la lectura real
/// del buffer del string antes de la conversion a elementos Delphi y lo
//  inicializa a zeros
function tBtrDataSet.AllocRafRecordBuffer: PChar;
begin
  Result := StrAlloc(FRafRecordSize);
  FillChar(Result^, FRafRecordSize, 0);
end;

// III: Initialize the record (set to zero)
procedure tBtrDataSet.InternalInitRecord(Buffer: PChar);
begin
  FillChar(Buffer^, FRecordBufferSize, 0);
end;

// III: Free the buffer
procedure tBtrDataSet.FreeRecordBuffer (var Buffer: PChar);
begin
  StrDispose(Buffer);
end;

// III: Retrieve data for current, previous, or next record
// (eventually moving to it) and return the status
function tBtrDataSet.GetRecord(Buffer: PChar; GetMode: TGetMode; DoCheck: Boolean): TGetResult;
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
            if not btrNext then begin
              if fStatus = B_END_OF_FILE then begin
                Result := grEOF
              end
              else begin
                Result := grError;
              end;
            end;
					end;
        gmPrior:
          begin
            // ShowMessage ('GetRecord Prior');
            // if previous message is not out of range
            if not btrPrevious then begin
              if fStatus = B_END_OF_FILE then begin
                Result := grBOF
              end
              else begin
                Result := grError;
              end;
            end;
          end;
        gmCurrent:
          begin
            // ShowMessage ('GetRecord Current');
            if fStatus<>0 then
              Result := grError;
          end;
      end;
      // load the data
      if Result = grOK then begin
        ConvertRafToDelphi(fDataBuffer, Buffer);   // pasa al buffer como delphi
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
procedure tBtrDataSet.InternalPost;
var
  BufferRaf: pChar;
begin
  CheckActive;
  try
    BufferRaf := AllocRafRecordBuffer;
    if State = dsEdit then begin
      // replace data with new data
//      FStream.Position := FDataFileHeaderSize + FRafRecordSize * FCurrentRecord;
      ConvertDelphiToRaf(ActiveBuffer,BufferRaf);
//      FStream.WriteBuffer (BufferRaf^, FRafRecordSize);
    end
    else begin
      // always append
      InternalLast;
//      FStream.Seek (0, soFromEnd);
      ConvertDelphiToRaf(ActiveBuffer,BufferRaf);
//      FStream.WriteBuffer (BufferRaf^, FRafRecordSize);
      Inc (FRecordCount);
    end;
  finally
    FreeRecordBuffer(BufferRaf);
  end;
end;

// III: Add the current data to the file
procedure tBtrDataSet.InternalAddRecord(Buffer: Pointer; Append: Boolean);
var
  BufferRaf: PChar;
begin
  try
    BufferRaf := AllocRafRecordBuffer;
    // always append
    InternalLast;
    // add record at the end of the file
//    FStream.Seek (0, soFromEnd);
    ConvertDelphiToRaf(ActiveBuffer,BufferRaf);
//    FStream.WriteBuffer (BufferRaf^, FRecordSize);
    Inc (FRecordCount);
  finally
    FreeRecordBuffer(BufferRaf);
  end;
end;

// III: Delete the current record
procedure tBtrDataSet.InternalDelete;
begin
  // not supported in this version
  raise EDataSetOneError.Create ('Delete: Operation not supported');
end;

// III: Move data from record buffer to field
function tBtrDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
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
procedure tBtrDataSet.SetFieldData(Field: TField; Buffer: Pointer);
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

procedure tBtrDataSet.InternalHandleException;
begin
  // standard exception handling
  Application.HandleException(Self);
end;

procedure tBtrDataSet.ConvertRafToDelphi(BufferRaf, Buffer: PChar);
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
              else if CampoInfo.TipoRaf = rftIx then begin
                bInteger := cvix(bString);
              end
              else begin
                bInteger := cviS(bString);
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

procedure tBtrDataSet.ConvertDelphiToRaf(Buffer, BufferRaf: PChar);
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
              rftInteger, rftIx,rftSI: begin
                  bInteger := 0;
                  Move(Buffer[pDelphiBuffer],bInteger,SizeOf(bInteger));
                  if CampoInfo.TipoRaf = rftInteger then begin
                    bString := mki(bInteger);
                  end
                  else if CampoInfo.TipoRaf = rftIx then begin
                    bString := mkix(bInteger);
                  end
                  else begin
                    bString := CvSI(bInteger);
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

procedure tBtrDataSet.GotoRecord(Value: Integer);
// es un sinonimo para SetREcNo
begin
  SetRecNo(Value);
end;



procedure Register;
begin
  RegisterComponents('Sage', [tBtrDataSet]);
end;


procedure tBtrDataSet.SetAllowInvalidSize(const Value: boolean);
begin
  FAllowInvalidSize := Value;
end;

function tBtrDataSet.GetBtrieveLoaded: boolean;
begin
{ Se fija si el btrieve esta cargado }
  fStatus := GetBtrVersion;
  result := (fStatus = 0);
end;

function tBtrDataSet.GetBtrVersion: integer;
var
	DataLen: word;
begin
	DataLen := sizeof(fVersionBuffer);
	result := BTRV(B_VERSION,fposBlock,fVersionBuffer,DataLen,fkeyBuf[1],fKeyNumber);
end;

function tBtrDataSet.BtrOpen: boolean;
var
	StatKeyBuffer: string;
	DataLen: word;
  OpenMode: SmallInt;
begin
	if FBtrReadOnly then begin
		OpenMode := -2; 	// read only
  end
  else begin
		OpenMode := 0; 	// normal
  end;

  fillChar(fDataBuffer,sizeof(fDataBuffer),#0);		//limpio el data buffer
  fillChar(StatKeyBuffer,sizeof(StatKeyBuffer),#0);					//limpio el data buffer
  DataLen := 0;
  StatKeyBuffer := fTableName + #0;
	fStatus := BTRV(B_OPEN,fposBlock,fDataBuffer,DataLen,StatKeyBuffer[1],OpenMode);
  result := (fStatus = 0);
end;

function tBtrDataSet.BtrClose: boolean;
var
	DataLen: word;
begin
  fillChar(fDataBuffer,sizeof(fDataBuffer),#0);		//limpio el data buffer
  fillChar(fKeyBuf,sizeof(fKeyBuf),#0);					//limpio el data buffer
  DataLen := 0;
  fKeyBuf := fTableName + #0;
	fStatus := BTRV(B_CLOSE,fposBlock,fDataBuffer,DataLen,fkeyBuf[1],fKeyNumber);
  result := (fStatus = 0);
end;

function tBtrDataSet.BtrStat: boolean;
var
	StatKeyBuffer: array[0..255] of char;
	DataLen: word;
  KeyNumber: word;
begin
  fillChar(fFileCreateBuffer,sizeof(fFileCreateBuffer),#0);		//limpio el buffer de status
  DataLen := sizeof(fFileCreateBuffer);
  fillChar(StatKeyBuffer,sizeof(StatKeyBuffer),#0);					//limpio el data buffer
  KeyNumber := 0;
	fStatus := BTRV(B_STAT,fposBlock,fFileCreateBuffer,DataLen,StatKeyBuffer[1],KeyNumber);
  result := (fStatus = 0);
end;

function tBtrDataSet.BtrFirst: boolean;
var
	DataLen: word;
begin
  DataLen := sizeof(fDataBuffer);
	fStatus := BTRV(B_GET_FIRST,fposBlock,fDataBuffer,DataLen,fKeyBuf[1],fKeyNumber);
  result := (fStatus = 0);
  if result then begin
    btrGetPosition;
  end;
end;

function tBtrDataSet.BtrLast: boolean;
var
	DataLen: word;
begin
  DataLen := sizeof(fDataBuffer);
	fStatus := BTRV(B_GET_LAST,fposBlock,fDataBuffer,DataLen,fKeyBuf[1],fKeyNumber);
  result := (fStatus = 0);
  if result then begin
    btrGetPosition;
  end;
end;

function tBtrDataSet.BtrNext: boolean;
var
	DataLen: word;
begin
  DataLen := sizeof(fDataBuffer);
	fStatus := BTRV(B_GET_NEXT,fposBlock,fDataBuffer,DataLen,fKeyBuf[1],fKeyNumber);
  result := (fStatus = 0);
  if result then begin
    btrGetPosition;
  end;
end;

function tBtrDataSet.BtrPrevious: boolean;
var
	DataLen: word;
begin
  DataLen := sizeof(fDataBuffer);
	fStatus := BTRV(B_GET_PREVIOUS,fposBlock,fDataBuffer,DataLen,fKeyBuf[1],fKeyNumber);
  result := (fStatus = 0);
  if result then begin
    btrGetPosition;
  end;
end;

function tBtrDataSet.BtrGetPosition: boolean;
var
	DataLen: word;
  KeyNum: smallInt;
begin
	KeyNum := 0;
  DataLen := sizeof(fPositionBuffer);
	fStatus := BTRV(B_GET_POSITION,fposBlock,fPositionBuffer,DataLen,fKeyBuf[1],KeyNum);
  result := (fStatus = 0);
end;

function tBtrDataSet.BtrGotoPosition(btrPosition: integer): boolean;
var
	DataLen: word;
  KeyNum: smallInt;
begin
	KeyNum := -1;
	move(btrPosition,fDataBuffer[0],sizeof(btrPosition));
  DataLen := sizeof(fDataBuffer);
	fStatus := BTRV(B_GET_POSITION,fposBlock,fDataBuffer,DataLen,fKeyBuf[1],KeyNum);
  result := (fStatus = 0);
end;


{
constructor tBtrDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fKeyNum := 0;
end;
}
procedure tBtrDataSet.SetKeyNumber(const Value: integer);
begin
//  FKeyNumber := (Value and $ff);
  FKeyNumber := Value;  // no me dejaba poner negativos !!
end;

function tBtrDataSet.GetKeyNumber: integer;
begin
	result := fKeyNumber;
end;

function tBtrDataSet.GetCurrentRecordNo: integer;
begin
  btrGetPosition;
  result := PositionToInt;    //fPositionBuffer;
end;

function tBtrDataSet.BtrLocate(clave,inicial,final: integer): boolean;
var
	BufferDelphi, BufferRaf: pChar;
  j, prueba: Integer;
	FindKeyBuffer: string;
	DataLen: word;
  KeyNumber: word;
begin
  BufferRaf := AllocRafRecordBuffer;
  try
    ConvertDelphiToRaf(ActiveBuffer, BufferRaf);
		FindKeyBuffer := '';

    // para boleta
    // for j := 0 to 4 do begin		// Iterate
    // para HHCC
    //for j := 25 to 28 do begin		// Iterate

    for j := inicial to final do begin		// Iterate
      FindKeyBuffer := FindKeyBuffer + BufferRaf[j];
    end;		// for
	  DataLen := sizeof(fDataBuffer);
	  KeyNumber := clave;
		// fStatus := BTRV(B_GET_GE,fposBlock,fDataBuffer,DataLen,FindKeyBuffer[1],KeyNumber);
		fStatus := BTRV(B_GET_EQUAL,fposBlock,fDataBuffer,DataLen,FindKeyBuffer[1],KeyNumber);

	  result := (fStatus = 0);
		if result then Resync([]);

  finally
    FreeRecordBuffer(BufferRaf);
  end;
end;

function tBtrDataSet.BtrGetNext: boolean;
begin
  if btrNext then begin
	  Resync([]);
	  result := (fStatus = 0);
  end
  else begin
    result := false;
  end;
end;

function tBtrDataSet.BtrGetPrevious: boolean;
begin
  if BtrPrevious then begin
	  Resync([]);
	  result := (fStatus = 0);
  end
  else begin
    result := false;
  end;
end;

function tBtrDataSet.GetIndexCount: integer;
begin
	result := 0;
	if FIsTableOpen then begin
		result := fFileCreateBuffer.fileSpecs.indexCount;
  end;
end;

function tBtrDataSet.GetKeysAsText: string;
var
	j: integer;
  kData: KEY_SPECS; 
begin
	result := 'clave  segmento  posicion  largo '+CrLf;
//	for j := 0 to 118 do begin		// Iterate
//		if fFileCreateBuffer.keySpecs[j].length>0 then begin
//      result := result + format('%d %d %d %d',[]);
//    end;

//		result :=
//  end;		// for
//  result
end;

procedure tBtrDataSet.SetBtrReadOnly(const Value: boolean);
begin
  FBtrReadOnly := Value;
end;

constructor tBtrDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
	FBtrReadOnly := false;
end;

end.
