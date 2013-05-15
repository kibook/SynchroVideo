uses dos,strarrutils, inifiles, sysutils, classes, strutils, htmlutils;

const
	DEFTITLE = 'Sync Vid';
	JSFILE   = 'room.js';
	DEFVIDEO = 'YTu-ctARF2w';

function nameformat(const roomname : string) : string;
begin
	nameformat := lowercase(roomname);
	nameformat := stringreplace(nameformat, ' ', '-', [rfreplaceall])
end;

var
	ini        : tinifile;
	params     : thttpquery;
	query      : thttpquerypair;
	sessionkey : string;
	roomscript : string;
	roomstyle  : string;
	sessionid  : string;
	pagetitle  : string;
	password   : string;
	hostpass   : string;
	roomdesc   : string;
	favicon    : string;
	videoid    : string;
	ircconf    : string;
	banner     : string;
	authuser   : boolean = FALSE;
	ishost     : boolean = FALSE;
	ref        : text;
begin
	writeln('Content-Type: text/html');
	writeln;

	ini := tinifile.create('settings.ini');

	with ini do
	begin
		password   := readstring('room', 'password',      '');
		hostpass   := readstring('room', 'host-password', '');
		pagetitle  := readstring('room', 'name',    DEFTITLE);
		videoid    := readstring('room', 'video',   DEFVIDEO);
		banner     := readstring('room', 'banner',        '');
		ircconf    := readstring('room', 'irc-settings',  '');
		roomdesc   := readstring('room', 'description',   '');
		favicon    := readstring('room', 'favicon',       '');
		roomscript := readstring('room', 'script',        '');
		roomstyle  := readstring('room', 'style',         '');

		free
	end;

	if videoid = '' then
		videoid := DEFVIDEO;
	
	if favicon = '' then
		favicon := '../res/favicon.gif';

	params := getquery(getrequest);

	writeln('<html>');
	writeln('<head>');
	writeln('<meta charset="utf-8">');
	writeln('<title>', pagetitle, '</title>');

	writeln('<link rel="stylesheet" type="text/css" ',
		'href="../general.css">');
	writeln('<link rel="stylesheet" type="text/css" ',
		'href="../room.css">');

	writeln('<link rel="icon" href="', favicon, '">');

	writeln('</head>');
	writeln('<body>');
	writeln('<center>');
	
	for query in params do case query[0] of
		'host': if
			not (query[1] = '') and
			(query[1] = hostpass)
		then
			ishost := TRUE
		else begin
			writeln('<h1>Error!</h1>');
			writeln('Password Invalid');
			redirect('./', 3);
			halt(0)
		end;
		'password': if
			not (query[1] = '') and
			(query[1] = password)
		then
			authuser := TRUE
	end;
	
	if not (password = '') and not (authuser or ishost) then
	begin
		writeln('<h1>Error!</h1>');
		writeln('Private room requires a password');
		redirect('private.cgi', 1);
		halt(0)
	end;
	
	writeln('<p>');
	writeln('<a href="../">&lt;- Home</a>');
	writeln('</p>');

	if not (banner = '') then
	begin
		writeln('<p>');
		writeln('<img width="1000" height="300" src="',
			banner, '">');
		writeln('</p>')
	end;
	
	if roomdesc <> '' then
		writeln('<div id="description">', roomdesc, '</div>');

	writeln('<table cellpadding="5" style="width:95%">');
	writeln('<tr>');
	writeln('<td width="50%">');

	writeln('<object id="movie_container">');
	writeln('<param name="movie" value="http://www.youtube.com/v/',
		videoid, '?enablejsapi=1&amp;version=3&autoplay=1">',
		'</param>');
	writeln('<param name="allowFullScreen" value="true"></param>');
	writeln('<param name="allowscriptaccess" value="always"></param>');
	writeln('<embed src="http://www.youtube.com/v/',
		videoid, '?enablejsapi=1&amp;version=3&autoplay=1"',
		'type="application/x-shockwave-flash" width="640"',
		'height="450" allowscriptaccess="always"',
		'allowfullscreen="true" id="movie_player"></embed>');
	writeln('</object>');

	writeln('</td>');
	writeln('<td width="50%">');
	
	writeln('<b>Playlist</b>&nbsp;');
	writeln('<span id="playlistcount"></span>');
	writeln('<br>');
	writeln('<div id="playlistvideos"></div>');

	writeln('</td>');
	writeln('</tr>');
	writeln('<tr>');
	writeln('<td>');

	writeln('<iframe width="640" height="330" scrolling="no" ',
		'frameborder="0" ',
		'id="chat" src="http://kibj.nprog.ru:9090?',
		'prompt=1&channels=', nameformat(pagetitle),
		'&uio=', ircconf, '&nick=unnamed.."></iframe>');

	writeln('</td>');
	writeln('<td>');

	writeln('<center>');
	
	writeln('<b>Playlist Controls</b><br>');
	writeln('<span id="lock"></span>');
	writeln('<span id="tvmode"></span>');
	writeln('<br>');

	if ishost then
	begin
		writeln('<table cellpadding="5">');		
		writeln('<tr>');

		writeln('<td class="btn">');
		writeln('&nbsp;<input type="button" ',
			'value="Clear" ',
			'onclick="clearPlaylist();">');
		writeln('</td>');

		writeln('<td class="btn">');
		writeln('&nbsp;<input type="button" ',
			'value="Lock" ',
			'onclick="lockPlaylist();">');
		writeln('</td>');

		writeln('<td class="btn">');
		writeln('&nbsp;<input type="button" ',
			'value="Unlock" ',
			'onclick="unlockPlaylist();">');
		writeln('</td>');

		writeln('</tr>');
		writeln('<tr>');

		writeln('<td class="btn">');
		writeln('&nbsp;<input type="button" ',
			'value="Shuffle" ',
			'onclick="shufflePlaylist();">');
		writeln('</td>');

		writeln('<td class="btn">');
		writeln('&nbsp;<input type="button" ',
			'value="Random" ',
			'onclick="playRandom();">');
		writeln('</td>');

		writeln('<td class="btn">');
		writeln('&nbsp;<input type="button" ',
			'value="Sort" ',
			'onclick="sortPlaylist();">');
		writeln('</td>');

		writeln('</tr>');
	
		writeln('<tr>');
		writeln('<td></td>');
		writeln('<td>');
		writeln('<input type="button" ',
			'value="TV Mode" ',
			'onclick="startTvMode();">');
		writeln('</td><td>');
		writeln('</td>');
		writeln('</tr>');

		writeln('</table>')
	end;
	
	writeln('<table>');
	writeln('<tr>');
	writeln('<td>Add:</td>');
	writeln('<td><input type="text" id="addvideo"></td>');
	writeln('<td><input type="button" onclick="btnAddVideo();" ',
		'value="Add"></td>');
	writeln('</table>');

	writeln('<div id="addwait">Adding video...</div>');

	writeln('<br>');

	if ishost then
	begin
		writeln('<table>');
		writeln('<tr>');
		writeln('<td>List:</td>');
		writeln('<td><input type="text" id="listname"></td>');
		writeln('</tr><tr>');
		writeln('<td></td>');
		writeln('<td><select id="playlists" ',
			'onchange="selectPlaylist();">');
		writeln('<option value="">--none--</option>');
		writeln('</select></td>');
		writeln('</tr>');
		writeln('</table>');

		writeln('<table>');
		writeln('<tr>');
		writeln('<td><input type="button" ',
			'onclick="btnLoadList();" value="Load"></td>');
		writeln('<td><input type="button" ',
			'onclick="btnSaveList();" value="Save"></td>');
		writeln('<td><input type="button" ',
			'onclick="btnRemoveList();" value="Delete"></td>');
		writeln('<td><input type="button" ',
			'onclick="btnImportList();" value="Import"></td>');
		writeln('</tr>');
		writeln('</table>');

		writeln('<div id="importwait">',
			'Importing playlist...</div>');
		writeln('<br>')
	end;

	writeln('</center>');	

	writeln('</td>');
	writeln('</tr>');
	writeln('</table>');

	writeln('<h3>Settings</h3>');

	writeln('<p>');

	writeln('Video Size:&nbsp;');
	writeln('<select id="videosize" ',
		'onchange="changeVideoSize();">');
	writeln('<option value="small">small</option>');
	writeln('<option value="normal" selected="selected">normal',
		'</option>');
	writeln('<option value="large">large</option>');
	writeln('</select>&nbsp;');

	write('<span style="display:');
	if ishost then
		write('none')
	else
		write('inline-block');
	writeln(';">');

	writeln('Synchronize:&nbsp;');
	write('<input type="checkbox" id="syncselect" ',
		'onchange="changeSync();" checked>&nbsp;');
	writeln('</span>');
	
	if not ishost then
	begin
		writeln('Time Buffer&nbsp;');
		writeln('<select id="bufferselect" ',
			'onchange="changeBuffer();">');
		writeln('<option value="1.0" selected="selected">1 sec',
			'</option>');
		writeln('<option value="2.0">2 secs</option>');
		writeln('<option value="5.0">5 secs</option>');
		writeln('<option value="10.0">10 secs</option>');
		writeln('<option value="20.0">20 secs</option>');
		writeln('</select>&nbsp;')
	end;

	writeln('Sync Interval&nbsp;');
	writeln('<select id="delayselect" onchange="changeDelay();">');
	writeln('<option value="500">0.5 secs</option>');
	writeln('<option value="1000" selected="selected">1.0 secs',
		'</option>');
	writeln('<option value="1500">1.5 secs</option>');
	writeln('<option value="2000">2.0 secs</option>');
	writeln('</select>&nbsp;');

	if ishost then
		writeln('<input type="button" value="Drop Host"',
			'onclick="window.location='''';">&nbsp;')
	else
		writeln('<input type="button" value="Become Host"',
			'onclick="takeHost();">&nbsp;');

	writeln('</p>');

	writeln('<p>');
	if ishost then
	begin
		writeln('<form name="form" action="settings.cgi" ',
			'method="POST" target="_blank">');
		writeln('<input type="hidden" name="host" value="',
			hostpass,'">');
		writeln('</form>');
		write('<a href="javascript:" onclick="form.submit();">');
	end
	else
		write('<a href="settings-auth.cgi" target="_blank">');
	writeln('[Room Settings]</a>');
	writeln('</p>');
	writeln('</center>');

	writeln('<hr noshade>');
	writeln('<div id="sandbox"></div>');	
	
	writeln('<script>');
	if ishost then
	begin
		randomize;
		str(random($FFFF), sessionid);
		str(random($FFFF), sessionkey);
		sessionid := xorencode(sessionkey, sessionid);

		assign(ref, 'session.id');
		rewrite(ref);
		writeln(ref, xorencode(hostpass, sessionid));
		close(ref);
		
		writeln('var SESSIONID = "', sessionid, '";');
	end;
	writeln('var VIDEOID = "', videoid, '";');
	writeln('</script>');

	writeln('<script type="text/javascript" src="../room.js">',
		'</script>');

	write('<script type="text/javascript" src="');
	if ishost then
		write('../sync-host.js')
	else
		write('../sync-client.js');
	writeln('"></script>');

	writeln('<script type="text/javascript" src="../init.js">',
		'</script>');

	{ Custom scripts and styles }

	if not (roomscript = '') then
		writeln('<script type="text/javascript" src="',
			roomscript, '"></script>');
	
	if not (roomstyle = '') then
		writeln('<link rel="stylesheet" type="text/css" href="',
			roomstyle, '">');

	writeln('</body>');
	writeln('</html>')
end.
