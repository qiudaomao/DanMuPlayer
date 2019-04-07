//
//  VideoPlayerViewController.m
//  The UI front-end of DanMuPlayer
//
//  Created by zfu on 2019/3/15.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "VideoPlayerViewController.h"
#import "IJKPlayerImplement.h"
#import "MPVPlayerImplement.h"
#import "AVPlayerImplement.h"
#import "SiriRemoteGestureRecognizer.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AudioInfoViewController.h"
#import "TopPanelViewController.h"
#import "CurrentMediaInfo.h"
#import "./TopPanel/PanelControlData.h"
#import "./LeftPanel/LeftPanelViewController.h"
#import "./RightPanel/RightPanelViewController.h"
#import "PushDownAnimator.h"
#import "PopUPAnimator.h"
#import "PushLeftRightAnimator.h"
#import "PopLeftRightAnimator.h"
#import "ContinuePlayViewController.h"

typedef NS_ENUM(NSUInteger, HUDKeyEvent) {
    HUDKeyEventMenu,
    HUDKeyEventPlayPause,
    HUDKeyEventUp,
    HUDKeyEventDown,
    HUDKeyEventLeft,
    HUDKeyEventRight,
    HUDKeyEventSelect,
    HUDKeyEventUnknown,
};

@interface VideoPlayerViewController () {

    UIProgressView *_progress;
    StrokeUILabel *_title;
    StrokeUILabel *_currentTime;
    StrokeUILabel *_leftTime;
    StrokeUILabel *_statLabel;
    StrokeUILabel *_timeLabel;
    StrokeUILabel *_presentSizeLabel;
    StrokeUILabel *timeLabel;
    UIActivityIndicatorView *loadingIndicator;
    UIVisualEffectView *loadingIndicatorBG;
    UIImageView *pointImageView;
    UIImageView *pauseImageView;
    StrokeUILabel *pauseTimeLabel;
    StrokeUILabel *_pointTime;
    StrokeUILabel *subTitle;
    StrokeUILabel *errorTitle;
    CGPoint indicatorStartPoint;
    
    UIView *hudLayer;
    NSTimer *hideTimer;
    BOOL isPlaying;
    BOOL isError;
    
    SiriRemoteGestureRecognizer *siriRemoteRecognizer;
    NSMutableArray<UITapGestureRecognizer*> *recognizers;
    CGPoint prevPanLocation;
    CGPoint beganPanLocation;
    CADisplayLink *displayLink;
    
    NSTimer *hudHideTimer;
    UIView *hudView;
    BOOL inHiddenChangeProgress;
    CGRect seekImageFrame;
    NSTimeInterval seekTargetTime;
    CurrentMediaInfo *currentMediaInfo;

    UISwipeGestureRecognizer *swipeGestureRecognizer;
    PanelControlData *controlData;
    BOOL playReady;
    DMPlaylist *playlist;
    BOOL stopped;
    BOOL siriRemoteActive;
    BOOL siriRemoteClicked;
    BOOL siriRemoteCancelled;
    BOOL siriRemoteEnd;
    
    PushDownAnimator *pushDownAnimator;
    PopUPAnimator *popUpAnimator;
    PushLeftRightAnimator *pushLeftAnimator;
    PopLeftRightAnimator *popLeftAnimator;
    PushLeftRightAnimator *pushRightAnimator;
    PopLeftRightAnimator *popRightAnimator;
    
    BOOL processed;
    NSTimeInterval _resumeTime;
    NSTimeInterval _changeSourceResumeTime;
    BOOL preventQuitUI;
    NSInteger targetMediaIndex;
    NSMutableArray *playURLs;
    NSInteger playURLIndex;
    RightPanelViewController *rightVC;
    LeftPanelViewController *leftVC;
}

@property (nonatomic, readwrite, strong) id<PlayerProtocol> player_;
@end

@implementation VideoPlayerViewController
@synthesize delegate;
@synthesize danmuView;
@synthesize buttonClickCallback;
@synthesize buttonFocusIndex;
@synthesize timeMode;
@synthesize playerType;
@synthesize navController;
@synthesize parser;
@synthesize currentMediaIndex;
@synthesize playlist;
@synthesize player_ = _player_;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    playURLs = [NSMutableArray array];
    playURLIndex = 0;
    preventQuitUI = NO;
    _resumeTime = 0;
    pushDownAnimator = PushDownAnimator.new;
    popUpAnimator = PopUPAnimator.new;
    pushLeftAnimator = [[PushLeftRightAnimator alloc] initWithDirection:YES];
    popLeftAnimator = [[PopLeftRightAnimator alloc] initWithDirection:YES];
    pushRightAnimator = [[PushLeftRightAnimator alloc] initWithDirection:NO];
    popRightAnimator = [[PopLeftRightAnimator alloc] initWithDirection:NO];
    siriRemoteActive = NO;
    siriRemoteClicked = NO;
    siriRemoteCancelled = NO;
    siriRemoteEnd = NO;
    stopped = NO;
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress)];
    displayLink.paused = YES;
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    self.view.backgroundColor = UIColor.blackColor;
    _player_ = nil;
    [self initHud];
    inHiddenChangeProgress = NO;
    seekTargetTime = -1;
    currentMediaInfo = CurrentMediaInfo.new;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
//    AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
//    for (AVAudioSessionPortDescription *output in currentRoute.outputs) {
//        NSLog(@"audio %@", output.portName);
//    }
    controlData = PanelControlData.new;
    controlData.speedMode = PlaySpeedModeNormal;
    controlData.scaleMode = PlayScaleModeRatio;
    controlData.danmuMode = PlayDanMuOn;
    playReady = NO;
}

- (void)applicationWillResignActive:(NSNotification*)note {
    if (isPlaying) {
        [_player_ pause];
    }
}

- (void)updateProgress
{
    //here should read currentTime
//    [self.delegate updateProgressHD];
    [self.delegate timeDidChangedHD:_player_.currentTime];
    [self updatePointTime:_player_.currentTime duration:_player_.duration];
    [self.danmu updateFrame];
}

