unit uSage3ToDelphi;
	{
		Esta unidad contiene funciones de conversion entre strings e integers
		de uso comun en Basic y en la Sage3.
		El objeto de tenerlas aca es poder usarlas en caso de compatibilidad
		con Basic

		Creada 29/12/99 EPD

		Falta:
				Tener en cuenta correccion de errores
	}

interface

uses
	RxDateUtil, Windows,Messages, SysUtils, RxStrUtils, Controls, Dialogs;

type
	trecStrIniFin = record
		Inicial: string;
		Final: string;
	end;

	trecIntIniFin = record
		Inicial: Integer;
		Final: Integer;
	end;

	trecDateIniFin = record
		Inicial: TDateTime;
		Final: TDateTime;
	end;


  // para LAB
  // Edad = diferencia entre anios, si da negativo, le sumo 100
function Edad(nacimiento: tDateTime): integer;

	// sgn es equivalente a sgn(n) en Basic -n, 0, n  -> (-1,0,1)
function Sgn(I:Integer): Integer;

// igual al cvi del basic  string[2] -> integer
function Cvi(s:string): Integer;

// da un integer pero entre 0 y 65000 (de 2 bytes saca los negativos)
function cvIS(s: string): Integer;
function cvSI(i: Integer): string;

	// igual al cvix de sage3  string[2] ordenable -> integer
function Cvix(s:string): Integer;

 	// igual al cvir de sage3  string[4] ordenable -> integer
function Cvir(s:string): Integer;

  // nuevo para LAB !!
  // string[3] -> integer
function Cviv(s:string): Integer;
function mkiV(n: integer): string;

	// igual al mki del basic  Integer -> string[2]
function Mki(n:Integer): String;

	// igual al mkix de sage3  Integer -> string[2] ordenable
function Mkix(n:Integer): String;

	// igual al mkix de sage3  Integer -> string[4] ordenable
function Mkir(n:Integer): String;

	// convierte S o N en True o False (ojo!! el default es False)
	// y solo es true si S o s
function CharToBool(s: String): Boolean;

	// convierte True o False en S o N
function BoolToChar(b: Boolean): Char;

	// convierte de numeros guardados en Dn1 a TDateTime
function Dn1(n: Integer): TDateTime;
function LabDn1(n: Integer): TDateTime;

	// convierte de TDateTime a integer compatibles con la fecha SAGE
function UnDn1(f: TDateTime): integer;

	// convierte de numeros guardados en Minutos a TDateTime
function MinutosToTime(n: Integer): TDateTime;

	// convierte de TDateTime a minutos
function TimeToMinutos(tTime: tDateTime): integer;

	// completa un String (de digitos) con ceros adelante
function Compl(m: Integer; const Digitos: Integer): String;

	// completa un String (de digitos) con ceros adelante y con 2 decimales
function Compl2(m: Real; const Digitos: Integer): String;

{devuelve un string de largo N tomado de la derecha
de S si alcanzan los caracteres, o bien S completo mas
blancos a la izquierda si no alcanzan}
function Right(S: String; const n: Integer): String;

{devuelve un string de largo N tomado de la izquierda
de S si alcanzan los caracteres, o bien S completo mas
blancos a la derecha si no alcanzan}
function Left(S: String; const n: Integer): String;

{convierte una hora expresada en minutos desde la medianoche
en el formato std Sage de 24 hs como un string HH:MM}
function Hora(const iHora: Integer): String;

{convierte una hora expresada en minutos desde la medianoche
en el formato std Sage de 24 hs como un string HHH:MM
Es similar a Hora solo que permite una cantidad de horas mayor}
function Horas(const iHoras, DigitosHora: Integer ): String;

{es similar a Horas pero devuelve un string sin ceros adelante}
function HorasN(const iHoras, DigitosHora: Integer ): String;

{es similar a Hora pero devuelve un string 00:00 cuando la hora es cero}
function HoraZ(const iHora: Integer ): String;

