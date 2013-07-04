switchLayout(getCookie('syncvid_layout'));

var tag = document.createElement('script');
tag.src = "https://www.youtube.com/iframe_api";
var firstScriptTag = document.getElementsByTagName('script')[0];
firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

var onYouTubeIframeAPIReady = function() {
	Player = new YT.Player('player', {
		events: {
			'onReady': onYouTubePlayerReady
		}
	});
}

checkPlaylist();
var onYouTubePlayerReady = function() {
	syncInit();
}
