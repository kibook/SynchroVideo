unit WmCreate;

{$mode objfpc}
{$H+}

interface

uses
	Classes,
	HttpDefs,
	FpHttp,
	FpWeb;

type
	TCreateModule = class(TFpWebModule)
	private
		FRoomDir : String;
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
	CreateModule : TCreateModule;

implementation

{$R *.lfm}

uses
	SysUtils,
	IniFiles;

procedure TCreateModule.ReplaceTags(
	Sender          : TObject;
	const TagString : string;
	TagParams       : TStringList;
	out ReplaceText : string);
begin
	case TagString of
		'Room' : ReplaceText := FRoomDir
	end
end;

procedure TCreateModule.Request(
	Sender      : TObject;
	ARequest    : TRequest;
	AResponse   : TResponse;
	var Handled : Boolean);
const
	CaptchaDir = 'res/captcha/';

var
	Rooms    : TStringList;
	Room     : string;
	Id       : string;
	Solve    : string;
	Pass     : string;
	MaxRooms : Integer;
	Ini      : TIniFile;

procedure ThrowError(Err : string);
begin
	AResponse.Contents.LoadFromFile(
		'templates/pages/error/create/' + Err + '.htm')
end;

procedure CreateRoom;
const
	DefVideo = '8tPnX7OPo0Q';
var
	Path   : string;
	NewIni : TIniFile;
begin
	Path := 'rooms/' + FRoomDir + '/';

	CreateDir(Path);
	CreateDir(Path + 'playlists/');

	NewIni := TIniFile.Create(Path + 'playlist.ini');
	NewIni.CacheUpdates := True;
	NewIni.WriteString('status', 'locked', 'true');
	NewIni.Free;

	NewIni := TIniFile.Create(Path + 'settings.ini');
	NewIni.CacheUpdates := True;

	NewIni.WriteString('room', 'name', Room);
	NewIni.WriteString('room', 'url', FRoomDir);
	NewIni.WriteString('room', 'video', DefVideo);
	NewIni.WriteString('room', 'banner', '');
	NewIni.WriteString('room', 'irc-settings', '');
	NewIni.WriteString('room', 'password', '');
	NewIni.WriteString('room', 'host-password', Pass);
	NewIni.WriteString('room', 'tags', '');
	NewIni.WriteString('room', 'description', '');
	NewIni.WriteString('room', 'favicon', '');
	NewIni.WriteString('room', 'script', '');
	NewIni.WriteString('room', 'style', '');

	NewIni.Free;

	FileCreate(Path + 'syncvid.syn');
	FileCreate(Path + 'session.id');

	Ini.WriteString('rooms', FRoomDir, Room);

	AResponse.Content := ModuleTemplate.GetContent
end;

procedure CheckRoom;
var
	NameCheck : Boolean;
	c         : Char;
begin
	FRoomDir := '';
	for c in LowerCase(Room) do
		if c in ['a'..'z'] then
			FRoomDir := FRoomDir + c;

	NameCheck := True;
	for c in Room do
		if not (c in ['A'..'Z', 'a'..'z', '0'..'9', ' ']) then
			NameCheck := False;

	if Trim(Pass) = '' then
		ThrowError('password')
	else if Rooms.Count >= MaxRooms then
		ThrowError('maxrooms')
	else if Rooms.IndexOf(FRoomDir) > -1 then
		ThrowError('exists')
	else if (Length(FRoomDir) < 5) or (Length(FRoomDir) > 16) then
		ThrowError('namelength')
	else if not NameCheck then
		ThrowError('badname')
	else
		CreateRoom
end;

procedure CheckCaptcha;
var
	AFile : Text;
	Check : String;
begin
	if FileExists(CaptchaDir + Id + '.cap') then
	begin
		AssignFile(AFile, CaptchaDir + Id + '.cap');
		Reset(AFile);
		ReadLn(AFile, Check);
		Close(AFile);
		Erase(AFile);

		if Check = Solve then
			CheckRoom
		else
			ThrowError('captcha');
	end
	else
		ThrowError('expire')
end;

procedure CheckParams;
var
	ParamCheck : Boolean;
begin
	Id    := ARequest.ContentFields.Values['id'];
	Solve := ARequest.ContentFields.Values['solve'];
	Room  := ARequest.ContentFields.Values['room'];
	Pass  := ARequest.ContentFields.Values['pass'];

	ParamCheck := not (Id = '')    and
	              not (Solve = '') and
		      not (Room = '')  and
		      not (Pass = '');

	if ParamCheck then
		CheckCaptcha
	else
		ThrowError('invalid')
end;

var
	Allow : Boolean;
begin
	Ini   := TIniFile.Create('data/rooms.ini');
	Rooms := TStringList.Create;
	Ini.ReadSection('rooms', Rooms);
	Allow := Ini.ReadString('security','allownew','false') = 'true';

	try
		MaxRooms := StrToInt(
			Ini.ReadString('security', 'maxrooms', '0'))
	except
		MaxRooms := 0
	end;
	
	if not Allow then
		AResponse.Contents.LoadFromFile(
			'templates/pages/error/newroom.htm')
	else
	begin
		ModuleTemplate.FileName := 'templates/pages/create.htm';
		ModuleTemplate.AllowTagParams := True;
		ModuleTemplate.OnReplaceTag := @ReplaceTags;

		CheckParams
	end;

	Handled := True
end;

initialization
	RegisterHttpModule('create', TCreateModule)
end.
