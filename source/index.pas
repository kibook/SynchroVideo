uses classes, inifiles;

const
	PAGETITLE = 'SynchroVideo';
var
	rooms : tstringlist;
	ini   : tinifile;
	pub   : integer = 0;
	priv  : integer = 0;
	room  : string;
begin
	writeln('Content-Type: text/html');
	writeln;

	writeln('<html>');
	writeln('<head>');
	writeln('<title>', PAGETITLE, '</title>');
	writeln('<link rel="stylesheet" type="text/css" ',
		'href="general.css">');
	writeln('<link rel="stylesheet" type="text/css" ',
		'href="index.css">');
	writeln('<link rel="icon" href="res/favicon.gif">');
	writeln('</head>');
	writeln('<body>');

	writeln('<div class="header">');
	writeln('<img src="res/logo.png" alt="SynchroVideo">');
	writeln('</div>');
	writeln('<hr width="50%" noshade>');

	writeln('<center>');
	writeln('<table cellpadding="10" cellspacing="10">');
	writeln('<tr>');
	writeln('<td class="link"><a href="info">Information</a></td>');
	writeln('<td class="link"><a href="new">Create Room</a></td>');
	writeln('<td class="link"><a href="source.htm">',
		'View Source</a></td>');
	writeln('</tr>');
	writeln('</table>');
	writeln('</center>');

	writeln('<div class="section">');

	ini   := tinifile.create('rooms.ini');
	rooms := tstringlist.create;
	ini.readsection('rooms', rooms);
	ini.free;

	for room in rooms do
	begin
		ini := tinifile.create(room + '/settings.ini');
		if ini.readstring('room', 'password', '') = '' then
			inc(pub)
		else
			inc(priv)
	end;

	writeln('<h2><u>Welcome to SynchroVideo!</u></h2>');

	writeln('<div class="subsection">');
	writeln('<p>Now serving ', rooms.count, ' rooms!</p>');
	writeln('<p>(', pub, ' public and ', priv, ' private)</p>');
	writeln('</div>');

	writeln('</div>');

	writeln('<div class="section">');
	writeln('<h3>Search for rooms:');
	writeln('<form action="search" method="GET">');
	writeln('<p><input type="text" size="30" name="q"></p>');
	writeln('<p><input type="submit" value="Search"></p>');
	writeln('</form>');
	writeln('<div class="subsection">');
	writeln('<a href="list">Full Room List</a>');
	writeln('</div>');
	writeln('</div>');

	writeln('</body>');
	writeln('</html>')
end.
