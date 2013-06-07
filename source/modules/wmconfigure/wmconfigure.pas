unit WmConfigure;

interface
uses
	IniFiles,
	SysUtils,
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

procedure ThrowError(Err : String);
begin
	AResponse.Contents.LoadFromFile(
		'templates/pages/error/configure/'+Err+'.htm')
end;

procedure ConfigureRoom;
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

	AResponse.Contents.LoadFromFile('templates/pages/configure.htm')
end;

procedure CheckInput;
var
	NameCheck : Boolean;
	c         : Char;
begin
	NameCheck := True;
	for c in PageTitle do
		if not (c in ['A'..'Z','a'..'z','0'..'9',' ']) then
			NameCheck := False;

	if not NameCheck then
		ThrowError('badname')
	else
		ConfigureRoom
end;

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
		CheckInput
	else
		ThrowError('configure');

	Ini.Free;

	Handle := True
end;

initialization
	RegisterHTTPModule('configure', TWmConfigure)
end.
