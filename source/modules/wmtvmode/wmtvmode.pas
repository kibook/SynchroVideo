unit WmTVMode;

interface
uses
	IniFiles,
	Process,
	StrUtils,
	HTTPDefs,
	fpHTTP,
	fpWeb;

type
	TWmTVMode = Class(TFPWebModule)
	published
		procedure DoRequest(
			Sender     : TObject;
			ARequest   : TRequest;
			AResponse  : TResponse;
			var Handle : Boolean);
	end;

var
	AWmTVMode : TWmTVMode;

implementation
{$R *.lfm}

procedure TWmTVMode.DoRequest(
	Sender     : TObject;
	ARequest   : TRequest;
	AResponse  : TResponse;
	var Handle : Boolean);
var
	Ini       : TIniFile;
	Room      : String;
	Id        : String;
	SessionId : String;
	HostPass  : String;
	AFile     : Text;
	Server    : TProcess;
begin
	Room := ARequest.QueryFields.Values['room'];
	Id   := ARequest.QueryFields.Values['session'];

	Ini := TIniFile.Create('rooms/'+Room+'/settings.ini');
	HostPass := Ini.ReadString('room', 'host-password', '');
	Ini.Free;

	AssignFile(AFile, 'rooms/'+Room+'/session.id');
	Reset(AFile);
	ReadLn(AFile, SessionId);
	Close(AFile);

	SessionId := XorDecode(HostPass, SessionId);

	if Id = SessionId then
	begin
		Server := TProcess.Create(Nil);
		Server.Executable := 'bin/tvserver';
		Server.Parameters.Add(Room);
		Server.Options := [poUsePipes];
		Server.Execute
	end;

	Handle := True
end;

initialization
	RegisterHTTPModule('tvmode', TWmTVMode)
end.
