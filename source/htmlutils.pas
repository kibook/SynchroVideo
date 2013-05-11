{ This unit provides some convenient functions for use with
	web-based applications and CGI scripting in Pascal }

unit htmlutils;

{$longstrings on}

interface

type
	{ key=value pair for HTTP query }
	thttpquerypair     = array of string;

	{ HTTP GET/POST query }
	thttpquery         = array of thttpquerypair;

{ format HTML URL encoded strings to plain text }
function html2text  (const rawtext : string) : string;

{ format plain text to HTML-safe encoding }
function text2html  (const rawtext : string) : string;

{ escape incoming data to be web-safe }
function escapetext (const rawtext : string) : string;

{ convert a GET/POST request URL into a thttpquery for parsing }
function getquery   (const request : string) : thttpquery;

{ fetch GET/POST request URL from incoming data }
function getrequest                          : string;


{ Get raw file data from a multipart/form-data POST request }

{ get the content-type of the file }
function getfiletype(request : string)       : string;

{ get the contents of the file }
function getfile    (request : string)       : string;

implementation
uses sysutils, strarrutils, dos, strutils;

const
	HTMLCODES: array [0..1] of string = (
		'+',   #32
	);

	CLEANCODES: array [0..7] of string = (
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

function getfiletype(request : string) : string;
var
	anchor : string;
begin
	anchor := 'Content-Type: ';
	getfiletype := copy(request, pos(anchor, request) + length(anchor),
		length(request));
	getfiletype := copy(getfiletype, 1, pos(CRLF, getfiletype))
end;

function getfile(request : string) : string;
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

function text2html(const rawtext : string) : string;
begin
	text2html := replacetext(rawtext, CLEANCODES)
end;

function escapetext(const rawtext : string) : string;
begin
	escapetext := text2html(html2text(rawtext))
end;

function getquery(const request: string): thttpquery;
var
	pairs : tstringarray;
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

end.
