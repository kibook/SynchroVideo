unit WmPlaylist;

interface
uses
	Classes,
	SysUtils,
	StrUtils,
	inifiles,
	fphttpclient,
	HTTPDefs,
	fpHTTP,
	fpWeb;

type
	TWmPlaylist = Class(TFPWebModule)
	published
		procedure DoRequest(
			Sender     : TObject;
			ARequest   : TRequest;
			AResponse  : TResponse;
			var Handle : Boolean);
	end;

var
	AWmPlaylist : TWmPlaylist;

implementation
uses
	math,
	svutils;

{$R *.lfm}

var
	Ini : TIniFile;

function CompareTitles(List : TStringList;
	Index1, Index2 : Integer) : Integer;
var
	t1 : String;
	t2 : String;
begin
	t1 := Ini.ReadString('videos', List[Index1], '???');
	t2 := Ini.ReadString('videos', List[Index2], '???');
	CompareTitles := AnsiCompareText(t1, t2)
end;

procedure TWmPlaylist.DoRequest(
	Sender     : TObject;
	ARequest   : TRequest;
	AResponse  : TResponse;
	var Handle : Boolean);
const
	YTAPIURL = 'http://gdata.youtube.com/feeds/api/videos/';
var
	Room      : String;
	SessionId : String;
	HostPass  : String;
	Secure    : Boolean;
	Locked    : Boolean;
	AFile   : Text;

function Alert(const s : String) : String;
begin
	Result := 'alert("'+s+'");'
end;

procedure WriteStatus;
begin
	AResponse.Content := 'Playlist.locked=' +
		IfThen(Locked, 'true', 'false') + ';'
end;

function GetPlaylists : TStringList;
var
	Info   : TSearchRec;
	faType : Word;
	Path   : String;

procedure CheckFile;
begin
	faType := Info.Attr and faDirectory;
	if not (faType = faDirectory) then
		Result.Add(Copy(Info.Name, 1, Length(Info.Name) - 4))
end;

begin
	Result := TStringList.Create;
	Path := 'rooms/'+Room+'/playlists/*';
	if FindFirst(Path, faAnyFile and faDirectory, Info) = 0 then
	begin
		repeat
			CheckFile
		until not (FindNext(Info) = 0)
	end;
	FindClose(Info)
end;

function GetTitle(Id : String) : String;
var
	Content : String;
	a       : Word;
	b       : Word;
begin
	with TFPHttpClient.Create(Nil) do
	begin
		Content := Get(YTAPIURL + Id + '?fields=title');
		Free
	end;

	a := Pos('<title type=''text''>', Content) + 19;
	b := Pos('</title>', Content);
	Result := Text2Html(Copy(Content, a, b - a))
end;

procedure WritePlaylists;
var
	Video   : String;
	Content : String;
begin
	Content := 'Playlists=[';
	for Video in GetPlaylists do
		Content := Content + '"'+Video+'",';
	AResponse.Content := Content + '];'
end;

procedure AddVideo;
var
	Id    : String;
	Title : String;
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
	Id : String;
begin
	Id := ARequest.QueryFields.Values['id'];
	Ini.DeleteKey('videos', Id)
end;

procedure ClearList;
var
	Videos : TStringList;
	Video  : String;
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
	Video  : String;
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
	FName    : String;
	ListName : String;
	Video    : String;	
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
	FName    : String;
	ListName : String;
	Video    : String;
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
	YTPLAPIURL = 'http://gdata.youtube.com/feeds/api/playlists/';
	Params     = '?v=2&max-results=50&start-index=';
var
	Id       : String;
	Content  : String;
	Title    : String;
	VideoId  : String;
	Index    : String;
	Requests : Word;
	a        : Word;
	b        : Word;
	i        : Word;

function GetListSize : Word;
const
	Tag    = 'openSearch:totalResults';
	Params = '?v=2&fields=' + Tag;
var
	Content : String;
	a       : Word;
	b       : Word;
begin
	GetListSize := 50;

	with TFPHttpClient.Create(Nil) do
	begin
		Content := Get(YTPLAPIURL + Id + Params);
		Free
	end;

	a := Pos('<'  + Tag + '>', Content) + 25;
	b := Pos('</' + Tag + '>', Content);
	GetListSize := StrToInt(Copy(Content, a, b - a))
end;

procedure ParseList;
begin
	Str((50 * i) + 1, Index);
	
	with TFPHttpClient.Create(Nil) do
	begin
		Content := Get(YTPLAPIURL + Id + Params + Index);
		Free
	end;

	a := Pos('<media:title type=''plain''>', Content) + 26;
	b := Pos('</media:title>', Content);
	Content := Copy(Content, b + 13, Length(Content));

	repeat
		Title := '';
		a := Pos('<media:title type=''plain''>', Content) + 26;
		b := Pos('</media:title>', Content);
		Title := Text2Html(Copy(Content, a, b - a));
		
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

function GetDuration(Id : String) : Double;
var
	Content : String;
	a       : Word;
	b       : Word;
begin
	try
		with TFPHttpClient.Create(NIL) do
		begin
			Content := Get(YTAPIURL + Id);
			Free
		end;
		a := Pos('<yt:duration seconds=''', Content) + 22;
		Content := Copy(Content, a, Length(Content));
		b := Pos('''/>', Content);
		GetDuration := StrToInt(Copy(Content, 1, b - 1))
	except
		GetDuration := 0
	end
end;

procedure SanitizeList;
var
	Videos : TStringList;
	Video  : String;
	Count  : Integer = 0;
begin
	Videos := TStringList.Create;
	Ini.ReadSection('videos', Videos);

	for Video in Videos do
		if GetDuration(Video) = 0 then
		begin
			Ini.DeleteKey('videos', Video);
			Inc(Count)
		end;

	Videos.Free
end;

procedure RemoveList;
var
	FName    : String;
	ListName : String;
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
	Status : String;
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

	Ini := TIniFile.Create('rooms/'+Room+'/playlist.ini');
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

	Handle := True
end;

initialization
	RegisterHTTPModule('playlist', TWmPlaylist)
end.
