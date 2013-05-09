uses strarrutils, dos, inifiles, classes, strutils;

const
	BUFFERFILE = 'syncvid.syn';

var
	query     : array of string;
	sessionid : string;
	synctime  : string;
	hostpass  : string;	
	videoid   : string;
	paused    : string;
	tvmode    : string;
	ref       : text;
	ini       : tinifile;
	playlist  : tstringlist;
begin
	writeln('Content-Type: text/javascript');
	writeln;

	query    := split(getenv('QUERY_STRING'), '&');
	synctime := '';

	ini      := tinifile.create('settings.ini');
	hostpass := ini.readstring('room', 'host-password', '');
	ini.free;

	assign(ref, 'session.id');
	reset(ref);
	readln(ref, sessionid);
	close(ref);

	sessionid := xordecode(hostpass, sessionid);

	assign(ref, BUFFERFILE);
	if length(query) > 1 then
		if query[0] = sessionid then
		begin
			videoid  := query[1];
			paused   := query[2];
			synctime := query[3];
			tvmode   := '0';

			rewrite(ref);
			writeln(ref, videoid);
			writeln(ref, paused);
			writeln(ref, synctime);
			writeln(ref, tvmode)
		end
		else begin
			writeln('window.location="./";');
			writeln('alert("You are no longer host!");');
			halt(0)
		end
	else begin
		reset(ref);
		readln(ref, videoid);
		readln(ref, paused);
		readln(ref, synctime);
		readln(ref, tvmode)
	end;
	close(ref);

	writeln('SYNCPLAY="', paused,   '";');
	writeln('SYNCTIME="', synctime, '";');
	writeln('SYNCVURL="', videoid,  '";');
	writeln('SYNCSVTV="', tvmode,   '";');

	ini      := tinifile.create('playlist.ini');
	playlist := tstringlist.create;
	ini.readsection('videos', playlist);

	write('Playlist.list=[');
	for videoid in playlist do
	begin
		write('{title:"');
		write(ini.readstring('videos', videoid, '???'));
		write('",id:"',videoid, '"},')
	end;
	writeln('];')
end.
