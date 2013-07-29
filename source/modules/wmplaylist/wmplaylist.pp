unit WmPlaylist;

{$mode objfpc}{$h+}{$r *.lfm}

interface

uses
  HttpDefs,
  FpHttp,
  FpWeb;

type
  TPlaylistModule = class(TFpWebModule)
  published
    procedure Request(
      Sender      : TObject;
      ARequest    : TRequest;
      AResponse   : TResponse;
      var Handled : Boolean);
  end;

var
  PlaylistModule : TPlaylistModule;

implementation

uses
  Classes,
  SysUtils,
  Math,
  IniFiles,
  FpHttpClient,
  StrUtils,
  SvUtils,
  HtmlElements;

var
  Ini : TIniFile;

function CompareTitles(
  List : TStringList;
  Index1 : Integer;
  Index2 : Integer
) : Integer;
var
  t1 : string;
  t2 : string;
begin
  t1 := Ini.ReadString('videos', List[Index1], '???');
  t2 := Ini.ReadString('videos', List[Index2], '???');
  CompareTitles := AnsiCompareText(t1, t2)
end;

procedure TPlaylistModule.Request(
  Sender      : TObject;
  ARequest    : TRequest;
  AResponse   : TResponse;
  var Handled : Boolean);
const
  YtApiUrl = 'http://gdata.youtube.com/feeds/api/videos/';
var
  Room      : string;
  SessionId : string;
  HostPass  : string;
  Secure    : Boolean;
  Locked    : Boolean;
  AFile     : Text;

function Alert(const Msg: string) : string;
begin
  Result := 'alert("' + Msg + '");'
end;

procedure WriteStatus;
begin
  AResponse.Content := 'Playlist.locked=' +
    IfThen(Locked, 'true', 'false') + ';'
end;

function GetTitle(Id: string) : string;
var
  Content : string;
  a       : Word;
  b       : Word;
begin
  with TFpHttpClient.Create(Nil) do
  begin
    Content := Get(YtApiUrl + Id + '?fields=title');
    Free
  end;

  a := Pos('<title type=''text''>', Content) + 19;
  b := Pos('</title>', Content);
  Result := EscapeHtml(Copy(Content, a, b - a))
end;

procedure WritePlaylists;
var
  Video   : string;
  Content : string;
begin
  Content := 'Playlists=[';
  for Video in GetRoomPlaylists(Room) do
    Content := Content + '"' + Video + '",';
  AResponse.Content := Content + '];'
end;

procedure AddVideo;
var
  Id    : string;
  Title : string;
begin
  if not Locked or Secure then
  begin
    Id := ARequest.QueryFields.Values['id'];
    Title := GetTitle(Id);
    if not (Title = '') then
      Ini.WriteString('videos', Id, Title)
    else
      AResponse.Content := Alert('Error adding video!')
  end
  else
    AResponse.Content := Alert('Playlist is locked!')
end;

procedure DeleteVideo;
var
  Id : string;
begin
  Id := ARequest.QueryFields.Values['id'];
  Ini.DeleteKey('videos', Id)
end;

procedure ClearList;
var
  Videos : TStringList;
  Video  : string;
begin
  Videos := TStringList.Create;
  Ini.ReadSection('videos', Videos);
  for Video in Videos do
    Ini.DeleteKey('videos', Video);
  Videos.Free
end;

procedure ShuffleList;
var
  Videos : TStringList;
  Titles : TStringList;
  Video  : string;
  a      : Word;
  b      : Word;
  i      : Word;
begin
  Videos := TStringList.Create;
  Ini.ReadSection('videos', Videos);

  for Video in Videos do
    for i := 1 to 10 do
    begin
      a := Random(Videos.Count);
      b := Random(Videos.Count);
      Videos.Exchange(a, b)
    end;

  Titles := TStringList.Create;

  for Video in Videos do
  begin
    Titles.Add(Ini.ReadString('videos', Video, '???'));
    Ini.DeleteKey('videos', Video)
  end;

  for i := 0 to Videos.Count - 1 do
    Ini.WriteString('videos', Videos[i], Titles[i]);
  
  Videos.Free;
  Titles.Free
