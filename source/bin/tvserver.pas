program TvServer;

{$mode objfpc}
{$H+}

uses
	IniFiles,
	Classes,
	StrUtils,
	SysUtils,
	FpHttpClient;
const
	BufferFile = 'syncvid.syn';
	YtApiUrl   = 'http://gdata.youtube.com/feeds/api/videos/';	

function GetDuration(Id : string) : Double;
var
	Content : string;
	a       : Word;
	b       : Word;
begin
	try
		with TFpHttpClient.Create(NIL) do
		begin
			Content := Get(YtApiUrl + Id);
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

var
	AFile      : Text;
	Videos     : TStringList;
	Ini        : TIniFile;
	Room       : string;
	SessionKey : string;
	SessionId  : string;
	HostPass   : string;
	VideoId    : string;
	GetStr     : string;
	TvMode     : string;
	Path       : string;
	Duration   : Double;
	Time       : Double;
	Index      : Word;
	i          : Word;
begin
	Room := ParamStr(1);

	Path := 'rooms/'+Room+'/';

	Ini := TIniFile.Create(Path + 'settings.ini');
	HostPass := Ini.ReadString('room', 'host-password', '');
	Ini.Free;

	Videos := TStringList.Create;

	Ini := TIniFile.Create(Path + 'playlist.ini');
	Ini.ReadSection('videos', Videos);
	Ini.Free;

	Randomize;
	Str(Random($FFFF), SessionId);
	Str(Random($FFFF), SessionKey);
	SessionId := XorEncode(SessionKey, SessionId);

	Assign(AFile, Path + 'session.id');
	Rewrite(AFile);
	Writeln(AFile, XorEncode(HostPass, SessionId));
	Close(AFile);

	Assign(AFile, Path + BufferFile);
	Reset(AFile);
	ReadLn(AFile, VideoId);
	ReadLn(AFile, GetStr);
	ReadLn(AFile, GetStr);
	Time := StrToFloat(GetStr);
	ReadLn(AFile, TvMode);
	close(AFile);

	Rewrite(AFile);
	WriteLn(AFile, VideoId);
	WriteLn(AFile, '0');
	WriteLn(AFile, Format('%.2F', [Time]));
	WriteLn(AFile, '1');
	Close(AFile);

	Duration := GetDuration(VideoId);
	Index := 0;
	for i := 0 to Videos.Count - 1 do
		if Videos[i] = VideoId then
			Index := i;
	repeat
		Reset(AFile);
		ReadLn(AFile, VideoId);
		ReadLn(AFile, GetStr);
		ReadLn(AFile, GetStr);
		Time := StrToFloat(GetStr);
		ReadLn(AFile, TvMode);
		Close(AFile);

		Sleep(1000);
		Time := Time + 1.00;

		if Time > Duration then
		begin
			Index := (Index + 1) mod Videos.Count;
			VideoId := Videos[Index];
			Time := 0;
			Duration := GetDuration(VideoId)
		end;

		Reset(AFile);
		ReadLn(AFile, GetStr);
		ReadLn(AFile, GetStr);
		ReadLn(AFile, GetStr);
		ReadLn(AFile, TvMode);
		Close(AFile);
		
		Rewrite(AFile);
		WriteLn(AFile, VideoId);
		WriteLn(AFile, '0');
		WriteLn(AFile, Format('%.2F', [Time]));
		WriteLn(AFile, TvMode);
		Close(AFile)
	until TvMode = '0';
end.
