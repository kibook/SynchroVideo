uses inifiles, process;
var
	ini   : tinifile;
	proc  : tprocess;
	rooms : array of string;
	room  : string;
	ref   : text;
	len   : integer;
begin
	ini := tinifile.create('rooms.ini');
	ini.cacheupdates := TRUE;

	ini.deletekey('rooms', paramstr(1));
	ini.updatefile;
	ini.free;

	proc := tprocess.create(NIL);
	{$ifdef unix}
		proc.executable := 'rm';
		proc.parameters.add('-r');
	{$endif}
	{$ifdef win32}
		proc.executable := 'del';
	{$endif}
	proc.parameters.add(paramstr(1));
	proc.options := [pousepipes];
	proc.execute;
	proc.waitonexit;
	proc.free;

	setlength(rooms, 0);
	assign(ref, 'rooms.list');
	reset(ref);
	repeat
		len := length(rooms);
		setlength(rooms, len + 1);
		readln(ref, rooms[len])
	until eof(ref);
	close(ref);
	rewrite(ref);
	for room in rooms do
		if room <> paramstr(1) then
			writeln(ref, room);
	close(ref)
end.
