unit WmApi;

{$mode objfpc}{$h+}{$r *.lfm}

interface

uses
  HttpDefs,
  FpHttp,
  FpWeb;

type
  TApiModule = class(TFpWebModule)
  published
    procedure Request(
      Sender      : TObject;
      ARequest    : TRequest;
      AResponse   : TResponse;
      var Handled : Boolean);
  end;

var
  ApiModule: TApiModule;

implementation

uses
  SysUtils,
  Classes,
  IniFiles,
  SvUtils;

procedure TApiModule.Request(
  Sender      : TObject;
  ARequest    : TRequest;
  AResponse   : TResponse;
  var Handled : Boolean);
var
  Room : string;

procedure GetCurrentVideo;
var
  BufferFile : string;
  ListFile   : string;
  VideoId    : string = '';
  VideoTitle : string = '';
  AFile      : Text;
  Ini        : TIniFile;
begin
  BufferFile := 'rooms/' + Room + '/syncvid.syn';
  ListFile   := 'rooms/' + Room + '/playlist.ini';

  if (FileExists(BufferFile)) and (FileExists(ListFile)) then
  begin
    AssignFile(AFile, BufferFile);
    Reset(AFile);
    ReadLn(AFile, VideoId);
    CloseFile(AFile);
    Ini := TIniFile.Create(ListFile);
    VideoTitle := Ini.ReadString('videos', VideoId, '');
    Ini.Free;
    AResponse.Content := VideoTitle
  end
  else
    AResponse.Code := 404
end;

procedure GetCurrentID;
var
  BufferFile : string;
  VideoId    : string = '';
  AFile      : Text;
begin
  BufferFile := 'rooms/' + Room + '/syncvid.syn';

  if FileExists(BufferFile) then
  begin
    AssignFile(AFile, BufferFile);
    Reset(AFile);
    ReadLn(AFile, VideoId);
    CloseFile(AFile);
    AResponse.Content := VideoId
  end
  else
    AResponse.Code := 404
end;

procedure GetSavedPlaylist;
var
  ListFile : string;
  Videos   : TStringList;
  i        : Integer;
  Ini      : TIniFile;
begin
  ListFile := ARequest.QueryFields.Values['list'];
  ListFile := 'rooms/' + Room + '/playlists/' + ListFile + '.ini';

  if FileExists(ListFile) then
  begin
    Ini := TIniFile.Create(ListFile);
    Videos := TStringList.Create;
    Ini.ReadSection('videos', Videos);
    for i := 0 to Videos.Count - 1 do
      Videos[i] := Ini.ReadString('videos',Videos[i], '');
    Ini.Free;
    AResponse.Contents := Videos;
    Videos.Free
  end
  else
    AResponse.Code := 404
end;

procedure GetPlaylist;
var
  ListFile : string;
  Videos   : TStringList;
  i        : Integer;
  Ini      : TIniFile;
begin
  ListFile := 'rooms/' + Room + '/playlist.ini';

  if FileExists(ListFile) then
  begin
    Ini := TIniFile.Create(ListFile);
    Videos := TStringList.Create;   
    Ini.ReadSection('videos', Videos);
    for i := 0 to Videos.Count - 1 do
      Videos[i] := Ini.ReadString('videos',Videos[i],'');
    Ini.Free;
    AResponse.Contents := Videos;
    Videos.Free   
  end
  else
    AResponse.Code := 404
end;

procedure GetTvMode;
var
  BufferFile : string;
  Line       : string;
  AFile      : Text;
begin
  BufferFile := 'rooms/' + Room + '/syncvid.syn';

  if FileExists(BufferFile) then
  begin
    AssignFile(AFile, BufferFile);
    Reset(AFile);
    ReadLn(AFile, Line);
    ReadLn(AFile, Line);
    ReadLn(AFile, Line);
    ReadLn(AFile, Line);
    CloseFile(AFile);
    if Line = '1' then
      AResponse.Content := 'true'
    else
      AResponse.Content := 'false'
  end
  else
    AResponse.Code := 404
end;

procedure GetCurrentTime;
var
  BufferFile : string;
  Line       : string;
  AFile      : Text;
begin
  BufferFile := 'rooms/' + Room + '/syncvid.syn';

  if FileExists(BufferFile) then
  begin
    AssignFile(AFile, BufferFile);
    Reset(AFile);
    ReadLn(AFile, Line);
    ReadLn(AFile, Line);
    ReadLn(AFile, Line);
    CloseFile(AFile);
    AResponse.Content := Line
  end
  else
    AResponse.Code := 404
end;

procedure GetCurrentStatus;
var
  BufferFile : string;
  Line       : string;
  AFile      : Text;
begin
  BufferFile := 'rooms/' + Room + '/syncvid.syn';

  if FileExists(BufferFile) then
  begin
    AssignFile(AFile, BufferFile);
    Reset(AFile);
    ReadLn(AFile, Line);
    ReadLn(AFile, Line);
    CloseFile(AFile);
    if Line = '1' then
      AResponse.Content := 'paused'
    else
      AResponse.Content := 'playing'
  end
  else
    AResponse.Code := 404
end;

procedure GetPlaylists;
begin
  AResponse.Contents := GetRoomPlaylists(Room)
end;

begin
  AResponse.ContentType := 'text/plain';

  Room := ARequest.QueryFields.Values['room'];

  case ARequest.QueryFields.Values['get'] of
    'videotitle'    : GetCurrentVideo;
    'videoid'       : GetCurrentId;
    'videotime'     : GetCurrentTime;
    'currentstatus' : GetCurrentStatus;
    'playlist'      : GetPlaylist;
    'tvmode'        : GetTvMode;
    'playlists'     : GetPlaylists;
    'savedlist'     : GetSavedPlaylist
  else
    AResponse.Code := 404
  end;

  Handled := True
end;

initialization
  RegisterHttpModule('api', TApiModule)
end.
