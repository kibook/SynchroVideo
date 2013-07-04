uses
	fpCGI,
	HTTPDefs,
	fpHTTP,

	IniFiles,

	{ Modules }
	WmHome,
	WmRoom,
	WmAuth,
	WmInfo,
	WmPlaylist,
	WmServer,
	WmSearch,
	WmList,
	WmNewRoom,
	WmCreate,
	WmDelete,
	WmSettings,
	WmConfigure,
	WmTVMode,
	WmAPI;

var
	Ini : TIniFile;
begin
	Application.Initialize;

	Ini := TIniFile.Create('data/info.ini');

	Application.Administrator :=
		Ini.ReadString('info', 'admin', 'webmaster');
	Application.Email :=
		Ini.ReadString('info', 'email', 'webmaster@localhost');

	Ini.Free;

	Application.ModuleVariable := 'action';

	Application.Run
end.
