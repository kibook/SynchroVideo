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

	sendCall('server', {
		session: SESSIONID,
		video: videourl,
		paused: paused,
		time: time
	});

	updatePlaylist();

	var syncplay = SYNCPLAY;
	var synctime = parseInt(SYNCTIME);

	if (videostate == 0)
		if (Playlist.list.length > 0)
			nextVideo();
}
var syncInit = function() {
	sendCall('server', {}, function() {
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
	sendCall('playlist', {do: 'status'}, function() {
		$('addwait').style.display = "block";
		sendCall('playlist',{
			session: SESSIONID,
			do: 'add',
			id: id
		}, function() {
			setTimeout(function() {
				$('addwait').style.display = "none";
			}, 2000);
		});
		sync();
	});
}
var moveVideo = function(index1, index2) {
	sendCall('playlist', {
		do: 'move',
		session: SESSIONID,
		index1: index1,
		index2: index2
	});
}
var removeVideo = function(id) {
	checkPlaylist();
	sendCall('playlist', {
		do: 'delete',
		session: SESSIONID,
		id: id
	});
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
	sendCall('playlist', {do: 'clear', session: SESSIONID});
	sync();
}
var loadPlaylist = function(list) {
	sendCall('playlist', {
		do: 'load',
		list: list,
		session: SESSIONID
	});
	sync();
}
var startTvMode = function() {
	sendCall('tvmode', {session: SESSIONID, room: ROOMNAME});
}
var btnLoadList = function() {
	loadPlaylist($('listname').value);
	$('listname').value = '';
	fetchPlaylists();	
}
var savePlaylist = function(list) {
	sendCall('playlist', {
		do: 'save',
		session: SESSIONID,
		list: list
	}, function() {
		fetchPlaylists();
	});
}
var btnSaveList = function() {
	savePlaylist($('listname').value);
	$('listname').value = '';
}
var removeList = function(list) {
	sendCall('playlist', {
		do: 'remove',
		session: SESSIONID,
		list: list
	}, function() {
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
	sendCall('playlist', {
		do: 'import',
		session: SESSIONID,
		id: id
	}, function() {
		$('importwait').style.display="none";
	});
}
var btnImportList = function() {
	importList(parseListUrl($('listname').value));
	$('listname').value = '';
}
var lockPlaylist = function() {
	sendCall('playlist', {
		do: 'lock',
		session: SESSIONID
	}, function() {
		Playlist.locked = true;
		checkPlaylist();
		sync();
	});
}
var unlockPlaylist = function() {
	sendCall('playlist', {
		do: 'unlock',
		session: SESSIONID
	}, function() {
		Playlist.locked = false;
		checkPlaylist();
		sync();
	});
}
var shufflePlaylist = function() {
	sendCall('playlist', {
		do: 'shuffle',
		session: SESSIONID
	}, function() {
		checkPlaylist();
		sync();
	});
}
var sortPlaylist = function() {
	sendCall('playlist', {
		do: 'sort',
		session: SESSIONID
	}, function() {
		checkPlaylist();
		sync();
	});
}
var sanitizePlaylist = function() {
	$('sanitizewait').style.display = "block";
	sendCall('playlist', {
		do: 'sanitize',
		session: SESSIONID
	}, function() {
		checkPlaylist();
		sync();
		$('sanitizewait').style.display = "none";
	});
}
var playRandom = function() {
	playVideo(Math.floor(Math.random() * Playlist.list.length));
}
var fetchPlaylists = function() {
	sendCall('playlist', {do: 'list'}, function() {
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
	if (SYNCSVTV == '1')
		$('tvmode').innerHTML = '(tvmode on)';
	else
		$('tvmode').innerHTML = '(tvmode off)';

	var same = true;
	try {	
		same = (CPlaylist.index==Playlist.index)&&
			(CPlaylist.locked==Playlist.locked)&&
			(CPlaylist.list.length==Playlist.list.length);
		if (same)
			for (var i = 0; i < Playlist.list.length; i++)
				same=same&&(CPlaylist.list[i].id==
					Playlist.list[i].id);
	}
	catch (err) {
		same = false;
	}

	if (same)
		return;
	
	if (Playlist.locked)
		$('lock').innerHTML = '(locked)';
	else
		$('lock').innerHTML = '(unlocked)';

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

	CPlaylist.index = Playlist.index;
	CPlaylist.locked = Playlist.locked;
	CPlaylist.list = Playlist.list;
}
