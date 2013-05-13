uses dos, strarrutils, inifiles, htmlutils;
const
	DEFTITLE     = 'Sync Vid';
	DEFVIDEO     = 'YTu-ctARF2w';

var
	ini         : tinifile;
	query       : thttpquerypair;
	params      : thttpquery;
	tags        : string;
	banner      : string;
	ircconf     : string;
	videoid     : string;
	password    : string;
	hostpass    : string;
	pagetitle   : string;
	description : string;
	roomurl     : string;
	isauth      : boolean = FALSE;
begin
	writeln('Content-Type: text/html');
	writeln;

	ini := tinifile.create('settings.ini');

	with ini do
	begin
		roomurl    := readstring('room', 'url',           '');
		password   := readstring('room', 'password',      '');
		hostpass   := readstring('room', 'host-password', '');
		pagetitle  := readstring('room', 'name',    DEFTITLE);
		videoid    := readstring('room', 'video',   DEFVIDEO);
		banner     := readstring('room', 'banner',        '');
		ircconf    := readstring('room', 'irc-settings',  '');
		tags       := readstring('room', 'tags',          '');
		description := readstring('room', 'description',   '');

		free
	end;

	params := getquery(getrequest);

	writeln('<html>');
	writeln('<head>');
	writeln('<link rel="stylesheet" type="text/css" ',
		'href="../general.css">');
	writeln('</head>');
	writeln('<body>');
	writeln('<center>');

	for query in params do
		case query[0] of
			'host': if
				not (query[1] = '') and
				(query[1] = hostpass)
			then
				isauth := TRUE
			else begin
				writeln('<h1>Error!</h1>');
				writeln('Password Invalid');
				redirect('settings-auth.cgi', 1);
				halt(0)
			end
		end;
	
	if not isauth then
	begin
		writeln('<h1>Error!</h1>');
		writeln('Settings page requires a password');
		redirect('settings-auth.cgi', 1);
		halt
	end;

	writeln('<h1>Settings</h1>');
	writeln('<form name="form" action="configure.cgi" method="POST">');

	writeln('<input type="text" name="host" value="' + hostpass + '" ',
		'style="display:none;">');

	writeln('<table cellpadding="5">');

	write('<tr>');
	write('<td>');
	write('Room Title:');
	write('</td>');
	write('<td>');
	write('<input type="text" name="title" ',
		'value="' + pagetitle + '">');
	write('</td>');
	writeln('</tr>');

	write('<tr>');
	write('<td>');
	write('Banner:');
	write('</td>');
	write('<td>');
	write('<input type="text" name="banner" ',
		'value="', banner, '">');
	write('</td>');
	writeln('</tr>');

	write('<tr>');
	write('<td>');
	write('IRC Settings:');
	write('</td>');
	write('<td>');
	write('<input type="text" name="ircconf" ',
		'value="', ircconf, '">');
	write('</td>');
	writeln('</tr>');

	write('<tr>');
	write('<td>');
	write('Room Password:');
	write('</td>');
	write('<td>');
	write('<input type="text" name="newpass" ',
		'value="', password, '">');
	write('</td>');
	writeln('</tr>');

	write('<tr>');
	write('<td>');
	write('Host Password:');
	write('</td>');
	write('<td>');
	write('<input type="text" name="newhost" ',
		'value="', hostpass, '">');
	write('</td>');
	writeln('</tr>');

	write('<tr>');
	write('<td>');
	write('Room tags:');
	write('</td>');
	write('<td>');
	write('<input type="text" name="tags" ',
		'value="', tags, '">');
	write('</td>');
	writeln('</tr>');

	write('<tr>');
	write('<td>');
	write('Description:');
	write('</td>');
	write('<td>');
	write('<input type="text" name="description" ',
		'value="', description, '">');
	write('</td>');
	writeln('</tr>');

	writeln('</table>');
	writeln('<input type="submit" value="Save Changes">');

	writeln('</form>');

	writeln('<br><br>');
	writeln('<form action="../deleteroom.cgi" method="POST" ',
		'target="_blank">');
	writeln('<input type="hidden" name="room" ',
		'value="', roomurl, '">');
	writeln('<input type="hidden" name="host" ',
		'value="', hostpass, '">');
	writeln('<input type="hidden" name="confirm" ',
		'value="false">');
	writeln('<input type="submit" value="Delete Room">');
	writeln('</form>');


	writeln('</center>');
	writeln('</body>');
	writeln('</html>')
end.
