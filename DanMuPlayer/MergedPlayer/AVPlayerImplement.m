//
//  AVPlayerImplement.m
//  DanMuPlayer
//
//  Created by zfu on 2019/4/5.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "AVPlayerImplement.h"

@interface AVPlayerImplement() {
    AVPlayer *player;
    BOOL paused;
    id timeObserver;
    BOOL stopped;
}
@end

@implementation AVPlayerImplement
@synthesize delegate;
@synthesize videoSize;
@synthesize videoView;

- (instancetype)init {
    self = [super init];
    return self;
}

- (NSTimeInterval)currentTime {
    if (player.currentItem) {
        return CMTimeGetSeconds(player.currentItem.currentTime);
    }
    return 0;
}

- (NSTimeInterval)duration {
    if (player.currentItem) {
        return CMTimeGetSeconds(player.currentItem.duration);
    }
    return 0;
}

- (void)empty {
    if (self->player.currentItem) {
        [self->player.currentItem cancelPendingSeeks];
        [self->player.currentItem.asset cancelLoading];
        @try{
            [self->player.currentItem removeObserver:self forKeyPath:@"status" context:nil];
        } @catch(id anException){}
    }
    [self->player replaceCurrentItemWithPlayerItem:nil];
}

- (void)pause {
    [player pause];
}

- (void)play {
    [player play];
}

- (void)playVideo:(NSString *)url
        withTitle:(NSString *)title
          withImg:(NSString *)img
   withDesciption:(NSString *)desc
          options:(NSMutableDictionary *)options
              mp4:(BOOL)mp4
   withResumeTime:(CGFloat)resumeTime {
    stopped = NO;
    AVURLAsset *asset = nil;
    NSURL *u = [NSURL URLWithString:url];
    NSDictionary *headers = nil;
    if ([options.allKeys containsObject:@"headers"]) {
        headers = [options objectForKey:@"headers"];
    }
    if (headers) {
        asset = [AVURLAsset URLAssetWithURL:u
                                    options:@{@"AVURLAssetHTTPHeaderFieldsKey": headers}];
    } else {
        asset = [AVURLAsset assetWithURL:u];
    }
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    player = [AVPlayer playerWithPlayerItem:item];
    self.avPlayerViewController = AVPlayerViewController.new;
    self.avPlayerViewController.delegate = self;
    self.avPlayerViewController.videoGravity = AVLayerVideoGravityResizeAspect;
    self.avPlayerViewController.showsPlaybackControls = NO;
    self.videoView = self.avPlayerViewController.view;
    self.avPlayerViewController.player = player;
    
    [item addObserver:self
           forKeyPath:@"status"
              options:NSKeyValueObservingOptionNew
              context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemFailedToPlayToEndTime:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification
                                               object:item];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidToPlayToEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:item];
    [player addObserver:self
             forKeyPath:@"rate"
                options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                context:nil];
    [player addObserver:self
             forKeyPath:@"timeControlStatus"
                options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                context:nil];
    [item addObserver:self
           forKeyPath:@"presentationSize"
              options:NSKeyValueObservingOptionNew
              context:nil];
    __weak typeof(self) weakSelf = self;
    timeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        NSTimeInterval current = CMTimeGetSeconds(time);
        NSTimeInterval duration = CMTimeGetSeconds(weakSelf.avPlayerViewController.player.currentItem.duration);
        if (current > duration) current=duration;
        NSLog(@"time %.2f/%.2f", current, duration);
        if (weakSelf.delegate && current > 0.0f) {
            NSTimeInterval playable = [weakSelf playableTime];
            [weakSelf.delegate updateProgress:current playableTime:playable buffering:NO total:duration];
        }
    }];
    [player setActionAtItemEnd:AVPlayerActionAtItemEndNone];
}

- (void)playerItemDidToPlayToEnd:(NSNotification *)notification
{
    if (self.delegate) {
        [self empty];
        @try{
            [self->player removeObserver:self forKeyPath:@"rate" context:nil];
        } @catch(id anException){}
        @try{
            [player.currentItem removeObserver:self forKeyPath:@"presentationSize"];
        } @catch(id anException){}
        @try{
            [self->player removeTimeObserver:self->timeObserver];
        } @catch(id anException){}
        if (self.delegate) {
            [self.delegate onEnd];
            self.delegate = nil;
        }
    }
}

