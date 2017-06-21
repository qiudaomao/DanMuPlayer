# A ffmpeg player for tvOS TVML support DanMu based on SGPlayer

With a Javascript API which is Similar to TVML built-in Player.

Lazycat use it to play bili and panda with dynamic subtitles danmu(弹幕).

javascript API Sample:

    let video = new MMMediaItem('video', video_url);
    video.url = video_url;
    video.artworkImageURL = data.img;
    video.title = data.MovieName;
    video.description = data.description;
    let videoList = new MMPlaylist();
    videoList.push(video);
    let myPlayer = new MMPlayer();
    myPlayer.playlist = videoList;
    myPlayer.addEventListener('timeBoundaryDidCross', (listener, extraInfo) => {
        console.log("bound: " + listener.boundary);
    }, time_array);
    myPlayer.addEventListener('timeDidChange', function(listener,extraInfo) {
        console.log("time: " + listener.time);
    },{interval: 1});
    myPlayer.addEventListener('stateDidChange', function(listener, extraInfo) {
        console.log("state: " + listener.state);
    },{});
    myPlayer.play()

Still under developping...

Build:

+ git submodule add https://github.com/fuzhuo/DanMuPlayer.git DanMuPlayer

+ cd DanMuPlayer && git submodule update --init --recursive

+ cd SGPlayer && sh compile-build.sh tvOS

+ import DanMuPlayer.xcodeproject to your project
