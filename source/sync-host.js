var sync = function() {
	var videourl = VIDEOID;

	try {
		var time = Player.getCurrentTime();
		var videostate = Player.getPlayerState();
	} catch (err) { }

	var paused = '0';
	if (videostate != 1) {
		paused = '1';
	}

	sendCall('server.cgi',SESSIONID+'&'+videourl+'&'+paused+'&'+time);

	updatePlaylist();

	var syncplay = SYNCPLAY;
	var synctime = parseInt(SYNCTIME);

	if (videostate == 0)
		if (Playlist.list.length > 0)
			nextVideo();
}
var syncInit = function() {
	sendCall('server.cgi', '', function() {
		updatePlaylist();
		var synctime = parseInt(SYNCTIME);
		loadVideo(SYNCVURL);
		setTimeout(function() {
			Player.seekTo(synctime);
			SYNC = setInterval(sync, SYNCDELAY);
		}, 1000);
		fetchPlaylists();
	});
}
var addVideo = function(id) {
	sendCall('playlist.cgi', 'status', function() {
		$('addwait').style.display = "block";
		sendCall('playlist.cgi',SESSIONID+'&add&'+id,function() {
			setTimeout(function() {
				$('addwait').style.display = "none";
			}, 2000);
		});
		sync();
	});
}
var moveVideo = function(index1, index2) {
	sendCall('playlist.cgi', SESSIONID+'&move&'+index1+'&'+index2);
}
var removeVideo = function(id) {
	checkPlaylist();
	sendCall('playlist.cgi',SESSIONID+'&delete&'+id);
	sync();
}
var clearVideo = function(index) {
	removeVideo(Playlist.list[index].id);
}
var btnAddVideo = function() {
	addVideo(parseUrl($('addvideo').value));
	$('addvideo').value = '';
}
var clearPlaylist = function() {
	sendCall('playlist.cgi', SESSIONID+'&clear');
	sync();
}
var loadPlaylist = function(list) {
	sendCall('playlist.cgi', SESSIONID+'&load&'+list);
	sync();
}
var startTvMode = function() {
	sendCall('tvmode.cgi', SESSIONID);
}
var btnLoadList = function() {
	loadPlaylist($('listname').value);
	$('listname').value = '';
	fetchPlaylists();	
}
var savePlaylist = function(list) {
	sendCall('playlist.cgi', SESSIONID+'&save&'+list, function() {
		fetchPlaylists();
	});
}
var btnSaveList = function() {
	savePlaylist($('listname').value);
	$('listname').value = '';
}
var removeList = function(list) {
	sendCall('playlist.cgi', SESSIONID+'&remove&'+list, function() {
		fetchPlaylists();
	});
}
var btnRemoveList = function() {
	removeList($('listname').value);
	$('listname').value = '';
}
var parseListUrl = function(url) {
	return url.substr(url.indexOf('list=')+5,34);
}
var importList = function(id) {
	$('importwait').style.display = "block";
	sendCall('playlist.cgi',SESSIONID+'&import&'+id,function() {
		$('importwait').style.display="none";
	});
}
var btnImportList = function() {
	importList(parseListUrl($('listname').value));
	$('listname').value = '';
}
var lockPlaylist = function() {
	sendCall('playlist.cgi', SESSIONID+'&lock', function() {
		Playlist.locked = true;
		checkPlaylist();
		sync();
	});
}
var unlockPlaylist = function() {
	sendCall('playlist.cgi', SESSIONID+'&unlock', function() {
		Playlist.locked = false;
		checkPlaylist();
		sync();
	});
}
var shufflePlaylist = function() {
	sendCall('playlist.cgi', SESSIONID+'&shuffle', function() {
		checkPlaylist();
		sync();
	});
}
var sortPlaylist = function() {
	sendCall('playlist.cgi', SESSIONID+'&sort', function() {
		checkPlaylist();
		sync();
	});
}
var playRandom = function() {
	playVideo(Math.floor(Math.random() * Playlist.list.length));
}
var fetchPlaylists = function() {
	sendCall('playlist.cgi', 'list', function() {
		var list = '<option value="">--none--</option>\n';
		var clist = $('listname').value;
		for (var i = 0; i < Playlists.length; i++) {
			list += '<option value="'+Playlists[i]+'"';
			if (Playlists[i] == clist)
				list += ' selected="selected"';
			list += '>'+Playlists[i]+'</option>\n';
		}
		$('playlists').innerHTML = list;
	});
}
var selectPlaylist = function() {
	$('listname').value = $('playlists').value;
}
var updatePlaylist = function() {
	if (Playlist.locked)
		$('lock').innerHTML = '(locked)';
	else
		$('lock').innerHTML = '(unlocked)';

	if (SYNCSVTV == '1')
		$('tvmode').innerHTML = '(tvmode on)';
	else
		$('tvmode').innerHTML = '(tvmode off)';

	$('playlistcount').innerHTML =
		'('+Playlist.list.length+' videos)';

	var table = '<table cellpadding="1" width="100%">';
	var pl = Playlist.list;
	Playlist.index = -1;
	if (pl.length == 0)
		table += '<tr><td><span style="color:#555"><center>'+
			'(empty)</center></span></td></tr>';
	else
		for (var i = 0; i < pl.length; i++) {
			if (pl[i].id == VIDEOID)
				Playlist.index = i;
			var color = "#A88";
			var bg = "#222";
			if (i == Playlist.index) {
				color = "#C31";
				bg = "#444";
			}
			table += '<tr style="background-color:'+bg+'">'+
			'<td>'+
			'<span style="color:'+color+
			';font-size:14px;cursor:pointer" '+
			'onclick="playVideo('+getVideoIndex(pl[i].id)+')'+
			';">'+pl[i].title+'</span></td><td><span style="'+
			'color:#FEE;cursor:pointer;float:right" '+
			'onclick="clearVideo('+
			getVideoIndex(pl[i].id)+');">'+
			'[X]'+
			'</span>'+
			'</td>'+
			'</tr>';
			table += '<tr><td>'+
			'<hr style="padding:0px;margin:0px">'+
			'</td><td>'+
			'<hr style="padding:0px;margin:0px">'+
			'</td></tr>';
		}
	$('playlistvideos').innerHTML = table + '</table>';
}
