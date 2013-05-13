uses dos, htmlutils, inifiles, process;

var
	room     : string;
	hostpass : string;
	pass     : string;
	query    : thttpquery;
	pair     : thttpquerypair;
	ini      : tinifile;
	isauth   : boolean;
	confirm  : boolean;
	proc     : tprocess;
begin
	writeln('Content-Type: text/html');
	writeln;

	writeln('<html>');
	writeln('<head>');
	writeln('<link rel="stylesheet" type="text/css" ',
		'href="general.css">');
	writeln('<title>Room Deletion</title>');
	writeln('</head>');
	writeln('<body>');
	writeln('<center>');

	query := getquery(getrequest);

	for pair in query do
		case pair[0] of
			'confirm': confirm := upcase(pair[1]) = 'TRUE';
			'room': room := pair[1];
			'host': hostpass := pair[1]
		end;

	ini := tinifile.create(room + '/settings.ini');
	pass := ini.readstring('room', 'host-password', '');
	isauth := (hostpass = pass) and not (room = '');
	ini.free;

	if isauth then
		if not confirm then
		begin
			writeln('<h1>Are you sure?</h1>');
			writeln('<form action="deleteroom.cgi" ',
				'method="POST">');
			writeln('<input type="hidden" name="room" ',
				'value="', room, '">');
			writeln('<input type="hidden" name="host" ',
				'value="', hostpass, '">');
			writeln('<input type="hidden" name="confirm" ',
				'value="true">');
			writeln('<input type="submit" ',
				'value="CONFIRM DELETE">');
			writeln('</form>');
			writeln('<h3 style="color:#a10;">');
			writeln('WARNING: Clicking this will permanently ',
				'delete this room and any saved ',
				'playlists!');
			writeln('</h3>');
			writeln('Close this window now to cancel')
		end
		else begin
			proc := tprocess.create(NIL);
			{$ifdef unix}
				proc.executable := './eraseroom';
			{$endif}
			{$ifdef win32}
				proc.executable := 'eraseroom.bat';
			{$endif}
			proc.parameters.add(room);
			proc.options := [pousepipes];
			proc.execute;
			proc.waitonexit;
			proc.free;
			writeln('<h2>Room deleted!</h2>');
			redirect('./', 2)
		end
	else begin
		writeln('<h1>Error!</h1>');
		writeln('<p>Unauthorized access</p>');
		redirect('./', 2)
	end;
	
	writeln('</center>');
	writeln('</body>');
	writeln('</html>')
end.			
