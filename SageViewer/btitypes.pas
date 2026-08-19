{*************************************************************************
**
**  Copyright 1982-2001 Pervasive Software Inc. All Rights Reserved
**
*************************************************************************}
{***********************************************************************
  BTITYPES.PAS
    This is a Pascal unit for MS Windows Btrieve to be called by
    Delphi for Windows NT/2000 or Windows 9x/Me.

************************************************************************}
unit BTITypes;

interface

type
  BTI_API = word;
  BTI_LONG = longint;
  BTI_LONG_PTR = ^BTI_LONG;
  BTI_INT64 = int64;
  BTI_ULONG = longword;
  BTI_ULONG_PTR = ^BTI_ULONG;
  BTI_WORD = WORD;
  BTI_CHAR = AnsiChar;
  BTI_SINT = smallint;
  BTI_BYTE = BYTE;
  BTI_SBYTE = shortint; { Signed byte }
  BTI_SBYTE_PTR = ^BTI_SBYTE;
  BTI_CHAR_PTR = PAnsiChar;
  BTI_BOOL = BTI_ULONG;
  BTI_WORD_PTR=^BTI_WORD;
implementation

end.
