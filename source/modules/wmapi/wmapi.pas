unit WmAPI;

interface
uses
	HTTPDefs,
	fpHTTP,
	fpWeb;

type
	TWmAPI = class(TFPWebModule)
	published
		procedure DoRequest(
			Sender     : TObject;
			ARequest   : TRequest;
			AResponse  : TResponse;
			var Handle : Boolean
		);
	end;

var
	AWmAPI : TWmAPI;

implementation
uses
	SysUtils,
	Classes,
	IniFiles;

{$R *.lfm}

procedure TWmAPI.DoRequest(
	Sender     : TObject;
	ARequest   : TRequest;
	AResponse  : TResponse;
	var Handle : Boolean
);
var
	Room : String;

procedure GetCurrentVideo;
var
	BufferFile : String;
	ListFile   : String;
	VideoId    : String = '';
	VideoTitle : String = '';
	AFile      : Text;
	Ini        : TIniFile;
begin
	BufferFile := 'rooms/' + Room + '/syncvid.syn';
	ListFile   := 'rooms/' + Room + '/playlist.ini';

	if (FileExists(BufferFile)) and (FileExists(ListFile)) then
	begin
		AssignFile(AFile, BufferFile);
		Reset(AFile);
		ReadLn(AFile, VideoId);
		CloseFile(AFile);
		Ini := TIniFile.Create(ListFile);
		VideoTitle := Ini.ReadString('videos', VideoId, '');
		Ini.Free;
		AResponse.Content := VideoTitle
	end
	else
		AResponse.Code := 404
end;

procedure GetCurrentId;
var
	BufferFile : String;
	VideoId    : String = '';
	AFile      : Text;
begin
	BufferFile := 'rooms/' + Room + '/syncvid.syn';

	if FileExists(BufferFile) then
	begin
		AssignFile(AFile, BufferFile);
		Reset(AFile);
		ReadLn(AFile, VideoId);
		CloseFile(AFile);
		AResponse.Content := VideoId
	end
	else
		AResponse.Code := 404
end;

procedure GetPlaylist;
var
	ListFile : String;
	Videos   : TStringList;
	i        : Integer;
	Ini      : TIniFile;
begin
	ListFile := 'rooms/' + Room + '/playlist.ini';

	if FileExists(ListFile) then
	begin
		Ini := TIniFile.Create(ListFile);
		Videos := TStringList.Create;		
		Ini.ReadSection('videos', Videos);
		for i := 0 to Videos.Count - 1 do
			Videos[i] := Ini.ReadString('videos',Videos[i],'');
		Ini.Free;
		AResponse.Contents := Videos;
		Videos.Free		
	end
	else
		AResponse.Code := 404
end;

procedure GetTvMode;
var
	BufferFile : String;
	Line       : String;
	AFile      : Text;
begin
	BufferFile := 'rooms/' + Room + '/syncvid.syn';

	if FileExists(BufferFile) then
	begin
		AssignFile(AFile, BufferFile);
		Reset(AFile);
		ReadLn(AFile, Line);
		ReadLn(AFile, Line);
		ReadLn(AFile, Line);
		ReadLn(AFile, Line);
		CloseFile(AFile);
		if Line = '1' then
			AResponse.Content := 'true'
		else
			AResponse.Content := 'false'
	end
	else
		AResponse.Code := 404
end;

procedure GetCurrentTime;
var
	BufferFile : String;
	Line       : String;
	AFile      : Text;
begin
	BufferFile := 'rooms/' + Room + '/syncvid.syn';

	if FileExists(BufferFile) then
	begin
		AssignFile(AFile, BufferFile);
		Reset(AFile);
		ReadLn(AFile, Line);
		ReadLn(AFile, Line);
		ReadLn(AFile, Line);
		CloseFile(AFile);
		AResponse.Content := Line
	end
	else
		AResponse.Code := 404
end;

procedure GetCurrentStatus;
var
	BufferFile : String;
	Line       : String;
	AFile      : Text;
begin
	BufferFile := 'rooms/' + Room + '/syncvid.syn';

	if FileExists(BufferFile) then
	begin
		AssignFile(AFile, BufferFile);
		Reset(AFile);
		ReadLn(AFile, Line);
		ReadLn(AFile, Line);
		CloseFile(AFile);
		if Line = '1' then
			AResponse.Content := 'paused'
		else
			AResponse.Content := 'playing'
	end
	else
		AResponse.Code := 404
end;

procedure GetPlaylists;
var
	Lists  : TStringList;
	Info   : TSearchRec;
	faType : Word;
	Path   : String;

procedure CheckFile;
begin
	faType := Info.Attr and faDirectory;
	if not (faType = faDirectory) then
		Lists.Add(Copy(Info.Name, 1, Length(Info.Name) - 4))
end;

begin
	Lists := TStringList.Create;
	Path := 'rooms/' + Room + '/playlists/*';
	if FindFirst(Path, faAnyFile and faDirectory, Info) = 0 then
	begin
		repeat
			CheckFile
		until not (FindNext(Info) = 0)
	end;
	FindClose(Info);

	AResponse.Contents := Lists
end;

begin
	AResponse.ContentType := 'text/plain';

	Room := ARequest.QueryFields.Values['room'];

	case ARequest.QueryFields.Values['get'] of
		'videotitle'    : GetCurrentVideo;
		'videoid'       : GetCurrentId;
		'videotime'     : GetCurrentTime;
		'currentstatus' : GetCurrentStatus;
		'playlist'      : GetPlaylist;
		'tvmode'        : GetTvMode;
		'playlists'     : GetPlaylists
	else
		AResponse.Code := 404
	end;

	Handle := True
end;

initialization
	RegisterHTTPModule('api', TWmAPI)
end.
