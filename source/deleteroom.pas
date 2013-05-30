uses
	dos,
	htmlutils,
	inifiles,
	process;

var
	Room     : String;
	HostPass : String;
	Pass     : String;
	Query    : THttpQuery;
	Pair     : tHttpQueryPair;
	Ini      : TIniFile;
	IsAuth   : Boolean;
	Confirm  : Boolean;
	Proc     : TProcess;
begin
	WriteLn('Content-Type: text/html');
	WriteLn;

	WriteLn('<html>');
	WriteLn('<head>');
	WriteLn('<link rel="stylesheet" type="text/css" ',
		'href="general.css">');
	WriteLn('<title>Room Deletion</title>');
	WriteLn('</head>');
	WriteLn('<body>');
	WriteLn('<center>');

	Query := GetQuery(GetRequest);

	for Pair in Query do
		case Pair[0] of
			'confirm' : Confirm  := UpCase(Pair[1]) = 'TRUE';
			'room'    : Room     := Pair[1];
			'host'    : HostPass := Pair[1]
		end;

	Ini := TIniFile.Create(Room + '/settings.ini');

	Pass := Ini.ReadString('room', 'host-password', '');

	IsAuth := (HostPass = Pass) and not (Room = '');

	Ini.Free;

	if IsAuth then
		if not Confirm then
		begin
			WriteLn('<h1>Are you sure?</h1>');
			WriteLn('<form action="deleteroom.cgi" ',
				'method="POST">');
			WriteLn('<input type="hidden" name="room" ',
				'value="', Room, '">');
			WriteLn('<input type="hidden" name="host" ',
				'value="', HostPass, '">');
			WriteLn('<input type="hidden" name="confirm" ',
				'value="true">');
			WriteLn('<input type="submit" ',
				'value="CONFIRM DELETE">');
			WriteLn('</form>');
			WriteLn('<h3 style="color:#a10;">');
			WriteLn('WARNING: Clicking this will permanently ',
				'delete this room and any saved ',
				'playlists!');
			WriteLn('</h3>');
			WriteLn('Close this window now to cancel')
		end else
		begin
			Proc := TProcess.Create(Nil);
			{$ifdef unix}
				Proc.Executable := './eraseroom';
			{$endif}
			{$ifdef win32}
				Proc.Executable := 'eraseroom.bat';
			{$endif}
			Proc.Parameters.add(room);
			Proc.Options := [pousepipes];
			Proc.Execute;
			Proc.WaitOnExit;
			Proc.Free;
			WriteLn('<h2>Room deleted!</h2>');
			Redirect('./', 2)
		end
	else
	begin
		WriteLn('<h1>Error!</h1>');
		WriteLn('<p>Unauthorized access</p>');
		Redirect('./', 2)
	end;
	
	WriteLn('</center>');
	WriteLn('</body>');
	WriteLn('</html>')
end.			
