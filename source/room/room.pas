uses
	dos,
	strarrutils,
	inifiles,
	sysutils,
	classes,
	strutils,
	htmlutils;

const
	DefTitle = 'Sync Vid';
	JSFile   = 'room.js';
	DefVideo = 'YTu-ctARF2w';

function NameFormat(const RoomName : String) : String;
begin
	NameFormat := LowerCase(RoomName);
	NameFormat := StringReplace(NameFormat, ' ', '-', [rfReplaceAll])
end;

var
	Ini        : TIniFile;
	Params     : THttpQuery;
	Query      : THttpQueryPair;
	SessionKey : String;
	RoomScript : String;
	RoomStyle  : String;
	SessionId  : String;
	PageTitle  : String;
	Password   : String;
	HostPass   : String;
	RoomDesc   : String;
	Favicon    : String;
	VideoId    : String;
	IrcConf    : String;
	Banner     : String;
	AuthUser   : Boolean = False;
	IsHost     : Boolean = False;
	Ref        : Text;

procedure DrawVideo;
begin
	WriteLn('<object id="movie_container">');
	WriteLn('<param id="movie_params" name="movie" ',
		'value="http://www.youtube.com/v/', VideoId,
		'?enablejsapi=1&amp;version=3&autoplay=1">',
		'</param>');
	WriteLn('<param name="allowFullScreen" value="true"></param>');
	WriteLn('<param name="allowscriptaccess" value="always"></param>');
	WriteLn('<embed src="http://www.youtube.com/v/',
		VideoId, '?enablejsapi=1&amp;version=3&autoplay=1"',
		'type="application/x-shockwave-flash" width="640"',
		'height="450" allowscriptaccess="always"',
		'allowfullscreen="true" id="movie_player"></embed>');
	WriteLn('</object>')
end;

procedure DrawPlaylist;
begin
	WriteLn('<b>Playlist</b>&nbsp;');
	WriteLn('<span id="playlistcount"></span>');
	WriteLn('<br>');
	WriteLn('<div id="playlistvideos"></div>')
end;

procedure DrawChat;
begin
	WriteLn('<iframe width="640" height="330" scrolling="no" ',
		'frameborder="0" ',
		'id="chat" src="http://kibj.nprog.ru:9090?',
		'prompt=1&channels=', NameFormat(PageTitle),
		'&uio=', IrcConf, '&nick=unnamed.."></iframe>')
end;

procedure DrawControls;
begin
	WriteLn('<center>');
	
	WriteLn('<b>Playlist Controls</b><br>');
	WriteLn('<span id="lock"></span>');
	WriteLn('<span id="tvmode"></span>');
	WriteLn('<br>');

	if IsHost then
	begin
		WriteLn('<table cellpadding="5">');		
		WriteLn('<tr>');

		WriteLn('<td class="btn">');
		WriteLn('&nbsp;<input type="button" ',
			'value="Clear" ',
			'onclick="clearPlaylist();">');
		WriteLn('</td>');

		WriteLn('<td class="btn">');
		WriteLn('&nbsp;<input type="button" ',
			'value="Lock" ',
			'onclick="lockPlaylist();">');
		WriteLn('</td>');

		WriteLn('<td class="btn">');
		WriteLn('&nbsp;<input type="button" ',
			'value="Unlock" ',
			'onclick="unlockPlaylist();">');
		WriteLn('</td>');

		WriteLn('</tr>');
		WriteLn('<tr>');

		WriteLn('<td class="btn">');
		WriteLn('&nbsp;<input type="button" ',
			'value="Shuffle" ',
			'onclick="shufflePlaylist();">');
		WriteLn('</td>');

		WriteLn('<td class="btn">');
		WriteLn('&nbsp;<input type="button" ',
			'value="Random" ',
			'onclick="playRandom();">');
		WriteLn('</td>');

		WriteLn('<td class="btn">');
		WriteLn('&nbsp;<input type="button" ',
			'value="Sort" ',
			'onclick="sortPlaylist();">');
		WriteLn('</td>');

		WriteLn('</tr>');
	
		WriteLn('<tr>');
		WriteLn('<td></td>');
		WriteLn('<td>');
		WriteLn('<input type="button" ',
			'value="TV Mode" ',
			'onclick="startTvMode();">');
		WriteLn('</td><td>');
		WriteLn('</td>');
		WriteLn('</tr>');

		WriteLn('</table>')
	end;
	
	WriteLn('<table>');
	WriteLn('<tr>');
	WriteLn('<td>Add:</td>');
	WriteLn('<td><input type="text" id="addvideo"></td>');
	WriteLn('<td><input type="button" onclick="btnAddVideo();" ',
		'value="Add"></td>');
	WriteLn('</table>');

	WriteLn('<div id="addwait">Adding video...</div>');

	WriteLn('<br>');

	if IsHost then
	begin
		WriteLn('<table>');
		WriteLn('<tr>');
		WriteLn('<td>List:</td>');
		WriteLn('<td><input type="text" id="listname"></td>');
		WriteLn('</tr><tr>');
		WriteLn('<td></td>');
		WriteLn('<td><select id="playlists" ',
			'onchange="selectPlaylist();">');
		WriteLn('<option value="">--none--</option>');
		WriteLn('</select></td>');
		WriteLn('</tr>');
		WriteLn('</table>');

		WriteLn('<table>');
		WriteLn('<tr>');
		WriteLn('<td><input type="button" ',
			'onclick="btnLoadList();" value="Load"></td>');
		WriteLn('<td><input type="button" ',
			'onclick="btnSaveList();" value="Save"></td>');
		WriteLn('<td><input type="button" ',
			'onclick="btnRemoveList();" value="Delete"></td>');
		WriteLn('<td><input type="button" ',
			'onclick="btnImportList();" value="Import"></td>');
		WriteLn('</tr>');
		WriteLn('</table>');

		WriteLn('<div id="importwait">',
			'Importing playlist...</div>');
		WriteLn('<br>')
	end;

	WriteLn('</center>')
