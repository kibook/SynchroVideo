unit WmTVMode;

{$mode objfpc}
{$H+}

interface

uses
	HttpDefs,
	FpHttp,
	FpWeb;

type
	TTvModeModule = class(TFpWebModule)
	published
		procedure Request(
			Sender      : TObject;
			ARequest    : TRequest;
			AResponse   : TResponse;
			var Handled : Boolean);
	end;

var
	TvModeModule : TTvModeModule;

implementation

{$R *.lfm}

uses
	IniFiles,
	Process,
	StrUtils;

procedure TTvModeModule.Request(
	Sender      : TObject;
	ARequest    : TRequest;
	AResponse   : TResponse;
	var Handled : Boolean);
var
	Ini       : TIniFile;
	Room      : string;
	Id        : string;
	SessionId : string;
	HostPass  : string;
	AFile     : Text;
	Server    : TProcess;
begin
	Room := ARequest.QueryFields.Values['room'];
	Id   := ARequest.QueryFields.Values['session'];

	Ini := TIniFile.Create('rooms/' + Room + '/settings.ini');
	HostPass := Ini.ReadString('room', 'host-password', '');
	Ini.Free;

	AssignFile(AFile, 'rooms/' + Room + '/session.id');
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

	Handled := True
end;

initialization
	RegisterHttpModule('tvmode', TTvModeModule)
end.
