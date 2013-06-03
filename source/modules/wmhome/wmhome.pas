unit WmHome;

interface
uses
	Classes,
	SysUtils,
	inifiles,
	HTTPDefs,
	fpHTTP,
	fpWeb;

type
	TWmHome = Class(TFPWebModule)
	private
		FRooms : TStringList;
		FPub   : Integer;
		FPriv  : Integer;
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
	AWmHome : TWmHome;

implementation
{$R *.lfm}

procedure TWmHome.ReplaceTags(
	Sender          : TObject;
	const TagString : String;
	TagParams       : TStringList;
	out ReplaceText : String);
begin
	case TagString of
		'NumRooms'  : ReplaceText := IntToStr(FRooms.Count);
		'PubRooms'  : ReplaceText := IntToStr(FPub);
		'PrivRooms' : ReplaceText := IntToStr(FPriv)
	end
end;

procedure TWmHome.DoRequest(
	Sender     : TObject;
	ARequest   : TRequest;
	AResponse  : TResponse;
	var Handle : Boolean);
var
	Room : String;
	Ini  : TIniFile;
begin
	FPub := 0;
	FPriv := 0;
	Ini := TIniFile.Create('data/rooms.ini');
	FRooms := TStringList.Create;
	Ini.ReadSection('rooms', FRooms);
	Ini.Free;

	for Room in FRooms do
	begin
		Ini := TIniFile.Create('rooms/'+Room+'/settings.ini');
		if Ini.ReadString('room', 'password', '') = '' then
			Inc(FPub)
		else
			Inc(FPriv);
		Ini.Free
	end;

	ModuleTemplate.FileName := 'templates/pages/home.htm';
	ModuleTemplate.AllowTagParams := True;
	ModuleTemplate.OnReplaceTag := @ReplaceTags;

	AResponse.Content := ModuleTemplate.GetContent;

	FRooms.Free;

	Handle := True
end;

initialization
	RegisterHTTPModule('', TWmHome)
end.
