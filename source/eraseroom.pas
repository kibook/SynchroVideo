uses
	inifiles,
	process;

var
	Ini   : TIniFile;
	Proc  : TProcess;
	Rooms : Array of String;
	Room  : String;
	Ref   : Text;
	Len   : Integer;
begin
	Ini := TIniFile.Create('rooms.ini');
	Ini.CacheUpdates := True;

	Ini.DeleteKey('rooms', ParamStr(1));
	Ini.UpdateFile;
	Ini.Free;

	Proc := TProcess.Create(NIL);
	{$ifdef unix}
		Proc.Executable := 'rm';
		Proc.Parameters.Add('-r');
	{$endif}
	{$ifdef win32}
		Proc.Executable := 'del';
	{$endif}
	Proc.Parameters.Add(ParamStr(1));
	Proc.Options := [poUsePipes];
	Proc.Execute;
	Proc.WaitOnExit;
	Proc.Free;

	SetLength(Rooms, 0);

	Assign(Ref, 'rooms.list');
	Reset(Ref);

	repeat
		Len := Length(Rooms);
		SetLength(Rooms, Len + 1);
		ReadLn(Ref, Rooms[Len])
	until EOF(Ref);

	Close(Ref);

	Rewrite(Ref);

	for Room in Rooms do
		if Room <> ParamStr(1) then
			WriteLn(Ref, Room);
	Close(Ref)
end.
