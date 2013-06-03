unit WmDelete;

interface
uses
	Classes,
	SysUtils,
	IniFiles,
	HTTPDefs,
	fpHTTP,
	fpWeb;

type
	TWmDelete = Class(TFPWebModule)
	private
		FRoom     : String;
		FHostPass : String;
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
	AWmDelete : TWmDelete;

implementation
{$R *.lfm}

procedure TWmDelete.ReplaceTags(
	Sender          : TObject;
	const TagString : String;
	TagParams       : TStringList;
	out ReplaceText : String);
begin
	case TagString of
		'Room' : ReplaceText := FRoom;
		'Host' : ReplaceText := FHostPass
	end
end;

procedure TWmDelete.DoRequest(
	Sender     : TObject;
	ARequest   : TRequest;
	AResponse  : TResponse;
	var Handle : Boolean);
var
	Confirm : Boolean;
	IsAuth  : Boolean;
	Ini     : TIniFile;
	Pass    : String;

procedure GetConfirmation;
begin
	ModuleTemplate.FileName :=
		'templates/pages/error/delete/confirm.htm'
end;

procedure DenyAccess;
begin
	ModuleTemplate.FileName :=
		'templates/pages/error/delete/deny.htm'
end;

function GetPlaylists : TStringList;
var
	Info   : TSearchRec;
	faType : Word;
	Path   : String;

procedure CheckFile;
begin
	faType := Info.Attr and faDirectory;
	if not (faType = faDirectory) then
		Result.Add(Copy(Info.Name, 1, Length(Info.Name) - 4))
end;

begin
	Result := TStringList.Create;
	Path := 'rooms/'+FRoom+'/playlists/*';
	if FindFirst(Path, faAnyFile and faDirectory, Info) = 0 then
	begin
		repeat
			CheckFile
		until not (FindNext(Info) = 0)
	end;
	FindClose(Info)
end;

procedure DeleteRoom;
var
	Playlist : String;
begin
	Ini := TIniFile.Create('data/rooms.ini');
	Ini.CacheUpdates := True;

	Ini.DeleteKey('rooms', FRoom);
	Ini.Free;

	for Playlist in GetPlaylists do
		DeleteFile('rooms/'+FRoom+'/playlists/'+Playlist+'.ini');

	RemoveDir('rooms/'+FRoom+'/playlists/');

	DeleteFile('rooms/'+FRoom+'/syncvid.syn');
	DeleteFile('rooms/'+FRoom+'/session.id');
	DeleteFile('rooms/'+FRoom+'/playlist.ini');
	DeleteFile('rooms/'+FRoom+'/settings.ini');

	RemoveDir('rooms/'+FRoom+'/');

	ModuleTemplate.FileName := 'templates/pages/delete.htm'
end;

var
	RoomExists : Boolean;
begin
	FRoom     := ARequest.ContentFields.Values['room'];
	Confirm   := ARequest.ContentFields.Values['confirm']='true';
	FHostPass := ARequest.ContentFields.Values['host'];

	Ini := TIniFile.Create('rooms/'+FRoom+'/settings.ini');
	Pass := Ini.ReadString('room', 'host-password', '');

	IsAuth := (FHostPass = Pass) and
		not (Pass = '') and
		not (FRoom = '');

	Ini.Free;

	RoomExists := FileExists('rooms/'+FRoom+'/settings.ini');

	if IsAuth and RoomExists then
		if not Confirm then
			GetConfirmation
		else
			DeleteRoom
	else
		DenyAccess;

	ModuleTemplate.AllowTagParams := True;
	ModuleTemplate.OnReplaceTag := @ReplaceTags;

	AResponse.Content := ModuleTemplate.GetContent;

	Handle := True
end;

initialization
	RegisterHTTPModule('delete', TWmDelete)
end.
