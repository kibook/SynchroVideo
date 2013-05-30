uses
	dos,
	strarrutils,
	inifiles,
	strutils,
	process;

var
	Ini       : TIniFile;
	Ref       : Text;
	SessionId : String;
	HostPass  : String;
	Request   : String;
	Server    : TProcess;
begin
	WriteLn('Content-Type: text/javascript');
	WriteLn;

	Request := GetEnv('QUERY_STRING');

	Ini := TIniFile.Create('settings.ini');	
	HostPass := Ini.ReadString('room', 'host-password', '');
	Ini.Free;

	Assign(Ref, 'session.id');
	Reset(Ref);
	ReadLn(Ref, SessionId);
	Close(Ref);

	SessionId := XorDecode(HostPass, SessionId);

	if Request = SessionId then
	begin
		Server := TProcess.Create(Nil);
		{$ifdef unix}
			Server.Executable := './tvserver';
		{$endif}
		{$ifdef win32}
			Server.Executable := 'tvserver.exe';
		{$endif}
		Server.Options := [poUsePipes];
		Server.Execute
	end
end.
