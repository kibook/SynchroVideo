var sync = function() {
	var videourl = VIDEOID;

	try {
		var time = Player.getCurrentTime();
		var videostate = Player.getPlayerState();
	} catch (err) { }

	sendCall('server', {}, function() {
		updatePlaylist();

		var syncplay = SYNCPLAY;
		var synctime = parseInt(SYNCTIME);

		if (videostate == 1 && syncplay == '1')
			Player.pauseVideo();
		if (videostate != 1 && syncplay == '0')
			Player.playVideo();
		if (Math.abs(synctime-time) > TIMEBUFFER)
			Player.seekTo(synctime);
		if (videourl != SYNCVURL)
			loadVideo(SYNCVURL);
	});
}
var syncInit = function() {
	SYNC = setInterval(sync, SYNCDELAY);
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
			var weight = "normal";
			var bg = "#222";
			if (i == Playlist.index) {
				color = "#D42";
				weight = "bold";
				bg = "#444";
			}
			table += '<tr style="background-color:'+bg+'">'+
			'<td>'+
			'<span style="color:'+color+';'+
			'font-size:14px;font-weight:'+weight+';">'+
			pl[i].title+
			'</span>'+
			'</td>'+
			'</tr>';
			table += '<tr><td>'+
			'<hr style="padding:0px;margin:0px">'+
			'</td></tr>';
		}
	$('playlistvideos').innerHTML = table + '</table>';
}
var addVideo = function(id) {
	sendCall('playlist', {do: 'status'}, function() {
		if (!Playlist.locked) {
			$('addwait').style.display = "block";
			sendCall('playlist',{do:'add',id:id},function() {
				setTimeout(function() {
					$('addwait').style.display="none";
				}, 2000);
			});
			sync();
		}
		else
			alert('Playlist is locked!');
	});
}
var btnAddVideo = function() {
	addVideo(parseUrl($('addvideo').value));
	$('addvideo').value = '';
}
