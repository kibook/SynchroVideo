unit WmHome;

{$mode objfpc}
{$H+}

interface

uses
	Classes,
	HttpDefs,
	FpHttp,
	FpWeb;

type
	THomeModule = class(TFpWebModule)
	private
		FRooms : TStringList;
		FPub   : Integer;
		FPriv  : Integer;
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
	HomeModule : THomeModule;

implementation

{$R *.lfm}

uses
	SysUtils,
	IniFiles;

procedure THomeModule.ReplaceTags(
	Sender          : TObject;
	const TagString : string;
	TagParams       : TStringList;
	out ReplaceText : string);
begin
	case TagString of
		'NumRooms'  : ReplaceText := IntToStr(FRooms.Count);
		'PubRooms'  : ReplaceText := IntToStr(FPub);
		'PrivRooms' : ReplaceText := IntToStr(FPriv)
	end
end;

procedure THomeModule.Request(
	Sender      : TObject;
	ARequest    : TRequest;
	AResponse   : TResponse;
	var Handled : Boolean);
var
	Room : string;
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
		Ini := TIniFile.Create('rooms/' + Room + '/settings.ini');
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

	Handled := True
end;

initialization
	RegisterHttpModule('', THomeModule)
end.