- (void)initHud
{
    NSLog(@"initHud");
    hudView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:hudView];
    CGSize size = [self.view bounds].size;
    
    _danmu = [[DanMuLayer alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_danmu];
//    _danmu = [[DanMuView alloc] initWithFrame:self.view.bounds];
    _danmu.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    subTitle = [[StrokeUILabel alloc] init];
    subTitle.textColor = [UIColor whiteColor];
    subTitle.strokeColor = [UIColor blackColor];
    subTitle.frame = CGRectMake(0, size.height-180, size.width, 80);
    subTitle.font = [UIFont systemFontOfSize:60];
    subTitle.textAlignment = NSTextAlignmentCenter;
    subTitle.text = @"";
    
    errorTitle = [[StrokeUILabel alloc] init];
    errorTitle.textColor = [UIColor redColor];
    errorTitle.strokeColor = [UIColor clearColor];
    errorTitle.frame = CGRectMake(0, size.height/2-40, size.width, 80);
    errorTitle.font = [UIFont systemFontOfSize:60];
    errorTitle.textAlignment = NSTextAlignmentCenter;
    errorTitle.text = @"";

    hudLayer = [[UIView alloc] init];
    hudLayer.frame = CGRectMake(0, size.height-200, size.width, 200);
    
    UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    loadingIndicatorBG = [[UIVisualEffectView alloc] initWithEffect:effect];
    loadingIndicatorBG.frame = CGRectMake(size.width/2 - 100/2, size.height/2 - 100/2, 100, 100);
    loadingIndicatorBG.layer.cornerRadius = 20.0f;
    loadingIndicatorBG.clipsToBounds = YES;
    
    loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    CGSize bgSize = loadingIndicatorBG.frame.size;
    CGSize indicatorSize = loadingIndicator.frame.size;
    loadingIndicator.frame = CGRectMake(bgSize.width/2-indicatorSize.width/2,
                                        bgSize.height/2-indicatorSize.height/2,
                                        indicatorSize.width,
                                        indicatorSize.height);
    [loadingIndicator setHidden:NO];
    [loadingIndicator startAnimating];
    [loadingIndicatorBG.contentView addSubview:loadingIndicator];
    
    _timeLabel = [[StrokeUILabel alloc] initWithFrame:CGRectMake(size.width-280, 60, 200, 60)];
    _timeLabel.text = @"";
    _timeLabel.textAlignment = NSTextAlignmentRight;
    _timeLabel.font = [UIFont systemFontOfSize:50];//[UIFont fontWithName:@"Menlo" size:50];
    _timeLabel.textColor = [UIColor whiteColor];
    
    _presentSizeLabel = [[StrokeUILabel alloc] initWithFrame:CGRectMake(80, 60, 300, 60)];
    _presentSizeLabel.text = @"";
    _presentSizeLabel.font = [UIFont systemFontOfSize:50];//[UIFont fontWithName:@"Menlo" size:50];
    _presentSizeLabel.textColor = [UIColor whiteColor];
    
    [hudView addSubview:hudLayer];
    [hudView addSubview:_timeLabel];
    [hudView addSubview:_presentSizeLabel];
    
    _progress = [[UIProgressView alloc] init];
    _progress.frame = CGRectMake(80, 110, size.width-160, 10);
    _progress.progress = 0.0f;
    //_progress.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1];
    _progress.tintColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.8];
    [hudLayer addSubview:_progress];
    [_progress setProgress:0];
    _title = [[StrokeUILabel alloc] init];
    _title.text = @"";
    _title.frame = CGRectMake(80, 60, size.width-360, 20);
    _title.textColor = [UIColor whiteColor];
    [hudLayer addSubview:_title];
    
    _currentTime = [[StrokeUILabel alloc] init];
    _currentTime.textColor = [UIColor whiteColor];
    _currentTime.frame = CGRectMake(80, 135, 160, 40);
    _currentTime.text = @"";
    _currentTime.font = [UIFont fontWithName:@"Menlo" size:34];
    _currentTime.textAlignment = NSTextAlignmentLeft;
    [hudLayer addSubview:_currentTime];
    
    _pointTime = [[StrokeUILabel alloc] init];
    _pointTime.textColor = [UIColor whiteColor];
    _pointTime.frame = CGRectMake(80, 135, 160, 40);
    _pointTime.text = @"";
    _pointTime.font = [UIFont fontWithName:@"Menlo" size:34];
    _pointTime.textAlignment = NSTextAlignmentCenter;
    _pointTime.hidden = YES;
    [hudLayer addSubview:_pointTime];
    
    _leftTime = [[StrokeUILabel alloc] init];
    _leftTime.textColor = [UIColor whiteColor];
    _leftTime.frame = CGRectMake(size.width-160-80, 135, 160, 40);
    _leftTime.text = @"";
    _leftTime.font = [UIFont systemFontOfSize:34];//[UIFont fontWithName:@"Menlo" size:34];
    _leftTime.textAlignment = NSTextAlignmentRight;
    [hudLayer addSubview:_leftTime];
    
    pointImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"indicator.png"]];
    pointImageView.frame = CGRectMake(80, 110, 2, 10);
    pointImageView.backgroundColor = [UIColor whiteColor];
    indicatorStartPoint = pointImageView.frame.origin;
    [hudLayer addSubview:pointImageView];
    
    pauseImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"indicator.png"]];
    pauseImageView.frame = CGRectMake(80, 80, 2, 40);
    pauseImageView.backgroundColor = [UIColor whiteColor];
    indicatorStartPoint = pauseImageView.frame.origin;
    [hudLayer addSubview:pauseImageView];
    pauseImageView.hidden = YES;
    
    pauseTimeLabel = [[StrokeUILabel alloc] init];
    pauseTimeLabel.textColor = [UIColor whiteColor];
    pauseTimeLabel.frame = CGRectMake(80, 42, 160, 40);
    pauseTimeLabel.text = @"";
    pauseTimeLabel.font = [UIFont systemFontOfSize:34];//[UIFont fontWithName:@"Menlo" size:34];
    pauseTimeLabel.textAlignment = NSTextAlignmentCenter;
    [hudLayer addSubview:pauseTimeLabel];
    pauseTimeLabel.hidden = YES;
    isPlaying = NO;
    isError = NO;
    
    [self.view insertSubview:loadingIndicatorBG aboveSubview:hudView];
    [self.view insertSubview:subTitle aboveSubview:hudView];
    [self.view insertSubview:errorTitle aboveSubview:subTitle];
}

