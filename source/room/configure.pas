uses
	dos,
	strarrutils,
	inifiles,
	htmlutils;

var
	Ini      : TIniFile;
	Params   : THttpQuery;
	HostPass : String;
begin
	WriteLn('Content-Type: text/html');
	WriteLn;
	
	Ini := TIniFile.Create('settings.ini');

	Ini.CacheUpdates := True;
	HostPass := Ini.ReadString('room', 'host-password', '');
	
	Params := GetQuery(GetRequest);

	WriteLn('<html>');
	WriteLn('<head>');
	WriteLn('<title></title>');
	WriteLn('<link rel="stylesheet" type="text/css" ',
		'href="../general.css">');	
	WriteLn('</head>');
	WriteLn('<body>');
	WriteLn('<center>');

	if (Params[0,0] = 'host') and (Params[0,1] = hostpass) then
	begin
		Ini.WriteString('room', 'name',
			Html2Text(Params[1,1]));
		Ini.WriteString('room', 'banner',
			Html2Text(Params[2,1]));
		Ini.WriteString('room', 'favicon',
			Html2Text(Params[3,1]));
		Ini.WriteString('room', 'irc-settings',
			Html2Text(Params[4,1]));
		Ini.WriteString('room', 'password',
			Html2Text(Params[5,1]));
		Ini.WriteString('room', 'host-password',
			Html2Text(Params[6,1]));
		Ini.WriteString('room', 'tags',
			Html2Text(Params[7,1]));
		Ini.WriteString('room', 'description',
			Html2Text(Params[8,1]));
		Ini.WriteString('room', 'script',
			Html2Text(Params[9,1]));
		Ini.WriteString('room', 'style',
			Html2Text(Params[10,1]));
		
		Ini.UpdateFile;
		Ini.Free;

		WriteLn('<h3>Settings saved...</h3>')
	end
	else
		WriteLn('<h2>Bad settings format!</h2>');

	WriteLn('<script>setTimeout(function(){',
		'window.close();},1000);</script>');

	WriteLn('</center>');
	WriteLn('</body>');
	WriteLn('</html>')
end.
