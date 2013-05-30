uses
	dos,
	strarrutils,
	inifiles,
	htmlutils;

const
	DefTitle     = 'Sync Vid';
	DefVideo     = 'YTu-ctARF2w';

var
	Ini         : TIniFile;
	Query       : THttpQueryPair;
	Params      : THttpQuery;
	Tags        : String;
	Banner      : String;
	IrcConf     : String;
	VideoId     : String;
	Favicon     : String;
	Password    : String;
	HostPass    : String;
	PageTitle   : String;
	Description : String;
	RoomScript  : String;
	RoomStyle   : String;
	RoomUrl     : String;
	IsAuth      : Boolean = False;
begin
	WriteLn('Content-Type: text/html');
	WriteLn;

	ini := tinifile.create('settings.ini');

	RoomUrl     := Ini.ReadString('room', 'url',           '');
	Password    := Ini.ReadString('room', 'password',      '');
	HostPass    := Ini.ReadString('room', 'host-password', '');
	PageTitle   := Ini.ReadString('room', 'name',          '');
	VideoId     := Ini.ReadString('room', 'video',         '');
	Banner      := Ini.ReadString('room', 'banner',        '');
	Favicon     := Ini.ReadString('room', 'favicon',       '');
	IrcConf     := Ini.ReadString('room', 'irc-settings',  '');
	Tags        := Ini.ReadString('room', 'tags',          '');
	Description := Ini.ReadString('room', 'description',   '');
	RoomScript  := Ini.ReadString('room', 'script',        '');
	RoomStyle   := Ini.ReadString('room', 'style',         '');

	Ini.Free;

	Params := GetQuery(GetRequest);

	WriteLn('<html>');
	WriteLn('<head>');
	WriteLn('<link rel="stylesheet" type="text/css" ',
		'href="../general.css">');
	WriteLn('</head>');
	WriteLn('<body>');
	WriteLn('<center>');

	for Query in Params do
		case Query[0] of
			'host': if
				not (Query[1] = '') and
				(Query[1] = HostPass)
			then
				IsAuth := True
			else
			begin
				WriteLn('<h1>Error!</h1>');
				WriteLn('Password Invalid');
				Redirect('settings-auth.cgi', 1);
				Halt
			end
		end;
	
	if not IsAuth then
	begin
		WriteLn('<h1>Error!</h1>');
		WriteLn('Settings page requires a password');
		Redirect('settings-auth.cgi', 1);
		halt
	end;

	WriteLn('<h1>Settings</h1>');
	WriteLn('<form name="form" action="configure.cgi" method="POST">');

	WriteLn('<input type="text" name="host" value="' + HostPass + '" ',
		'style="display:none;">');

	WriteLn('<table cellpadding="5">');

	Write('<tr>');
	Write('<td>');
	Write('Room Title:');
	Write('</td>');
	Write('<td>');
	Write('<input type="text" name="title" ',
		'value="' + PageTitle + '">');
	Write('</td>');
	WriteLn('</tr>');

	Write('<tr>');
	Write('<td>');
	Write('Banner:');
	Write('</td>');
	Write('<td>');
	Write('<input type="text" name="banner" ',
		'value="', Banner, '">');
	Write('</td>');
	WriteLn('</tr>');

	Write('<tr>');
	Write('<td>');
	Write('Favicon:');
	Write('</td>');
	Write('<td>');
	Write('<input type="text" name="favicon" ',
		'value="', Favicon, '">');
	Write('</td>');
	WriteLn('</tr>');

	Write('<tr>');
	Write('<td>');
	Write('IRC Settings:');
	Write('</td>');
	Write('<td>');
	Write('<input type="text" name="ircconf" ',
		'value="', IrcConf, '">');
	Write('</td>');
	WriteLn('</tr>');

	Write('<tr>');
	Write('<td>');
	Write('Room Password:');
	Write('</td>');
	Write('<td>');
	Write('<input type="text" name="newpass" ',
		'value="', Password, '">');
	Write('</td>');
	WriteLn('</tr>');

	Write('<tr>');
	Write('<td>');
	Write('Host Password:');
	Write('</td>');
	Write('<td>');
	Write('<input type="text" name="newhost" ',
		'value="', HostPass, '">');
	Write('</td>');
	WriteLn('</tr>');

	Write('<tr>');
	Write('<td>');
	Write('Room tags:');
	Write('</td>');
	Write('<td>');
	Write('<input type="text" name="tags" ',
		'value="', Tags, '">');
	Write('</td>');
	WriteLn('</tr>');

	Write('<tr>');
	Write('<td>');
	Write('Description:');
	Write('</td>');
	Write('<td>');
	Write('<input type="text" name="description" ',
		'value="', Description, '">');
	Write('</td>');
	WriteLn('</tr>');

	Write('<tr>');
	Write('<td>');
	Write('Custom Script:');
	Write('</td>');
	Write('<td>');
	Write('<input type="text" name="script" ',
		'value="', RoomScript, '">');
	Write('</td>');
	WriteLn('</tr>');

	Write('<tr>');
	Write('<td>');
	Write('Custom Style:');
	Write('</td>');
	Write('<td>');
	Write('<input type="text" name="style" ',
		'value="', RoomStyle, '">');
	Write('</td>');
	WriteLn('</tr>');

	WriteLn('</table>');
	WriteLn('<input type="submit" value="Save Changes">');

	WriteLn('</form>');

	WriteLn('<br><br>');
	WriteLn('<form action="../deleteroom.cgi" method="POST" ',
		'target="_blank">');
	WriteLn('<input type="hidden" name="room" ',
		'value="', RoomUrl, '">');
	WriteLn('<input type="hidden" name="host" ',
		'value="', HostPass, '">');
	WriteLn('<input type="hidden" name="confirm" ',
		'value="false">');
	WriteLn('<input type="submit" value="Delete Room">');
	WriteLn('</form>');


	WriteLn('</center>');
	WriteLn('</body>');
	WriteLn('</html>')
end.