- (void)updateProgress:(NSTimeInterval)current playableTime:(NSTimeInterval)playableTime buffering:(BOOL)buffering total:(NSTimeInterval)total {
    currentMediaInfo.duration = (total<0.1)? -1:total;
    if (total > 0.001) {
        _currentTime.text = [self timeToStr:current];
        _leftTime.text = [self timeToStr:(total-current)];
        _progress.hidden = NO;
    } else {
        _currentTime.text = @"";
        _leftTime.text = @"";
        _progress.hidden = YES;
    }
    if (total > 0.0f) _progress.progress = playableTime / total;
    else _progress.progress = 0.0f;
    [self updatePointTime:current duration:total];
    if (self.delegate) {
        [self.delegate timeDidChanged:current duration:total];
        NSLog(@"timeDidChanged %.2f %.2f", current, total);
    }
    [self updateNowPlaying:current duration:total];
    [self updateTimeClock];
}

- (NSString*)timeToStr:(int)time {
    int min = time/60;
    int sec = time-min*60;
    return [NSString stringWithFormat:@"%02d:%02d", min, sec];
}

- (void)resetHideTimer {
    if (hideTimer && hideTimer.isValid) {
        [hideTimer invalidate];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self->hudView.hidden = NO;
        self->hudView.alpha = 1.0;
        self->hideTimer = [NSTimer timerWithTimeInterval:4.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
            self->inHiddenChangeProgress = YES;
            [UIView animateWithDuration:0.5 animations:^{
                [self->hudView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                self->hudView.hidden = YES;
                self->inHiddenChangeProgress = NO;
            }];
        }];
        [[NSRunLoop currentRunLoop] addTimer:self->hideTimer forMode:NSRunLoopCommonModes];
    });
}

- (void)stopAndShowTimer {
    if (hideTimer && hideTimer.isValid) {
        [hideTimer invalidate];
    }
    hudView.hidden = NO;
    inHiddenChangeProgress = YES;
    [UIView animateWithDuration:0.5 animations:^{
        [self->hudView setAlpha:1.0f];
    } completion:^(BOOL finished) {
        self->hudView.hidden = NO;
        self->inHiddenChangeProgress = NO;
    }];
}

- (void)stopAndHideTimer {
    if (hideTimer && hideTimer.isValid) {
        [hideTimer invalidate];
    }
    hudView.hidden = NO;
    inHiddenChangeProgress = YES;
    [UIView animateWithDuration:0.5 animations:^{
        [self->hudView setAlpha:0.0f];
    } completion:^(BOOL finished) {
        self->hudView.hidden = YES;
        self->inHiddenChangeProgress = NO;
    }];
}

- (void)stopHideTimer {
    if (hideTimer && hideTimer.isValid) {
        [hideTimer invalidate];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->hudView setAlpha:1.0];
        self->hudView.hidden = NO;
    });
}

- (void)updatePointTime: (CGFloat)time duration: (CGFloat)duration
{
    pointImageView.hidden = (duration<0.1);
    //NSLog(@"time %.2f %.2f %.2f", offset, time, (offset+time));
    if (pointImageView && duration !=0) {
        CGFloat x = indicatorStartPoint.x + _progress.frame.size.width * (time/duration);
        CGRect frame = pointImageView.frame;
        CGRect pauseframe = pauseImageView.frame;
        CGRect pauseTimeFrame = pauseTimeLabel.frame;
        frame.origin.x = x;
        pauseframe.origin.x = x;
        pauseTimeFrame.origin.x = x-78;
        pointImageView.frame = frame;
        pauseImageView.frame = pauseframe;
        pauseTimeLabel.frame = pauseTimeFrame;
        _pointTime.text = [self timeToStr:time];
        seekImageFrame = pauseframe;
        if (x > (80+48) && x < (80+_progress.frame.size.width-50)) {
            _pointTime.hidden = NO;
            _currentTime.hidden = YES;
            CGRect pointTimeFrame = _pointTime.frame;
            pointTimeFrame.origin.x = x-77;
            _pointTime.frame = pointTimeFrame;
            //pointImageView.frame = frame;
        }
        if (x < (80+48)) {
            _currentTime.hidden = NO;
            _pointTime.hidden = YES;
        }
        if (x > _progress.frame.size.width+80-180) {
            _leftTime.hidden = YES;
        } else {
            _leftTime.hidden = NO;
        }
    }
}

- (void)onKeyPressed:(HUDKeyEvent)event {
    switch (event) {
        case HUDKeyEventMenu:
            if (!isPlaying && !isError && playReady) {
                [_player_ play];
            } else {
                [self stop];
            }
            break;
        case HUDKeyEventLeft:
            if (isPlaying) {
                if (_player_.currentTime > 10) {
                    [_player_ seekToTime:_player_.currentTime-10.0];
                } else {
                    [_player_ seekToTime:0];
                }
            } else if (playReady) {
                CGRect frame = seekImageFrame;
                CGRect pauseLabelFrame = pauseTimeLabel.frame;
                frame.origin.x -= 30;
                NSTimeInterval duration = _player_.duration;
                if (frame.origin.x < _progress.frame.origin.x) {
                    frame.origin.x = _progress.frame.origin.x;
                } else if (frame.origin.x > _progress.frame.origin.x + _progress.frame.size.width) {
                    frame.origin.x = _progress.frame.origin.x + _progress.frame.size.width;
                }
                NSTimeInterval targetTime = duration * (frame.origin.x - _progress.frame.origin.x) / _progress.frame.size.width;
                seekTargetTime = targetTime;
                pauseTimeLabel.text = [self timeToStr:targetTime];
                pauseLabelFrame.origin.x = frame.origin.x - 78;
                pauseImageView.frame = frame;
                pauseTimeLabel.frame = pauseLabelFrame;
                seekImageFrame = frame;
            }
            break;
        case HUDKeyEventDown:
            [self presentInfoPanel];
            break;
        case HUDKeyEventUp:
            [self presentLeftPanel];
            break;
        case HUDKeyEventRight:
            if (isPlaying) {
                if (_player_.currentTime < _player_.duration - 10) {
                    [_player_ seekToTime:_player_.currentTime+10.0];
                }
            } else if (playReady){
                CGRect frame = seekImageFrame;
                CGRect pauseLabelFrame = pauseTimeLabel.frame;
                frame.origin.x += 30;
                NSTimeInterval duration = _player_.duration;
                if (frame.origin.x < _progress.frame.origin.x) {
                    frame.origin.x = _progress.frame.origin.x;
                } else if (frame.origin.x > _progress.frame.origin.x + _progress.frame.size.width) {
                    frame.origin.x = _progress.frame.origin.x + _progress.frame.size.width;
                }
                NSTimeInterval targetTime = duration * (frame.origin.x - _progress.frame.origin.x) / _progress.frame.size.width;
                seekTargetTime = targetTime;
                pauseTimeLabel.text = [self timeToStr:targetTime];
                pauseLabelFrame.origin.x = frame.origin.x - 78;
                pauseImageView.frame = frame;
                pauseTimeLabel.frame = pauseLabelFrame;
                seekImageFrame = frame;
            }
            break;
        case HUDKeyEventPlayPause:
        case HUDKeyEventSelect:
            if (!isError) {
                NSLog(@"isPlaying %@", @(isPlaying));
                if (isPlaying) {
                    [self pause];
                } else {
                    [self play];
                }
            }
            break;
            
        default:
            break;
    }
}

