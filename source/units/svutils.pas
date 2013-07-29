unit SvUtils;

{$mode objfpc}{$h+}

interface

uses
  Classes;

function GetRoomPlaylists(Room : string) : TStringList;

implementation

uses
  SysUtils,
  StrUtils;

function GetRoomPlaylists(Room : string) : TStringList;
var
  Info      : TSearchRec;
  Ext       : string;
  Name      : string;
begin
  Result := TStringList.Create;
  FindFirst('rooms/' + Room + '/playlists/*', faAnyFile, Info);
  repeat
    Name := Copy(Info.Name, 1, Pos('.', Info.Name) - 1);
    Ext  := Copy(Info.Name,
      Pos('.', Info.Name) + 1, Length(Info.Name));
    if Ext = 'ini' then
      Result.Add(Name)
  until not (FindNext(Info) = 0);
  FindClose(Info)
end;

end.
