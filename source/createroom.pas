uses dos, strarrutils, sysutils, inifiles, process, htmlutils;
const
	REDIRECT = '<script>setTimeout(function(){window.location="./"},'+
		'1000);</script>';
	CAPTCHADIR = 'res/captcha/';
	RESERVEDNAMES : array [1..5] of string =
		('new', 'source', 'res', 'search', 'info');
var
	query      : thttpquerypair;
	rooms      : array of string;
	params     : thttpquery;
	roomdir    : string;
	solve      : string;
	check      : string;
	room       : string;
	pass       : string;
	id         : string;
	ref        : text;
	ini        : tinifile;
	c          : char;
	allow      : boolean;
	paramcheck : boolean;
	roomexists : boolean;
	verified   : boolean;
	i          : integer;
	e          : integer;
	maxrooms   : integer;
	proc       : tprocess;
begin
	writeln('Content-Type: text/html');
	writeln;
	
	params := getquery(getrequest);

	writeln('<html>');
	writeln('<head>');
	writeln('<link rel="stylesheet" type="text/css" ',
		'href="general.css">');
	writeln('</head>');
	writeln('<body>');
	writeln('<center>');

	ini := tinifile.create('rooms.ini');
	allow := ini.readstring('security', 'allownew', 'false') = 'true';
	val(ini.readstring('security', 'maxrooms', ''), maxrooms, e);
	if not (e = 0) then
		maxrooms := 0;

	if not allow then
	begin
		writeln('<h1>Error!</h1>');
		writeln('Room creation disabled');
		writeln(REDIRECT);
		halt
	end;
	
	verified := FALSE;

	paramcheck := length(params) = 4;
	for query in params do
		paramcheck := length(query) = 2;

	if paramcheck then
	begin
		id    := params[0,1];
		solve := params[1,1];
		room  := params[2,1];
		pass  := params[3,1];

		if fileexists(CAPTCHADIR+id+'.cap') then
		begin
			assign(ref, CAPTCHADIR+id+'.cap');
			reset(ref);
			readln(ref, check);
			close(ref);
			erase(ref);

			if check = solve then
				verified := TRUE;
		end
	end;

	if not verified then
	begin
		writeln('<h1>Error!</h1>');
		writeln('Captcha not solved');
		writeln(REDIRECT);
		halt
	end;

	if trim(pass) = '' then
	begin
		writeln('<h1>Error!</h1>');
		writeln('Password cannot be blank!');
		writeln(REDIRECT);
		halt
	end;

	room := stringreplace(room, '+', ' ', [rfreplaceall]);

	roomdir := '';
	for c in lowercase(room) do
		if c in ['a'..'z'] then
			roomdir := roomdir + c;

	setlength(rooms, 0);
	
	assign(ref, 'rooms.list');
	reset(ref);
	repeat
		setlength(rooms, length(rooms) + 1);
		readln(ref, rooms[high(rooms)])
	until eof(ref);
	close(ref);

	if length(rooms) >= maxrooms then
	begin
		writeln('<h1>Error!</h1>');
		writeln('Maximum number of rooms have been created');
		writeln(REDIRECT);
		halt
	end;

	roomexists := FALSE;

	for i := low(RESERVEDNAMES) to high(RESERVEDNAMES) do
		if RESERVEDNAMES[i] = roomdir then
			roomexists := TRUE;

	if not roomexists then
		for i := low(rooms) to high(rooms) do
			if rooms[i] = roomdir then
				roomexists := TRUE;

	if roomexists then
	begin
		writeln('<h1>Error!</h1>');
		writeln('Room already exists!');
		writeln(REDIRECT);
		halt
	end;

	if (length(roomdir) < 5) or (length(roomdir) > 12) then
	begin
		writeln('<h1>Error!</h1>');
		writeln('Room name must 5-12 alphanumeric characters!');
		writeln(REDIRECT);
		halt
	end;

	for c in room do
		if not (c in ['A'..'Z', 'a'..'z', '0'..'9', ' ']) then
		begin
			writeln('<h1>Error!</h1>');
			writeln('Invalid room name!');
			writeln(REDIRECT);
			halt
		end;

	proc := tprocess.create(NIL);
	{$ifdef unix}
		proc.executable := 'sh';
		proc.parameters.add('createroom.sh');
	{$endif}
	{$ifdef win32}
		proc.executable := 'createroom.bat';
	{$endif}
	proc.parameters.add(roomdir);
	proc.options := [pousepipes];
	proc.execute;
	proc.waitonexit;
	proc.free;


	setlength(rooms, length(rooms) + 1);
	rooms[high(rooms)] := roomdir;

	rewrite(ref);
	for i := low(rooms) to high(rooms) do
		writeln(ref, rooms[i]);
	close(ref);

	ini := tinifile.create('rooms.ini');
	with ini do
	begin
		cacheupdates := TRUE;
		writestring('rooms', roomdir, room);
		updatefile;
		free
	end;

	ini := tinifile.create(roomdir+'/settings.ini');
	with ini do
	begin
		cacheupdates := TRUE;
		writestring('room', 'name', room);
		writestring('room', 'url', roomdir);
		writestring('room', 'video', '');
		writestring('room', 'banner', '');
		writestring('room', 'irc-settings', '');
		writestring('room', 'password', '');
		writestring('room', 'host-password', pass);
		writestring('room', 'tags', '');
		writestring('room', 'description', '');
		updatefile;
		free
	end;

	writeln('<h1>Room created!</h1>');
	writeln('<script>setTimeout(function(){window.location="',
		roomdir, '"}, 2000);</script>');
end.
