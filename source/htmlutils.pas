unit htmlutils;

interface

type
	thttpquery         = array of array of string;
	thttpquerypair     = array of string;

	tansihttpquery     = array of array of ansistring;
	tansihttpquerypair = array of ansistring;

function html2text     (const rawtext : string)     : string;
function ansihtml2text (const rawtext : ansistring) : ansistring;

function text2html     (const rawtext : string)     : string;
function ansitext2html (const rawtext : ansistring) : ansistring;

function escapetext    (const rawtext : string)     : string;
function ansiescapetext(const rawtext : ansistring) : ansistring;

function getquery      (const request : string)     : thttpquery;
function ansigetquery  (const request : ansistring) : tansihttpquery;

function getrequest                                 : string;
function ansigetrequest                             : ansistring;

function getfiletype(request : ansistring)          : string;
function getfile    (request : ansistring)          : ansistring;

implementation
uses sysutils, strarrutils, dos, strutils;

const
	HTMLCODES: array [0..1] of string = (
		'+',   #32
	);

	CLEANCODES: array [0..7] of string = (
	//	'&',  '&amp;',
		'"',  '&quot;',
		'''', '&#39;',
		'>',  '&gt;',
		'<',  '&lt;'
	);
	CRLF = #13#10;

function converthex(rawtext : string) : string;
var
	i    : integer;
	ch   : char;
	code : string;
begin
	converthex := '';
	i := 1;
	repeat
		ch := rawtext[i];
		if ch = '%' then
		begin
			code := concat(rawtext[i + 1], rawtext[i + 2]);
			converthex := concat(converthex,
				chr(hex2dec(code)));
			inc(i, 2)
		end
		else
			converthex := concat(converthex, ch);
		inc(i)
	until i > length(rawtext)
end;

function ansiconverthex(rawtext : ansistring) : string;
var
	i    : integer;
	ch   : char;
	code : string;
begin
	ansiconverthex := '';
	i := 1;
	repeat
		ch := rawtext[i];
		if ch = '%' then
		begin
			code := concat(rawtext[i + 1], rawtext[i + 2]);
			ansiconverthex := concat(ansiconverthex,
				chr(hex2dec(code)));
			inc(i, 2)
		end
		else
			ansiconverthex := concat(ansiconverthex, ch);
		inc(i)
	until i > length(rawtext)
end;

function replacetext(rawtext : string;
	const list : array of string) : string;
var
	i : integer;
begin
	replacetext := rawtext;
	for i := 0 to high(list) div 2 do
		replacetext := stringreplace(replacetext, list[i*2],
			list[i*2+1], [rfreplaceall]);
end;

function ansireplacetext(rawtext : ansistring;
	const list : array of string) : ansistring;
var
	i : word;
begin
	ansireplacetext := rawtext;
	for i := 0 to high(list) div 2 do
		ansireplacetext := stringreplace(ansireplacetext, list[i*2],
			list[i*2+1], [rfreplaceall]);
end;

function getfiletype(request : ansistring) : string;
var
	anchor : string;
begin
	anchor := 'Content-Type: ';
	getfiletype := copy(request, pos(anchor, request) + length(anchor),
		length(request));
	getfiletype := copy(getfiletype, 1, pos(CRLF, getfiletype))
end;

function getfile(request : ansistring) : ansistring;
var
	anchor : string;
begin
	anchor := 'Content-Type: ' + getfiletype(request);
	getfile := copy(request, pos(anchor, request) + length(anchor) + 3,
		length(request));
	getfile := copy(getfile, 1, pos('------', getfile) - 2)
end;

function html2text(const rawtext : string) : string;
begin
	html2text := replacetext(converthex(rawtext), HTMLCODES)
end;

function ansihtml2text(const rawtext : ansistring) : ansistring;
begin
	ansihtml2text := ansireplacetext(ansiconverthex(rawtext), HTMLCODES)
end;

function text2html(const rawtext : string) : string;
begin
	text2html := replacetext(rawtext, CLEANCODES)
end;

function ansitext2html(const rawtext : ansistring) : ansistring;
begin
	ansitext2html := ansireplacetext(rawtext, CLEANCODES)
end;

function escapetext(const rawtext : string) : string;
begin
	escapetext := text2html(html2text(rawtext))
end;

function ansiescapetext(const rawtext : ansistring) : ansistring;
begin
	ansiescapetext := ansitext2html(ansihtml2text(rawtext))
end;

function getquery(const request: string): thttpquery;
var
	pairs : array of string;
	each  : string;
	len   : word;
begin
	pairs := split(request, '&');
	setlength(getquery, 0);
	for each in pairs do
	begin
		len := length(getquery);
		setlength(getquery, len + 1, 2);
		getquery[len] := split(each, '=')
	end
end;

function ansigetquery(const request : ansistring): tansihttpquery;
var
	pairs : tansihttpquerypair;
	each  : ansistring;
	len   : word;
begin
	pairs := ansisplit(request, '&');
	setlength(ansigetquery, 0);
	for each in pairs do
	begin
		len := length(ansigetquery);
		setlength(ansigetquery, len + 1, 2);
		ansigetquery[len] := ansisplit(each, '=')
	end
end;

function getrequest : string;
var
	ch : char;
begin
	if getenv('REQUEST_METHOD') = 'POST' then
	begin
		getrequest := '';
		repeat
			read(ch);
			getrequest := concat(getrequest, ch)
		until eof(input)
	end
	else
		getrequest := getenv('QUERY_STRING')
end;

function ansigetrequest : ansistring;
var
	ch : char;
begin
	if getenv('REQUEST_METHOD') = 'POST' then
	begin
		ansigetrequest := '';
		repeat
			read(ch);
			ansigetrequest := concat(ansigetrequest, ch)
		until eof(input)
	end
	else
		ansigetrequest := getenv('QUERY_STRING')
end;

end.