-(UIViewController *) topMostController {
    UIViewController *topController = UIApplication.sharedApplication.keyWindow.rootViewController;
    while (topController.presentedViewController){
        topController=topController.presentedViewController;
    }
    return topController;
}

-(void)presentInfoPanel {
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.fuzhuo.DanMuPlayer"];
    TopPanelViewController *topPanelVC = [[TopPanelViewController alloc] initWithNibName:@"TopPanelViewController" bundle:bundle];
    topPanelVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    topPanelVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [topPanelVC setCurrentMediaInfo:currentMediaInfo];
    topPanelVC.delegate = self;
    topPanelVC.controlData = controlData;
    if (playlist) {
//        __weak typeof(self) weakSelf = self;
        [topPanelVC setupPlayList:playlist clickCallBack:^void(NSInteger index) {
            NSLog(@"button list click %lu", index);
            if (self->targetMediaIndex != index) {
                self->preventQuitUI = YES;
                //set target
                self->targetMediaIndex = index;
                [self->playURLs removeAllObjects];
                self->currentMediaIndex = 0;
                [self->_player_ stop];
            } else {
                NSLog(@"select the same item, no need to change");
            }
        } focusIndex:self.currentMediaIndex];
    }
    UIViewController *top = [self topMostController];
    topPanelVC.transitioningDelegate = self;
    [top presentViewController:topPanelVC animated:YES completion:^{
    }];
}

- (void)presentLeftPanel {
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.fuzhuo.DanMuPlayer"];
    if (leftVC == nil) {
        leftVC = [[LeftPanelViewController alloc] initWithNibName:@"LeftPanelViewController" bundle:bundle];
        leftVC.transitioningDelegate = self;
        leftVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        leftVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        leftVC.title = @"播放列表";
    }
    [leftVC setupPlayList:playlist clickCallBack:^void(NSInteger index) {
        NSLog(@"button list click %lu", index);
        if (self->targetMediaIndex != index) {
            self->preventQuitUI = YES;
            //set target
            self->targetMediaIndex = index;
            [self->playURLs removeAllObjects];
            self->currentMediaIndex = 0;
            [self->_player_ stop];
        } else {
            NSLog(@"select the same item, no need to change");
        }
    } currentIndex:currentMediaIndex];
    UIViewController *top = [self topMostController];
    [top presentViewController:leftVC animated:YES completion:^{
    }];
}

- (void)presentRightPanel {
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.fuzhuo.DanMuPlayer"];
    if (rightVC == nil) {
        rightVC = [[RightPanelViewController alloc] initWithNibName:@"RightPanelViewController" bundle:bundle];
        rightVC.transitioningDelegate = self;
        rightVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        rightVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        rightVC.title = @"播放链接";
        [rightVC setupPlayURLs:playURLs currentIndex:playURLIndex];
        __weak typeof(self) weakSelf = self;
        [rightVC setCallBack:^(NSInteger index) {
//            NSLog(@"right panel select from %lu to %lu", self->playURLIndex, index);
            self->playURLIndex = index;
            if (self->_player_.currentTime > 0 && self->isPlaying) {
                NSTimeInterval sTime = weakSelf.player_.currentTime;
                self->_changeSourceResumeTime = sTime;
                NSLog(@"_changeSourceResumeTime is %.2f", sTime);
            } else {
                NSLog(@"not saving current change source resume time");
            }
            self->preventQuitUI = YES;
            [weakSelf.player_ stop];
        }];
    }
    UIViewController *top = [self topMostController];
    [top presentViewController:rightVC animated:YES completion:^{
    }];
}

-(void)pause {
    if (_player_) {
        [self.delegate playStateDidChanged:PS_PAUSED];
        [_player_ pause];
    }
}

-(void)play {
    if (_player_) {
        [self.delegate playStateDidChanged:PS_PLAYING];
        [_player_ play];
        //check seek
        if (seekTargetTime > 0) {
            [_player_ seekToTime:seekTargetTime];
            seekTargetTime = -1;
        }
    }
}

-(void)stop {
    if (stopped) return;
    stopped = YES;
    if (_player_) {
        [self.delegate playStateDidChanged:PS_FINISH];
        [_player_ stop];
    }
}

-(void)seekToTime:(CGFloat)time {
    if (_player_) {
        [_player_ seekToTime:time];
    }
}

-(void)downloadArtWork {
    if ([currentMediaInfo.imgURL hasPrefix:@"http"]) {
        NSURL *url = [NSURL URLWithString:currentMediaInfo.imgURL];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setValue:@"" forHTTPHeaderField:@"User-Agent"];
        NSURLSession *session = NSURLSession.sharedSession;
        NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            UIImage *image = [UIImage imageNamed:@"lazycat"];
            if (!error && data) {
                image = [UIImage imageWithData:data];
            } else {
                NSLog(@"Error download artwork from URL %@", self->currentMediaInfo.imgURL);
            }
            self->currentMediaInfo.artwork = [[MPMediaItemArtwork alloc] initWithBoundsSize:CGSizeMake(200, 120) requestHandler:^UIImage * _Nonnull(CGSize size) {
                UIGraphicsBeginImageContextWithOptions(CGSizeMake(200, 120), NO, 0.0);
                [image drawInRect:CGRectMake(0, 0, 200, 120)];
                UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                self->currentMediaInfo.image = newImage;
                NSLog(@"donwload artwork successfully from %@", self->currentMediaInfo.imgURL);
                return newImage;
            }];
        }];
        [task resume];
    } else {
        NSLog(@"Error download artwork from URL %@", currentMediaInfo.imgURL);
    }
}

