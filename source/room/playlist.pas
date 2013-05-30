{$mode objfpc}
uses
	dos,
	strarrutils,
	inifiles,
	classes,
	strutils,
	math,
	htmlutils,
	sysutils,
	fphttpclient;

const
	YTAPIURL   = 'http://gdata.youtube.com/feeds/api/videos/';
	YTPLAPIURL = 'http://gdata.youtube.com/feeds/api/playlists/';
	ValidChars = ['a'..'z', '0'..'9'];

var
	Ini: TIniFile;

function GetPlaylists : TStringList;
var
	Info   : TSearchRec;
	faType : Word;

procedure CheckFile;
begin
	faType := Info.Attr and faDirectory;
	if not (faType = faDirectory) then
		GetPlaylists.Add(Copy(Info.Name, 1, Length(Info.name) - 4))
end;

begin
	GetPlaylists := TStringList.Create;
	if FindFirst('playlists/*',faAnyFile and faDirectory,Info)=0 then
	begin
		repeat
			CheckFile
		until not (FindNext(Info) = 0)
	end;
	FindClose(Info)
end;

function GetTitle(Id : String) : String;
var
	Content : AnsiString;
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
	GetTitle := Text2Html(Copy(Content, a, b - a));
end;

function GetListSize(Id : String) : Word;
const
	Tag    = 'openSearch:totalResults';
	Params = '?v=2&fields=' + Tag;
var
	Content : AnsiString;
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

procedure ImportList(Id : String);
const
	Params = '?v=2&max-results=50&start-index=';
var
	Content  : AnsiString;
	Title    : String;
	VideoId  : String;
	Index    : String;
	Requests : Word;
	a        : Word;
	b        : Word;
	i        : Word;

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
	Requests := Ceil(GetListSize(Id) / 50.0);
	
	for i := 0 to Requests - 1 do
	begin
		ParseList;
	end
end;

function CompareTitles(List : TStringList;
	Index1, Index2 : Integer) : Integer;
var
	t1, t2 : string;
begin
	t1 := Ini.ReadString('videos', List[Index1], '???');
	t2 := Ini.ReadString('videos', List[Index2], '???');
	CompareTitles := AnsiCompareText(t1, t2)
end;

procedure WriteStatus(Locked : Boolean);
begin
	Write('Playlist.locked=');
	if Locked then
		Write('true')
	else
		Write('false');
	WriteLn(';')
end;

procedure WritePlaylists;
var
	Video : String;
begin
	Write('Playlists=[');
	for Video in GetPlaylists do
		Write('"', Video, '",');
	WriteLn('];')
end;

procedure AddVideo(Id : String);
begin
	Ini.WriteString('videos', Id, GetTitle(Id))
end;

procedure DeleteVideo(Id : String);
begin
	Ini.DeleteKey('videos', Id)
end;

procedure ToggleLock(Lock : Boolean);
var
	Status : String;
begin
	if Lock then
		Status := 'true'
	else
		Status := 'false';
	Ini.WriteString('status', 'locked', Status);
	writeln('Playlist.locked=', Status, ';')
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

procedure SaveList(FName : String);
var
	ListName : String;
	Video    : String;	
	Ch       : Char;
	Videos   : TStringList;
	NewIni   : TIniFile;
	Ref      : Text;
begin
	ListName := '';

	for Ch in LowerCase(FName) do
		if Ch in ValidChars then
			ListName := Concat(ListName, Ch);

	if FileExists('playlists/' + ListName +'.ini') then
	begin
		Assign(Ref, 'playlists/' + ListName + '.ini');
		Erase(Ref)
	end;

	NewIni := TIniFile.Create('playlists/' + ListName + '.ini');
	NewIni.CacheUpdates := True;
	NewIni.WriteString('status', 'locked', 'false');

	Videos := TStringList.Create;
	Ini.ReadSection('videos', Videos);

	for Video in Videos do
		NewIni.WriteString('videos', Video,
			Ini.ReadString('videos', Video, ''));

	NewIni.UpdateFile;

	NewIni.Free;
	Videos.Free
