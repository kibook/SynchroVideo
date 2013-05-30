uses
	dos,
	htmlutils,
	classes,
	inifiles,
	sysutils;

function CheckVideo(Room : String) : String;
var
	Ini    : TIniFile;
	Id     : String;
	Ref    : Text;
begin
	Assign(Ref, '../' + Room + '/syncvid.syn');
	Reset(Ref);
	ReadLn(Ref, Id);
	Close(Ref);

	Ini := TIniFile.Create('../' + Room + '/playlist.ini');
	CheckVideo := Ini.ReadString('videos', Id, '???');
	Ini.Free
end;

var
	Query       : THttpQuery;
	Pair        : THttpQueryPair;
	SearchTerms : String = '';
	Each        : String;
	Password    : String;
	RoomName    : String;
	RoomTags    : String;
	RoomDesc    : String;
	Playing     : String;
	Rooms       : TStringList;
	Ini         : TIniFile;
	Match       : Boolean;
	Priv        : Boolean;

procedure DisplayRoom;
begin
	if not Priv then
	begin
		Write('<h3>');
		Write('<a href="../', Each, '">');
		Write(RoomName);
		WriteLn('</a></h3>');
		WriteLn('<p>', RoomDesc, '</p>');
		WriteLn('<p class="smalltext">',
			'<em>Now Playing: <b>', Playing, '</b></em>',
			'</p>');
	end
end;

begin
	WriteLn('Content-Type: text/html');
	WriteLn;

	Query := GetQuery(GetRequest);

	for Pair in Query do case Pair[0] of
		'q': SearchTerms := Html2Text(Pair[1])
	end;

	if Trim(SearchTerms) = '' then
	begin
		Redirect('../', 0);
		Halt
	end;
	
	Ini   := TIniFile.Create('../rooms.ini');
	Rooms := TStringList.Create;
	with Ini do
	begin
		ReadSection('rooms', Rooms);
		Free
	end;

	WriteLn('<html>');
	WriteLn('<head>');
	WriteLn('<title>Search Results</title>');
	WriteLn('<link rel="stylesheet" type="text/css" ',
		'href="../general.css">');
	WriteLn('</head>');
	WriteLn('<body>');
	WriteLn('<center>');
	WriteLn('<a href="../">&lt;- Home</a>');
	WriteLn('<h1><u>Room Search</u></h1>');
	WriteLn('<p>Results for "', SearchTerms, '"</p>');
	WriteLn('<form action="./" method="GET">');
	WriteLn('<input type="text" size"30" name="q">');
	WriteLn('<input type="submit" value="Search">');
	WriteLn('</form>');
	WriteLn('<hr width="50%" noshade>');

	for Each in Rooms do
	begin
		Ini := TIniFile.Create('../' + Each + '/settings.ini');

		Password := Ini.ReadString('room', 'password', '');

		Priv     := Length(Password) > 1;

		RoomName := Ini.ReadString('room', 'name', '');
		RoomTags := Ini.ReadString('room', 'tags', '');
		RoomDesc := Ini.ReadString('room', 'description', '');

		Ini.Free;

		Playing := CheckVideo(Each);

		Match := (Pos(UpCase(SearchTerms), UpCase(Each))     > 0) or
			 (Pos(UpCase(SearchTerms), UpCase(RoomName)) > 0) or
			 (Pos(UpCase(SearchTerms), UpCase(RoomTags)) > 0) or
			 (Pos(UpCase(SearchTerms), UpCase(Playing))  > 0);
		if Match then
			DisplayRoom
	end;

	WriteLn('</center>');
	WriteLn('</body>');
	WriteLn('</html>')
end.
