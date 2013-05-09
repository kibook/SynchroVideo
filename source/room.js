var SYNCPLAY = '';
var PLAYLISTMSG = '';
var SYNCTIME = '';
var TIMEBUFFER = 1.0;
var SYNCDELAY = 1000;
var VIDEOHEAD = 'http://www.youtube.com/v/';
var VIDEOTAIL = '?enablejsapi=1&version=3';
var SYNCVURL = VIDEOID;
var SYNCSVTV = '0';
var SYNC;

var Player;
var Playlist = {index: 0, locked: false, list: [{title:"",
	id:VIDEOID}]};
var Playlists = [];

var $ = function(id) {
	return document.getElementById(id);
}
var mod = function(x,m) {
	return (((x % m) + m) % m);
}
function setCookie(c_name, value, exdays) {
	var exdate=new Date();
	exdate.setDate(exdate.getDate() + exdays);
	var c_value=escape(value) +
		((exdays==null) ? "" : "; expires="+exdate.toUTCString());
	document.cookie=c_name + "=" + c_value;
}
function getCookie(c_name) {
	var i,x,y,ARRcookies=document.cookie.split(";");
	for (i=0;i<ARRcookies.length;i++) {
		x=ARRcookies[i].substr(0,ARRcookies[i].indexOf("="));
		y=ARRcookies[i].substr(ARRcookies[i].indexOf("=")+1);
		x=x.replace(/^\s+|\s+$/g,"");
		if (x==c_name)
			return unescape(y);
	}
}
var sendCall = function(call, query, f) {
	n = document.createElement("script");
	n.type = "text/javascript";
	n.src  = call + "?" + query;
	n.id   = 'synccall';
	n.onload = function() {
		document.body.removeChild(this);
		if (f != undefined)
			f();
	};
	document.body.appendChild(n);
}
var checkPlaylist = function() {
	sendCall('playlist.cgi', 'status');
}
var getVideoIndex = function(id) {
	var pl = Playlist.list;
	for (var i = 0; i < pl.length; i++)
		if (pl[i].id == id)
			return i;
	return -1;
}
var loadVideo = function(url) {
	Player.loadVideoByUrl(VIDEOHEAD + url + VIDEOTAIL);
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
	Player.width = x;
	Player.height = y;
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
	window.location = 'auth.cgi';
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
