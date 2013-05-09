uses dos, htmlutils, classes, inifiles;
const
	REDIRECT = '<script>window.location="../"</script>';
var
	query       : array of array of string;
	pair        : array of string;
	searchterms : string = '';
	each        : string;
	password    : string;
	roomname    : string;
	roomtags    : string;
	roomdesc    : string;
	rooms       : tstringlist;
	ini         : tinifile;
	match       : boolean;
	priv        : boolean;
begin
	writeln('Content-Type: text/html');
	writeln;

	query := getquery(getrequest);

	for pair in query do
		case pair[0] of
			'q': searchterms := html2text(pair[1])
		end;

	if searchterms = '' then
		writeln(REDIRECT);
	
	ini := tinifile.create('../rooms.ini');
	rooms := tstringlist.create;
	with ini do
	begin
		readsection('rooms', rooms);
		free
	end;

	writeln('<html>');
	writeln('<head>');
	writeln('<title>Search Results</title>');
	writeln('<link rel="stylesheet" type="text/css" ',
		'href="../general.css">');
	writeln('</head>');
	writeln('<body>');
	writeln('<center>');
	writeln('<a href="../">&lt;- Home</a>');
	writeln('<h1><u>Room Search</u></h1>');
	writeln('<p>Results for "', searchterms, '"</p>');
	writeln('<form action="./" method="GET">');
	writeln('<input type="text" size"30" name="q">');
	writeln('<input type="submit" value="Search">');
	writeln('</form>');
	writeln('<hr width="50%" noshade>');

	for each in rooms do
	begin
		ini := tinifile.create('../' + each + '/settings.ini');
		password := ini.readstring('room', 'password', '');
		priv := length(password) > 1;
		with ini do
		begin
			roomname := readstring('room', 'name', '');
			roomtags := readstring('room', 'tags', '');
			roomdesc := readstring('room', 'description', '');
			free
		end;
		match := (pos(upcase(searchterms), upcase(each)) > 0) or
			(pos(upcase(searchterms), upcase(roomname)) > 0) or
			(pos(upcase(searchterms), upcase(roomtags)) > 0);
		if match then
			if not priv then
			begin
				write('<h3>');
				write('<a href="../', each, '">');
				write(roomname);
				writeln('</a></h3>');
				write('<p>');
				write(roomdesc);
				writeln('</p>')
			end
	end;

	writeln('</center>');
	writeln('</body>');
	writeln('</html>')
end.