-(void)playVideo:(NSString*)url
       withTitle:(NSString*)title
         withImg:(NSString*)img
  withDesciption:(NSString*)desc
         options:(NSMutableDictionary*)options
             mp4:(BOOL)mp4
  withResumeTime:(CGFloat)resumeTime {
    currentMediaInfo.title = title;
    currentMediaInfo.imgURL = img;
    //download image
    currentMediaInfo.description = desc;
    currentMediaInfo.resolution = @" ";
    currentMediaInfo.fps = -1;
    currentMediaInfo.duration = -1;
    [self downloadArtWork];
    if (_player_) {
        //remove anything of previous player
        NSLog(@"Error, _player_ should already destroy before new play");
        return;
    }
    if ([options.allKeys containsObject:@"player"]) {
        playerType = [options objectForKey:@"player"];
    }
    NSLog(@"playVideo with player type %@", playerType);
    if ([playerType isEqualToString:@"IJKPlayer"]) {
        _player_ = [[IJKPlayerImplement alloc] init];
    } else if ([playerType isEqualToString:@"MPVPlayer"]) {
        _player_ = [[MPVPlayerImplement alloc] init];
    } else if ([playerType isEqualToString:@"AVPlayer"]){
        _player_ = [[AVPlayerImplement alloc] init];
    } else {
        _player_ = [[IJKPlayerImplement alloc] init];
    }
    [_player_ playVideo:url
             withTitle:title
               withImg:img
        withDesciption:desc
               options:options
                   mp4:mp4
        withResumeTime:resumeTime];
    _player_.delegate = self;
    [self.view insertSubview:_player_.videoView belowSubview:hudView];
    _player_.videoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _player_.videoView.frame = self.view.bounds;
    if (resumeTime > 0) {
        _resumeTime = resumeTime;
        [_player_ play];
    } else {
        [_player_ play];
    }
    [self setupRemoteCommand];
}

- (void)showContinuePlay:(NSTimeInterval)resumeTime {
    NSLog(@"showContinuePlay %.2f", resumeTime);
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.fuzhuo.DanMuPlayer"];
    ContinuePlayViewController *cpVC = [[ContinuePlayViewController alloc] initWithNibName:@"ContinuePlayViewController" bundle:bundle];
    cpVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    cpVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    NSString *ts = [self timeToStr:resumeTime];
    cpVC.title = [NSString stringWithFormat:@"从%@处继续播放", ts];
    cpVC.resume = ^{
        NSLog(@"resume");
        [self seekToTime:resumeTime];
        [self resetHideTimer];
    };
    UIViewController *top = [self topMostController];
    [top presentViewController:cpVC animated:YES completion:^{
    }];
}

-(void)playItemAtIndex:(NSInteger)index {
    NSLog(@"playItemAtIndex %lu", index);
    if (index < self.playlist.count) {
        DMMediaItem *item = self.playlist.items[index];
        self.currentMediaIndex = index;
        targetMediaIndex = index;
        if (playURLs.count==0 && self.parser && !self.parser.isUndefined && !self.parser.isNull) {
            NSLog(@"no playURLs try get from parser");
            [self.parser.context[@"setTimeout"] callWithArguments:@[self.parser, @(0), item, @(index),
                                                                    ^void (JSValue *error, JSValue *playableURLs, NSInteger preferedIndex, JSValue *webURL) {
                if (error && !error.isNull && error.isString) {
                    NSLog(@"parser error %@", error.toString);
                    [self onError:error.toString];
                } else if (playableURLs && !playableURLs.isNull && playableURLs.isArray && playableURLs.toArray.count>preferedIndex) {
                    [self->playURLs removeAllObjects];
                    for (NSDictionary *item in playableURLs.toArray) {
                        [self->playURLs addObject:item];
                    }
                    if (self->rightVC) {
                        [self->rightVC setupPlayURLs:self->playURLs currentIndex:preferedIndex];
                        [self->rightVC reload];
                    }
                    self->playURLIndex = preferedIndex;
                    JSValue *value = [playableURLs objectAtIndexedSubscript:preferedIndex];
                    NSMutableDictionary *options = [item.options mutableCopy];
                    NSString *url = item.url;
                    if ([value hasProperty:@"url"]) {
                        url = [value objectForKeyedSubscript:@"url"].toString;
                    }
                    if ([value hasProperty:@"options"]) {
                        options = [[value objectForKeyedSubscript:@"options"].toDictionary mutableCopy];
                    }
                    [self playVideo:url
                          withTitle:item.title
                            withImg:item.artworkImageURL
                     withDesciption:item.description
                            options:options
                                mp4:item.mp4
                     withResumeTime:item.resumeTime];
                } else {
                    NSLog(@"Error, should not coming here");
                }
                if (webURL && !webURL.isNull){
                    //add to parser
                }
            }]];
        } else {
            if (playURLs.count > playURLIndex) {
                NSLog(@"already have playURLs not need to parser");
                NSDictionary *dict = [playURLs objectAtIndex:playURLIndex];
                NSMutableDictionary *options = nil;
                NSString *url = item.url;
                if ([dict.allKeys containsObject:@"url"]) {
                    url = [dict objectForKey:@"url"];
                }
                if ([dict.allKeys containsObject:@"options"]) {
                    options = [dict objectForKey:@"options"];
                }
                [self playVideo:url
                      withTitle:item.title
                        withImg:item.artworkImageURL
                 withDesciption:item.description
                        options:options
                            mp4:item.mp4
                 withResumeTime:item.resumeTime];
            } else {
                NSString *url = item.url;
                if (url.length > 0) {
                    NSLog(@"direct play url from item: %@", item.url);
                    NSMutableDictionary *options = [item.options mutableCopy];
                    [playURLs addObject:@{
                                          @"url": item.url,
                                          @"name": @"默认链接",
                                          @"options": (item.options)?item.options:@{}
                                          }];
                    playURLIndex = 0;
                    [self playVideo:item.url
                          withTitle:item.title
                            withImg:item.artworkImageURL
                     withDesciption:item.description
                            options:options
                                mp4:item.mp4
                     withResumeTime:item.resumeTime];
                } else {
                    [self onError:@"No valid playable URL"];
                }
            }
        }
    }
}

