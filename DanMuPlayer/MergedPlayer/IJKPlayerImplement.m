//
//  IJKPlayerImplement.m
//  DanMuPlayer
//
//  Created by zfu on 2019/3/15.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "IJKPlayerImplement.h"
#import <IJKMediaFrameworkWithSSL/IJKMediaFrameworkWithSSL.h>

@interface IJKPlayerImplement() {
    IJKFFMoviePlayerController *player;
    BOOL stopped;
    NSTimeInterval prevTime;
}
@end

@implementation IJKPlayerImplement
@synthesize videoView;
@synthesize videoSize;
@synthesize delegate;

- (instancetype)init {
    self = [super init];
    [self installMovieNotificationObservers];
    stopped = NO;
    prevTime = -1;
    return self;
}

- (void)play {
    if (player.isPreparedToPlay) {
        [player play];
    } else {
        [player prepareToPlay];
        [player play];
    }
}

- (void)pause {
    if (player) {
        [player pause];
    }
}
- (void)empty {
}
- (void)stop {
    if (player) {
        stopped = YES;
        [player shutdown];
        [self removeMovieNotificationObservers];
        if (self.delegate) {
            [self.delegate onEnd];
        }
    }
}
- (void)seekToTime:(NSTimeInterval)time {
    if (player) {
        [player setCurrentPlaybackTime:time];
    }
}
- (void)playVideo:(NSString*)url
        withTitle:(NSString*)title
          withImg:(NSString*)img
   withDesciption:(NSString*)desc
          options:(NSMutableDictionary*)options
              mp4:(BOOL)mp4
   withResumeTime:(CGFloat)resumeTime {
#if 0
    [IJKFFMoviePlayerController setLogReport:YES];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_DEBUG];
#else
    [IJKFFMoviePlayerController setLogReport:NO];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_SILENT];
#endif

    [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];
    // [IJKFFMoviePlayerController checkIfPlayerVersionMatch:YES major:1 minor:0 micro:0];
    
    IJKFFOptions *ffoptions = [IJKFFOptions optionsByDefault];
    [ffoptions setFormatOptionValue:@"file,concat,http,tcp,https,tls,rtmp,rtsp,ijkio,ffio,cache,async,rtp,udp,ijklongurl,crypto" forKey:@"protocol_whitelist"];
