unit WmServer;

{$mode objfpc}{$h+}{$r *.lfm}

interface

uses
  Classes,
  HttpDefs,
  FpHttp,
  FpWeb;

type
  TServerModule = class(TFpWebModule)
  published
    procedure Request(
      Sender      : TObject;
      ARequest    : TRequest;
      AResponse   : TResponse;
      var Handled : Boolean);
  end;

var
  ServerModule : TServerModule;

implementation

uses
  SysUtils,
  StrUtils,
  IniFiles;

procedure TServerModule.Request(
  Sender      : TObject;
  ARequest    : TRequest;
  AResponse   : TResponse;
  var Handled : Boolean);
var
  Room       : string;
  SyncTime   : string = '';
  HostPass   : string;
  SessionId  : string;
  BufferFile : string;
  Content    : string = '';
  VideoId    : string;
  Paused     : string;
  TvMode     : string;
  Id         : string;
  Playlist   : TStringList;
  AFile      : Text;
  Ini        : TIniFile;

procedure SetSync;
begin
  VideoId  := ARequest.QueryFields.Values['video'];
  Paused   := ARequest.QueryFields.Values['paused'];
  SyncTime := ARequest.QueryFields.Values['time'];
  TvMode   := '0';

  AssignFile(AFile, BufferFile);      
  Rewrite(AFile);
  WriteLn(AFile, VideoId);
  WriteLn(AFile, Paused);
  WriteLn(AFile, SyncTime);
  WriteLn(AFile, TvMode);
  CloseFile(AFile)
end;

procedure GetPlaylist;
begin
  Ini := TIniFile.Create('rooms/'+Room+'/playlist.ini');
  Playlist := TStringList.Create;
  Ini.ReadSection('videos', Playlist);

  Content := Content + 'Playlist.list=[';
  for VideoId in Playlist do
  begin
    Content := Content + '{title:"';
    Content := Content + Ini.ReadString('videos',
      VideoId, '???');
    Content := Content + '",id:"' + VideoId + '"},'
  end;
  Content := Content + '];';

  Ini.Free
end;

procedure GetSync;
begin
  AssignFile(AFile, BufferFile);
  Reset(AFile);
  ReadLn(AFile, VideoId);
  ReadLn(AFile, Paused);
  ReadLn(AFile, SyncTime);
  ReadLn(AFile, TvMode);
  CloseFile(AFile);

  Content := Content +
    'SYNCPLAY="' + Paused   + '";'#13#10+
    'SYNCTIME="' + SyncTime + '";'#13#10+
    'SYNCVURL="' + VideoId  + '";'#13#10+
    'SYNCSVTV="' + TvMode   + '";'#13#10
end;

procedure CheckHost;
begin
  if Id = SessionId then
    SetSync
  else
    Content := Content + 'window.location="'+
      '?action=join&room='+Room+'";'
end;

begin
  AResponse.ContentType := 'text/javascript';

  Room := ARequest.QueryFields.Values['room'];
  Id   := ARequest.QueryFields.Values['session'];

  BufferFile := 'rooms/' + Room + '/syncvid.syn';

  Ini := TIniFile.Create('rooms/'+Room+'/settings.ini');
  HostPass := Ini.ReadString('room', 'host-password', '');
  Ini.Free;

  if FileExists('rooms/'+Room+'/session.id') then
  begin
    AssignFile(AFile, 'rooms/'+Room+'/session.id');
    Reset(AFile);
    ReadLn(AFile, SessionId);
    CloseFile(AFile);

    SessionId := XorDecode(HostPass, SessionId);

    if not (Id = '') then
      CheckHost
    else
      GetSync;

    GetPlaylist
  end
  else
    Content := 'location.reload(true);';
  
  AResponse.Content := Content;

  Handled := True
end;

initialization
  RegisterHttpModule('server', TServerModule)
end.