end;

procedure SortList;
var
  Videos : TStringList;
  Titles : TStringList;
  Video  : string;
  i      : word;
begin
  Videos := TStringList.Create;
  Titles := TStringList.Create;

  Ini.ReadSection('videos', Videos);

  Videos.CustomSort(@CompareTitles);

  for Video in Videos do
  begin
    Titles.Add(Ini.ReadString('videos', Video, '???'));
    Ini.DeleteKey('videos', Video)
  end;

  for i := 0 to Videos.Count - 1 do
    Ini.WriteString('videos', Videos[i], Titles[i]);
  
  Videos.Free;
  Titles.Free
end;

procedure SaveList;
const
  ValidChars = ['a'..'z', '0'..'9'];
var
  FName    : string;
  ListName : string;
  Video    : string;  
  Ch       : Char;
  Videos   : TStringList;
  NewIni   : TIniFile;
  AFile    : Text;
begin
  FName := ARequest.QueryFields.Values['list'];

  ListName := 'rooms/'+Room+'/playlists/';

  for Ch in LowerCase(FName) do
    if Ch in ValidChars then
      ListName := ListName + Ch;

  if ListName = '' then
    ListName := 'unnamed';
  
  ListName := ListName + '.ini';

  if FileExists(ListName) then
  begin
    AssignFile(AFile, ListName);
    Erase(AFile)
  end;

  NewIni := TIniFile.Create(ListName);
  NewIni.CacheUpdates := True;
  NewIni.WriteString('status', 'locked', 'false');

  Videos := TStringList.Create;
  Ini.ReadSection('videos', Videos);

  for Video in Videos do
    NewIni.WriteString('videos', Video,
      Ini.ReadString('videos', Video, ''));

  NewIni.Free;
  Videos.Free
end;

procedure LoadList;
var
  FName    : string;
  ListName : string;
  Video    : string;
  Videos   : TStringList;
  NewIni   : TIniFile;
begin
  FName := ARequest.QueryFields.Values['list'];

  ListName := 'rooms/'+Room+'/playlists/'+FName+'.ini';

  if not FileExists(ListName) then
    Exit;

  NewIni := TIniFile.Create(ListName);

  Videos := TStringList.Create;
  NewIni.ReadSection('videos', Videos);

  for Video in Videos do
    Ini.WriteString('videos', Video,
      NewIni.ReadString('videos', Video, '???'));

  Videos.Free;
  NewIni.Free
end;

procedure ImportList;
const
  YtPlApiUrl = 'http://gdata.youtube.com/feeds/api/playlists/';
  Params     = '?v=2&max-results=50&start-index=';
var
  Id       : string;
  Content  : string;
  Title    : string;
  VideoId  : string;
  Index    : string;
  Requests : Word;
  a        : Word;
  b        : Word;
  i        : Word;

function GetListSize : Word;
const
  Tag    = 'openSearch:totalResults';
  Params = '?v=2&fields=' + Tag;
var
  Content : string;
  a       : Word;
  b       : Word;
begin
  GetListSize := 50;

  with TFpHttpClient.Create(Nil) do
  begin
    Content := Get(YtPlApiUrl + Id + Params);
    Free
  end;

  a := Pos('<'  + Tag + '>', Content) + 25;
  b := Pos('</' + Tag + '>', Content);
  GetListSize := StrToInt(Copy(Content, a, b - a))
end;

