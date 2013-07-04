unit WmAuth;

{$mode objfpc}
{$H+}

interface

uses
	Classes,
	HttpDefs,
	FpHttp,
	FpWeb;

type
	TAuthModule = class(TFpWebModule)
	private
		FRoomName  : string;
		FRoom      : string;
		FAccess    : string;
		FType      : string;
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
	AuthModule : TAuthModule;

implementation

{$R *.lfm}

uses
	IniFiles;

procedure TAuthModule.ReplaceTags(
	Sender          : TObject;
	const TagString : string;
	TagParams       : TStringList;
	out ReplaceText : string);
begin
	case TagString of
		'RoomName' : ReplaceText := FRoomName;
		'Room'     : ReplaceText := FRoom;
		'Access'   : ReplaceText := FAccess;
		'Type'     : ReplaceText := FType;
	end
end;

procedure TAuthModule.Request(
	Sender      : TObject;
	ARequest    : TRequest;
	AResponse   : TResponse;
	var Handled : Boolean);
var
	Ini : TIniFile;
begin
	FRoom   := ARequest.QueryFields.Values['room'];
	FAccess := ARequest.QueryFields.Values['access'];
	FType   := ARequest.QueryFields.Values['type'];

	Ini := TIniFile.Create('rooms/' + FRoom + '/settings.ini');
	FRoomName := Ini.ReadString('room', 'name', '');
	Ini.Free;

	ModuleTemplate.FileName := 'templates/pages/auth.htm';
	ModuleTemplate.AllowTagParams := True;
	ModuleTemplate.OnReplaceTag := @ReplaceTags;

	AResponse.Content := ModuleTemplate.GetContent;

	Handled := True
end;

initialization
	RegisterHttpModule('auth', TAuthModule)
end.
