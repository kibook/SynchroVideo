uses inifiles;
var
	ini       : tinifile;
	pagetitle : string;
begin
	writeln('Content-Type: text/html');
	writeln;

	ini := tinifile.create('settings.ini');

	with ini do
	begin
		pagetitle := readstring('room', 'name', 'Sync Vid');
		free
	end;

	writeln('<html>');
	writeln('<head>');
	writeln('<title>', pagetitle, ' Settings Auth</title>');
	writeln('<link rel="stylesheet" type="text/css" ',
		'href="../general.css">');	
	writeln('</head>');
	writeln('<body onload="document.form.host.focus()">');
	writeln('<center>');
	writeln('<h1>Authorization</h1>');
	writeln('<form name="form" action="settings.cgi" method="POST">');
	writeln('Password:<br>');
	writeln('<input type="password" name="host"><br>');
	writeln('<input type="submit">');
	writeln('</form>');
	writeln('</center>');
	writeln('</body>');
	writeln('</html>')
end.
