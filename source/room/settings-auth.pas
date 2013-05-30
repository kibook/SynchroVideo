uses
	inifiles;
var
	Ini       : TIniFile;
	PageTitle : String;
begin
	WriteLn('Content-Type: text/html');
	WriteLn;

	Ini := TIniFile.Create('settings.ini');
	PageTitle := Ini.ReadString('room', 'name', 'Sync Vid');
	Ini.Free;

	WriteLn('<html>');
	WriteLn('<head>');
	WriteLn('<title>', PageTitle, ' Settings Auth</title>');
	WriteLn('<link rel="stylesheet" type="text/css" ',
		'href="../general.css">');	
	WriteLn('</head>');
	WriteLn('<body onload="document.form.host.focus()">');
	WriteLn('<center>');
	WriteLn('<h1>Authorization</h1>');
	WriteLn('<form name="form" action="settings.cgi" method="POST">');
	WriteLn('Password:<br>');
	WriteLn('<input type="password" name="host"><br>');
	WriteLn('<input type="submit">');
	WriteLn('</form>');
	WriteLn('</center>');
	WriteLn('</body>');
	WriteLn('</html>')
end.
