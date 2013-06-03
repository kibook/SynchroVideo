unit WmConfigure;

interface
uses
	IniFiles,
	HTTPDefs,
	fpHTTP,
	fpWeb;

type
	TWmConfigure = Class(TFPWebModule)
	published
		procedure DoRequest(
			Sender     : TObject;
			ARequest   : TRequest;
			AResponse  : TResponse;
			var Handle : Boolean);
	end;

var
	AWmConfigure : TWmConfigure;

implementation
{$R *.lfm}

procedure TWmConfigure.DoRequest(
	Sender     : TObject;
	ARequest   : TRequest;
	AResponse  : TResponse;
	var Handle : Boolean);
var
	Room        : String;
	Pass        : String;
	PageTitle   : String;
	Banner      : String;
	Favicon     : String;
	IrcConf     : String;
	NewPass     : String;
	NewHost     : String;
	Tags        : String;
	Description : String;
	RoomScript  : String;
	RoomStyle   : String;
	HostPass    : String;
	Ini         : TIniFile;
begin
	Room        := ARequest.ContentFields.Values['room'];
	Pass        := ARequest.ContentFields.Values['host'];
	PageTitle   := ARequest.ContentFields.Values['title'];
	Banner      := ARequest.ContentFields.Values['banner'];
	Favicon     := ARequest.ContentFields.Values['favicon'];
	IrcConf     := ARequest.ContentFields.Values['ircconf'];
	NewPass     := ARequest.ContentFields.Values['newpass'];
	NewHost     := ARequest.ContentFields.Values['newhost'];
	Tags        := ARequest.ContentFields.Values['tags'];
	Description := ARequest.ContentFields.Values['desc'];
	RoomScript  := ARequest.ContentFields.Values['script'];
	RoomStyle   := ARequest.ContentFields.Values['style'];

	Ini := TIniFile.Create('rooms/'+Room+'/settings.ini');
	Ini.CacheUpdates := True;

	HostPass := Ini.ReadString('room', 'host-password', '');

	if not (Pass = '') and (Pass = HostPass) then
	begin
		Ini.WriteString('room', 'name',          PageTitle);
		Ini.WriteString('room', 'banner',        Banner);
		Ini.WriteString('room', 'favicon',       Favicon);
		Ini.WriteString('room', 'irc-settings',  IrcConf);
		Ini.WriteString('room', 'password',      NewPass);
		Ini.WriteString('room', 'host-password', NewHost);
		Ini.WriteString('room', 'tags',          Tags);
		Ini.WriteString('room', 'description',   Description);
		Ini.WriteString('room', 'script',        RoomScript);
		Ini.WriteString('room', 'style',         RoomStyle);

		Ini.Free;

		AResponse.Contents.LoadFromFile(
			'templates/pages/configure.htm')
	end
	else
		AResponse.Contents.LoadFromFile(
			'templates/pages/error/configure.htm');

	Handle := True
end;

initialization
	RegisterHTTPModule('configure', TWmConfigure)
end.
