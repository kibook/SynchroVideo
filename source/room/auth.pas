uses inifiles;

var
	pagetitle : string;
	ini       : tinifile;
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
	writeln('<title>', pagetitle, ' Host Auth</title>');
	writeln('<link rel="stylesheet" type="text/css" ',
		'href="../general.css">');
	writeln('</head>');
	writeln('<body onload="document.form.host.focus()">');
	writeln('<center>');
	writeln('<a href="./">&lt;- Back</a>');
	writeln('<h1>Authorization</h1>');
	writeln('<form name="form" action="./" method="POST">');
	writeln('Password:<br>');
	writeln('<input type="password" name="host"><br>');
	writeln('<input type="submit" value="Become Host">');
	writeln('</form>');
	writeln('</center>');
	writeln('</body>');
	writeln('</html>')
end.
