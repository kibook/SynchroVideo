uses classes, inifiles;
var
	rooms : tstringlist;
	title : string;	
	room  : string;
	desc  : string;
	ini   : tinifile;
	i     : integer;
	priv  : boolean;
begin
	writeln('Content-Type: text/html');
	writeln;

	writeln('<html>');
	writeln('<head>');
	writeln('<link rel="stylesheet" type="text/css" ',
		'href="../general.css">');
	writeln('<title>Room Listing</title>');
	writeln('</head>');
	writeln('<body>');
	writeln('<center>');
	writeln('<a href="../">&lt;- Home</a>');
	writeln('<h1><u>Room Listing</u></h1>');

	ini   := tinifile.create('../rooms.ini');
	rooms := tstringlist.create;
	ini.readsection('rooms', rooms);
	ini.free;

	rooms.sort;

	writeln('<table cellpadding="30">');
	i := 0;
	for room in rooms do
	begin
		ini := tinifile.create('../'+room+'/settings.ini');
		priv := not (ini.readstring('room', 'password', '') = '');

		if not priv then
		begin
			if i mod 3 = 0 then
				writeln('<tr>');
			writeln('<td>');
			title := ini.readstring('room', 'name', '');
			desc  := ini.readstring('room', 'description', '');
			writeln('<div title="', desc, '">');
			writeln('<h3><a href="../', room, '">', title,
				'</a></h3>');
			writeln('</div>');
			writeln('</td>');
			if i mod 3 = 2 then
				writeln('</tr>');
			ini.free;
			inc(i)
		end
	end;
	writeln('</table>');

	writeln('</center>');
	writeln('</body>');
	writeln('</html>')
end.
