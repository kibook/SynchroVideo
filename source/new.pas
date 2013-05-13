{$mode objfpc}
uses fpwritepng, fpimage, fpcanvas, fpimgcanv, ftfont, base64,
	inifiles, classes;

const
	CAPTCHADIR = 'res/captcha/';
	CHARS = '0123456789abcdefghijklmnopqrstuvwxyz';

type
	tcanvas = class(tfpimagecanvas)
	protected
		procedure docopyrect(x, y : integer;
			canvas : tfpcustomcanvas;
			const sourcerect : trect); override;
		procedure dodraw(x, y : integer;
			const img : tfpcustomimage); override;
	end;

procedure tcanvas.docopyrect(x, y : integer; canvas : tfpcustomcanvas;
	const sourcerect : trect);
begin
end;

procedure tcanvas.dodraw(x, y : integer; const img : tfpcustomimage);
begin
end;

var
	image      : tfpcustomimage;
	canvas     : tcanvas;
	writer     : tfpcustomimagewriter;
	afont      : tfreetypefont;
	content    : ansistring;
	captchatxt : string;
	key        : string;
	id         : string;
	ini        : tinifile;
	achar      : char;
	ref        : text;
	allow      : boolean;
	i          : integer;
	x          : integer;
	y          : integer;
	x1         : integer;
	y1         : integer;
	x2         : integer;
	y2         : integer;
begin
	writeln('Content-Type: text/html');
	writeln;

	randomize;

	image := tfpmemoryimage.create(132, 46);
	
	canvas := tcanvas.create(image);

	ftfont.initengine;
	fontmgr.searchpath := '/Library/Fonts/';
	afont := tfreetypefont.create;

	ini   := tinifile.create('rooms.ini');
	key   := ini.readstring('security', 'key', '');
	allow := ini.readstring('security', 'allownew', 'false') = 'true';
	ini.free;

	writeln('<html>');
	writeln('<head>');
	writeln('<title>Create New Room</title>');
	writeln('<link rel="stylesheet" type="text/css" ',
		'href="general.css">');
	writeln('</head>');
	writeln('<body>');
	writeln('<center>');
	writeln('<a href="./">&lt;- Home</a>');

	if not allow then
	begin
		writeln('<h1>Error!</h1>');
		writeln('Room creation is disabled');
		redirect('./', 2);
		halt
	end;

	randomize;
	captchatxt := '';
	for i := 1 to 5 do
		captchatxt := captchatxt+CHARS[random(length(CHARS))+1];
	x  := random(image.width div 3);
	y  := random(image.height div 2) + image.height div 2;

	with canvas do
	begin
		brush.fpcolor := colwhite;
		brush.style := bssolid;
		rectangle(0, 0, image.width - 1, image.height - 1);

		font := afont;

		case random(2) of
			0 : font.name := 'TI Uni Regular';
			1 : font.name := 'Arial'
		end;

		font.size := 20;

		textout(x, y, captchatxt);

		for i := 1 to 12 do
		begin
			x1 := random(image.width);
			y1 := random(image.height);
			x2 := random(image.width);
			y2 := random(image.height);
			line(x1,y1,x2,y2)
		end
	end;

	str(random($FF), id);
	writer := tfpwriterpng.create;
	image.savetofile(CAPTCHADIR+id+'.png', writer);

	content := '';
	assign(ref, CAPTCHADIR+id+'.png');
	reset(ref);
	repeat
		read(ref, achar);
		content := concat(content, achar)
	until eof(ref);
	close(ref);
	erase(ref);

	content := encodestringbase64(content);

	writeln('<h1>New Room</h1>');

	writeln('<form action="createroom.cgi" method="POST">');
	writeln('<input type="hidden" name="check" value="', id, '">');
	writeln('<p><b>CAPTCHA:</b></p>');
	writeln('<p><img src="data:image/png;base64,', content, '"></p>');
	writeln('<p class="smalltext">',
		'Type in the letters and numbers above:</p>');
	writeln('<p><input type="text" name="solve"></p>');
	writeln('<table cellpadding="2">');
	writeln('<tr>');
	writeln('<td>Room Name:</td>');
	writeln('<td><input type="text" name="room"></td>');
	writeln('</tr><tr>');
	writeln('<td>Host Pass:</td>');
	writeln('<td><input type="password" name="pass"></td>');
	writeln('</tr><tr>');
	writeln('<td><input type="button" value="Reset" ',
		'onclick="location.reload(true)"></td>');
	writeln('<td><input type="submit"></td>');
	writeln('</tr></table>');
	writeln('</form>');

	writeln('<p><a href="info/#create">',
		'How do I create a room?</a></p>');

	writeln('</center>');
	writeln('</body>');
	writeln('</html>');

	assign(ref, CAPTCHADIR+id+'.cap');
	rewrite(ref);
	writeln(ref, captchatxt);
	close(ref);

	writer.free;
	canvas.free;
	image.free
end.
