uses
	strarrutils,
	inifiles,
	classes,
	crt,
	strutils,
	sysutils,
	fphttpclient;
const
	BufferFile = 'syncvid.syn';
	YTAPIURL   = 'http://gdata.youtube.com/feeds/api/videos/';	

function GetDuration(Id : String) : Double;
var
	Content : AnsiString;
	a       : Word;
	b       : Word;
begin
	GetDuration := 0;
	with TFPHttpClient.Create(NIL) do
	begin
		Content := Get(YTAPIURL + Id);
		Free
	end;
	a := Pos('<yt:duration seconds=''', Content) + 22;
	Content := Copy(Content, a, Length(Content));
	b := Pos('''/>', Content);
	GetDuration := StrToInt(Copy(Content, 1, b - 1))
end;

var
	Ref        : Text;
	Videos     : TStringList;
	Ini        : TIniFile;
	SessionKey : String;
	SessionId  : String;
	HostPass   : String;
	VideoId    : String;
	GetStr     : String;
	TvMode     : String;
	Duration   : Double;
	Time       : Double;
	Index      : Word;
	i          : Word;
begin
	Ini := TIniFile.Create('settings.ini');
	HostPass := Ini.ReadString('room', 'host-password', '');
	Ini.Free;

	Videos := TStringList.Create;

	Ini := TIniFile.Create('playlist.ini');
	Ini.ReadSection('videos', Videos);
	Ini.Free;

	Randomize;
	Str(Random($FFFF), SessionId);
	Str(Random($FFFF), SessionKey);
	SessionId := XorEncode(SessionKey, SessionId);

	Assign(Ref, 'session.id');
	Rewrite(Ref);
	Writeln(Ref, XorEncode(HostPass, SessionId));
	Close(Ref);

	Assign(Ref, BufferFile);
	Reset(Ref);
	ReadLn(Ref, VideoId);
	ReadLn(Ref, GetStr);
	ReadLn(Ref, GetStr);
	Time := StrToFloat(GetStr);
	ReadLn(Ref, TvMode);
	close(Ref);

	Rewrite(Ref);
	WriteLn(Ref, VideoId);
	WriteLn(Ref, '0');
	WriteLn(Ref, Format('%.2F', [Time]));
	WriteLn(Ref, '1');
	Close(Ref);

	Duration := GetDuration(VideoId);
	Index := 0;
	for i := 0 to Videos.Count - 1 do
		if Videos[i] = VideoId then
			Index := i;
	repeat
		Reset(Ref);
		ReadLn(Ref, VideoId);
		ReadLn(Ref, GetStr);
		ReadLn(Ref, GetStr);
		Time := StrToFloat(GetStr);
		ReadLn(Ref, TvMode);
		Close(Ref);

		Delay(1000);
		Time := Time + 1.00;

		//writeln('TIME: ', time, '||DURATION: ', duration);

		if Time > Duration then
		begin
			Index := (Index + 1) mod Videos.Count;
			VideoId := Videos[Index];
			Time := 0;
			Duration := GetDuration(VideoId)
		end;

		Reset(Ref);
		ReadLn(Ref, GetStr);
		ReadLn(Ref, GetStr);
		ReadLn(Ref, GetStr);
		ReadLn(Ref, TvMode);
		Close(Ref);
		
		Rewrite(Ref);
		WriteLn(Ref, VideoId);
		WriteLn(Ref, '0');
		WriteLn(Ref, Format('%.2F', [Time]));
		WriteLn(Ref, TvMode);
		Close(Ref)
	until TvMode = '0';
end.
