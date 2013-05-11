uses strarrutils, inifiles, classes, crt, strutils, sysutils, httpsend;
const
	BUFFERFILE = 'syncvid.syn';
	YTAPIURL   = 'http://gdata.youtube.com/feeds/api/videos/';	

function getduration(id : string) : double;
var
	data    : tstringlist;
	content : ansistring;
	i       : ansistring;
	a       : integer;
	b       : integer;
	e       : integer; 
begin
	data := tstringlist.create;
	httpgettext(YTAPIURL + id, data);
	content := '';
	for i in data do
		content := content + i;
	a := pos('<yt:duration seconds=''', content) + 22;
	content := copy(content, a, length(content));
	b := pos('''/>', content);
	val(copy(content, 1, b - 1), getduration, e);
	if not (e = 0) then
		getduration := 0;
end;

var
	ref        : text;
	videos     : tstringlist;
	ini        : tinifile;
	sessionkey : string;
	sessionid  : string;
	hostpass   : string;
	videoid    : string;
	getstr     : string;
	tvmode     : string;
	duration   : double;
	time       : double;
	index      : integer;
	e          : integer;
	i          : integer;
begin
	ini := tinifile.create('settings.ini');
	
	with ini do
	begin
		hostpass := readstring('room', 'host-password', '');
		free
	end;

	ini    := tinifile.create('playlist.ini');
	videos := tstringlist.create;

	with ini do
	begin
		readsection('videos', videos);
		free
	end;

	randomize;
	str(random($FFFF), sessionid);
	str(random($FFFF), sessionkey);
	sessionid := xorencode(sessionkey, sessionid);

	assign(ref, 'session.id');
	rewrite(ref);
	writeln(ref, xorencode(hostpass, sessionid));
	close(ref);

	assign(ref, BUFFERFILE);
	reset(ref);
	readln(ref, videoid);
	readln(ref, getstr);
	readln(ref, getstr);
	val(getstr, time, e);
	readln(ref, tvmode);
	close(ref);

	rewrite(ref);
	writeln(ref, videoid);
	writeln(ref, '0');
	writeln(ref, format('%.2F', [time]));
	writeln(ref, '1');
	close(ref);

	duration := getduration(videoid);
	index := 0;
	for i := 0 to videos.count - 1 do
		if videos.strings[i] = videoid then
			index := i;
	repeat
		reset(ref);
		readln(ref, videoid);
		readln(ref, getstr);
		readln(ref, getstr);
		val(getstr, time, e);
		if not (e = 0) then
			halt;
		readln(ref, tvmode);
		close(ref);

		delay(1000);
		time := time + 1.00;

		if time > duration then
		begin
			index := (index + 1) mod videos.count;
			videoid := videos.strings[index];
			time := 0;
			duration := getduration(videoid)
		end;

		reset(ref);
		readln(ref, getstr);
		readln(ref, getstr);
		readln(ref, getstr);
		readln(ref, tvmode);
		close(ref);
		
		rewrite(ref);
		writeln(ref, videoid);
		writeln(ref, '0');
		writeln(ref, format('%.2F', [time]));
		writeln(ref, tvmode);
		close(ref)
	until tvmode = '0';
end.
