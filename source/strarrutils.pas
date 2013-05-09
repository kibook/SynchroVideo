unit strarrutils;

interface

type
	tstringarray	 = array of string;
	tansistringarray = array of ansistring;


{ ---------- split ---------- }

{ split a null-terminated string into an array by a delimiter }
function ansisplit(const astring : ansistring;
	const delimiter : ansistring) : tansistringarray;

{ split a string into an array by a delimiter }
function split(const astring : string;
	const delimiter : string) : tstringarray;

{ split a null-terimated string into an array by spaces }
function ansisplit(const astring : ansistring) : tansistringarray;

{ split a string into an array by spaces }
function split(const astring : string) : tstringarray;


{ ---------- join ---------- }

{ join a specific range of an array into a null-terminated string,
	separating each element with delimiter }
function ansijoinrange(const stringarray : tansistringarray;
	const delimiter : ansistring; const startindex : word;
	const endindex : word) : ansistring;

{ join a specific range of an array into a string,
	separating each element with delimiter }
function joinrange(const stringarray : tstringarray;
	const delimiter : string; const startindex : word;
	const endindex : word) : string;

{ join an array into a null-terminated string,
	separating each element with delimiter }
function ansijoin(const stringarray : tansistringarray;
	const delimiter : ansistring) : ansistring;

{ join an array into a string,
	separating each element with a delimiter }
function join(const stringarray : tstringarray;
	const delimiter : string) : string;

{ join an array into a null-terminated string,
	separating each element with a space }
function ansijoin(const stringarray : tansistringarray) : ansistring;

{ join an array into a string,
	separating each element with a space }
function join(const stringarray : tstringarray) : string;

implementation


{ ---------- split ---------- }

function ansisplit(const astring : ansistring;
	const delimiter : ansistring) : tansistringarray;
var
	buffer : ansistring = '';
	token  : ansistring;	
	i      : word       = 1;
	len    : word;
begin
	setlength(ansisplit, 0);

	repeat
		token := copy(astring, i, length(delimiter));

		if token = delimiter then
		begin
			len := length(ansisplit);
			setlength(ansisplit, len + 1);
			ansisplit[len] := buffer;
			buffer := ''
		end
		else
			buffer := concat(buffer, token);

		inc(i, length(token))
	until i > length(astring);

	len            := length(ansisplit);
	setlength(ansisplit, len + 1);
	ansisplit[len] := buffer
end;


function split(const astring : string;
	const delimiter : string) : tstringarray;
var
	buffer : string  = '';
	i      : word    = 1;
	token  : string;
	len    : word;
begin
	setlength(split, 0);

	repeat
		token := copy(astring, i, length(delimiter));

		if token = delimiter then
		begin
			len := length(split);
			setlength(split, len + 1);
			split[len] := buffer;
			buffer := ''
		end
		else
			buffer := concat(buffer, token);

		inc(i, length(token))
	until i > length(astring);

	len        := length(split);
	setlength(split, len + 1);
	split[len] := buffer
end;

function ansisplit(const astring : ansistring) : tansistringarray;
begin
	ansisplit := ansisplit(astring, ' ')
end;

function split(const astring : string): tstringarray;
begin
	split := split(astring, ' ')
end;


{ ---------- join ---------- }

function ansijoinrange(const stringarray : tansistringarray;
	const delimiter : ansistring; const startindex : word;
	const endindex : word) : ansistring;
var
	i : word;
begin
	ansijoinrange := '';
	for i := startindex to endindex - 1 do
		ansijoinrange := concat(ansijoinrange, stringarray[i],
			delimiter);
	ansijoinrange := concat(ansijoinrange, stringarray[endindex]);
end;

function joinrange(const stringarray : tstringarray;
	const delimiter : string; const startindex : word;
	const endindex : word) : string;
var
	i : word;
begin
	joinrange := '';
	for i:=startindex to endindex - 1 do
		joinrange := concat(joinrange, stringarray[i],
			delimiter);
	joinrange := concat(joinrange, stringarray[endindex])
end;

function ansijoin(const stringarray : tansistringarray;
	const delimiter : ansistring) : ansistring;
begin
	ansijoin := ansijoinrange(stringarray, delimiter,
		low(stringarray), high(stringarray));
end;

function join(const stringarray : tstringarray;
	const delimiter : string) : string;
begin
	join := joinrange(stringarray, delimiter,
		low(stringarray), high(stringarray));
end;

function ansijoin(const stringarray : tansistringarray): ansistring;
begin
	ansijoin := ansijoinrange(stringarray, ' ',
		low(stringarray), high(stringarray));
end;

function join(const stringarray : tstringarray) : string;
begin
	join := joinrange(stringarray, ' ',
		low(stringarray), high(stringarray));
end;

end.
