unit WmList;

{$mode objfpc}{$h+}{$r *.lfm}

interface

uses
  Classes,
  HttpDefs,
  FpHttp,
  FpWeb;

type
  TListModule = class(TFpWebModule)
  private
    FRoomList : string;
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
  ListModule : TListModule;

implementation

uses
  SysUtils,
  IniFiles;

procedure TListModule.ReplaceTags(
  Sender          : TObject;
  const TagString : string;
  TagParams       : TStringList;
  out ReplaceText : string);
begin
  case TagString of
    'RoomList' : ReplaceText := FRoomList
  end
end;

procedure TListModule.Request(
  Sender      : TObject;
  ARequest    : TRequest;
  AResponse   : TResponse;
  var Handled : Boolean);
var
  Ini     : TIniFile;
  Rooms   : TStringList;
  Content : TStringList;
  Desc    : string;
  Title   : string;
  Room    : string;
  Priv    : Boolean;
  i       : Word = 0;

procedure ListRoom;
begin
  if i mod 3 = 0 then
    FRoomList := FRoomList+'<tr>'+LineEnding;

  Title := Ini.ReadString('room', 'name', '');
  Desc  := Ini.ReadString('room', 'description', '');

  FRoomList := FRoomList +
    Format(Content.Text, [Desc, Room, Title]);

  if (i mod 3 = 2) or (i = Rooms.Count - 1) then
    FRoomList := FRoomList+'</tr>'+LineEnding;
  Inc(i)
end;
  
begin
  Ini := TIniFile.Create('data/rooms.ini');
  Rooms := TStringList.Create;
  Ini.ReadSection('rooms', Rooms);
  Ini.Free;

  Rooms.Sort;

  FRoomList := '';

  Content := TStringList.Create;
  Content.LoadFromFile('templates/html/listentry.htm');

  for Room in Rooms do
  begin
    Ini := TIniFile.Create('rooms/' + Room + '/settings.ini');
    Priv := not (Ini.ReadString('room','password','') = '');

    if not Priv then
      ListRoom;

    Ini.Free;   
  end;

  Content.Free;

  ModuleTemplate.FileName := 'templates/pages/list.htm';
  ModuleTemplate.AllowTagParams := True;
  ModuleTemplate.OnReplaceTag := @ReplaceTags;

  AResponse.Content := ModuleTemplate.GetContent;

  Handled := True
end;

initialization
  RegisterHttpModule('list', TListModule)
end.