{Devuelve un integer con la cantidad de minutos desde la medianoche
 Supone que sHora es un string con largo 5 y formato de hora o similar}
function UnHora(const sHora: String ): Integer;

{ Devuelve el dia de la semana segun convencion SAGE}
function DiaSemanaSage(const Fecha: tDateTime): integer;

//asc devuelve el ascii de la primera letra de s o bien un 0
function Asc(const s: String ): Integer;

//MakeStrPrintable saca de un string todos los caracteres no alfabéticos
function MakeStrPrintable(const s: String ): String;

//GenClaveAlfa genera uns string de Largo caracteres con le contenido de s
//sin tener en cuenta mayusculas, minusculas, signos de puntuacion  ni blancos
function GenClaveAlfa(const s: String; const Largo: Integer ): String;


// GetFlag desempaqueta un conjunto de flags de un integer
function GetFlags(sInput: string; BitPos: integer): boolean;

// paramvar es para obtener strings de largo variable del archivo de parámetros
// (c3.raf) del sistema viejo
function ParamVar(StInput: string): string;

procedure FillChArray(var chArray: array of char; C: Char);

procedure CopyToArray(var chArray: array of char; st: string; Index: integer);

function IntToStrNoZero(i: Integer): string;

// Devuelve el string s entre tildes
function StrTilde(s: string): string;

// compara s2 con s2 case non sensitive y saca blancos antes y despues
function TrimmedTextEqual(s1,s2: string): boolean;

// compara s2 con s2 case non sensitive y saca blancos antes y despues
function FechaLast: tDateTime;

// permite setear la fecha y la hora de la maquina
procedure SetDateTime(Year, Month, Day, Hour, Minu, Sec, MSec: Word);

// toler genera un string con los valores de la tolerancia poniendo 0-250 como
// cantidad de minutos y --- para cualquier cosa superior a 250
function Toler(Minutos: integer): string;


