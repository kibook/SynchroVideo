{ This unit provides some convenient functions for use with
	web-based applications and CGI scripting in Pascal }

unit htmlutils;

{$h+}

interface

type
	{ key=value pair for HTTP query }
	THttpQueryPair     = Array of String;

	{ HTTP GET/POST query }
	THttpQuery         = Array of THttpQueryPair;

{ format HTML URL encoded strings to plain text }
function Html2Text  (const RawText : String) : String;

{ format plain text to HTML-safe encoding }
function Text2Html  (const RawText : String) : String;

{ escape incoming data to be web-safe }
function EscapeText (const RawText : String) : String;

{ convert a GET/POST request URL into a thttpquery for parsing }
function GetQuery   (const Request : String) : THttpQuery;

{ fetch GET/POST request URL from incoming data }
function GetRequest                          : String;


{ Get raw file data from a multipart/form-data POST request }

{ get the content-type of the file }
function GetFileType(Request : String)       : String;

{ get the contents of the file }
function GetFile    (Request : String)       : String;

procedure Redirect  (Url : String; Time : Word);

implementation
uses sysutils, strarrutils, dos, strutils;

const
	HtmlCodes: Array [0..1] of String = (
		'+',   #32
	);

	CleanCodes: Array [0..7] of String = (
		'"',  '&quot;',
		'''', '&#39;',
		'>',  '&gt;',
		'<',  '&lt;'
	);

	CRLF = #13#10;

function ConvertHex(RawText : String) : String;
var
	i    : Integer;
	Ch   : Char;
	Code : String;
begin
	ConvertHex := '';
	if Length(RawText) > 0 then
	begin
		i := 1;
		repeat
			ch := RawText[i];
			if ch = '%' then
			begin
				Code := Concat(RawText[i + 1],
					RawText[i + 2]);
				ConvertHex := Concat(ConvertHex,
					Chr(Hex2Dec(Code)));
				inc(i, 2)
			end
			else
				ConvertHex := Concat(ConvertHex, Ch);
			Inc(i)
		until i > Length(RawText)
	end
end;

function ReplaceText(RawText : String;
	const List : Array of String) : String;
var
	i : Integer;
begin
	ReplaceText := RawText;
	for i := 0 to High(list) div 2 do
		ReplaceText := StringReplace(ReplaceText, List[i*2],
			List[i*2+1], [rfReplaceAll]);
end;

function GetFileType(Request : String) : String;
var
	Anchor : String;
begin
	Anchor := 'Content-Type: ';
	GetFiletype := Copy(Request, Pos(Anchor, Request) + Length(Anchor),
		Length(Request));
	GetFiletype := Copy(GetFiletype, 1, Pos(CRLF, GetFileType))
end;

function GetFile(Request : String) : String;
var
	Anchor : String;
begin
	Anchor := 'Content-Type: ' + GetFiletype(Request);
	GetFile := Copy(Request, Pos(Anchor, Request) + Length(Anchor) + 3,
		Length(Request));
	GetFile := Copy(GetFile, 1, Pos('------', GetFile) - 2)
end;

function Html2Text(const RawText : String) : String;
begin
	Html2Text := ReplaceText(ConvertHex(RawText), HtmlCodes)
end;

function Text2Html(const RawText : String) : String;
begin
	Text2Html := ReplaceText(RawText, CleanCodes)
end;

function EscapeText(const RawText : String) : String;
begin
	EscapeText := Text2Html(Html2Text(RawText))
end;

function GetQuery(const Request: String): THttpQuery;
var
	Pairs : TStringArray;
	Each  : String;
	Len   : Word;
begin
	Pairs := Split(Request, '&');
	SetLength(GetQuery, 0);
	for Each in Pairs do
	begin
		Len := Length(GetQuery);
		SetLength(GetQuery, Len + 1, 2);
		GetQuery[Len] := Split(Each, '=')
	end
end;

function GetRequest : String;
var
	Ch : Char;
begin
	if GetEnv('REQUEST_METHOD') = 'POST' then
	begin
		GetRequest := '';
		repeat
			Read(Ch);
			GetRequest := Concat(GetRequest, Ch)
		until EOF(input)
	end
	else
		GetRequest := GetEnv('QUERY_STRING')
end;

procedure Redirect(Url : String; Time : word);
begin
	WriteLn('<meta http-equiv="refresh" content="', Time,
		';url=', Url, '">')
end;

end.
