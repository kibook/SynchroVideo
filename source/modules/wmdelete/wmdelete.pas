unit WmDelete;

{$mode objfpc}
{$H+}

interface

uses
	Classes,
	HttpDefs,
	FpHttp,
	FpWeb;

type
	TDeleteModule = class(TFpWebModule)
	private
		FRoom     : string;
		FHostPass : string;
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
	DeleteModule : TDeleteModule;

implementation

{$R *.lfm}

uses
	SysUtils,
	IniFiles,
	SvUtils;

procedure TDeleteModule.ReplaceTags(
	Sender          : TObject;
	const TagString : string;
	TagParams       : TStringList;
	out ReplaceText : string);
begin
	case TagString of
		'Room' : ReplaceText := FRoom;
		'Host' : ReplaceText := FHostPass
	end
end;

procedure TDeleteModule.Request(
	Sender      : TObject;
	ARequest    : TRequest;
	AResponse   : TResponse;
	var Handled : Boolean);
var
	Confirm : Boolean;
	IsAuth  : Boolean;
	Ini     : TIniFile;
	Pass    : string;

procedure GetConfirmation;
begin
	ModuleTemplate.FileName :=
		'templates/pages/error/delete/confirm.htm'
end;

procedure DenyAccess;
begin
	ModuleTemplate.FileName :=
		'templates/pages/error/delete/deny.htm'
end;

procedure DeleteRoom;
var
	Playlist : string;
begin
	Ini := TIniFile.Create('data/rooms.ini');
	Ini.CacheUpdates := True;

	Ini.DeleteKey('rooms', FRoom);
	Ini.Free;

	for Playlist in GetRoomPlaylists(FRoom) do
		DeleteFile('rooms/'+FRoom+'/playlists/'+Playlist+'.ini');

	RemoveDir('rooms/' + FRoom + '/playlists/');

	DeleteFile('rooms/' + FRoom + '/syncvid.syn');
	DeleteFile('rooms/' + FRoom + '/session.id');
	DeleteFile('rooms/' + FRoom + '/playlist.ini');
	DeleteFile('rooms/' + FRoom + '/settings.ini');

	RemoveDir('rooms/' + FRoom + '/');

	ModuleTemplate.FileName := 'templates/pages/delete.htm'
end;

var
	RoomExists : Boolean;
begin
	FRoom     := ARequest.ContentFields.Values['room'];
	Confirm   := ARequest.ContentFields.Values['confirm']='true';
	FHostPass := ARequest.ContentFields.Values['host'];

	Ini := TIniFile.Create('rooms/' + FRoom + '/settings.ini');
	Pass := Ini.ReadString('room', 'host-password', '');

	IsAuth := (FHostPass = Pass) and
		not (Pass = '') and
		not (FRoom = '');

	Ini.Free;

	RoomExists := FileExists('rooms/' + FRoom + '/settings.ini');

	if IsAuth and RoomExists then
		if not Confirm then
			GetConfirmation
		else
			DeleteRoom
	else
		DenyAccess;

	ModuleTemplate.AllowTagParams := True;
	ModuleTemplate.OnReplaceTag := @ReplaceTags;

	AResponse.Content := ModuleTemplate.GetContent;

	Handled := True
end;

initialization
	RegisterHttpModule('delete', TDeleteModule)
end.
