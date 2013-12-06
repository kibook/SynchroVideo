var SYNCPLAY = '';
var PLAYLISTMSG = '';
var SYNCTIME = '';
var TIMEBUFFER = 1.0;
var SYNCDELAY = 1000;
var SYNCVURL = VIDEOID;
var SYNCSVTV = '0';
var SYNC;
var LAYOUT = 'layout1';

var Player;
var Playlist = {index: 0, locked: false, list: [{title:"", id:VIDEOID}]};
var CPlaylist = {};
var Playlists = [];

var $ = function(id) {
	return document.getElementById(id);
}
var mod = function(x,m) {
	return (((x % m) + m) % m);
}
var getCookie = function(c_name) {
	var i, x, y, ARRcookies = document.cookie.split(';');
	for (i = 0; i < ARRcookies.length; i++) {
		x = ARRcookies[i].substr(0, ARRcookies[i].indexOf('='));
		y = ARRcookies[i].substr(ARRcookies[i].indexOf('=') + 1);
		x = x.replace(/^\s+|\s+$/g, "");
		if (x == c_name) {
			return unescape(y);
		}
	}
}

var setCookie = function(c_name, value, exdays) {
	var exdate = new Date();
	exdate.setDate(exdate.getDate() + exdays);
	var c_value = escape(value) +
		((exdays == null) ? '' : '; expires' +
		exdate.toUTCString());
	document.cookie = c_name + '=' + c_value;
}
var getEmbedUrl = {
	yt: function(id) {
		return 'http://www.youtube.com/v/' + id +
			'?enablejsapi=1&version=3';
	},
	vm : function(id) {
		return 'http://vimeo.com/moogaloop.swf?clip_id=' + id +
			'&force_embed=1&server=vimeo.com&show_title=1'+
			'&show_byline=1&show_portrait=1&color=00adef' +
			'&fullscreen=1&autoplay=1&loop=0';
	}
}
var sendCall = function(action, params, f) {
	var paramList = '';
	for (param in params)
		paramList = paramList + '&' + param + '=' + params[param];
	var n = document.createElement("script");
	n.type = "text/javascript";
	n.src  = '/?action=' + action + '&room=' + ROOMNAME + paramList;
	n.id   = 'synccall';
	n.onload = function() {
		document.body.removeChild(this);
		if (f != undefined)
			f();
	};
	document.body.appendChild(n);
}
var checkPlaylist = function() {
	sendCall('playlist', {'do': 'status'});
}
var getVideoIndex = function(id) {
	var pl = Playlist.list;
	for (var i = 0; i < pl.length; i++)
		if (pl[i].id == id)
			return i;
	return -1;
}
var loadVideo = function(url) {
	Player.loadVideoByUrl(getEmbedUrl['yt'](url));
	VIDEOID = url;
	SYNCVURL = url;
}
var btnLoadVideo = function() {
	loadVideo($('idbox').value);
}
var playVideo = function(index) {
	Playlist.index = index;
	var url = Playlist.list[index].id;
	loadVideo(url);
}
var nextVideo = function() {
	Playlist.index = mod(Playlist.index + 1,
		Playlist.list.length);
	playVideo(Playlist.index);
}
var prevVideo = function() {
	Playlist.index = mod(Playlist.index - 1,
		Playlist.index.length);
	playVideo(Playlist.index);
}
var changeSync = function() {
	clearInterval(SYNC);
	if ($('syncselect').checked)
		syncInit();
}
var changeBuffer = function() {
	TIMEBUFFER = parseInt($('bufferselect').value);
}
var setVideoSize = function(x,y) {
	Player.setSize(x, y);
	$('playlistvideos').style.height = (y-24) + 'px';
	$('chat').width = x;
}
var changeVideoSize = function() {
	var size = $('videosize').value;
	if (size == 'small')
		setVideoSize(480, 360);
	if (size == 'normal')
		setVideoSize(640, 450);
	if (size == 'large')
		setVideoSize(760, 540);
}
var changeDelay = function() {
	clearInterval(SYNC);
	SYNCDELAY = parseInt($('delayselect').value);
	syncInit();
}
var togglePlaylist = function() {
	if ($('playlist').style.display == 'none')
		$('playlist').style.display = 'block';
	else
		$('playlist').style.display = 'none';
}
var takeHost = function() {
	window.location='?action=auth&access=join&type=host&room='+ROOMNAME;
}
var dropHost = function() {
	window.location = '';
}
var parseUrl = function(url) {
	return url.substr(url.indexOf('v=') + 2, 11);
}
var scrollListToCurrent = function() {
	var pl = $('playlistvideos');
	var v = Playlist.list.length;
	var z = (Playlist.index + 1) / v;
	pl.scrollTop = pl.scrollHeight * (1 - z);
}
var openVideo = function(id) {
	window.open('http://youtube.com/watch?v='+id);
}
var switchLayout = function(layout) {
	var T1 = $('T1');
	var T2 = $('T2');
	var T3 = $('T3');
	var T4 = $('T4');

	var video    = T1.innerHTML;
	var playlist = T2.innerHTML;
	var chat     = T3.innerHTML;
	var controls = T4.innerHTML;
	var none     = '';

	switch (layout) {

		case "top-chat":
			T1.innerHTML = chat;
			T2.innerHTML = controls;
			T3.innerHTML = video;
			T4.innerHTML = playlist;
			break;

		case "right-chat":
			T1.innerHTML = playlist;
			T2.innerHTML = video;
			T3.innerHTML = controls;
			T4.innerHTML = chat;
			break;

		case "no-chat":
			T1.innerHTML = video;
			T2.innerHTML = playlist;
			T3.innerHTML = none;
			T4.innerHTML = controls;
			break;

		case "mirror":
			T1.innerHTML = controls;
			T2.innerHTML = chat;
			T3.innerHTML = playlist;
			T4.innerHTML = video;
			break;
	}

	try {
		$(layout).selected = true;
	} catch (err) { }
}
var changeLayout = function() {
	var layout = $('layouts').value;
	switchLayout(layout);
	setCookie('syncvid_layout', layout, 365);
	window.location = '';
}
var popout = function() {
	window.open("?action=mini&room=" + ROOMNAME, "",
		"width=680, height=480");
	$('syncselect').checked = false;		
	clearInterval(SYNC);
	Player.pauseVideo();
}
