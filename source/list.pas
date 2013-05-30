uses
	classes,
	inifiles;	

var
	Rooms : TStringList;
	Title : String;	
	Room  : String;
	Desc  : String;
	Ini   : TIniFile;
	i     : Integer;
	Priv  : Boolean;
begin
	WriteLn('Content-Type: text/html');
	WriteLn;

	WriteLn('<html>');
	WriteLn('<head>');
	WriteLn('<link rel="stylesheet" type="text/css" ',
		'href="../general.css">');
	WriteLn('<title>Room Listing</title>');
	WriteLn('</head>');
	WriteLn('<body>');
	WriteLn('<center>');
	WriteLn('<a href="../">&lt;- Home</a>');
	WriteLn('<h1><u>Room Listing</u></h1>');

	Ini   := TIniFile.Create('../rooms.ini');
	Rooms := TStringList.Create;
	Ini.ReadSection('rooms', Rooms);
	Ini.Free;

	Rooms.Sort;

	WriteLn('<table cellpadding="30">');
	i := 0;
	for Room in Rooms do
	begin
		Ini := TIniFile.Create('../'+Room+'/settings.ini');
		Priv := not (Ini.ReadString('room', 'password', '') = '');

		if not Priv then
		begin
			if i mod 3 = 0 then
				WriteLn('<tr>');
			WriteLn('<td>');
			Title := Ini.ReadString('room', 'name', '');
			Desc  := Ini.ReadString('room', 'description', '');
			WriteLn('<div title="', Desc, '">');
			WriteLn('<h3><a href="../', Room, '">', Title,
				'</a></h3>');
			WriteLn('</div>');
			WriteLn('</td>');
			if i mod 3 = 2 then
				WriteLn('</tr>');
			Ini.Free;
			Inc(i)
		end
	end;
	WriteLn('</table>');

	WriteLn('</center>');
	WriteLn('</body>');
	WriteLn('</html>')
end.