end;

procedure LoadList(FName : String);
var
	ListName : String;
	Video    : String;
	Videos   : TStringList;
	NewIni   : TIniFile;
begin
	ListName := 'playlists/' + FName + '.ini';

	if not FileExists(ListName) then
		Halt;

	NewIni := TIniFile.Create(ListName);

	Videos := TStringList.Create;
	NewIni.ReadSection('videos', Videos);

	for Video in Videos do
		Ini.WriteString('videos', Video,
			NewIni.ReadString('videos', Video, '???'));

	Videos.Free;
	NewIni.Free
end;

procedure MoveVideo(Id1, Id2 : String);
var
	Video  : String;
	Videos : TStringList;
	Titles : TStringList;
	a      : Word;
	b      : Word;
	e      : Word;
	i      : Word;
begin
	Videos := TStringList.Create;
	Titles := TStringList.Create;

	Ini.ReadSection('videos', Videos);

	for Video in Videos do
	begin
		Titles.Add(Ini.ReadString('videos', Video, '???'));
		Ini.DeleteKey('videos', Video)
	end;

	Val(Id1, a, e);
	if not (e = 0) then
		Halt;

	Val(Id2, b, e);
	if not (e = 0) then
		Halt;

	Video := Videos[a];
	Videos.Delete(a);
	Videos.Insert(b, Video);

	for i := 0 to Videos.Count - 1 do
		Ini.WriteString('videos', Videos[i], Titles[i])
end;

procedure RemoveList(FName : String);
var
	ListName : String;
	Ref      : Text;
begin
	ListName := 'playlists/' + FName + '.ini';
	if not FileExists(ListName) then
		Halt;
	Assign(Ref, ListName);
	Erase(Ref)
end;


var
	Query     : TStringArray;
	SessionId : String;	
	HostPass  : String;
	Locked    : Boolean;
	Secure    : Boolean;
	Ref       : Text;
begin
	WriteLn('Content-Type: text/javascript');
	WriteLn;

	Query    := Split(GetEnv('QUERY_STRING'), '&');

	Secure   := False;
	Ini      := TIniFile.Create('settings.ini');
	HostPass := Ini.ReadString('room', 'host-password', '');

	Assign(Ref, 'session.id');
	Reset(Ref);
	ReadLn(Ref, SessionId);
	Close(Ref);

	SessionId := XorDecode(HostPass, SessionId);
	Secure := (SessionId = Query[0]);


	Ini    := TIniFile.Create('playlist.ini');
	Ini.CacheUpdates := True;

	locked := Ini.ReadString('status', 'locked', 'true') = 'true';

	case Length(Query) of
		1 : case Query[0] of
			'status': WriteStatus(Locked);
			'list'  : WritePlaylists;
		end;

		2 : begin
			case Query[0] of
				'add': if not Locked then
					AddVideo(Query[1])
			end;
			case Query[1] of
				'lock'    : if Secure then
					ToggleLock(True);
				'unlock'  : if Secure then
					ToggleLock(False);
				'clear'   : if Secure then
					ClearList;
				'shuffle' : if Secure then
					ShuffleList;
				'sort'    : if Secure then
					SortList
			end
		end;

		3 : case Query[1] of
			'add'    : if Secure then
				AddVideo(Query[2]);
			'delete' : if Secure then
				DeleteVideo(Query[2]);
			'save'   : if Secure then
				SaveList(Query[2]);
			'load'   : if Secure then
				LoadList(Query[2]);
			'remove' : if Secure then
				RemoveList(Query[2]);
			'import' : if Secure then
				ImportList(Query[2])
		end;
		4 : case Query[1] of
			'move' : if Secure then
				MoveVideo(Query[2], Query[3])
		end
	end;

	Ini.UpdateFile;
	Ini.Free
end.
