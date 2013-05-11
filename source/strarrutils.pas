unit strarrutils;

{$longstrings on}

interface

type
	tstringarray = array of string;

{ ---------- split ---------- }

{ split a null-terminated string into an array by a delimiter }
function split(const astring : string;
	const delimiter : string) : tstringarray;

{ split a null-terimated string into an array by spaces }
function split(const astring : string) : tstringarray;


{ ---------- join ---------- }

{ join a specific range of an array into a null-terminated string,
	separating each element with delimiter }
function joinrange(const stringarray : tstringarray;
	const delimiter : string; const startindex : word;
	const endindex : word) : string;

{ join an array into a null-terminated string,
	separating each element with delimiter }
function join(const stringarray : tstringarray;
	const delimiter : string) : string;

{ join an array into a null-terminated string,
	separating each element with a space }
function join(const stringarray : tstringarray) : string;

implementation
uses math;


{ ---------- split ---------- }

function split(const astring : string;
	const delimiter : string) : tstringarray;
var
	token  : string;		
	buffer : string = '';
	i      : word   = 1;
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

function split(const astring : string) : tstringarray;
begin
	split := split(astring, ' ')
end;

{ ---------- join ---------- }

function joinrange(const stringarray : tstringarray;
	const delimiter : string; const startindex : word;
	const endindex : word) : string;
var
	i : word;
begin
	joinrange := '';
	if not (endindex - 1 < low(stringarray)) then
		for i := startindex to endindex - 1 do
			joinrange := concat(joinrange,
				stringarray[i], delimiter);
	joinrange := concat(joinrange, stringarray[endindex]);
end;

function join(const stringarray : tstringarray;
	const delimiter : string) : string;
begin
	join := joinrange(stringarray, delimiter,
		low(stringarray), high(stringarray));
end;

function join(const stringarray : tstringarray): string;
begin
	join := joinrange(stringarray, ' ',
		low(stringarray), high(stringarray));
end;

end.