const
	cHoraSep = ':';
	cFechaSep = '/';
	cTilde = '''';

	CrLf = #10 + #13;


	Si = true;
	No = false;

implementation

function TrimmedTextEqual(s1,s2: string): boolean;
begin
  result := (Trim(UpperCase(s1)) =  Trim(UpperCase(s2)));
end;

function IntToStrNoZero(i: Integer): string;
begin
  if i=0 then
    Result := ''
  else
    Result := IntToStr(i);
end;

procedure CopyToArrayInternal(var chArray: array of char; st: string;Index, Count: integer);
	var
		j: integer;
		cha: Char;
	begin
		if Index>0 then begin
			Dec(Index);
			for j := 1 to Count do begin    // Iterate
				if (Index<=High(chArray)) then begin
					if j <= Length(st) then
						cha := St[j]
					else
						cha := #0;
					chArray[Index] := cha;
					Inc(Index);
				end;
			end;    // for
		end;
	end;

procedure CopyToArray(var chArray: array of char; st: string; Index: integer);
begin
	CopyToArrayInternal(chArray, st, index, Length(st));
end;

procedure FillChArray(var chArray: array of char; C: Char);
var
	j: integer;
begin
	for j := low(chArray) to high(chArray) do begin    // Iterate
		chArray[j] := c;
	end;    // for
end;

function GetFlags(sInput: string; BitPos: integer): boolean;
var
	Bit, ByteCount, MyBit: integer;
	intResult, j: integer;
begin
	ByteCount := 1;
	Bit := BitPos;
	while (Bit>7) do begin
		inc(ByteCount);
		dec(Bit,8);
	end;    // while

	myBit := 1;
	for j := 1 to Bit do begin    // Iterate
		myBit := 2 * myBit;						//	myBit := 2 ^ Bit;
	end;    // for

	if (Length(sInput)<ByteCount) then
		intResult := 0
	else
		intResult := asc(sInput[ByteCount]) and (myBit);

	result := (intResult<>0);
end;

function MakeStrPrintable(const s: String): String;
var
	m: char;
	SBuf: string;
	j: Integer;
begin
	SBuf := '';
	for j := 1 to Length(s) do begin    // Iterate
		m := s[j];
		if (m < ' ') then m := ' ';
		sBuf := sBuf + m;
	end;    // for
	Result := SBuf;
end;

function ParamVar(StInput: string): string;
var
	cLargo: Integer;
begin
	cLargo := Asc(StInput);
	if (cLargo>0) then
		Result := Copy(StInput,2,cLargo)
	else
		Result := '';
end;

function Sgn(I:Integer): Integer;
begin
	if I = 0 then
		Result := 0
	else if I > 0 then
		Result := 1
	else
		Result := -1;
end;

function Cvi(s:string): Integer;
begin
	if Length(s) <> 2 then
		Result := 0
	else begin
		if Ord(s[2]) < 127 then
			Result := Ord(s[1]) + (256 * Ord(s[2]))
		else
			Result := ((Ord(s[1])) + (256 * (Ord(s[2])-128))) - 32768;
	end;
end;

function Mki(n:Integer): String;
var
	m: Integer;
	s: string;
begin
	if (n > 32767) or (n < (-32768)) then
		s := #0 + #0
	else
		if n > 0 then
			s := Chr(n mod 256) + Chr(n div 256)
		else begin
			m := n + 32768;
			s := Chr(m mod 256) + Chr(128 + (m div 256));
		end;
	Result := s;
end;


function Cvix(s:string): Integer;
var
	n: Integer;
begin
	if Length(s) <> 2 then
		Result := 0
	else begin
		n := cvi(s[2]+s[1]);		//doy vuelta los bytes
		if n = -32768 then
			Result := 0
		else
			Result := (-32768 + Abs(n)) * sgn(n);
	end
end;


function Mkix(n:Integer): String;
var
	s: string;
begin
	if (n > 32767) or (n < (-32768)) then
		Result := #0 + #0
	else begin
		s := mki(sgn(n) * (-32768 + abs(n)));
		Result := s[2] + s[1];
	end;
end;

function cviV(S: string): Integer;
begin
	if Length(s) <> 3 then
		Result := 0
	else begin
		Result := (ord(s[1]) * 65536) + (ord(s[2]) * 256) + ord(s[3]);
	end
	//	ffnVI! = ASC(a$) * 65536! + ASC(MID$(a$, 2, 1)) * 256! + ASC(RIGHT$(a$, 1))'PROTOC
end;    //

function mkiV(n: integer): string;
begin
  result := chr(trunc(n / 65536)) + chr(trunc((n - INT(n / 65536) * 65536) / 256)) + chr(n - trunc(n / 256) * 256);
end;

function Cvir(s:string): Integer;
var
	sleft,sright:string;
begin
	if Length(s) <> 4 then
		Result := 0
	else begin
		sleft := copy(s,1,2);
		sright := copy(s,3,2);
		Result := cvix(sleft) * 32768 + cvix(sright);
	end
end;

function Mkir(n:Integer): String;
begin
	Result := mkix(n div 32768) + mkix(n mod 32768);
end;


function CharToBool(s: string): Boolean;
begin
	result := false;
	if Length(s)=1 then begin
    if (s[1] = 'S') or (s[1] = 's') then
      Result := True
    else
      Result := False;
	end;
end;

function BoolToChar(b: Boolean): Char;
begin
	if b = True then
		Result := 'S'
	else
		Result := 'N';
end;

function Dn1(n: Integer): TDateTime;
var
	n1: Double;
begin
  if n>0 then begin
		n1 := n + 35065 - 9039;				//hago la cuenta en un doble
		Result := TDateTime(n1);			//y lo mando al tipo correcto
  end
  else begin
    result := 0.0;
  end;
end;

function LabDn1(n: Integer): TDateTime;
var
	n1: Double;
begin
   n1 := n + 35065 - 9039;    //hago la cuenta en un doble
   Result := TDateTime(n1);   //y lo mando al tipo correcto
end;



function UnDn1(f: TDateTime): integer;
begin
	if (f<1) then begin
		Result  := 0;				//hago la cuenta en un doble
  end
  else begin
		Result  := Trunc(Double(f)) + 9039 - 35065;				//hago la cuenta en un doble
  end;
end;

function MinutosToTime(n: Integer): TDateTime;
var
	n1: Double;
begin
	n1 := n;							//hago la cuenta en un doble
	n1 := (n1 / 1440);    //pasandolo a fraccion de dia
	Result := TDateTime(n1);			//y lo mando al tipo correcto
end;

function TimeToMinutos(tTime: tDateTime): integer;
var
	n1: Double;
begin
	n1 := frac(tTime);					//hago la cuenta en un doble
	result := round(24 * 60 * n1);    //pasandolo a fraccion de dia
end;

function Compl(m: Integer; const Digitos: Integer): String;
begin
	if Digitos > 8 then
		Compl := StringOfChar('?',8)
	else
		Compl := Right(IntToStr(1000000000 + m),Digitos);
end;

	// completa un String (de digitos) con ceros adelante y con 2 decimales
function Compl2(m: Real; const Digitos: Integer): String;
var
  DigsEnt,DigsDec: integer;
begin
	if Digitos > 8 then
		Compl2 := StringOfChar('?',8)
	else begin
    DigsEnt:= Trunc(m);
    DigsDec:= Trunc(Frac(m)*100);
    Compl2 := Compl(DigsEnt,Digitos-3)+ '.'+Compl(DigsDec,2);
  end;
end;


function Right(S: String; const n: Integer): String;
{devuelve un string de largo N tomado de la derecha
de S si alcanzan los caracteres, o bien S completo mas
blancos a la izquierda si no alcanzan}
var
	Largo: Integer;
begin
	Largo := Length(s);
	if n > Largo then
		Result := StringOfChar(' ',n-Largo) + s
	else
		Result := Copy(s,Largo-n+1,n);
end;


function Left(S: String; const n: Integer): String;
{devuelve un string de largo N tomado de la derecha
de S si alcanzan los caracteres, o bien S completo mas
blancos a la izquierda si no alcanzan}
var
	Largo: Integer;
begin
	Largo := Length(s);
	if n > Largo then
		Result := s + StringOfChar(' ',n-Largo)
	else
		Result := Copy(s,1,n);
end;


function Hora(const iHora: Integer): String;
{convierte una hora expresada en minutos desde la medianoche
en el formato std Sage de 24 hs como un string HH:MM}
var
	Hor, Min: Integer;
begin
	if iHora <=0 then
		Result := StringOfChar(' ',5)
	else if ((iHora mod (24 * 60)) = 0) then
		Result := '24' + cHoraSep + '00'
	else begin
		Hor := Trunc(Int(iHora /60)) mod 24;
		Min := iHora mod 60;
		Result := Compl(Hor,2) + cHoraSep + Compl(Min,2);
	end;
end;

function Horas(const iHoras, DigitosHora: Integer ): String;
{convierte una hora expresada en minutos desde la medianoche
en el formato std Sage de 24 hs como un string HHH:MM
Es similar a Hora solo que permite una cantidad de horas mayor}
var
	Hor, Min: Integer;
begin
	if iHoras <=0 then
		Result := StringOfChar(' ',DigitosHora+1+2)
	else begin
		Hor := Trunc(iHoras /60);
		Min := iHoras mod 60;
		Result := Compl(Hor,DigitosHora) + cHoraSep + Compl(Min,2);
	end;
end;

function HorasN(const iHoras, DigitosHora: Integer ): String;
{convierte una hora expresada en minutos desde la medianoche
en el formato std Sage de 24 hs como un string HHH:MM
Es similar a Horas pero sin ceros adelante}
var
	Hor, Min: Integer;
begin
	if iHoras <=0 then
		Result := StringOfChar(' ',DigitosHora+1+2)
	else begin
		Hor := Trunc(iHoras /60);
		Min := iHoras mod 60;
    Result := Right(IntToStr(Hor),DigitosHora) + cHoraSep + Compl(Min,2);
	end;
end;

function HoraZ(const iHora: Integer ): String;
{es similar a Hora pero devuelve un string 00:00 cuando la hora es cero}
begin
	if iHora =0 then
		Result := '00:00'
	else
		Result := Hora(iHora);
end;

function UnHora(const sHora: String ): Integer;
{Devuelve un integer con la cantidad de minutos desde la medianoche
 Supone que sHora es un string con largo 5 y formato de hora o similar}
var
	Hor, Min: Integer;
	stHor, stMin: string;
begin
	stHor  := Trim(Left(sHora,2));
	if Length(sHora)>=4 then
		stMin  := Trim(Right(sHora,2))
	else
		stMin := '00';
	Hor  := StrToIntDef(stHor,0) * 60;
	Min  := StrToIntDef(stMin,0);
	if ((Hor + Min) = (24 * 60)) then
		Result := 24 * 60
	else
		Result := (Hor + Min) mod (60 * 24);
end;

//asc devuelve el ascii de la primera letra de s o bien un 0
function Asc(const s: String ): Integer;
var
	c: char;
begin
	if Length(s)>0 then
		c := s[1]
	else
		c := chr(0);
	Result := ord(c);
end;

//asc devuelve el ascii de la primera letra de s o bien un 0
function GenClaveAlfa(const s: String; const Largo: Integer ): String;
var
	j: integer;
	Dato, Clave: string;
	Car: Char;
begin
	Clave := '';
	Dato := AnsiUpperCase(s);
	for j := 1 to Length(Dato) do begin    // Iterate
		Car := Dato[j];
		case Car  of    //
			'A'..'Z', 'a'..'z', '-', '0'..'9':
				Clave := Clave + Car;
		end;    // case
	end;    // for
	Result := Left(Clave,Largo);
end;

{ 	ValIniFinStr valida los strings pasados como rango inicial/final de
	un listado, genera un mensaje si el valor final es menor que el inicial
	y permite al usuario en ese caso avisar que va a corregir el rango

}
function ValIniFinStr(Referencia, InicialInput, FinalInput: string;
						CualquierRango: boolean; var InicialOutput, FinalOutput: string):Boolean;
const
	StrPrimero = #0;
	StrUltimo = #255;
var
	s: string;
	Acepta: Boolean;
begin

	if CualquierRango then begin
		InicialOutput := StrPrimero;
		FinalOutput := StrUltimo;
		Acepta := True;
	end
	else begin
		// pongo para empezar los valores como vinieron
		InicialOutput := InicialInput;
		FinalOutput := FinalInput;
		if IsEmptyStr(FinalInput,[' ']) then
			FinalOutput := StrUltimo;
		if FinalOutput < InicialOutput then begin
			s := 'El valor final dado para '+ Referencia +' es menor que el inicial.'+CrLf
				+ 'Desea continuar suponiendo ambos valores iguales?';
			if MessageDlg(s, mtConfirmation,[mbYes, mbNo],0) = mrNo then
				Acepta := False
			else begin
				Acepta := False;
				FinalOutput := InicialOutput;
			end;
		end
		else begin
			Acepta := True;
		end;
	end;
	result := Acepta;
end;

function ValIniFinInt(Referencia, InicialInput, FinalInput: string;
						CualquierRango: boolean; var InicialOutput, FinalOutput: Integer):Boolean;

var
	s: string;
	Acepta: Boolean;
	IntPrimero, IntUltimo: Integer;
begin

	//inicializa los valores limites
	IntPrimero := 0;
	IntUltimo := High(Integer);

	if CualquierRango then begin
		InicialOutput := IntPrimero;
		FinalOutput := IntUltimo;
		Acepta := True;
	end
	else begin
		// pongo para empezar los valores como vinieron
		InicialOutput := StrToIntDef(InicialInput,0);
		FinalOutput := StrToIntDef(FinalInput,0);
		if IsEmptyStr(FinalInput,[' ']) then
			FinalOutput := IntUltimo;
		if FinalOutput < InicialOutput then begin
			s := 'El valor final dado para '+ Referencia +' es menor que el inicial.'+CrLf
				+ 'Desea continuar suponiendo ambos valores iguales?';
			if MessageDlg(s, mtConfirmation,[mbYes, mbNo],0) = mrNo then
				Acepta := False
			else begin
				Acepta := False;
				FinalOutput := InicialOutput;
			end;
		end
		else begin
			Acepta := True;
		end;
	end;
	result := Acepta;
end;

function ValIniFinDate(Referencia: string; InicialInput, FinalInput: TDateTime;
					CualquierRango: boolean; var InicialOutput, FinalOutput: TDateTime):Boolean;
var
	s: string;
	Acepta: Boolean;

begin

	s := '';

	if CualquierRango then begin
		Acepta := True;
		InicialOutput := StrToDate('01'+DateSeparator+'01'+DateSeparator+'1900');
		FinalOutput := StrToDate('01'+DateSeparator+'01'+DateSeparator+'2050');
	end
	else begin
		// pongo para empezar los valores como vinieron

		InicialOutput := InicialInput;
		FinalOutput := FinalInput;

		if FinalOutput < InicialOutput then begin
			s := 'La fecha final ingresada para '+ Referencia +' es menor que la inicial.'+CrLf
				+'Desea continuar suponiendo ambas fechas iguales?';
			if MessageDlg(s, mtConfirmation,[mbYes, mbNo],0) = mrNo then
				Acepta := False
			else begin
				Acepta := True;
				FinalOutput := InicialOutput;
			end
		end
		else begin
			Acepta := true;
		end;
	end;
	result := Acepta;
end;

function StrTilde(s: string): string;
begin
  result := QuotedString(s,cTilde);
end;

function FechaLast:tDateTime;
begin
  result := EncodeDate(2100,1,1);
end;

function DiaSemanaSage(const Fecha: tDateTime): integer;
begin
//  	1=Lun .. 7=Dom
	result := ((UnDn1(Fecha) mod 7) + 12) mod 7 + 1
end;


procedure SetDateTime(Year, Month, Day, Hour, Minu, Sec, MSec: Word);
var
  NewDateTime: TSystemTime;
begin
  FillChar(NewDateTime, sizeof(NewDateTime), #0);
  NewDateTime.wYear := Year;
  NewDateTime.wMonth := Month;
  NewDateTime.wDay := Day;
  NewDateTime.wHour := Hour;
  NewDateTime.wMinute := Minu;
  NewDateTime.wSecond := Sec;
  NewDateTime.wMilliseconds := MSec;
  SetLocalTime(NewDateTime);
end;


// toler genera un string con los valores de la tolerancia poniendo 0-250 como
// cantidad de minutos y --- para cualquier cosa superior a 250
function Toler(Minutos: integer): string;
begin
	if Minutos>250  then
		Result := '---'
	else
		Result := Format('%3d',[Minutos]);
end;

function Edad(nacimiento: tDateTime): integer;
begin
  result := extractYear(now) - extractYear(nacimiento);
  if result <0 then inc(result,100);
end;    //

function cvIS(s: string): Integer;
var
  a: Integer;
begin
  a := cvi(s);
  if (a < 0) then begin
    result := 65536 + a;
  end
  else begin
    result := a;
  end;
end;    //

function cvSI(i: Integer): string;
var
  a: integer;
begin
  if (a > 32767) then begin
    result := mki(65536 - a);
  end
  else begin
    result := mki(a);
  end;
end;    //


end.