//    [ffoptions setPlayerOptionIntValue:1 forKey:@"enable-accurate-seek"];
    //    [ffoptions setPlayerOptionIntValue:1 forKey:@"videotoolbox"];
    if ([options.allKeys containsObject:@"headers"]) {
        NSDictionary *headers = [options objectForKey:@"headers"];
        NSString *headerStr = @"";
        for (NSString *key in headers.allKeys) {
            NSString *value = [headers objectForKey:key];
            if ([key.lowercaseString isEqualToString:@"user-agent"]) {
                [ffoptions setFormatOptionValue:value forKey:key.lowercaseString];
            }
            headerStr = [NSString stringWithFormat:@"%@%@:%@\r\n", headerStr, key, value];
        }
        if (headerStr.length > 0) {
            NSLog(@"headers %@", headerStr);
            [ffoptions setFormatOptionValue:headerStr forKey:@"headers"];
        }
    }
    if ([url hasPrefix:@"rtsp:"]) {
//        [ffoptions setPlayerOptionIntValue:1 forKey:@"videotoolbox"];
        [ffoptions setFormatOptionValue:@"prefer_tcp" forKey:@"rtsp_flags"];
        [ffoptions setFormatOptionValue:@"tcp" forKey:@"rtsp_transport"];
        [ffoptions setFormatOptionValue:@"video" forKey:@"allowed_media_types"];
        [ffoptions setFormatOptionIntValue:1 forKey:@"infbuf"];
        [ffoptions setPlayerOptionIntValue:0 forKey:@"packet-buffering"];
    }
    [ffoptions setPlayerOptionIntValue:1 forKey:@"deinterlace"];
    [ffoptions setPlayerOptionValue:@"w3fdif" forKey:@"vf0"];
    [ffoptions setFormatOptionIntValue:0 forKey:@"auto_convert"];
    
    [ffoptions setPlayerOptionIntValue:500 forKey:@"first-high-water-mark-ms"];
    [ffoptions setPlayerOptionIntValue:1000 forKey:@"next-high-water-mark-ms"];
    [ffoptions setPlayerOptionIntValue:1500 forKey:@"last-high-water-mark-ms"];
    [ffoptions setPlayerOptionIntValue:300 forKey:@"min-frames"];
    [ffoptions setPlayerOptionIntValue:14*1024*1024 forKey:@"max-buffer-size"];

    //set buffer size
    //read ijkOptions from options
    if ([options.allKeys containsObject:@"ijkOptions"]) {
        NSDictionary *ijkOptions = [options objectForKey:@"ijkOptions"];
        /*
         ijkOptions: {
         "enable-accurate-seek": {
         "target": "player",
         "type": "number",
         "value": @(1)
         },
         "user-agent": {
         "target": "format",
         "type": "string",
         "value": "ijkplayer"
         }
         }
         */
        for (NSString *key in ijkOptions.allKeys) {
            NSDictionary *value = [ijkOptions objectForKey:key];
            if ([value.allKeys containsObject:@"target"]
                && [value.allKeys containsObject:@"type"]
                && [value.allKeys containsObject:@"value"]) {
                NSString *target = [value objectForKey:@"target"];
                NSString *type = [value objectForKey:@"type"];
                IJKFFOptionCategory category = kIJKFFOptionCategorySwr;
                BOOL failed = NO;
                if ([target isEqualToString:@"player"]) {
                    category = kIJKFFOptionCategoryPlayer;
                } else if ([target isEqualToString:@"format"]) {
                    category = kIJKFFOptionCategoryFormat;
                } else if ([target isEqualToString:@"codec"]) {
                    category = kIJKFFOptionCategoryCodec;
                } else if ([target isEqualToString:@"swr"]) {
                    category = kIJKFFOptionCategorySwr;
                } else if ([target isEqualToString:@"sws"]) {
                    category = kIJKFFOptionCategorySws;
                } else {
                    failed = YES;
                }
                if (!failed) {
                    if ([type isEqualToString:@"number"]) {
                        NSNumber *intValue = [value objectForKey:@"value"];
                        NSInteger v = intValue.integerValue;
                        [ffoptions setOptionIntValue:v forKey:key ofCategory:category];
                    } else if ([type isEqualToString:@"string"]){
                        [ffoptions setOptionValue:[value objectForKey:@"value"] forKey:key ofCategory:category];
                    } else {
                        NSLog(@"unknown options %@ => value %@", key, value);
                    }
                } else {
                    NSLog(@"unknown target %@ when set options %@ => value %@", target, key, value);
                }
            } else {
                NSLog(@"Error missing target or type or value in %@", value);
            }
        }
    }
    
    //    NSURL *url_ = [NSURL URLWithString:@"http://127.0.0.1/media/i-see-fire.mp4"];
    NSURL *url_ = [NSURL URLWithString:url];
    player = [[IJKFFMoviePlayerController alloc] initWithContentURL:url_ withOptions:ffoptions];
    player.scalingMode = IJKMPMovieScalingModeAspectFit;
//    player.shouldAutoplay = YES;
    self.videoView = player.view;

    [self installMovieNotificationObservers];
    [self updateTick];
}

- (void)loadStateDidChange:(NSNotification*)notification
{
    //    MPMovieLoadStateUnknown        = 0,
    //    MPMovieLoadStatePlayable       = 1 << 0,
    //    MPMovieLoadStatePlaythroughOK  = 1 << 1, // Playback will be automatically started in this state when shouldAutoplay is YES
    //    MPMovieLoadStateStalled        = 1 << 2, // Playback will be automatically paused in this state, if started
    IJKMPMovieLoadState loadState = player.loadState;
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStatePlaythroughOK: %d\n", (int)loadState);
        if ([self.delegate respondsToSelector:@selector(stopBufferring)]) {
            [self.delegate stopBufferring];
        }
        if ([self.delegate respondsToSelector:@selector(onVideoSizeChanged:)]) {
            [self.delegate onVideoSizeChanged:player.naturalSize];
        }
        if ([self.delegate respondsToSelector:@selector(onVideoFPSChanged:)]) {
            [self.delegate onVideoFPSChanged:player.fpsInMeta];
        }
    } else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
        if ([self.delegate respondsToSelector:@selector(bufferring)]) {
            [self.delegate bufferring];
        }
    } else if ((loadState & IJKMPMovieLoadStatePlayable) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadState Playable: %d\n", (int)loadState);
    } else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

