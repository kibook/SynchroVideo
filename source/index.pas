uses
	classes,
	inifiles;

var
	Rooms : TStringList;
	Ini   : TIniFile;
	Pub   : Integer = 0;
	Priv  : Integer = 0;
	Room  : String;
begin
	WriteLn('Content-Type: text/html');
	WriteLn;

	WriteLn('<html>');
	WriteLn('<head>');
	WriteLn('<title>SynchroVideo</title>');
	WriteLn('<link rel="stylesheet" type="text/css" ',
		'href="general.css">');
	WriteLn('<link rel="stylesheet" type="text/css" ',
		'href="index.css">');
	WriteLn('<link rel="icon" href="res/favicon.gif">');
	WriteLn('</head>');
	WriteLn('<body>');

	WriteLn('<div class="header">');
	WriteLn('<img src="res/logo.png" alt="SynchroVideo">');
	WriteLn('</div>');
	WriteLn('<hr width="50%" noshade>');

	WriteLn('<center>');
	WriteLn('<table cellpadding="10" cellspacing="10">');
	WriteLn('<tr>');
	WriteLn('<td class="link"><a href="info">Information</a></td>');
	WriteLn('<td class="link"><a href="new">Create Room</a></td>');
	WriteLn('<td class="link"><a href="source.htm">',
		'View Source</a></td>');
	WriteLn('</tr>');
	WriteLn('</table>');
	WriteLn('</center>');

	WriteLn('<div class="section">');

	Ini   := TIniFile.Create('rooms.ini');
	Rooms := TStringList.Create;
	Ini.ReadSection('rooms', Rooms);
	Ini.Free;

	for Room in Rooms do
	begin
		Ini := TIniFile.Create(Room + '/settings.ini');
		if Ini.ReadString('room', 'password', '') = '' then
			Inc(Pub)
		else
			Inc(Priv)
	end;

	WriteLn('<h2><u>Welcome to SynchroVideo!</u></h2>');

	WriteLn('<div class="subsection">');
	WriteLn('<p>Now serving ', Rooms.Count, ' rooms!</p>');
	WriteLn('<p>(', Pub, ' public and ', Priv, ' private)</p>');
	WriteLn('</div>');

	WriteLn('</div>');

	WriteLn('<div class="section">');
	WriteLn('<h3>Search for rooms:');
	WriteLn('<form action="search" method="GET">');
	WriteLn('<p><input type="text" size="30" name="q"></p>');
	WriteLn('<p><input type="submit" value="Search"></p>');
	WriteLn('</form>');
	WriteLn('<div class="subsection">');
	WriteLn('<a href="list">Full Room List</a>');
	WriteLn('</div>');
	WriteLn('</div>');

	WriteLn('</body>');
	WriteLn('</html>')
end.
