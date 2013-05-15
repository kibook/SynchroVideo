uses dos, strarrutils, inifiles, htmlutils;

const
	REDIRECT = '<script>setTimeout(function(){window.close();},'+
		'1000);</script>';

var
	ini      : tinifile;
	params   : thttpquery;
	hostpass : string;
begin
	writeln('Content-Type: text/html');
	writeln;
	
	ini := tinifile.create('settings.ini');

	with ini do
	begin
		cacheupdates := TRUE;
		hostpass := readstring('room', 'host-password', '')
	end;
	
	params := getquery(getrequest);

	writeln('<html>');
	writeln('<head>');
	writeln('<title></title>');
	writeln('<link rel="stylesheet" type="text/css" ',
		'href="../general.css">');	
	writeln('</head>');
	writeln('<body>');
	writeln('<center>');

	if (params[0,0] = 'host') and (params[0,1] = hostpass) then
	begin
		with ini do
		begin
			writestring('room', 'name',
				html2text(params[1,1]));
			writestring('room', 'banner',
				html2text(params[2,1]));
			writestring('room', 'favicon',
				html2text(params[3,1]));
			writestring('room', 'irc-settings',
				html2text(params[4,1]));
			writestring('room', 'password',
				html2text(params[5,1]));
			writestring('room', 'host-password',
				html2text(params[6,1]));
			writestring('room', 'tags',
				html2text(params[7,1]));
			writestring('room', 'description',
				html2text(params[8,1]));
			writestring('room', 'script',
				html2text(params[9,1]));
			writestring('room', 'style',
				html2text(params[10,1]));

			updatefile;
			free
		end;

		writeln('<h3>Settings saved...</h3>')
	end
	else
		writeln('<h2>Bad settings format!</h2>');

	writeln(REDIRECT);

	writeln('</center>');
	writeln('</body>');
	writeln('</html>')
end.
