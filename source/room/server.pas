uses
	strarrutils,
	dos,
	inifiles,
	classes,
	strutils;

const
	BufferFile = 'syncvid.syn';

var
	Query     : TStringArray;
	SessionId : String;
	SyncTime  : String;
	HostPass  : String;	
	VideoId   : String;
	Paused    : String;
	TvMode    : String;
	Ref       : Text;
	Ini       : TIniFile;
	Playlist  : TStringList;
begin
	WriteLn('Content-Type: text/javascript');
	WriteLn;

	Query    := Split(GetEnv('QUERY_STRING'), '&');
	SyncTime := '';

	Ini      := TIniFile.Create('settings.ini');
	HostPass := Ini.ReadString('room', 'host-password', '');
	Ini.Free;

	Assign(Ref, 'session.id');
	Reset(Ref);
	ReadLn(Ref, SessionId);
	Close(Ref);

	SessionId := XorDecode(HostPass, SessionId);

	Assign(Ref, BufferFile);
	if Length(Query) > 1 then
		if Query[0] = SessionId then
		begin
			VideoId  := Query[1];
			Paused   := Query[2];
			SyncTime := Query[3];
			TvMode   := '0';

			Rewrite(Ref);
			WriteLn(Ref, VideoId);
			WriteLn(Ref, Paused);
			WriteLn(Ref, SyncTime);
			WriteLn(Ref, TvMode)
		end else
		begin
			WriteLn('window.location="./";');
			WriteLn('alert("You are no longer host!");');
			Halt
		end
	else
	begin
		Reset(ref);
		ReadLn(Ref, Videoid);
		ReadLn(Ref, Paused);
		ReadLn(Ref, SyncTime);
		ReadLn(Ref, TvMode)
	end;
	Close(Ref);

	WriteLn('SYNCPLAY="', Paused,   '";');
	WriteLn('SYNCTIME="', SyncTime, '";');
	WriteLn('SYNCVURL="', VideoId,  '";');
	WriteLn('SYNCSVTV="', TvMode,   '";');

	Ini      := TIniFile.Create('playlist.ini');
	Playlist := TStringList.Create;
	Ini.ReadSection('videos', Playlist);

	Write('Playlist.list=[');
	for VideoId in Playlist do
	begin
		Write('{title:"');
		Write(Ini.ReadString('videos', VideoId, '???'));
		Write('",id:"', VideoId, '"},')
	end;
	WriteLn('];')
end.
