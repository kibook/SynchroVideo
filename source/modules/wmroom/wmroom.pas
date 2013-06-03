unit WmRoom;

interface
uses
	Classes,
	SysUtils,
	StrUtils,
	IniFiles,
	HTTPDefs,
	fpHTTP,
	fpWeb;

type
	TWmRoom = Class(TFPWebModule)
	private
		FRoom        : String;
		FPageTitle   : String;
		FBanner      : String;
		FDescription : String;
		FVideoId     : String;
		FIrcConf     : String;
		FChannelName : String;
		FHostPass    : String;
		FRoomScript  : String;
		FRoomStyle   : String;
		FIsHost      : Boolean;
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
	AWmRoom : TWmRoom;

implementation
{$R *.lfm}

procedure TWmRoom.DoRequest(
	Sender     : TObject;
	ARequest   : TRequest;
	AResponse  : TResponse;
	var Handle : Boolean);
const
	DefVideo = '8tPnX7OPo0Q';
var
	Ini      : TIniFile;
	Pass     : String;
	Host     : String;
	Password : String;
	IsAuth   : Boolean;

function NameFormat(const RoomName : String) : String;
begin
	Result := LowerCase(RoomName);
	Result := StringReplace(Result, ' ', '-', [rfReplaceAll])
end;

begin
	FRoom := ARequest.QueryFields.Values['room'];
	Host  := ARequest.ContentFields.Values['host'];
	Pass  := ARequest.ContentFields.Values['password'];

	if not FileExists('rooms/' + FRoom + '/settings.ini') then
	begin
		AResponse.Code := 404;
		AResponse.CodeText := 'Room does not exist';
		AResponse.Contents.LoadFromFile(
			'templates/pages/404/room.htm')
	end else
	begin
		Ini := TIniFile.Create('rooms/' + FRoom + '/settings.ini');

		FPageTitle   := Ini.ReadString('room','name',         '');
		FBanner      := Ini.ReadString('room','banner',       '');
		FDescription := Ini.ReadString('room','description',  '');
		FVideoId     := Ini.ReadString('room','video',  DefVideo);
		FIrcConf     := Ini.ReadString('room','irc-settings', '');
		Password     := Ini.ReadString('room','password',     '');
		FHostPass    := Ini.ReadString('room','host-password','');
		FRoomScript  := Ini.ReadString('room','script',       '');
		FRoomStyle   := Ini.ReadString('room','style',        '');

		Ini.Free;

		FIsHost :=  not (Host = '') and (Host = FHostPass);
		IsAuth  := (not (Pass = '') and (Pass = Password)) or 
			(Password = '') or FIsHost;

		FChannelName := NameFormat(FPageTitle);

		ModuleTemplate.FileName := 'templates/pages/' +
			IfThen(IsAuth, 'room.htm', 'error/room.htm');
		ModuleTemplate.AllowTagParams := True;
		ModuleTemplate.OnReplaceTag := @ReplaceTags;

		AResponse.Content := ModuleTemplate.GetContent
	end;

	Handle := True
end;

procedure TWmRoom.ReplaceTags(
	Sender          : TObject;
	const TagString : String;
	TagParams       : TStringList;
	out ReplaceText : String);

function GetHostControls : String;
begin
	if FIsHost then
		with TStringList.Create do
		begin
			LoadFromFile('templates/html/hostcontrols.htm');
			Result := Text;
			Free
		end
end;

function GetListControls : String;
begin
	if FIsHost then
		with TStringList.Create do
		begin
			LoadFromFile('templates/html/listcontrols.htm');
			Result := Text;
			Free
		end
end;

function GetSyncControls : String;
begin
	if not FIsHost then
		with TStringList.Create do
		begin
			LoadFromFile('templates/html/synccontrols.htm');
			Result := Text;
			Free
		end
end;

function GetHostButton : String;
begin
	if FIsHost then
		Result := '<input type="button" ' +
			'value="Drop Host" ' +
			'onclick="dropHost();">&nbsp;'
	else
		Result := '<input type="button" ' +
			'value="Become Host" ' +
			'onclick="takeHost();">&nbsp;'
end;

function GetSettingsLink : String;
begin
	if FIsHost then
		Result := '<form name="form" ' +
			'action="?action=settings&room='+FRoom+'" '+
			'method="POST" target="_blank">'#13#10 +
			'<input type="hidden" name="host" ' +
			'value="'+FHostPass+'">'#13#10 +
			'</form>'#13#10 +
			'<a href="javascript:" onclick="form.submit();">'
	else
		Result := '<a href="?action=settings&room='+FRoom+'" '+
			'target="_blank">';
	
	Result := Result + '[Room Settings]</a>'
end;

function GetRoomVars : String;
var
	SessionId  : String;
	SessionKey : String;
	AFile      : Text;
begin
	Result := '';
	if FIsHost then
	begin
		Randomize;
		Str(Random($FFFF), SessionId);
		Str(Random($FFFF), SessionKey);
		SessionId := XorEncode(SessionKey, SessionId);

		AssignFile(AFile, 'rooms/'+FRoom+'/session.id');
		Rewrite(AFile);
		WriteLn(AFile, XorEncode(FHostPass, SessionId));
		CloseFile(AFile);

		Result := 'var SESSIONID = "' + SessionId + '";'#13#10;
	end;

	Result := Result + 'var VIDEOID = "' + FVideoId + '";'#13#10;
	Result := Result + 'var ROOMNAME = "' + FRoom + '";'
end;

function GetSyncScript : String;
begin
	Result := 'templates/js/' +
		IfThen(FIsHost, 'sync-host.js', 'sync-client.js')
end;

function GetBanner : String;
begin
	if not (FBanner = '') then
		Result := '<p><img width="1000" height="300" src="' +
			FBanner + '"></p>'
	else
		Result := ''
end;

function GetDescription : String;
begin
	if not (FDescription = '') then
		Result := '<div id="description">'+FDescription+'</div>'
	else
		Result := ''
end;

begin
	case TagString of
		'PageTitle'    : ReplaceText := FPageTitle;
		'Banner'       : ReplaceText := GetBanner;
		'Description'  : ReplaceText := GetDescription;
		'VideoId'      : ReplaceText := FVideoId;
		'ChannelName'  : ReplaceText := FChannelName;
		'IrcConf'      : ReplaceText := FIrcConf;
		'HostControls' : ReplaceText := GetHostControls;
		'ListControls' : ReplaceText := GetListControls;
		'SyncControls' : ReplaceText := GetSyncControls;
		'TakeHost'     : ReplaceText := GetHostButton;
		'SettingsLink' : ReplaceText := GetSettingsLink;
		'VideoVars'    : ReplaceText := GetRoomVars;
		'SyncScript'   : ReplaceText := GetSyncScript;
		'RoomScript'   : ReplaceText := FRoomScript;
		'RoomStyle'    : ReplaceText := FRoomStyle;
		'Room'         : ReplaceText := FRoom
	end
end;

initialization
	RegisterHTTPModule('join', TWmRoom)
end.
