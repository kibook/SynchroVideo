unit WmRoom;

{$mode objfpc}
{$H+}

interface

uses
	Classes,
	HttpDefs,
	FpHttp,
	FpWeb;

type
	TRoomModule = class(TFpWebModule)
	private
		FRoom        : string;
		FPageTitle   : string;
		FBanner      : string;
		FFavicon     : string;
		FDescription : string;
		FVideoId     : string;
		FIrcConf     : string;
		FChannelName : string;
		FHostPass    : string;
		FRoomScript  : string;
		FRoomStyle   : string;
		FIsHost      : Boolean;
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
	RoomModule : TRoomModule;

implementation

{$R *.lfm}

uses
	SysUtils,
	StrUtils,
	IniFiles;

procedure TRoomModule.ReplaceTags(
	Sender          : TObject;
	const TagString : string;
	TagParams       : TStringList;
	out ReplaceText : string
);

function GetHostControls : string;
begin
	if FIsHost then
		with TStringList.Create do
		begin
			LoadFromFile('templates/html/hostcontrols.htm');
			Result := Text;
			Free
		end
end;

function GetListControls : string;
begin
	if FIsHost then
		with TStringList.Create do
		begin
			LoadFromFile('templates/html/listcontrols.htm');
			Result := Text;
			Free
		end
end;

function GetSyncControls : string;
begin
	if not FIsHost then
		with TStringList.Create do
		begin
			LoadFromFile('templates/html/synccontrols.htm');
			Result := Text;
			Free
		end
end;

function GetHostButton : string;
begin
	with TStringList.Create do
	begin
		if FIsHost then
			LoadFromFile('templates/html/hostbutton.htm')
		else
			LoadFromFile('templates/html/clientbutton.htm');
		Result := Text;
		Free
	end
end;

function GetSettingsLink : string;
begin
	with TStringList.Create do
	begin
		if FIsHost then
		begin
			LoadFromFile('templates/html/hostsettings.htm');
			Result := Format(Text, [FRoom, FHostPass])
		end else
		begin
			LoadFromFile('templates/html/clientsettings.htm');
			Result := Format(Text, [FRoom])
		end;
		Free
	end
end;

function GetRoomVars : string;
var
	SessionId  : string = 'undefined';
	SessionKey : string;
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
	end;

	with TStringList.Create do
	begin
		LoadFromFile('templates/js/roomvars.js');
		Result := Format(Text, [SessionId, FVideoId, FRoom]);
		Free
	end
end;

function GetSyncScript : string;
begin
	if FIsHost then
		Result := 'templates/js/sync-host.js'
	else
		Result := 'templates/js/sync-client.js'
end;

function GetBanner : string;
begin
	if not (FBanner = '') then
		with TStringList.Create do
		begin
			LoadFromFile('templates/html/banner.htm');
			Result := Format(Text, [FBanner]);
			Free
		end
	else
		Result := ''
end;

function GetDescription : string;
begin
	if not (FDescription = '') then
		with TStringList.Create do
		begin
			LoadFromFile('templates/html/description.htm');
			Result := Format(Text, [FDescription]);
			Free
		end
	else
		Result := ''
end;

begin
	case TagString of
		'PageTitle'    : ReplaceText := FPageTitle;
		'Banner'       : ReplaceText := GetBanner;
		'Favicon'      : ReplaceText := FFavicon;
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

procedure TRoomModule.Request(
	Sender      : TObject;
	ARequest    : TRequest;
	AResponse   : TResponse;
	var Handled : Boolean
);
const
	DefVideo = '8tPnX7OPo0Q';
var
	Ini      : TIniFile;
	Pass     : string;
	Host     : string;
	Password : string;
	IsAuth   : Boolean;
	BadPass  : Boolean;

function NameFormat(const RoomName : string) : string;
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

		FPageTitle   := Ini.ReadString('room','name', '');
		FBanner      := Ini.ReadString('room','banner', '');
		FFavicon     := Ini.ReadString('room','favicon', '');
		FDescription := Ini.ReadString('room','description', '');
		FVideoId     := Ini.ReadString('room','video',  DefVideo);
		FIrcConf     := Ini.ReadString('room','irc-settings', '');
		Password     := Ini.ReadString('room','password', '');
		FHostPass    := Ini.ReadString('room','host-password', '');
		FRoomScript  := Ini.ReadString('room','script', '');
		FRoomStyle   := Ini.ReadString('room','style', '');

		Ini.Free;

		FIsHost :=  not (Host = '') and (Host = FHostPass);
		IsAuth  := (not (Pass = '') and (Pass = Password)) or 
			(Password = '') or FIsHost;

		BadPass := (not (Host = '') and not FIsHost) or
			(not (Pass = '') and not IsAuth);

		FChannelName := NameFormat(FPageTitle);

		if BadPass then
			ModuleTemplate.FileName :=
				'templates/pages/error/auth.htm'
		else if IsAuth then
			ModuleTemplate.FileName :=
				'templates/pages/room.htm'
		else
			ModuleTemplate.FileName :=
				'templates/pages/error/room.htm';

		ModuleTemplate.AllowTagParams := True;
		ModuleTemplate.OnReplaceTag := @ReplaceTags;

		AResponse.Content := ModuleTemplate.GetContent
	end;

	Handled := True
end;

initialization
	RegisterHttpModule('join', TRoomModule)
end.