-(void)addDanMu:(NSString*)content
      withStyle:(DanmuStyle)style
      withColor:(UIColor*)color
withStrokeColor:(UIColor*)bgcolor
   withFontSize:(CGFloat)fontSize {
    [self.danmu addDanMu:content
               withStyle:style
               withColor:color
         withStrokeColor:bgcolor
            withFontSize:fontSize];
}

-(void)setSubTitle:(NSString*)subTitle_ {
    subTitle.text = subTitle_;
}

-(void)setupButtonList:(DMPlaylist*)playlist_ {
    //setup here for display
    playlist = playlist_;
}

- (void)onEnd {
    isPlaying = NO;
    displayLink.paused = YES;
    [self stopHideTimer];
    if (self.delegate) {
        [self.delegate playStateDidChanged:PS_FINISH];
        self.delegate=nil;
    }
    [self clearRemoteCommand];
    MPNowPlayingInfoCenter *center = MPNowPlayingInfoCenter.defaultCenter;
    center.nowPlayingInfo = nil;
    //check if need auto play next here
    if (!preventQuitUI) {
        //check the top controller
        UIViewController *controller = [self topMostController];
        if ([controller isKindOfClass:NSClassFromString(@"VideoPlayerViewController")]) {
            [self dismissViewControllerAnimated:NO completion:^{
                NSLog(@"finish dismiss VideoPlayerViewController");
            }];
        } else {
            NSLog(@"VideoPlayerViewController not on top, not quit");
            __weak typeof(self) weakSelf = self;
            [controller dismissViewControllerAnimated:YES completion:^{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf dismissViewControllerAnimated:NO completion:^{
                        NSLog(@"finish dismiss VideoPlayerViewController");
                    }];
                });
            }];
        }
    } else {
        preventQuitUI = NO;
        NSLog(@"change preventQuitUI to NO");
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_player_.videoView removeFromSuperview];
            self->_player_ = nil;
            [weakSelf playItemAtIndex:self->targetMediaIndex];
        });
    }
}

- (void)onError:(NSString *)msg {
    isPlaying = NO;
    displayLink.paused = YES;
    [self stopHideTimer];
    if (self.delegate) {
        [self.delegate playStateDidChanged:PS_ERROR];
        self.delegate=nil;
    }
    loadingIndicatorBG.hidden = YES;
    [loadingIndicator stopAnimating];
    errorTitle.text = @"!!(╯' - ')╯︵ ┻━┻ 播放出错了";
    MPNowPlayingInfoCenter *center = MPNowPlayingInfoCenter.defaultCenter;
    center.nowPlayingInfo = nil;
}

- (void)onPause {
    isPlaying = NO;
    displayLink.paused = YES;
    [self stopHideTimer];
    if (_player_.duration > 0) {
        pauseTimeLabel.hidden = NO;
        pauseTimeLabel.text = _pointTime.text;
        pauseImageView.hidden = NO;
    }
}

- (void)onPlay {
    BOOL forceSeek = NO;
    if (_changeSourceResumeTime > 0) {
        NSLog(@"seek to %.2f for _changeSourceResumeTime", _changeSourceResumeTime);
        [_player_ seekToTime:_changeSourceResumeTime];
        forceSeek = YES;
        _changeSourceResumeTime = 0;
    }
    if (!forceSeek && _resumeTime > 0) {
        [self showContinuePlay:_resumeTime];
        _resumeTime = 0;
    }
    playReady = YES;
    isPlaying = YES;
    displayLink.paused = NO;
    [self resetHideTimer];
    dispatch_async(dispatch_get_main_queue(), ^{
        self->pauseTimeLabel.hidden = YES;
        self->pauseImageView.hidden = YES;
    });
}

- (void)setupRecognizers {
    recognizers = [NSMutableArray array];
    NSArray<NSNumber*> *types = @[@(UIPressTypeMenu),
                                  //@(UIPressTypeSelect),
                                  @(UIPressTypeUpArrow),
                                  @(UIPressTypeDownArrow),
                                  @(UIPressTypeLeftArrow),
                                  @(UIPressTypeRightArrow),
                                  @(UIPressTypePlayPause)];
    for (NSNumber *type in types) {
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(tapKey:)];
        recognizer.allowedPressTypes = @[type];
        [self.view addGestureRecognizer:recognizer];
        [recognizers addObject:recognizer];
    }
    
    //    swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(siriSwipe:)];
    //    [swipeGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionDown];
    //    [self.view addGestureRecognizer:swipeGestureRecognizer];
    
    siriRemoteRecognizer = [[SiriRemoteGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(siriTouch:)];
    siriRemoteRecognizer.delegate = self;
    [self.view addGestureRecognizer:siriRemoteRecognizer];
}

- (void)siriSwipe:(UISwipeGestureRecognizer*)sender {
    NSLog(@"siri swipe down");
    [self presentInfoPanel];
}

