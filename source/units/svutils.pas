unit SVUtils;

{$mode objfpc}
{$H+}

interface

uses
	Classes;

{ format HTML URL encoded strings to plain text }
function Html2Text  (const RawText : string) : string;

{ format plain text to HTML-safe encoding }
function Text2Html  (const RawText : string) : string;

{ escape incoming data to be web-safe }
function EscapeText (const RawText : string) : string;

function GetRoomPlaylists(Room : string) : TStringList;

implementation

uses
	SysUtils,
	StrUtils;

const
	HtmlCodes  : array [0..1] of string = (
		'+',   #32
	);

	CleanCodes : array [0..7] of string = (
		'"',  '&quot;',
		'''', '&#39;',
		'>',  '&gt;',
		'<',  '&lt;'
	);

function ConvertHex(RawText : string) : string;
var
	i    : Integer;
	Ch   : Char;
	Code : string;
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
				Inc(i, 2)
			end
			else
				ConvertHex := Concat(ConvertHex, Ch);
			Inc(i)
		until i > Length(RawText)
	end
end;

function ReplaceText(RawText : string;
	const List : array of string) : string;
var
	i : Integer;
begin
	ReplaceText := RawText;
	for i := 0 to High(list) div 2 do
		ReplaceText := StringReplace(ReplaceText, List[i*2],
			List[i*2+1], [rfReplaceAll]);
end;

function Html2Text(const RawText : string) : string;
begin
	Html2Text := ReplaceText(ConvertHex(RawText), HtmlCodes)
end;

function Text2Html(const RawText : string) : string;
begin
	Text2Html := ReplaceText(RawText, CleanCodes)
end;

function EscapeText(const RawText : string) : string;
begin
	EscapeText := Text2Html(Html2Text(RawText))
end;

function GetRoomPlaylists(Room : string) : TStringList;
var
	Info      : TSearchRec;
	Ext       : string;
	Name      : string;
begin
	Result := TStringList.Create;
	FindFirst('rooms/' + Room + '/playlists/*', faAnyFile, Info);
	repeat
		Name := Copy(Info.Name, 1, Pos('.', Info.Name) - 1);
		Ext  := Copy(Info.Name,
			Pos('.', Info.Name) + 1, Length(Info.Name));
		if Ext = 'ini' then
			Result.Add(Name)
	until not (FindNext(Info) = 0)
end;

end.
