switchLayout(getCookie('syncvid_layout'));

Player = $('movie_player');

checkPlaylist();
var onYouTubePlayerReady = function() {
	syncInit();
}