- (void)playerItemFailedToPlayToEndTime:(NSNotification *)notification
{
    NSError *error = notification.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey];
    NSLog(@"error %@", error.localizedDescription);
}

- (NSTimeInterval)playableTime {
    if (player.currentItem && player.currentItem.loadedTimeRanges.count>0) {
        NSValue *last = player.currentItem.loadedTimeRanges.lastObject;
        CMTimeRange range = last.CMTimeRangeValue;
        NSTimeInterval end = CMTimeGetSeconds(range.start) + CMTimeGetSeconds(range.duration);
        return end;
    }
    return 0;
}

- (void)seekToTime:(NSTimeInterval)time {
    [player seekToTime:CMTimeMake(time, 1)];
}

- (void)stop {
    [self empty];
    @try{
        [self->player removeObserver:self forKeyPath:@"rate" context:nil];
    } @catch(id anException){}
    @try{
        [player.currentItem removeObserver:self forKeyPath:@"presentationSize"];
    } @catch(id anException){}
    @try{
        [self->player removeTimeObserver:self->timeObserver];
    } @catch(id anException){}
    if (self.delegate) {
        [self.delegate onEnd];
        self.delegate = nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"observeValueForKeyPath %@", keyPath);
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *playerItem = (AVPlayerItem*)object;
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            if (self.delegate) {
            }
        } else if (playerItem.status == AVPlayerItemStatusFailed) {
            if (self.delegate) {
                [self.delegate onError:playerItem.error.localizedDescription];
            }
            NSLog(@"Item is failed to play error %@ %@ suggestion %@", playerItem.error.localizedDescription, playerItem.error.localizedFailureReason, playerItem.error.localizedRecoverySuggestion);
        } else if (playerItem.status == AVPlayerItemStatusUnknown) {
            NSLog(@"Item is unknown");
            if (self.delegate) {
                [self.delegate onError:@"unknown error"];
            }
        }
    } else if ([keyPath isEqualToString:@"rate"]) {
        NSLog(@"current rate %.2f", player.rate);
    } else if ([keyPath isEqualToString:@"timeControlStatus"]) {
        if (player.timeControlStatus == AVPlayerTimeControlStatusPaused) {
            NSLog(@"timeControlStatus paused");
            if (self.delegate) {
                [self.delegate onPause];
            }
        } else if (player.timeControlStatus == AVPlayerTimeControlStatusPlaying) {
            NSLog(@"timeControlStatus playing");
            if (self.delegate) {
                [self.delegate onPlay];
                [self.delegate stopBufferring];
            }
        } else if (player.timeControlStatus == AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate) {
            NSLog(@"timeControlStatus WaitingToPlayAtSpecifiedRate");
        }
    } else if ([keyPath isEqualToString:@"presentationSize"]) {
        CGSize size = player.currentItem.presentationSize;
        NSLog(@"presentationSize change %.2f %.2f", size.width, size.height);
        if (self.delegate) {
            [self.delegate onVideoSizeChanged:size];
        }
    }
}

- (void)changeSpeedMode:(PlaySpeedMode)speedMode {
    NSLog(@"onPanelChangeSpeedMode %lu", speedMode);
    CGFloat speed = 1;
    switch (speedMode) {
        case PlaySpeedModeQuarter:
            speed = 0.25;
            break;
        case PlaySpeedModeHalf:
            speed = 0.5;
            break;
        case PlaySpeedModeNormal:
            speed = 1;
            break;
        case PlaySpeedModeDouble:
            speed = 2.0;
            break;
        case PlaySpeedModeTriple:
            speed = 3.0;
            break;
        case PlaySpeedModeQuad:
            speed = 4.0;
            break;
            
        default:
            speed = 1;
            NSLog(@"Error change speed Mode %lu", speedMode);
            break;
    }
    //change playback speed
    player.rate = speed;
}

- (void)changeScaleMode:(PlayScaleMode)scaleMode {
    NSLog(@"onPanelChangeScaleMode %lu", scaleMode);
    switch (scaleMode) {
        case PlayScaleModeRatio:
            self.avPlayerViewController.videoGravity = AVLayerVideoGravityResizeAspect;
            break;
        case PlayScaleModeClip:
            self.avPlayerViewController.videoGravity = AVLayerVideoGravityResizeAspectFill;
            break;
        case PlayScaleModeStretch:
            self.avPlayerViewController.videoGravity = AVLayerVideoGravityResize;
            break;
        default:
            break;
    }
}
@end
