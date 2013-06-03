unit WmAuth;

interface
uses
	Classes,
	inifiles,
	HTTPDefs,
	fpHTTP,
	fpWeb;

type
	TWmAuth = Class(TFPWebModule)
	private
		FRoomName  : String;
		FRoom      : String;
		FAccess    : String;
		FType      : String;
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
	AWmAuth : TWmAuth;

implementation
{$R *.lfm}

procedure TWmAuth.ReplaceTags(
	Sender          : TObject;
	const TagString : String;
	TagParams       : TStringList;
	out ReplaceText : String);
begin
	case TagString of
		'RoomName' : ReplaceText := FRoomName;
		'Room'     : ReplaceText := FRoom;
		'Access'   : ReplaceText := FAccess;
		'Type'     : ReplaceText := FType;
	end
end;

procedure TWmAuth.DoRequest(
	Sender     : TObject;
	ARequest   : TRequest;
	AResponse  : TResponse;
	var Handle : Boolean);
var
	Ini : TIniFile;
begin
	FRoom   := ARequest.QueryFields.Values['room'];
	FAccess := ARequest.QueryFields.Values['access'];
	FType   := ARequest.QueryFields.Values['type'];

	Ini := TIniFile.Create('rooms/'+FRoom+'/settings.ini');
	FRoomName := Ini.ReadString('room', 'name', '');
	Ini.Free;

	ModuleTemplate.FileName := 'templates/pages/auth.htm';
	ModuleTemplate.AllowTagParams := True;
	ModuleTemplate.OnReplaceTag := @ReplaceTags;

	AResponse.Content := ModuleTemplate.GetContent;

	Handle := True
end;

initialization
	RegisterHTTPModule('auth', TWmAuth)
end.
