uses
	dos,
	strarrutils,
	sysutils,
	inifiles,
	process,
	htmlutils;

const
	CaptchaDir = 'res/captcha/';
	ReservedNames : Array [1..5] of String =
		('new', 'source', 'res', 'search', 'info');
var
	Query      : THttpQueryPair;
	Rooms      : Array of String;
	Params     : THttpQuery;
	RoomDir    : String;
	Solve      : String;
	Check      : String;
	Room       : String;
	Pass       : String;
	Id         : String;
	Ref        : Text;
	Ini        : TIniFile;
	c          : Char;
	Allow      : Boolean;
	ParamCheck : Boolean;
	RoomExists : Boolean;
	Verified   : Boolean;
	i          : Integer;
	e          : Integer;
	MaxRooms   : Integer;
	Proc       : TProcess;
begin
	WriteLn('Content-Type: text/html');
	WriteLn;
	
	Params := GetQuery(GetRequest);

	WriteLn('<html>');
	WriteLn('<head>');
	WriteLn('<link rel="stylesheet" type="text/css" ',
		'href="general.css">');
	WriteLn('</head>');
	WriteLn('<body>');
	WriteLn('<center>');

	Ini   := TIniFile.Create('rooms.ini');
	Allow := Ini.ReadString('security', 'allownew', 'false') = 'true';

	Val(Ini.ReadString('security', 'maxrooms', ''), MaxRooms, e);
	if not (e = 0) then
		MaxRooms := 0;

	if not Allow then
	begin
		WriteLn('<h1>Error!</h1>');
		WriteLn('Room creation disabled');
		Redirect('./', 1);
		Halt
	end;
	
	Verified := False;

	ParamCheck := Length(Params) = 4;
	for Query in Params do
		ParamCheck := Length(Query) = 2;

	if ParamCheck then
	begin
		Id    := Params[0,1];
		Solve := Params[1,1];
		Room  := Params[2,1];
		Pass  := Params[3,1];

		if FileExists(CaptchaDir+Id+'.cap') then
		begin
			Assign(Ref, CaptchaDir+Id+'.cap');
			Reset(Ref);
			ReadLn(Ref, Check);
			Close(Ref);
			Erase(Ref);

			if Check = Solve then
				Verified := True;
		end
	end;

	if not Verified then
	begin
		WriteLn('<h1>Error!</h1>');
		WriteLn('Captcha not solved');
		Redirect('./', 1);
		Halt
	end;

	if Trim(Pass) = '' then
	begin
		WriteLn('<h1>Error!</h1>');
		WriteLn('Password cannot be blank!');
		Redirect('./', 1);
		Halt
	end;

	Room := StringReplace(Room, '+', ' ', [rfReplaceAll]);

	RoomDir := '';
	for c in LowerCase(Room) do
		if c in ['a'..'z'] then
			RoomDir := RoomDir + c;

	SetLength(Rooms, 0);
	
	Assign(Ref, 'rooms.list');
	Reset(Ref);

	repeat
		SetLength(Rooms, Length(Rooms) + 1);
		ReadLn(Ref, Rooms[High(Rooms)])
	until EOF(Ref);

	Close(Ref);

	if Length(Rooms) >= MaxRooms then
	begin
		WriteLn('<h1>Error!</h1>');
		WriteLn('Maximum number of rooms have been created');
		Redirect('./', 1);
		Halt
	end;

	RoomExists := False;

	for i := Low(ReservedNames) to High(ReservedNames) do
		if ReservedNames[i] = RoomDir then
			RoomExists := True;

	if not RoomExists then
		for i := Low(Rooms) to High(Rooms) do
			if Rooms[i] = RoomDir then
				RoomExists := True;

	if RoomExists then
	begin
		WriteLn('<h1>Error!</h1>');
		WriteLn('Room already exists!');
		Redirect('./', 1);
		Halt
	end;

	if (Length(RoomDir) < 5) or (Length(RoomDir) > 12) then
	begin
		WriteLn('<h1>Error!</h1>');
		WriteLn('Room name must 5-12 alphanumeric characters!');
		Redirect('./', 1);
		Halt
	end;

	for c in Room do
		if not (c in ['A'..'Z', 'a'..'z', '0'..'9', ' ']) then
		begin
			WriteLn('<h1>Error!</h1>');
			WriteLn('Invalid room name!');
			Redirect('./', 1);
			Halt
		end;

	Proc := TProcess.Create(Nil);
	{$ifdef unix}
		Proc.Executable := 'sh';
		Proc.Parameters.Add('createroom.sh');
	{$endif}
	{$ifdef win32}
		Proc.Executable := 'createroom.bat';
	{$endif}
	Proc.Parameters.Add(RoomDir);
	Proc.Options := [poUsePipes];
	Proc.Execute;
	Proc.WaitOnExit;
	Proc.Free;


	SetLength(Rooms, Length(Rooms) + 1);
	Rooms[High(Rooms)] := RoomDir;

	Rewrite(Ref);
	for i := Low(Rooms) to High(Rooms) do
		WriteLn(Ref, Rooms[i]);
	Close(Ref);

	Ini := TIniFile.Create('rooms.ini');
	with Ini do
	begin
		CacheUpdates := True;
		WriteString('rooms', RoomDir, Room);
		UpdateFile;
		Free
	end;

	Ini := TIniFile.Create(RoomDir+'/settings.ini');

	Ini.CacheUpdates := True;
	Ini.WriteString('room', 'name', Room);
	Ini.WriteString('room', 'url', RoomDir);
	Ini.WriteString('room', 'video', '');
	Ini.WriteString('room', 'banner', '');
	Ini.WriteString('room', 'irc-settings', '');
	Ini.WriteString('room', 'password', '');
	Ini.WriteString('room', 'host-password', pass);
	Ini.WriteString('room', 'tags', '');
	Ini.WriteString('room', 'description', '');
	Ini.UpdateFile;
	Ini.Free;

	WriteLn('<h1>Room created!</h1>');
	WriteLn('<script>setTimeout(function(){window.location="',
		RoomDir, '"}, 2000);</script>');
end.