end;	

begin
	WriteLn('Content-Type: text/html');
	WriteLn;

	Ini := TIniFile.Create('settings.ini');

	Password   := Ini.ReadString('room', 'password',      '');
	HostPass   := Ini.ReadString('room', 'host-password', '');
	PageTitle  := Ini.ReadString('room', 'name',    DefTitle);
	VideoId    := Ini.ReadString('room', 'video',   DefVideo);
	Banner     := Ini.ReadString('room', 'banner',        '');
	IrcConf    := Ini.ReadString('room', 'irc-settings',  '');
	RoomDesc   := Ini.ReadString('room', 'description',   '');
	Favicon    := Ini.ReadString('room', 'favicon',       '');
	RoomScript := Ini.ReadString('room', 'script',        '');
	RoomStyle  := Ini.ReadString('room', 'style',         '');

	Ini.Free;

	if VideoId = '' then
		VideoId := DefVideo;
	
	if Favicon = '' then
		Favicon := '../res/favicon.gif';

	Params := GetQuery(GetRequest);

	WriteLn('<html>');
	WriteLn('<head>');
	WriteLn('<meta charset="utf-8">');
	WriteLn('<title>', PageTitle, '</title>');

	WriteLn('<link rel="stylesheet" type="text/css" ',
		'href="../general.css">');
	WriteLn('<link rel="stylesheet" type="text/css" ',
		'href="../room.css">');

	WriteLn('<link rel="icon" href="', Favicon, '">');

	WriteLn('</head>');
	WriteLn('<body>');
	WriteLn('<center>');
	
	for Query in Params do case Query[0] of
		'host': if
			not (Query[1] = '') and
			(Query[1] = HostPass)
		then
			IsHost := True
		else
		begin
			WriteLn('<h1>Error!</h1>');
			WriteLn('Password Invalid');
			Redirect('./', 3);
			Halt
		end;
		'password': if
			not (Query[1] = '') and
			(Query[1] = Password)
		then
			AuthUser := True
	end;
	
	if not (Password = '') and not (AuthUser or IsHost) then
	begin
		WriteLn('<h1>Error!</h1>');
		WriteLn('Private room requires a password');
		Redirect('private.cgi', 1);
		Halt
	end;
	
	WriteLn('<p>');
	WriteLn('<a href="../">&lt;- Home</a>');
	WriteLn('</p>');

	if not (Banner = '') then
	begin
		WriteLn('<p>');
		WriteLn('<img width="1000" height="300" src="',
			Banner, '">');
		WriteLn('</p>')
	end;
	
	if RoomDesc <> '' then
		WriteLn('<div id="description">', RoomDesc, '</div>');

	WriteLn('<table cellpadding="5" style="width:95%">');
	WriteLn('<tr>');

	WriteLn('<td width="50%" id="T1">');
	DrawVideo;
	WriteLn('</td>');

	WriteLn('<td width="50%" id="T2">');
	DrawPlaylist;
	WriteLn('</td>');

	WriteLn('</tr>');
	WriteLn('<tr>');

	WriteLn('<td id="T3">');
	DrawChat;
	WriteLn('</td>');

	WriteLn('<td id="T4">');
	DrawControls;
	WriteLn('</td>');

	WriteLn('</tr>');
	WriteLn('</table>');

	WriteLn('<h3>Settings</h3>');

	WriteLn('<p>');

	WriteLn('Video Size:&nbsp;');
	WriteLn('<select id="videosize" ',
		'onchange="changeVideoSize();">');
	WriteLn('<option value="small">small</option>');
	WriteLn('<option value="normal" selected="selected">normal',
		'</option>');
	WriteLn('<option value="large">large</option>');
	WriteLn('</select>&nbsp;');

	WriteLn('Layout:&nbsp;');
	WriteLn('<select id="layouts" ',
		'onchange="changeLayout();">');
	WriteLn('<option id="default" value="default">Default</option>');
	WriteLn('<option id="top-chat" value="top-chat">Top Chat</option>');
	WriteLn('<option id="right-chat" value="right-chat">Right Chat',
		'</option>');
	WriteLn('<option id="no-chat" value="no-chat">No Chat</option>');
	WriteLn('<option id="mirror" value="mirror">Mirrored</option>');
	WriteLn('</select>&nbsp;');

	Write('<span style="display:');
	if IsHost then
		Write('none')
	else
		Write('inline-block');
	WriteLn(';">');

	WriteLn('Synchronize:&nbsp;');
	Write('<input type="checkbox" id="syncselect" ',
		'onchange="changeSync();" checked>&nbsp;');
	WriteLn('</span>');
	
	if not IsHost then
	begin
		WriteLn('Time Buffer&nbsp;');
		WriteLn('<select id="bufferselect" ',
			'onchange="changeBuffer();">');
		WriteLn('<option value="1.0" selected="selected">1 sec',
			'</option>');
		WriteLn('<option value="2.0">2 secs</option>');
		WriteLn('<option value="5.0">5 secs</option>');
		WriteLn('<option value="10.0">10 secs</option>');
		WriteLn('<option value="20.0">20 secs</option>');
		WriteLn('</select>&nbsp;')
	end;

	WriteLn('Sync Interval&nbsp;');
	WriteLn('<select id="delayselect" onchange="changeDelay();">');
	WriteLn('<option value="500">0.5 secs</option>');
	WriteLn('<option value="1000" selected="selected">1.0 secs',
		'</option>');
	WriteLn('<option value="1500">1.5 secs</option>');
	WriteLn('<option value="2000">2.0 secs</option>');
	WriteLn('</select>&nbsp;');

	if IsHost then
		WriteLn('<input type="button" value="Drop Host"',
			'onclick="window.location='''';">&nbsp;')
	else
		WriteLn('<input type="button" value="Become Host"',
			'onclick="takeHost();">&nbsp;');

	WriteLn('</p>');

	WriteLn('<p>');
	if IsHost then
	begin
		WriteLn('<form name="form" action="settings.cgi" ',
			'method="POST" target="_blank">');
		WriteLn('<input type="hidden" name="host" value="',
			HostPass,'">');
		WriteLn('</form>');
		Write('<a href="javascript:" onclick="form.submit();">');
	end
	else
		Write('<a href="settings-auth.cgi" target="_blank">');
	WriteLn('[Room Settings]</a>');
	WriteLn('</p>');
	WriteLn('</center>');

	WriteLn('<hr noshade>');
	WriteLn('<div id="sandbox"></div>');	
	
	WriteLn('<script>');
	if IsHost then
	begin
		Randomize;
		Str(Random($FFFF), SessionId);
		Str(Random($FFFF), SessionKey);
		SessionId := XorEncode(SessionKey, SessionId);

		Assign(Ref, 'session.id');
		ReWrite(Ref);
		WriteLn(Ref, XorEncode(HostPass, SessionId));
		Close(Ref);
		
		WriteLn('var SESSIONID = "', SessionId, '";');
	end;
	WriteLn('var VIDEOID = "', VideoId, '";');
	WriteLn('</script>');

	WriteLn('<script type="text/javascript" src="../room.js">',
		'</script>');

	Write('<script type="text/javascript" src="');
	if IsHost then
		Write('../sync-host.js')
	else
		Write('../sync-client.js');
	WriteLn('"></script>');

	WriteLn('<script type="text/javascript" src="../init.js">',
		'</script>');

	{ Custom scripts and styles }

	if not (RoomScript = '') then
		WriteLn('<script type="text/javascript" src="',
			RoomScript, '"></script>');
	
	if not (RoomStyle = '') then
		WriteLn('<link rel="stylesheet" type="text/css" href="',
			RoomStyle, '">');

	WriteLn('</body>');
	WriteLn('</html>')
end.
