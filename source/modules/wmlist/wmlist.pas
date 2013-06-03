unit WmList;

interface
uses
	Classes,
	IniFiles,
	HTTPDefs,
	fpHTTP,
	fpWeb;

type
	TWmList = Class(TFPWebModule)
	private
		FRoomList : String;
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
	AWmList : TWmList;

implementation
{$R *.lfm}

procedure TWmList.ReplaceTags(
	Sender          : TObject;
	const TagString : String;
	TagParams       : TStringList;
	out ReplaceText : String);
begin
	case TagString of
		'RoomList' : ReplaceText := FRoomList
	end
end;

procedure TWmList.DoRequest(
	Sender     : TObject;
	ARequest   : TRequest;
	AResponse  : TResponse;
	var Handle : Boolean);
const
	CRLF = #13#10;

var
	Ini   : TIniFile;
	Rooms : TStringList;
	Desc  : String;
	Title : String;
	Room  : String;
	Priv  : Boolean;
	i     : Word = 0;

procedure ListRoom;
begin
	Title := Ini.ReadString('room', 'name', '');
	Desc  := Ini.ReadString('room', 'description', '');

	FRoomList := FRoomList + '<td>' + CRLF;
	FRoomList := FRoomList + '<div title="'+Desc+'">' + CRLF;
	FRoomList := FRoomList + '<h3>';
	FRoomList := FRoomList + '<a href="room/'+Room+'">'+Title+'</a>';
	FRoomList := FRoomList + '</h3>' + CRLF;
	FRoomList := FRoomList + '</div' + CRLF + '</td>' + CRLF
end;
	
begin
	Ini := TIniFile.Create('data/rooms.ini');
	Rooms := TStringList.Create;
	Ini.ReadSection('rooms', Rooms);
	Ini.Free;

	Rooms.Sort;

	FRoomList := '';

	for Room in Rooms do
	begin
		Ini := TIniFile.Create('rooms/'+Room+'/settings.ini');
		Priv := not (Ini.ReadString('room','password','')='');

		if not Priv then
		begin
			if i mod 3 = 0 then
				FRoomList := FRoomList + '<tr>' + CRLF;

			ListRoom;

			if i mod 3 = 2 then
				FRoomList := FRoomList + '</tr>' + CRLF;
			Ini.Free;
			Inc(i)
		end
	end;

	ModuleTemplate.FileName := 'templates/pages/list.htm';
	ModuleTemplate.AllowTagParams := True;
	ModuleTemplate.OnReplaceTag := @ReplaceTags;

	AResponse.Content := ModuleTemplate.GetContent;

	Handle := True
end;

initialization
	RegisterHTTPModule('list', TWmList)
end.
