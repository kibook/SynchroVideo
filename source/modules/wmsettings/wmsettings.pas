unit WmSettings;

{$mode objfpc}{$h+}{$r *.lfm}

interface

uses
  Classes,
  HttpDefs,
  FpHttp,
  FpWeb;

type
  TSettingsModule = class(TFpWebModule)
  private
    FRoom        : string;
    FPassword    : string;
    FHostPass    : string;
    FPageTitle   : string;
    FBanner      : string;
    FFavicon     : string;
    FIrcConf     : string;
    FTags        : string;
    FDescription : string;
    FRoomScript  : string;
    FRoomStyle   : string;
    procedure ReplaceTags(
      Sender          : TObject;
      const TagString : string;
      TagParams       : TStringList;
      out ReplaceText : string);
  published
    procedure Request(
      Sender     : TObject;
      ARequest   : TRequest;
      AResponse  : TResponse;
      var Handle : Boolean);
  end;

var
  SettingsModule : TSettingsModule;

implementation

uses
  SysUtils,
  IniFiles;

procedure TSettingsModule.ReplaceTags(
  Sender          : TObject;
  const TagString : string;
  TagParams       : TStringList;
  out ReplaceText : string);
begin
  case TagString of
    'PageTitle'   : ReplaceText := FPageTitle;
    'Room'        : ReplaceText := FRoom;
    'HostPass'    : ReplaceText := FHostPass;
    'Banner'      : ReplaceText := FBanner;
    'Favicon'     : ReplaceText := FFavicon;
    'IrcConf'     : ReplaceText := FIrcConf;
    'Password'    : ReplaceText := FPassword;
    'Tags'        : ReplaceText := FTags;
    'Description' : ReplaceText := FDescription;
    'RoomScript'  : ReplaceText := FRoomScript;
    'RoomStyle'   : ReplaceText := FRoomStyle
  end
end;

procedure TSettingsModule.Request(
  Sender     : TObject;
  ARequest   : TRequest;
  AResponse  : TResponse;
  var Handle : Boolean);
var
  Ini  : TIniFile;
  Pass : string;
begin
  FRoom := ARequest.QueryFields.Values['room'];
  
  Pass := ARequest.ContentFields.Values['host'];

  Ini := TIniFile.Create('rooms/'+FRoom+'/settings.ini');

  FPassword    := Ini.ReadString('room', 'password',      '');
  FHostPass    := Ini.ReadString('room', 'host-password', '');
  FPageTitle   := Ini.ReadString('room', 'name',          '');
  FBanner      := Ini.ReadString('room', 'banner',        '');
  FFavicon     := Ini.ReadString('room', 'favicon',       '');
  FIrcConf     := Ini.ReadString('room', 'irc-settings',  '');
  FTags        := Ini.ReadString('room', 'tags',          '');
  FDescription := Ini.ReadString('room', 'description',   '');
  FRoomScript  := Ini.ReadString('room', 'script',        '');
  FRoomStyle   := Ini.ReadString('room', 'style',         '');

  if not (Pass = '') and (Pass = FHostPass) then
    ModuleTemplate.FileName := 'templates/pages/settings.htm'
  else
    ModuleTemplate.FileName := 'templates/pages/error/settings.htm';

  ModuleTemplate.AllowTagParams := True;
  ModuleTemplate.OnReplaceTag := @ReplaceTags;

  AResponse.Content := ModuleTemplate.GetContent;

  Handle := True
end;

initialization
  RegisterHttpModule('settings', TSettingsModule)
end.