procedure ParseList;
begin
  Str((50 * i) + 1, Index);
  
  with TFpHttpClient.Create(Nil) do
  begin
    Content := Get(YtPlApiUrl + Id + Params + Index);
    Free
  end;

  a := Pos('<media:title type=''plain''>', Content) + 26;
  b := Pos('</media:title>', Content);
  Content := Copy(Content, b + 13, Length(Content));

  repeat
    Title := '';
    a := Pos('<media:title type=''plain''>', Content) + 26;
    b := Pos('</media:title>', Content);
    Title := EscapeHtml(Copy(Content, a, b - a));
    
    Content := Copy(Content, b + 13, Length(Content));

    VideoId := '';
    a := Pos('<yt:videoid>',  Content) + 12;
    b := Pos('</yt:videoid>', Content);
    VideoId := Copy(Content, a, b - a);

    Content := Copy(Content, b + 13, Length(Content));

    if not (Title = '') and not (VideoId = '') then
      Ini.WriteString('videos', VideoId, Title)
  until Pos('<media:title type=''plain''>', Content) = 0
end;

begin
  Id := ARequest.QueryFields.Values['id'];

  Requests := Ceil(GetListSize / 50.0);
  
  for i := 0 to Requests - 1 do
  begin
    ParseList;
  end
end;

procedure SanitizeList;
var
  Videos     : TStringList;
  Video      : string;
  Content    : string;
  Bad        : Boolean = False;
  HttpClient : TFpHttpClient;
begin
  Videos := TStringList.Create;
  Ini.ReadSection('videos', Videos);

  HttpClient := TFpHttpClient.Create(Nil);

  for Video in Videos do
  begin
    try
      Content := HttpClient.Get(YtApiUrl + Video)
    except
      if not (HttpClient.ResponseStatusCode = 404) then
        Break;
      Bad := True
    end;
    Bad := Bad or
          (Pos('reasonCode=''requesterRegion''', Content) > 0);
    if Bad then
      Ini.DeleteKey('videos', Video);
    Sleep(500)
  end;

  HttpClient.Free;
  Videos.Free
end;

procedure RemoveList;
var
  FName    : string;
  ListName : string;
  Ref      : Text;
begin
  FName := ARequest.QueryFields.Values['list'];
  ListName := 'rooms/'+Room+'/playlists/'+FName+'.ini';
  if not FileExists(ListName) then
    Halt;
  AssignFile(Ref, ListName);
  Erase(Ref)
end;

procedure ToggleLock(Lock : Boolean);
var
  Status : string;
begin
  Status := IfThen(Lock, 'true', 'false');
  Ini.WriteString('status', 'locked', Status);
  AResponse.Content := 'Playlist.locked=' + Status + ';'
end;

begin
  AResponse.ContentType := 'text/javascript';

  Room := ARequest.QueryFields.Values['room'];

  Ini := TIniFile.Create('rooms/'+Room+'/settings.ini');
  HostPass := Ini.ReadString('room', 'host-password', '');
  Ini.Free;

  AssignFile(AFile, 'rooms/'+Room+'/session.id');
  Reset(AFile);
  ReadLn(AFile, SessionId);
  CloseFile(AFile);

  SessionId := XorDecode(HostPass, SessionId);
  Secure := (SessionId = ARequest.QueryFields.Values['session']);

  Ini := TIniFile.Create('rooms/' + Room + '/playlist.ini');
  Ini.CacheUpdates := True;

  Locked := Ini.ReadString('status', 'locked', 'true') = 'true';
  
  case ARequest.QueryFields.Values['do'] of
    'status'   : WriteStatus;
    'list'     : WritePlaylists;
    'add'      : AddVideo;
    'delete'   : if Secure then DeleteVideo;
    'lock'     : if Secure then ToggleLock(True);
    'unlock'   : if Secure then ToggleLock(False);
    'clear'    : if Secure then ClearList;
    'shuffle'  : if Secure then ShuffleList;
    'sort'     : if Secure then SortList;
    'save'     : if Secure then SaveList;
    'load'     : if Secure then LoadList;
    'import'   : if Secure then ImportList;
    'remove'   : if Secure then RemoveList;
    'sanitize' : if Secure then SanitizeList
  end;

  Ini.Free;

  Handled := True
end;

initialization
  RegisterHttpModule('playlist', TPlaylistModule)
end.