- (void)siriTouch:(SiriRemoteGestureRecognizer*)sender {
    //NSLog(@"taped siriRemote state: %ld %@ location %ld %@",
    //(long)sender.state, sender.stateName, (long)sender.touchLocation, sender.touchLocationName);
    NSLog(@"taped siriRemote state: %@ click %d", sender.stateName, sender.isClick);
    if (sender.state == UIGestureRecognizerStateEnded && sender.isClick) {
        //NSLog(@"taped siriRemote, location %@", sender.touchLocationName);
        if (sender.touchLocation == MMSiriRemoteTouchLocationCenter
            || sender.touchLocation == MMSiriRemoteTouchLocationUp
            || sender.touchLocation == MMSiriRemoteTouchLocationDown) {
            [self onKeyPressed:HUDKeyEventSelect];
            NSLog(@"taped select action");
        } else if (sender.touchLocation == MMSiriRemoteTouchLocationLeft) {
            [self onKeyPressed:HUDKeyEventLeft];
            NSLog(@"taped left action");
        } else if (sender.touchLocation == MMSiriRemoteTouchLocationRight) {
            [self onKeyPressed:HUDKeyEventRight];
            NSLog(@"taped right action");
        }
        siriRemoteActive = NO;
    } else if (sender.state == UIGestureRecognizerStateBegan) {
        //[self stopAndShowTimer];
        prevPanLocation = sender.location;
        beganPanLocation = sender.location;
        NSLog(@"siri remote state began");
        siriRemoteActive = YES;
        siriRemoteCancelled = NO;
        processed = NO;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        if (!isPlaying && playReady) {
            CGPoint distence = CGPointMake(sender.location.x - prevPanLocation.x,
                                           sender.location.y - prevPanLocation.y);
            prevPanLocation = sender.location;
            NSLog(@"taped siriRemote state pan: %.6f %.6f - %.6f %.6f velocity %.6f %.6f",
                  sender.location.x, sender.location.y,
                  distence.x, distence.y,
                  sender.velocity.x, sender.velocity.y);
            CGRect frame = seekImageFrame;
            CGRect pauseLabelFrame = pauseTimeLabel.frame;
            frame.origin.x += distence.x * 300;
            NSTimeInterval duration = _player_.duration;
            if (frame.origin.x < _progress.frame.origin.x) {
                frame.origin.x = _progress.frame.origin.x;
            } else if (frame.origin.x > _progress.frame.origin.x + _progress.frame.size.width) {
                frame.origin.x = _progress.frame.origin.x + _progress.frame.size.width;
            }
            NSTimeInterval targetTime = duration * (frame.origin.x - _progress.frame.origin.x) / _progress.frame.size.width;
            seekTargetTime = targetTime;
            pauseTimeLabel.text = [self timeToStr:targetTime];
            pauseLabelFrame.origin.x = frame.origin.x - 78;
            pauseImageView.frame = frame;
            pauseTimeLabel.frame = pauseLabelFrame;
            seekImageFrame = frame;
        } else {
            //check swipeRight, swipLeft and swipeDown
            if (!processed) {
                CGPoint endLocation = sender.location;
                CGFloat gapY = endLocation.y - beganPanLocation.y;
                CGFloat gapX = endLocation.x - beganPanLocation.x;
                if (fabs(gapY) > fabs(gapX) && gapY > 0.18) {
                    processed = YES;
                    [self presentInfoPanel];
                } else if (fabs(gapX) > fabs(gapY) && gapX > 0.18) {
                    processed = YES;
                    [self presentLeftPanel];
                } else if (fabs(gapX) > fabs(gapY) && gapX < -0.18) {
                    processed = YES;
                    [self presentRightPanel];
                }
            }
        }
    } else if ((sender.state == UIGestureRecognizerStateEnded
                || sender.state == UIGestureRecognizerStateCancelled)
               && !sender.isClick) {
        NSLog(@"taped not click action");
        siriRemoteActive = NO;
        if (sender.state == UIGestureRecognizerStateCancelled) {
            siriRemoteCancelled = YES;
        }
        if (!isPlaying) {
            //here to avoid hide during swipe to adjust seek time
            return;
        }
        //swap hide
        if (!processed) {
            if (sender.state == UIGestureRecognizerStateCancelled && !inHiddenChangeProgress) {
                NSLog(@"hudView hidden %@", @(hudView.hidden));
                if (hudView.hidden) {
                    [self stopAndShowTimer];
                    [self resetHideTimer];
                } else {
                    [self stopAndHideTimer];
                }
            }
        }
    }
}

- (void)removeRecognizers {
    for (UITapGestureRecognizer *recognizer in recognizers) {
        [self.view removeGestureRecognizer:recognizer];
    }
    [self.view removeGestureRecognizer:siriRemoteRecognizer];
}

- (void)viewWillAppear:(BOOL)animated {
    [self setupRecognizers];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self removeRecognizers];
    displayLink.paused = YES;
    [displayLink invalidate];
    displayLink = nil;
}

- (void)tapKey:(UITapGestureRecognizer*)sender {
    if (sender.allowedPressTypes.count == 0) return;
    NSLog(@"tapKey");
    NSNumber *n = [sender.allowedPressTypes objectAtIndex:0];
    UIPressType type = (UIPressType)n.intValue;
    HUDKeyEvent eventType = HUDKeyEventUnknown;
    switch (type) {
        case UIPressTypeMenu:
            eventType = HUDKeyEventMenu;
            break;
        case UIPressTypeSelect:
            eventType = HUDKeyEventSelect;
            break;
        case UIPressTypePlayPause:
            eventType = HUDKeyEventPlayPause;
            break;
        case UIPressTypeRightArrow:
            eventType = HUDKeyEventRight;
            break;
        case UIPressTypeLeftArrow:
            eventType = HUDKeyEventLeft;
            break;
        case UIPressTypeUpArrow:
            eventType = HUDKeyEventUp;
            break;
        case UIPressTypeDownArrow:
            eventType = HUDKeyEventDown;
            break;
            
        default:
            break;
    }
    if (eventType == HUDKeyEventDown || eventType == HUDKeyEventLeft || eventType == HUDKeyEventRight) {
        if (siriRemoteCancelled) {
            NSLog(@"skip event down for siriRemote Cancelled");
            return;
        }
    }
    [self onKeyPressed:eventType];
}

- (void)updateTimeClock {
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
    //NSInteger seconds = [components second];
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];
    _timeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", hour, minute];
    //NSLog(@"update Time: %@", _timeLabel.text);
}

- (void)onVideoSizeChanged:(CGSize)size {
    currentMediaInfo.resolution = [NSString stringWithFormat:@"%d×%d", (int)size.width, (int)size.height];
}
- (void)onVideoFPSChanged:(CGFloat)fps {
    currentMediaInfo.fps = fps;
}

- (void)bufferring {
    NSLog(@"bufferring");
    //    if (!isPaused) {
    loadingIndicatorBG.hidden = NO;
    [loadingIndicator startAnimating];
    //    }
}

- (void)stopBufferring {
    NSLog(@"stop bufferring");
    loadingIndicatorBG.hidden = YES;
    [loadingIndicator stopAnimating];
}

