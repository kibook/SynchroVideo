unit WmSearch;

interface
uses
	Classes,
	SysUtils,
	IniFiles,
	HTTPDefs,
	fpHTTP,
	fpWeb;

type
	TWmSearch = Class(TFPWebModule)
	private
		FSearchTerms   : String;
		FSearchResults : String;
		procedure ReplaceTags(
			Sender          : TObject;
			const TagString : String;
			TagParams       : TStringList;
			out ReplaceText : String);
	published
		procedure DoRequest(
			Sender     : TObject;
			ARequest   : TRequest;
			AResponse  : TResponse;
			var Handle : Boolean);
	end;

var
	AWmSearch : TWmSearch;

implementation
{$R *.lfm}

procedure TWmSearch.ReplaceTags(
	Sender          : TObject;
	const TagString : String;
	TagParams       : TStringList;
	out ReplaceText : String);
begin
	case TagString of
		'SearchTerms'   : ReplaceText := FSearchTerms;
		'SearchResults' : ReplaceText := FSearchResults;
	end
end;

procedure TWmSearch.DoRequest(
	Sender     : TObject;
	ARequest   : TRequest;
	AResponse  : TResponse;
	var Handle : Boolean);
var
	Each     : String;
	Playing  : String;
	Password : String;
	RoomName : String;
	RoomTags : String;
	RoomDesc : String;
	Rooms    : TStringList;
	Ini      : TIniFile;
	Match    : Boolean;
	Priv     : Boolean;

function CheckVideo : String;
var
	Playlist   : TIniFile;
	Id         : String;
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
	begin
		FSearchResults := FSearchResults +
			'<h3>'+
			'<a href="room/'+Each+'">'+RoomName+'</a>'+
			'</h3>'#13#10+
			'<p>'+RoomDesc+'</p>'#13#10+
			'<p class="smalltext">'#13#10+
			'<em>Now Playing: <b>'+Playing+'</b></em>'#13#10+
			'</p>'#13#10;
	end
end;


procedure CheckRoom;
begin
	Ini := TIniFile.Create('rooms/'+Each+'/settings.ini');
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

		for Each in Rooms do
			CheckRoom;

		ModuleTemplate.FileName := 'templates/pages/search.htm';
		ModuleTemplate.AllowTagParams := True;
		ModuleTemplate.OnReplaceTag := @ReplaceTags;

		AResponse.Content := ModuleTemplate.GetContent
	end;
	
	Handle := True
end;

initialization
	RegisterHTTPModule('search', TWmSearch)
end.
