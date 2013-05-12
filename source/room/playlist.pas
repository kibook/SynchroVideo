{$mode objfpc}
uses dos, strarrutils, inifiles, classes, strutils, math, htmlutils,
	sysutils, fphttpclient;

const
	YTAPIURL   = 'http://gdata.youtube.com/feeds/api/videos/';
	YTPLAPIURL = 'http://gdata.youtube.com/feeds/api/playlists/';
	VALIDCHARS = ['a'..'z', '0'..'9'];

var
	ini: tinifile;

function getplaylists : tstringlist;
var
	info   : tsearchrec;
	fatype : word;
begin
	getplaylists := tstringlist.create;
	if findfirst('playlists/*',faanyfile and fadirectory,info)=0 then
	begin
		repeat
			fatype := info.attr and fadirectory;
			if not (fatype = fadirectory) then
				getplaylists.add(copy(info.name, 1,
					length(info.name) - 4))
		until not (findnext(info) = 0)
	end;
	findclose(info)
end;

function gettitle(id : string) : string;
var
	content : ansistring;
	a       : word;
	b       : word;
begin
	with tfphttpclient.create(NIL) do
	begin
		content := get(YTAPIURL + id + '?fields=title');
		free
	end;

	a := pos('<title type=''text''>', content) + 19;
	b := pos('</title>', content);
	gettitle := text2html(copy(content, a, b - a));
end;

function getlistsize(id : string) : word;
const
	tag    = 'openSearch:totalResults';
	params = '?v=2&fields=' + tag;
var
	content : ansistring;
	a       : word;
	b       : word;
begin
	getlistsize := 50;

	with tfphttpclient.create(NIL) do
	begin
		content := get(YTPLAPIURL + id + params);
		free
	end;

	a := pos('<'  + tag + '>', content) + 25;
	b := pos('</' + tag + '>', content);
	getlistsize := strtoint(copy(content, a, b - a))
end;

procedure importlist(id : string);
const
	params = '?v=2&max-results=50&start-index=';
var
	content  : ansistring;
	title    : string;
	videoid  : string;
	index    : string;
	requests : word;
	a        : word;
	b        : word;
	i        : word;

procedure parselist;
begin
	str((50 * i) + 1, index);
	
	with tfphttpclient.create(NIL) do
	begin
		content := get(YTPLAPIURL + id + params + index);
		free
	end;

	a := pos('<media:title type=''plain''>', content) + 26;
	b := pos('</media:title>', content);
	content := copy(content, b + 13, length(content));

	repeat
		title := '';
		a := pos('<media:title type=''plain''>',
			content) + 26;
		b := pos('</media:title>', content);
		title := text2html(copy(content, a, b - a));
		
		content := copy(content, b + 13, length(content));

		videoid := '';
		a := pos('<yt:videoid>',  content) + 12;
		b := pos('</yt:videoid>', content);
		videoid := copy(content, a, b - a);

		content := copy(content, b + 13, length(content));

		if not (title = '') and not (videoid = '') then
			ini.writestring('videos', videoid, title)
	until pos('<media:title type=''plain''>', content) = 0
end;
	
begin
	requests := ceil(getlistsize(id) / 50.0);
	
	for i := 0 to requests - 1 do
	begin
		parselist;
	end
end;

function comparetitles(list : tstringlist;
	index1, index2 : integer) : integer;
var
	t1, t2 : string;
begin
	t1 := ini.readstring('videos', list[index1], '???');
	t2 := ini.readstring('videos', list[index2], '???');
	comparetitles := ansicomparetext(t1, t2)
end;

procedure writestatus(locked : boolean);
begin
	write('Playlist.locked=');
	if locked then
		write('true')
	else
		write('false');
	writeln(';')
end;

procedure writeplaylists;
var
	video : string;
begin
	write('Playlists=[');
	for video in getplaylists do
		write('"', video, '",');
	writeln('];')
end;

procedure addvideo(id : string);
begin
	ini.writestring('videos', id, gettitle(id))
end;

procedure deletevideo(id : string);
begin
	ini.deletekey('videos', id)
end;

procedure togglelock(lock : boolean);
var
	status : string;
begin
	if lock then
		status := 'true'
	else
		status := 'false';
	ini.writestring('status', 'locked', status);
	writeln('Playlist.locked=', status, ';')
end;

procedure clearlist;
var
	videos : tstringlist;
	video  : string;
begin
	videos := tstringlist.create;
	ini.readsection('videos', videos);
	for video in videos do
		ini.deletekey('videos', video);
	videos.free
end;

procedure shufflelist;
var
	videos : tstringlist;
	titles : tstringlist;
	video  : string;
	a      : word;
	b      : word;
	i      : word;
