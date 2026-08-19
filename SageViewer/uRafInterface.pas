unit uRafInterface;

interface
uses
  SysUtils, Classes, Db;

type
  EDataSetOneError = class (Exception);

  PRecInfo = ^TRecInfo;
  TRecInfo = record
    Bookmark: Longint;
    BookmarkFlag: TBookmarkFlag;
  end;

  tRafFieldType = (rftString,  rftInteger, rftIr, rftIx, rftAsc, rftDate, rftCVS, rftCVIV, rftSI);

  PRafFieldInfo = ^TRafFieldInfo;
  TRafFieldInfo = class
    Nombre: string;
    TipoDelphi: tFieldType;
    TipoRaf: tRafFieldType;
    Largo: integer;
  end;

  function MBFToFloatIEEE(msbin: array of byte): real;
	function FloatIEEEToMBF(fValue: real; var msbin: array of byte): boolean;

implementation
uses Dialogs;


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

end.
