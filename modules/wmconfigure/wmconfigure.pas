unit WmConfigure;

{$mode objfpc}{$h+}{$r *.lfm}

interface

uses
  HttpDefs,
  FpHttp,
  FpWeb;

type
  TConfigureModule = class(TFpWebModule)
  published
    procedure Request(
      Sender      : TObject;
      ARequest    : TRequest;
      AResponse   : TResponse;
      var Handled : Boolean);
  end;

var
  ConfigureModule: TConfigureModule;

implementation

uses
  SysUtils,
  IniFiles;

procedure TConfigureModule.Request(
  Sender      : TObject;
  ARequest    : TRequest;
  AResponse   : TResponse;
  var Handled : Boolean);
var
  Room        : string;
  Pass        : string;
  PageTitle   : string;
  Banner      : string;
  Favicon     : string;
  IrcConf     : string;
  NewPass     : string;
  NewHost     : string;
  Tags        : string;
  Description : string;
  RoomScript  : string;
  RoomStyle   : string;
  HostPass    : string;
  Ini         : TIniFile;

procedure ThrowError(Err: string);
begin
  AResponse.Contents.LoadFromFile(
    'templates/pages/error/configure/' + Err + '.htm')
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
  NameCheck: Boolean;
  c: Char;
begin
  NameCheck := True;
  for c in PageTitle do
    if not (c in ['A'..'Z','a'..'z','0'..'9',' ']) then
      NameCheck := False;

  if not NameCheck then
    ThrowError('badname')
  else if NewHost = '' then
    ThrowError('password')
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

  Ini := TIniFile.Create('rooms/' + Room + '/settings.ini');
  Ini.CacheUpdates := True;

  HostPass := Ini.ReadString('room', 'host-password', '');

  if not (Pass = '') and (Pass = HostPass) then
    CheckInput
  else
    ThrowError('configure');

  Ini.Free;

  Handled := True
end;

initialization
  RegisterHttpModule('configure', TConfigureModule)
end.