- (void)clearRemoteCommand {
    MPRemoteCommandCenter *center = MPRemoteCommandCenter.sharedCommandCenter;
    [center.pauseCommand removeTarget:self];
    [center.playCommand removeTarget:self];
    [center.changePlaybackPositionCommand removeTarget:self];
    [center.skipForwardCommand removeTarget:self];
    [center.skipBackwardCommand removeTarget:self];
    MPNowPlayingInfoCenter *center_ = MPNowPlayingInfoCenter.defaultCenter;
    [center_ setNowPlayingInfo:nil];
}

- (void)setupRemoteCommand {
    MPRemoteCommandCenter *center = MPRemoteCommandCenter.sharedCommandCenter;
    [center.pauseCommand addTarget:self action:@selector(remotePause)];
    center.pauseCommand.enabled = YES;
    [center.playCommand addTarget:self action:@selector(remotePlay)];
    center.playCommand.enabled = YES;
    [center.changePlaybackPositionCommand addTarget:self action:@selector(remoteChangePlaybackPosition:)];
    [center.skipForwardCommand addTarget:self action:@selector(remoteSkipForward)];
    [center.skipBackwardCommand addTarget:self action:@selector(remoteSkipBackward)];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

- (MPRemoteCommandHandlerStatus)remoteChangePlaybackPosition:(MPChangePlaybackPositionCommandEvent*)event {
    NSTimeInterval target = event.positionTime;
    [self seekToTime:target];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)remotePause {
    [self pause];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)remotePlay {
    [self play];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)remoteSkipForward {
    if (isPlaying) {
        if (_player_.currentTime < _player_.duration - 15) {
            [_player_ seekToTime:_player_.currentTime + 15.0f];
        }
    }
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)remoteSkipBackward {
    if (isPlaying) {
        if (_player_.currentTime > 15.0f) {
            [_player_ seekToTime:_player_.currentTime - 15.0f];
        } else {
            [_player_ seekToTime:0];
        }
    }
    return MPRemoteCommandHandlerStatusSuccess;
}

- (void)updateNowPlaying:(NSTimeInterval)current duration:(NSTimeInterval)duration {
    //    NSLog(@"updateNowPlaying %.2f %.2f", current, duration);
    MPNowPlayingInfoCenter *center = MPNowPlayingInfoCenter.defaultCenter;
    if (duration > 0) {
        if (currentMediaInfo.artwork) {
            center.nowPlayingInfo = @{
                                      MPMediaItemPropertyTitle: currentMediaInfo.title,
                                      MPMediaItemPropertyArtist: @"",
                                      MPMediaItemPropertyAlbumTitle: @"",
                                      MPMediaItemPropertyMediaType: @(MPNowPlayingInfoMediaTypeVideo),
                                      MPNowPlayingInfoPropertyElapsedPlaybackTime: @(current),
                                      MPMediaItemPropertyPlaybackDuration: @(duration),
                                      MPMediaItemPropertyArtwork: currentMediaInfo.artwork
                                      };
        } else {
            center.nowPlayingInfo = @{
                                      MPMediaItemPropertyTitle: currentMediaInfo.title,
                                      MPMediaItemPropertyArtist: @"",
                                      MPMediaItemPropertyAlbumTitle: @"",
                                      MPMediaItemPropertyMediaType: @(MPNowPlayingInfoMediaTypeVideo),
                                      MPNowPlayingInfoPropertyElapsedPlaybackTime: @(current),
                                      MPMediaItemPropertyPlaybackDuration: @(duration),
                                      };
        }
    } else {
        if (currentMediaInfo.artwork) {
            center.nowPlayingInfo = @{
                                      MPMediaItemPropertyTitle: _title.text,
                                      MPMediaItemPropertyArtist: @"",
                                      MPMediaItemPropertyAlbumTitle: @"",
                                      MPMediaItemPropertyMediaType: @(MPNowPlayingInfoMediaTypeVideo),
                                      MPMediaItemPropertyArtwork: currentMediaInfo.artwork,
                                      MPNowPlayingInfoPropertyIsLiveStream: @(YES),
                                      };
        } else {
            center.nowPlayingInfo = @{
                                      MPMediaItemPropertyTitle: _title.text,
                                      MPMediaItemPropertyArtist: @"",
                                      MPMediaItemPropertyAlbumTitle: @"",
                                      MPMediaItemPropertyMediaType: @(MPNowPlayingInfoMediaTypeVideo),
                                      MPNowPlayingInfoPropertyIsLiveStream: @(YES),
                                      };
        }
    }
    //    NSLog(@"finish updateNowPlaying %.2f %.2f", current, duration);
}

- (void)onPanelChangePlaySpeedMode:(PlaySpeedMode)speedMode {
    if ([_player_ respondsToSelector:@selector(changeSpeedMode:)]) {
        [_player_ changeSpeedMode:speedMode];
    }
}
- (void)onPanelChangePlayScaleMode:(PlayScaleMode)scaleMode {
    if ([_player_ respondsToSelector:@selector(changeScaleMode:)]) {
        [_player_ changeScaleMode:scaleMode];
    }
}
- (void)onPanelChangeDanMuMode:(PlayDanMuMode)danmuMode {
    switch (danmuMode) {
        case PlayDanMuOn:
            self.danmu.hidden = NO;
            break;
        case PlayDanMuOff:
            self.danmu.hidden = YES;
            break;
            
        default:
            self.danmu.hidden = NO;
            break;
    }
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    if ([presented isKindOfClass:NSClassFromString(@"TopPanelViewController")]) {
        return pushDownAnimator;
    } else if ([presented isKindOfClass:NSClassFromString(@"LeftPanelViewController")]) {
        return pushLeftAnimator;
    } else if ([presented isKindOfClass:NSClassFromString(@"RightPanelViewController")]) {
        return pushRightAnimator;
    } else {
        return nil;
    }
}
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    if ([dismissed isKindOfClass:NSClassFromString(@"TopPanelViewController")]) {
        return popUpAnimator;
    } else if ([dismissed isKindOfClass:NSClassFromString(@"LeftPanelViewController")]) {
        return popLeftAnimator;
    } else if ([dismissed isKindOfClass:NSClassFromString(@"RightPanelViewController")]) {
        return popRightAnimator;
    } else {
        return nil;
    }
}

@end