begin
	videos := tstringlist.create;
	ini.readsection('videos', videos);

	for video in videos do
		for i := 1 to 10 do
		begin
			a := random(videos.count);
			b := random(videos.count);
			videos.exchange(a, b)
		end;

	titles := tstringlist.create;

	for video in videos do
	begin
		titles.add(ini.readstring('videos', video, '???'));
		ini.deletekey('videos', video)
	end;

	for i := 0 to videos.count - 1 do
		ini.writestring('videos', videos[i], titles[i]);
	
	videos.free;
	titles.free
end;

procedure sortlist;
var
	videos : tstringlist;
	titles : tstringlist;
	video  : string;
	i      : word;
begin
	videos := tstringlist.create;
	titles := tstringlist.create;

	ini.readsection('videos', videos);

	videos.customsort(@comparetitles);

	for video in videos do
	begin
		titles.add(ini.readstring('videos', video, '???'));
		ini.deletekey('videos', video)
	end;

	for i := 0 to videos.count - 1 do
		ini.writestring('videos', videos[i], titles[i]);
	
	videos.free;
	titles.free
end;

procedure savelist(fname : string);
var
	listname : string;
	video    : string;	
	ch       : char;
	videos   : tstringlist;
	newini   : tinifile;
begin
	listname := '';

	for ch in lowercase(fname) do
		if ch in VALIDCHARS then
			listname := concat(listname, ch);

	newini := tinifile.create('playlists/' + listname + '.ini');
	newini.cacheupdates := TRUE;
	newini.writestring('status', 'locked', 'false');

	videos := tstringlist.create;
	ini.readsection('videos', videos);

	for video in videos do
		newini.writestring('videos', video,
			ini.readstring('videos', video, ''));

	newini.updatefile;

	newini.free;
	videos.free
end;

procedure loadlist(fname : string);
var
	listname : string;
	video    : string;
	videos   : tstringlist;
	newini   : tinifile;
begin
	listname := 'playlists/' + fname + '.ini';

	if not fileexists(listname) then
		halt;

	newini := tinifile.create(listname);

	videos := tstringlist.create;
	newini.readsection('videos', videos);

	for video in videos do
		ini.writestring('videos', video,
			newini.readstring('videos', video, '???'));

	videos.free;
	newini.free
end;

procedure movevideo(id1, id2 : string);
var
	video  : string;
	videos : tstringlist;
	titles : tstringlist;
	a      : word;
	b      : word;
	e      : word;
	i      : word;
begin
	videos := tstringlist.create;
	titles := tstringlist.create;

	ini.readsection('videos', videos);

	for video in videos do
	begin
		titles.add(ini.readstring('videos', video, '???'));
		ini.deletekey('videos', video)
	end;

	val(id1, a, e);
	if not (e = 0) then
		halt;

	val(id2, b, e);
	if not (e = 0) then
		halt;

	video := videos[a];
	videos.delete(a);
	videos.insert(b, video);

	for i := 0 to videos.count - 1 do
		ini.writestring('videos', videos[i], titles[i])
end;

procedure removelist(fname : string);
var
	listname : string;
	ref      : text;
begin
	listname := 'playlists/' + fname + '.ini';
	if not fileexists(listname) then
		halt;
	assign(ref, listname);
	erase(ref)
end;


var
	query     : tstringarray;
	sessionid : string;	
	hostpass  : string;
	locked    : boolean;
	secure    : boolean;
	ref       : text;
begin
	writeln('Content-Type: text/javascript');
	writeln;

	query    := split(getenv('QUERY_STRING'), '&');

	secure   := FALSE;
	ini      := tinifile.create('settings.ini');
	hostpass := ini.readstring('room', 'host-password', '');

	assign(ref, 'session.id');
	reset(ref);
	readln(ref, sessionid);
	close(ref);

	sessionid := xordecode(hostpass, sessionid);
	secure := (sessionid = query[0]);


	ini    := tinifile.create('playlist.ini');
	ini.cacheupdates := TRUE;
	locked := (ini.readstring('status', 'locked', 'true') = 'true');

	case length(query) of
		1: case query[0] of
			'status': writestatus(locked);
			'list'  : writeplaylists;
		end;

		2: begin
			case query[0] of
				'add': if not locked then
					addvideo(query[1])
			end;
			case query[1] of
				'lock': if secure then
					togglelock(TRUE);
				'unlock': if secure then
					togglelock(FALSE);
				'clear': if secure then
					clearlist;
				'shuffle': if secure then
					shufflelist;
				'sort': if secure then
					sortlist
			end
		end;

		3: case query[1] of
			'add': if secure then
				addvideo(query[2]);
			'delete': if secure then
				deletevideo(query[2]);
			'save': if secure then
				savelist(query[2]);
			'load': if secure then
				loadlist(query[2]);
			'remove': if secure then
				removelist(query[2]);
			'import': if secure then
				importlist(query[2])
		end;
		4: case query[1] of
			'move': if secure then
				movevideo(query[2], query[3])
		end
	end;

	ini.updatefile
end.
