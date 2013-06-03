unit SVUtils;

interface

{ format HTML URL encoded strings to plain text }
function Html2Text  (const RawText : String) : String;

{ format plain text to HTML-safe encoding }
function Text2Html  (const RawText : String) : String;

{ escape incoming data to be web-safe }
function EscapeText (const RawText : String) : String;

implementation
uses
	SysUtils,
	StrUtils;

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

end.