unit WmSearch;

{$mode objfpc}
{$H+}

interface

uses
	Classes,
	HttpDefs,
	FpHttp,
	FpWeb;

type
	TSearchModule = class(TFpWebModule)
	private
		FSearchTerms   : string;
		FSearchResults : string;
		procedure ReplaceTags(
			Sender          : TObject;
			const TagString : string;
			TagParams       : TStringList;
			out ReplaceText : string);
	published
		procedure Request(
			Sender      : TObject;
			ARequest    : TRequest;
			AResponse   : TResponse;
			var Handled : Boolean);
	end;

var
	SearchModule : TSearchModule;

implementation

{$R *.lfm}

uses
	SysUtils,
	IniFiles;

procedure TSearchModule.ReplaceTags(
	Sender          : TObject;
	const TagString : string;
	TagParams       : TStringList;
	out ReplaceText : string);
begin
	case TagString of
		'SearchTerms'   : ReplaceText := FSearchTerms;
		'SearchResults' : ReplaceText := FSearchResults;
	end
end;

procedure TSearchModule.Request(
	Sender      : TObject;
	ARequest    : TRequest;
	AResponse   : TResponse;
	var Handled : Boolean);
var
	Each     : string;
	Playing  : string;
	Password : string;
	RoomName : string;
	RoomTags : string;
	RoomDesc : string;
	Rooms    : TStringList;
	Content  : TStringList;
	Ini      : TIniFile;
	Match    : Boolean;
	Priv     : Boolean;

function CheckVideo : string;
var
	Playlist   : TIniFile;
	Id         : string;
	AFile      : Text;
begin
	AssignFile(AFile, 'rooms/'+Each+'/syncvid.syn');
	Reset(AFile);
	ReadLn(AFile, Id);
	CloseFile(AFile);

	Playlist := TIniFile.Create('rooms/'+Each+'/playlist.ini');
	Result := Playlist.ReadString('videos', Id, '???');
	Playlist.Free
end;

procedure DisplayRoom;
begin
	if not Priv then
		FSearchResults := FSearchResults + Format(Content.Text,
			[Each, RoomName, RoomDesc, Playing])
end;


procedure CheckRoom;
begin
	Ini := TIniFile.Create('rooms/' + Each + '/settings.ini');
	Password := Ini.ReadString('room', 'password', '');
	Priv := Length(Password) > 1;

	RoomName := Ini.ReadString('room', 'name', '');
	RoomTags := Ini.ReadString('room', 'tags', '');
	RoomDesc := Ini.ReadString('room', 'description', '');

	Ini.Free;

	Playing := CheckVideo;

	Match := (Pos(UpCase(FSearchTerms), UpCase(Each))     > 0) or
		 (Pos(UpCase(FSearchTerms), UpCase(RoomName)) > 0) or
		 (Pos(UpCase(FSearchTerms), UpCase(RoomTags)) > 0) or
		 (Pos(UpCase(FSearchTerms), UpCase(Playing))  > 0);
	if Match then
		DisplayRoom
end;

begin
	FSearchTerms := ARequest.QueryFields.Values['q'];

	FSearchResults := '';

	If Trim(FSearchTerms) = '' then
		AResponse.Content := '<meta http-equiv="refresh" ' +
			'content="0;url=./">'
	else
	begin
		Ini := TIniFile.Create('data/rooms.ini');
		Rooms := TStringList.Create;
		Ini.ReadSection('rooms', Rooms);
		Ini.Free;

		Content := TStringList.Create;
		Content.LoadFromFile('templates/html/searchresult.htm');

		for Each in Rooms do
			CheckRoom;

		Content.Free;
		Rooms.Free;

		ModuleTemplate.FileName := 'templates/pages/search.htm';
		ModuleTemplate.AllowTagParams := True;
		ModuleTemplate.OnReplaceTag := @ReplaceTags;

		AResponse.Content := ModuleTemplate.GetContent
	end;
	
	Handled := True
end;

initialization
	RegisterHttpModule('search', TSearchModule)
end.
