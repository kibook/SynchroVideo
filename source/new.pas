{$mode objfpc}

uses
	fpwritepng,
	fpimage,
	fpcanvas,
	fpimgcanv,
	ftfont,
	base64,
	inifiles,
	classes;

const
	CaptchaDir = 'res/captcha/';
	Chars      = '0123456789abcdefghijklmnopqrstuvwxyz';

type
	TCanvas = class(TFPImageCanvas)
	protected
		procedure DoCopyRect(x, y : Integer;
			Canvas : TFPCustomCanvas;
			const SourceRect : TRect); override;
		procedure DoDraw(x, y : Integer;
			const Img : TFPCustomImage); override;
	end;

procedure TCanvas.DoCopyRect(x, y : Integer; Canvas : TFPCustomCanvas;
	const SourceRect : TRect);
begin
end;

procedure TCanvas.DoDraw(x, y : Integer; const Img : TFPCustomImage);
begin
end;

var
	Image      : TFPCustomImage;
	Canvas     : TCanvas;
	Writer     : TFPCustomImageWriter;
	AFont      : TFreeTypeFont;
	Content    : AnsiString;
	CaptchaTxt : String;
	Key        : String;
	Id         : String;
	Ini        : TIniFile;
	AChar      : Char;
	Ref        : Text;
	Allow      : Boolean;
	i          : Integer;
	x          : Integer;
	y          : Integer;
	x1         : Integer;
	y1         : Integer;
	x2         : Integer;
	y2         : Integer;
begin
	WriteLn('Content-Type: text/html');
	WriteLn;

	Randomize;

	Image := TFPMemoryImage.Create(132, 46);
	
	Canvas := TCanvas.Create(Image);

	FTFont.InitEngine;
	FontMgr.SearchPath := '/Library/Fonts/';
	AFont := TFreeTypeFont.Create;

	Ini   := TIniFile.Create('rooms.ini');
	Key   := Ini.ReadString('security', 'key', '');
	Allow := Ini.ReadString('security', 'allownew', 'false') = 'true';
	Ini.Free;

	WriteLn('<html>');
	WriteLn('<head>');
	WriteLn('<title>Create New Room</title>');
	WriteLn('<link rel="stylesheet" type="text/css" ',
		'href="general.css">');
	WriteLn('</head>');
	WriteLn('<body>');
	WriteLn('<center>');
	WriteLn('<a href="./">&lt;- Home</a>');

	if not Allow then
	begin
		WriteLn('<h1>Error!</h1>');
		WriteLn('Room creation is disabled');
		Redirect('./', 2);
		halt
	end;

	Randomize;
	CaptchaTxt := '';
	for i := 1 to 5 do
		CaptchaTxt := CaptchaTxt+Chars[Random(Length(Chars))+1];
	x  := Random(Image.Width  div 3);
	y  := Random(Image.Height div 2) + Image.Height div 2;

	Canvas.Brush.FPColor := colWhite;
	Canvas.Brush.Style   := bsSolid;
	Canvas.Rectangle(0, 0, Image.Width - 1, Image.Height - 1);

	Canvas.Font := AFont;

	case Random(2) of
		0 : Canvas.Font.Name := 'TI Uni Regular';
		1 : Canvas.Font.Name := 'Arial'
	end;

	Canvas.TextOut(x, y, CaptchaTxt);

	for i := 1 to 12 do
	begin
		x1 := Random(Image.Width);
		y1 := Random(Image.Height);
		x2 := Random(Image.Width);
		y2 := Random(Image.Height);
		Canvas.Line(x1, y1, x2, y2)
	end;

	Str(Random($FF), Id);
	Writer := TFPWriterPng.Create;
	Image.SaveToFile(CaptchaDir + Id + '.png', Writer);

	Content := '';

	Assign(Ref, CaptchaDir + Id + '.png');
	Reset(Ref);

	repeat
		read(Ref, AChar);
		Content := Concat(Content, AChar)
	until EOF(Ref);

	Close(Ref);
	Erase(Ref);

	Content := EncodeStringBase64(Content);

	WriteLn('<h1>New Room</h1>');

	WriteLn('<form action="createroom.cgi" method="POST">');
	WriteLn('<input type="hidden" name="check" value="', Id, '">');
	WriteLn('<p><b>CAPTCHA:</b></p>');
	WriteLn('<p><img src="data:image/png;base64,', Content, '"></p>');
	WriteLn('<p class="smalltext">',
		'Type in the letters and numbers above:</p>');
	WriteLn('<p><input type="text" name="solve"></p>');
	WriteLn('<table cellpadding="2">');
	WriteLn('<tr>');
	WriteLn('<td>Room Name:</td>');
	WriteLn('<td><input type="text" name="room"></td>');
	WriteLn('</tr><tr>');
	WriteLn('<td>Host Pass:</td>');
	WriteLn('<td><input type="password" name="pass"></td>');
	WriteLn('</tr><tr>');
	WriteLn('<td><input type="button" value="Reset" ',
		'onclick="location.reload(true)"></td>');
	WriteLn('<td><input type="submit"></td>');
	WriteLn('</tr></table>');
	WriteLn('</form>');

	WriteLn('<p><a href="info/#create">',
		'How do I create a room?</a></p>');

	WriteLn('</center>');
	WriteLn('</body>');
	WriteLn('</html>');

	Assign(Ref, CaptchaDir + Id + '.cap');
	Rewrite(Ref);
	WriteLn(Ref, CaptchaTxt);
	Close(Ref);

	Writer.Free;
	Canvas.Free;
	Image.Free
end.
