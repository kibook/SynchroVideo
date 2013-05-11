uses dos, strarrutils, inifiles, strutils, process;
var
	ini       : tinifile;
	ref       : text;
	sessionid : string;
	hostpass  : string;
	request   : string;
	server    : tprocess;
begin
	writeln('Content-Type: text/javascript');
	writeln;

	request := getenv('QUERY_STRING');

	ini := tinifile.create('settings.ini');
	with ini do
	begin
		hostpass := readstring('room', 'host-password', '');
		free
	end;

	assign(ref, 'session.id');
	reset(ref);
	readln(ref, sessionid);
	close(ref);

	sessionid := xordecode(hostpass, sessionid);

	if request = sessionid then
	begin
		server := tprocess.create(NIL);
		{$ifdef unix}
			server.executable := './tvserver';
		{$endif}
		{$ifdef win32}
			server.executable := 'tvserver.exe';
		{$endif}
		server.options := [pousepipes];
		server.execute
	end
end.
