unit WmSettings;

interface
uses
	Classes,
	SysUtils,
	inifiles,
	HTTPDefs,
	fpHTTP,
	fpWeb;

type
	TWmSettings = Class(TFPWebModule)
	private
		FRoom        : String;
		FPassword    : String;
		FHostPass    : String;
		FPageTitle   : String;
		FBanner      : String;
		FFavicon     : String;
		FIrcConf     : String;
		FTags        : String;
		FDescription : String;
		FRoomScript  : String;
		FRoomStyle   : String;
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
	AWmSettings : TWmSettings;

implementation
{$R *.lfm}

procedure TWmSettings.ReplaceTags(
	Sender          : TObject;
	const TagString : String;
	TagParams       : TStringList;
	out ReplaceText : String);
begin
	case TagString of
		'PageTitle'   : ReplaceText := FPageTitle;
		'Room'        : ReplaceText := FRoom;
		'HostPass'    : ReplaceText := FHostPass;
		'Banner'      : ReplaceText := FBanner;
		'Favicon'     : ReplaceText := FFavicon;
		'IrcConf'     : ReplaceText := FIrcConf;
		'Password'    : ReplaceText := FPassword;
		'Tags'        : ReplaceText := FTags;
		'Description' : ReplaceText := FDescription;
		'RoomScript'  : ReplaceText := FRoomScript;
		'RoomStyle'   : ReplaceText := FRoomStyle
	end
end;

procedure TWmSettings.DoRequest(
	Sender     : TObject;
	ARequest   : TRequest;
	AResponse  : TResponse;
	var Handle : Boolean);
var
	Ini  : TIniFile;
	Pass : String;
begin
	FRoom := ARequest.QueryFields.Values['room'];
	
	Pass := ARequest.ContentFields.Values['host'];

	Ini := TIniFile.Create('rooms/'+FRoom+'/settings.ini');

	FPassword    := Ini.ReadString('room', 'password',      '');
	FHostPass    := Ini.ReadString('room', 'host-password', '');
	FPageTitle   := Ini.ReadString('room', 'name',          '');
	FBanner      := Ini.ReadString('room', 'banner',        '');
	FFavicon     := Ini.ReadString('room', 'favicon',       '');
	FIrcConf     := Ini.ReadString('room', 'irc-settings',  '');
	FTags        := Ini.ReadString('room', 'tags',          '');
	FDescription := Ini.ReadString('room', 'description',   '');
	FRoomScript  := Ini.ReadString('room', 'script',        '');
	FRoomStyle   := Ini.ReadString('room', 'style',         '');

	if not (Pass = '') and (Pass = FHostPass) then
		ModuleTemplate.FileName := 'templates/pages/settings.htm'
	else
		ModuleTemplate.FileName :=
			'templates/pages/error/settings.htm';

	ModuleTemplate.AllowTagParams := True;
	ModuleTemplate.OnReplaceTag := @ReplaceTags;

	AResponse.Content := ModuleTemplate.GetContent;

	Handle := True
end;

initialization
	RegisterHTTPModule('settings', TWmSettings)
end.
