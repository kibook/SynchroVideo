uses
	inifiles;

var
	PageTitle : String;
	Ini       : TIniFile;
begin
	WriteLn('Content-Type: text/html');
	WriteLn;

	Ini := TIniFile.Create('settings.ini');

	PageTitle := Ini.ReadString('room', 'name', 'Sync Vid');
	Ini.Free;

	WriteLn('<html>');
	WriteLn('<head>');
	WriteLn('<title>', PageTitle, ' Host Auth</title>');
	WriteLn('<link rel="stylesheet" type="text/css" ',
		'href="../general.css">');
	WriteLn('</head>');
	WriteLn('<body onload="document.form.host.focus()">');
	WriteLn('<center>');
	WriteLn('<a href="./">&lt;- Back</a>');
	WriteLn('<h1>Authorization</h1>');
	WriteLn('<form name="form" action="./" method="POST">');
	WriteLn('Password:<br>');
	WriteLn('<input type="password" name="host"><br>');
	WriteLn('<input type="submit" value="Become Host">');
	WriteLn('</form>');
	WriteLn('</center>');
	WriteLn('</body>');
	WriteLn('</html>')
end.
