# A ffmpeg player for tvOS TVML support DanMu based on SGPlayer

A front-end HUD similiar to built-in Player.

Javascript API Similar to TVML built-in Player.

Back-end based on a [modified](https://github.com/fuzhuo/SGPlayer) [SGPlayer](https://github.com/libobjc/SGPlayer)

My project [LazyCat](https://github.com/fuzhuo/Lazycat) use DanMuPlayer to play bili and panda video and live stream with dynamic subtitles (danmu弹幕).

JavaScript API Sample:

    let video = new DMMediaItem('video', video_url);
    video.url = video_url;
    video.artworkImageURL = data.img;
    video.title = data.MovieName;
    video.description = data.description;
    let videoList = new DMPlaylist();
    videoList.push(video);
    let myPlayer = new DMPlayer();
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
    myPlayer.addDanMu(msg="This is a test", color=0xFF0000, fontSize=25, style=0);
    //style 0:normal 1:top 2:bottom
    myPlayer.play()

New feature developping and bug fix ongoing...

Integreting and Build Step:

+ git submodule add https://github.com/fuzhuo/DanMuPlayer.git DanMuPlayer

+ cd DanMuPlayer && git submodule update --init --recursive

+ cd SGPlayer && sh compile-build.sh tvOS

+ drag DanMuPlayer.xcodeproject to your project

+ Add below line to tvos swift project to finish basic setup

    #import <DanMuPlayer.h>//add this line to objc-swift bridge file YourProjectName-Bridging-Header.h

    func appController(_ appController: TVApplicationController, evaluateAppJavaScriptIn jsContext: JSContext) {
        *DMPlayer.setup(jsContext, controller: appController.navigationController)*
    }

    #then call the player from javascript

Demo from [LazyCat](https://github.com/fuzhuo/Lazycat):

![a.jpg](https://ooo.0o0.ooo/2017/06/21/594a290031bd9.jpg)

![b.jpg](https://ooo.0o0.ooo/2017/06/21/594a290031127.jpg)