- (void)moviePlayBackDidFinish:(NSNotification*)notification
{
    //    MPMovieFinishReasonPlaybackEnded,
    //    MPMovieFinishReasonPlaybackError,
    //    MPMovieFinishReasonUserExited
    int reason = [[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    
    switch (reason)
    {
        case IJKMPMovieFinishReasonPlaybackEnded:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason);
            [self stop];
            break;
            
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            [self stop];
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);
            if (self.delegate) {
                [self.delegate onError:@""];
            }
            break;
            
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification
{
    NSLog(@"mediaIsPreparedToPlayDidChange\n");
}

- (void)moviePlayBackStateDidChange:(NSNotification*)notification
{
    switch (player.playbackState)
    {
        case IJKMPMoviePlaybackStateStopped: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: stoped", (int)player.playbackState);
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateTick) object:nil];
            [self.delegate onEnd];
            break;
        }
        case IJKMPMoviePlaybackStatePlaying: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: playing", (int)player.playbackState);
            [self.delegate onPlay];
            break;
        }
        case IJKMPMoviePlaybackStatePaused: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: paused", (int)player.playbackState);
            [self.delegate onPause];
            break;
        }
        case IJKMPMoviePlaybackStateInterrupted: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: interrupted", (int)player.playbackState);
            [self.delegate onError:@"Interrupted"];
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateTick)
                                                       object:nil];
            break;
        }
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: seeking", (int)player.playbackState);
            break;
        }
        default: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)player.playbackState);
            break;
        }
    }
}

- (void)installMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:player];
}

-(void)removeMovieNotificationObservers
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerLoadStateDidChangeNotification object:player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackDidFinishNotification object:player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification object:player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:player];
}

- (void)updateTick {
    if (stopped) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateTick) object:nil];
        return;
    }
    NSTimeInterval duration = player.duration;
    NSTimeInterval currentTime = player.currentPlaybackTime;
    NSTimeInterval playableTime = player.playableDuration;
    if (fabs(prevTime-currentTime) > 0.01) {
        prevTime = currentTime;
        NSInteger bufferingProgress = player.bufferingProgress;
        NSInteger isSeekBuffering = player.isSeekBuffering;
        NSLog(@"currentTime/duration %.2f / %.2f playable %.2f bufferingProgress %lu isSeekBuffering %lu",
              currentTime, duration, playableTime, bufferingProgress, isSeekBuffering);
        [self.delegate updateProgress:currentTime playableTime:playableTime buffering:NO total:duration];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateTick) object:nil];
    }
    [self performSelector:@selector(updateTick) withObject:nil afterDelay:1.0];
}

- (NSTimeInterval)currentTime {
    if (player) {
        return player.currentPlaybackTime;
    }
    return -1;
}
- (NSTimeInterval)duration {
    if (player) {
        return player.duration;
    }
    return -1;
}
- (NSTimeInterval)playableTime {
    if (player) {
        return player.playableDuration;
    }
    return -1;
}
- (void)changeSpeedMode:(PlaySpeedMode)speedMode {
    NSLog(@"onPanelChangeSpeedMode %lu", speedMode);
    switch (speedMode) {
        case PlaySpeedModeQuarter:
            player.playbackRate = 0.25;
            break;
        case PlaySpeedModeHalf:
            player.playbackRate = 0.5;
            break;
        case PlaySpeedModeNormal:
            player.playbackRate = 1;
            break;
        case PlaySpeedModeDouble:
            player.playbackRate = 2.0;
            break;
        case PlaySpeedModeTriple:
            player.playbackRate = 3.0;
            break;
        case PlaySpeedModeQuad:
            player.playbackRate = 4.0;
            break;
            
        default:
            player.playbackRate = 1;
            NSLog(@"Error change speed Mode %lu", speedMode);
            break;
    }
}
- (void)changeScaleMode:(PlayScaleMode)scaleMode {
    NSLog(@"onPanelChangeScaleMode %lu", scaleMode);
    switch (scaleMode) {
        case PlayScaleModeRatio:
            player.scalingMode = IJKMPMovieScalingModeAspectFit;
            break;
        case PlayScaleModeClip:
            player.scalingMode = IJKMPMovieScalingModeAspectFill;
            break;
        case PlayScaleModeStretch:
            player.scalingMode = IJKMPMovieScalingModeFill;
            break;

        default:
            break;
    }
}
@end
