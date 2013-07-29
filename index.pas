program SynchroVideo;

{$mode objfpc}{$h+}

uses
  FpCgi,

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
  WmApi;

var
  Ini : TIniFile;
begin
  Application.Initialize;

  Ini := TIniFile.Create('data/info.ini');

  Application.Administrator := Ini.ReadString('info', 'admin', '');
  Application.Email := Ini.ReadString('info', 'email', '');

  Ini.Free;

  Application.ModuleVariable := 'action';

  Application.Run
end.
