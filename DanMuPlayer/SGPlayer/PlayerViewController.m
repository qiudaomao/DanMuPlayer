//
//  PlayerViewController.m
//  tvosPlayer
//
//  Created by zfu on 2017/4/9.
//  Copyright © 2017年 zfu. All rights reserved.
//

#import "PlayerViewController.h"
#import <SGPlayer/SGPlayer.h>
#import "StrokeUILabel.h"
#import "SiriRemoteGestureRecognizer.h"
//#define OFFLINE_TEST true
#define OFFLINE_TEST false
#define SUPPORT_PLAYLIST 0

@interface PlayerViewController ()
{
    UIView *hudLayer;
    //UIVisualEffectView *hudLayerBg;
    UIProgressView *_progress;
    StrokeUILabel *_title;
    StrokeUILabel *_currentTime;
    StrokeUILabel *_leftTime;
    StrokeUILabel *_statLabel;
    StrokeUILabel *_timeLabel;
    StrokeUILabel *_presentSizeLabel;
    UITapGestureRecognizer *playPauseRecognizer;
    UITapGestureRecognizer *menuRecognizer;
    UITapGestureRecognizer *leftArrowRecognizer;
    UITapGestureRecognizer *rightArrowRecognizer;
    UITapGestureRecognizer *upArrowRecognizer;
    UITapGestureRecognizer *downArrowRecognizer;
    SiriRemoteGestureRecognizer *siriRemoteRecognizer;
    UIPanGestureRecognizer *panRecognizer;
    UIGestureRecognizer *touchRecognizer;
    UIActivityIndicatorView *loadingIndicator;
    UIImageView *pointImageView;
    UIImageView *pauseImageView;
    StrokeUILabel *pauseTimeLabel;
    StrokeUILabel *_pointTime;
    BOOL _isPlaying;
    CGPoint indicatorStartPoint;
    CGFloat oldProgress;
    CADisplayLink *displayLink;
    CGRect oriPauseImageRect;
    CGRect oriPauseTimeRect;
    BOOL hudInited;
    CGPoint lastLocation;
    BOOL _hudInHidenProgress;
    CGFloat _resumeTime;
    CGFloat _realResumeTime;
    NSTimer *_hideDelayTimer;
    NSTimer *_BufferingWatchDog;
    StrokeUILabel *subTitle;
    MMVideoSources *videoSource;
    DanMuLayer *danmu;
    BOOL siriRemoteTouched;
    BOOL needResumeDialog;
    UIView *eventsLayer;
    
    //left panel button list
    UITableView *playlistTableView;
    UIVisualEffectView *bgView;
    BOOL isPlayListShowing;
    DMPlaylist *list;
    CGFloat currentTime;
}

@property (nonatomic, readwrite, assign) PlayerState playerState;
@property (nonatomic, readwrite, assign) CGFloat targetProgress;
@property (nonatomic, readwrite, strong) NSSet<UIGestureRecognizer*> *simultaneousGestureRecognizers;
@property (nonatomic, readwrite, assign) BOOL isHudHidden;
@end

@implementation PlayerViewController
@synthesize player = _player;
@synthesize playerState;
@synthesize targetProgress;
@synthesize isHudHidden;
@synthesize delegate;
@synthesize buttonClickCallback;
@synthesize buttonFocusIndex;
@synthesize timeMode;

-(id)init {
    self = [super init];
    self.delegate = nil;
    hudInited = NO;
    _hudInHidenProgress = NO;
    lastLocation = CGPointMake(0.0, 0.0);
    _resumeTime = 0.0;
    self.isHudHidden = NO;
    return self;
}

-(void)seekToTime:(CGFloat)time {
    NSInteger targetIdx = [videoSource findIndexByTime:time];
    CGFloat offset = [videoSource getOffsetByIdx:targetIdx];
    CGFloat targetTime = time-offset;
    NSLog(@"seek to time current %ld segmentIdx %ld time %.2f targetTime %.2f",
          videoSource.current, targetIdx, time, targetTime);
    if (videoSource.current == targetIdx) {
        //[_player seekToTime:targetTime];
        NSLog(@"seek to progress %ld %f", targetIdx, targetTime);
        [self updatePointTime:targetTime];
        [self.player seekToTime:targetTime completeHandler:^(BOOL finished) {
            self.targetProgress = -1;
            [self.player play];
        }];
    } else {
        needResumeDialog = NO;
        _resumeTime = targetTime;
        NSString *url_ = [videoSource.segments objectAtIndex:targetIdx].url;
        BOOL mp4 = videoSource.mp4;
        NSMutableDictionary *options = videoSource.options;
        [self.player pause];
        videoSource.current = targetIdx;
        if (OFFLINE_TEST) {
            static NSURL * normalVideo = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                normalVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"i-see-fire" ofType:@"mp4"]];
            });
            [self.player replaceVideoWithURL:normalVideo options: options mp4: mp4];
        } else {
            NSURL *video = [NSURL URLWithString:url_];
            if (mp4) {
                [self.player replaceVideoWithURL:video options:options mp4:mp4];
            } else {
                [self.player replaceVideoWithURL:video options: options mp4:mp4];
            }
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"view did load");
    oldProgress = 0;
    _player = [SGPlayer player];
    [self.player registerPlayerNotificationTarget:self
                                      stateAction:@selector(stateAction:)
                                   progressAction:@selector(progressAction:)
                                   playableAction:@selector(playableAction:)
                                      errorAction:@selector(errorAction:)];
    [self.player setViewTapAction:^(SGPlayer * _Nonnull player, SGPLFView * _Nonnull view) {
        NSLog(@"player display view did click!");
    }];
    [self.view insertSubview:self.player.view atIndex:0];

    self.playerState = PS_INIT;
    self.targetProgress = -1;
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress)];
    displayLink.paused = YES;
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
#if SUPPORT_PLAYLIST
    CGRect rect = CGRectMake(0, 0, 550, UIScreen.mainScreen.bounds.size.height);
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
    bgView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    bgView.frame = rect;
    [self.view insertSubview:bgView atIndex:1];
    isPlayListShowing = NO;
    [self initButtonListView];
    [self setNeedsFocusUpdate];
#endif
}

-(void)playVideo:(NSString*)url
       withTitle:(NSString*)title
         withImg:(NSString*)img
  withDesciption:(NSString*)desc
         options:(NSMutableDictionary*)options
             mp4:(BOOL)mp4
  withResumeTime: (CGFloat)resumeTime {
    NSLog(@"playVideo %@ resumeTime %.2f", url, resumeTime);
    _realResumeTime = resumeTime;
    videoSource = [MMVideoSources sourceFromURL:url];
    videoSource.url = url;
    videoSource.title = title;
    videoSource.img = img;
    videoSource.desc = desc;
    videoSource.options = [options copy];
    [videoSource dump];
    _title.text = title;
    NSInteger idx = [videoSource findIndexByTime:resumeTime];
    CGFloat offset = [videoSource getOffsetByIdx:idx];
    CGFloat targetTime = resumeTime-offset;
    videoSource.current = idx;
    if (videoSource.count < 1) {
        NSLog(@"ERROR no video segments founded");
        return;
    }
    NSString *url_ = [videoSource.segments objectAtIndex:idx].url;
    NSLog(@"playVideo %@ resumeTime %.2f current idx: %ld/%ld full duration %.2f", url_, resumeTime, idx, [videoSource count],videoSource.duration);
    if (resumeTime>0.0f) {
        needResumeDialog = YES;
    }
    if (OFFLINE_TEST) {
        static NSURL * normalVideo = nil;
        static dispatch_once_t onceToken;
        _resumeTime = targetTime;
        dispatch_once(&onceToken, ^{
            normalVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"i-see-fire" ofType:@"mp4"]];
        });
        [self.player replaceVideoWithURL:normalVideo options:options mp4: mp4];
    } else {
        _resumeTime = targetTime;
        NSURL *video = [NSURL URLWithString:url_];
        if (mp4) {
            [self.player replaceVideoWithURL:video options:options mp4:mp4];
        } else {
            [self.player replaceVideoWithURL:video options:options mp4:mp4];
        }
    }
    if (videoSource.segments.count > 1) {//seperators
        for (int i=0; i<videoSource.segments.count-1; i++) {
            UIImageView *seperatorImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"seperator.png"]];
            CGFloat offset = [videoSource getOffsetByIdx:i];
            CGFloat duration = [videoSource.segments objectAtIndex:i].duration;
            CGFloat x = indicatorStartPoint.x + _progress.frame.size.width * (offset+duration)/videoSource.duration;
            seperatorImageView.frame = CGRectMake(x, 110, 2, 10);
            //NSLog(@"x=%.2f", x);
            [hudLayer addSubview:seperatorImageView];
        }
    }
    _BufferingWatchDog = [NSTimer scheduledTimerWithTimeInterval:8.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
        if (self.player.state == SGPlayerStateBuffering) {
            NSLog(@"Error buffering timeout");
        } else {
            NSLog(@"play OK");
        }
    }];
}

- (void)updateProgress
{
    CGFloat progress = self.player.progress;
    if ([videoSource count]>1) {
        progress += [videoSource getOffsetByIdx:videoSource.current];
    }
    [self updatePointTime:self.player.progress];
    [danmu updateFrame];
    if (self.delegate) {
        [self.delegate timeDidChangedHD:progress];
    }
}

- (void)updatePointTime: (CGFloat)time
{
    CGFloat offset = 0;
    CGFloat duration = self.player.duration;
    if ([videoSource count]>1) {
        offset = [videoSource getOffsetByIdx:videoSource.current];
        duration=videoSource.duration;
    }
    //NSLog(@"time %.2f %.2f %.2f", offset, time, (offset+time));
    if (pointImageView && self.player.duration !=0) {
        CGFloat x = indicatorStartPoint.x + _progress.frame.size.width * ((offset+time)/duration);
        CGRect frame = pointImageView.frame;
        CGRect pauseframe = pauseImageView.frame;
        CGRect pauseTimeFrame = pauseTimeLabel.frame;
        frame.origin.x = x;
        pauseframe.origin.x = x;
        pauseTimeFrame.origin.x = x-78;
        pointImageView.frame = frame;
        pauseImageView.frame = pauseframe;
        pauseTimeLabel.frame = pauseTimeFrame;
        _pointTime.text = [self timeToStr:(offset+time)];
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

- (void) startUpdateProgress {
    displayLink.paused = NO;
}

- (void) stopUpdateProgress {
    displayLink.paused = YES;
}

- (void)initHud
{
    NSLog(@"initHud");
    CGSize size = [self.view bounds].size;
    
    danmu = [[DanMuLayer alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:danmu];
    
    subTitle = [[StrokeUILabel alloc] init];
    subTitle.textColor = [UIColor whiteColor];
    subTitle.strokeColor = [UIColor blackColor];
    subTitle.frame = CGRectMake(0, size.height-130, size.width, 80);
    subTitle.font = [UIFont fontWithName:@"Menlo" size:65];
    subTitle.textAlignment = NSTextAlignmentCenter;
    subTitle.text = @"";
    [self.view addSubview:subTitle];
    
    hudLayer = [[UIView alloc] init];
    eventsLayer = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:eventsLayer];
    [self setupRecognizers];
    hudLayer.frame = CGRectMake(0, size.height-200, size.width, 200);
    
    loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    CGSize indicatorSize = loadingIndicator.frame.size;
    loadingIndicator.frame = CGRectMake(size.width/2-indicatorSize.width/2,
                                        size.height/2-indicatorSize.height/2,
                                        indicatorSize.width,
                                        indicatorSize.height);
    [loadingIndicator setHidden:NO];
    [loadingIndicator startAnimating];
    
    _timeLabel = [[StrokeUILabel alloc] initWithFrame:CGRectMake(size.width-280, 60, 200, 60)];
    _timeLabel.text = @"";
    _timeLabel.textAlignment = NSTextAlignmentRight;
    _timeLabel.font = [UIFont fontWithName:@"Menlo" size:50];
    _timeLabel.textColor = [UIColor whiteColor];
    
    _presentSizeLabel = [[StrokeUILabel alloc] initWithFrame:CGRectMake(80, 60, 300, 60)];
    _presentSizeLabel.text = @"";
    _presentSizeLabel.font = [UIFont fontWithName:@"Menlo" size:50];
    _presentSizeLabel.textColor = [UIColor whiteColor];
    
    [self.view addSubview:hudLayer];
    [self.view addSubview:loadingIndicator];
    [self.view addSubview:_timeLabel];
    [self.view addSubview:_presentSizeLabel];
    
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
    _leftTime.font = [UIFont fontWithName:@"Menlo" size:34];
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
    pauseTimeLabel.font = [UIFont fontWithName:@"Menlo" size:34];
    pauseTimeLabel.textAlignment = NSTextAlignmentCenter;
    [hudLayer addSubview:pauseTimeLabel];
    pauseTimeLabel.hidden = YES;
    
    _isPlaying = NO;
}

- (void) setupRecognizers {
    playPauseRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPlayPause:)];
    playPauseRecognizer.allowedPressTypes = @[@(UIPressTypePlayPause)];
    [self.view addGestureRecognizer:playPauseRecognizer];
    
    menuRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapMenu:)];
    menuRecognizer.allowedPressTypes = @[@(UIPressTypeMenu)];
    [self.view addGestureRecognizer:menuRecognizer];
    
    leftArrowRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapLeftArrow:)];
    leftArrowRecognizer.allowedPressTypes = @[@(UIPressTypeLeftArrow)];
    [self.view addGestureRecognizer:leftArrowRecognizer];
    
    rightArrowRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRightArrow:)];
    rightArrowRecognizer.allowedPressTypes = @[@(UIPressTypeRightArrow)];
    [self.view addGestureRecognizer:rightArrowRecognizer];
    
    upArrowRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapUpArrow:)];
    upArrowRecognizer.allowedPressTypes = @[@(UIPressTypeUpArrow)];
    [self.view addGestureRecognizer:upArrowRecognizer];
    
    downArrowRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDownArrow:)];
    downArrowRecognizer.allowedPressTypes = @[@(UIPressTypeDownArrow)];
    [self.view addGestureRecognizer:downArrowRecognizer];
    
    panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [eventsLayer addGestureRecognizer:panRecognizer];
    
    siriRemoteRecognizer = [[SiriRemoteGestureRecognizer alloc] initWithTarget:self action:@selector(siriTouch:)];
    siriRemoteRecognizer.delegate = self;
    [eventsLayer addGestureRecognizer:siriRemoteRecognizer];
    
    NSMutableSet<UIGestureRecognizer*> *simultaneousGestureRecognizers = [NSMutableSet set];
    [simultaneousGestureRecognizers addObject:panRecognizer];
    [simultaneousGestureRecognizers addObject:siriRemoteRecognizer];
    self.simultaneousGestureRecognizers = simultaneousGestureRecognizers;
}

#pragma mark - gesture recognizer delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return [self.simultaneousGestureRecognizers containsObject:gestureRecognizer];
}

- (void)tapPlayPause:(UITapGestureRecognizer*)sender {
    NSLog(@"taped playpause");
    if (_hudInHidenProgress) return;
    if (_isPlaying) {
        _isPlaying=!_isPlaying;
        [self.player pause];
        pauseTimeLabel.text = [self timeToStr: self.player.progress];
        pauseTimeLabel.hidden = NO;
        pauseImageView.hidden = NO;
        _title.hidden = YES;
        _pointTime.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    } else {
        if (self.targetProgress != -1) {
            [self seekToTime:self.targetProgress];
        } else {
            [self.player play];
        }
        _isPlaying=!_isPlaying;
        pauseTimeLabel.hidden = YES;
        pauseImageView.hidden = YES;
        _title.hidden = NO;
        _pointTime.textColor = UIColor.whiteColor;
    }
}

- (void)tapMenu:(UITapGestureRecognizer*)sender {
    NSLog(@"taped Menu key");
    if (_hudInHidenProgress) return;
    if (isPlayListShowing) {
        [self hideButtonList];
        return;
    }
    NSLog(@"accept taped Menu key");
    if (self.playerState == PS_PAUSED) {
        _isPlaying=!_isPlaying;
        pauseTimeLabel.hidden = YES;
        pauseImageView.hidden = YES;
        _title.hidden = NO;
        _pointTime.textColor = UIColor.whiteColor;
        [self.player play];
        self.targetProgress = -1;
    } else {
        [self stop];
    }
}

- (void)tapLeftArrow:(UITapGestureRecognizer*)sender {
    if (siriRemoteTouched) return;
    [self handleLeftArrow];
}

- (void)handleLeftArrow {
    if (_hudInHidenProgress) return;
    NSLog(@"taped leftArrow");
    if (self.playerState == PS_PLAYING) {
        CGFloat currentProgress = [videoSource getOffsetByIdx:videoSource.current]+self.player.progress;
        CGFloat targetProgress_ = (currentProgress-20.0f)>0.0f?(currentProgress-20.0f):0.0f;
        [self seekToTime:targetProgress_];
    } else if (self.playerState == PS_PAUSED) {
        oriPauseImageRect = pauseImageView.frame;
        oriPauseTimeRect = pauseTimeLabel.frame;
        oriPauseImageRect.origin.x -= _progress.frame.size.width*5/100;
        if (oriPauseImageRect.origin.x < _progress.frame.origin.x) {
            oriPauseImageRect.origin.x = _progress.frame.origin.x;
        } else if (oriPauseImageRect.origin.x > _progress.frame.origin.x + _progress.frame.size.width) {
            oriPauseImageRect.origin.x = (_progress.frame.origin.x + _progress.frame.size.width);
        }
        oriPauseTimeRect.origin.x = oriPauseImageRect.origin.x - 78;
        
        oriPauseImageRect.origin.y = 80;
        oriPauseTimeRect.origin.y = 42;
        
        CGFloat duration = self.player.duration;
        if (videoSource.count>1) duration = videoSource.duration;
        CGFloat targetTime = duration * (oriPauseImageRect.origin.x - _progress.frame.origin.x) / _progress.frame.size.width;
        self.targetProgress = targetTime;
        pauseTimeLabel.text = [self timeToStr:targetTime];
        pauseImageView.frame = oriPauseImageRect;
        pauseTimeLabel.frame = oriPauseTimeRect;
    }
}

- (void)tapRightArrow:(UITapGestureRecognizer*)sender {
    if (siriRemoteTouched) return;
    [self handleRightArrow];
}
- (void)handleRightArrow {
    if (_hudInHidenProgress) return;
    NSLog(@"taped rightArrow");
    if (self.playerState == PS_PLAYING) {
        CGFloat currentProgress = [videoSource getOffsetByIdx:videoSource.current]+self.player.progress;
        CGFloat duration = self.player.duration;
        if (videoSource.count>1) duration = videoSource.duration;
        CGFloat targetProgress_ = (currentProgress+20.0f)>duration?duration:(currentProgress+20.0f);
        [self seekToTime:targetProgress_];
    } else if (self.playerState == PS_PAUSED) {
        oriPauseImageRect = pauseImageView.frame;
        oriPauseTimeRect = pauseTimeLabel.frame;
        oriPauseImageRect.origin.x += _progress.frame.size.width*5/100;
        if (oriPauseImageRect.origin.x < _progress.frame.origin.x) {
            oriPauseImageRect.origin.x = _progress.frame.origin.x;
        } else if (oriPauseImageRect.origin.x > _progress.frame.origin.x + _progress.frame.size.width) {
            oriPauseImageRect.origin.x = (_progress.frame.origin.x + _progress.frame.size.width);
        }
        oriPauseTimeRect.origin.x = oriPauseImageRect.origin.x - 78;
        
        oriPauseImageRect.origin.y = 80;
        oriPauseTimeRect.origin.y = 42;
        
        CGFloat duration = self.player.duration;
        if (videoSource.count>1) duration = videoSource.duration;
        CGFloat targetTime = duration * (oriPauseImageRect.origin.x - _progress.frame.origin.x) / _progress.frame.size.width;
        self.targetProgress = targetTime;
        pauseTimeLabel.text = [self timeToStr:targetTime];
        pauseImageView.frame = oriPauseImageRect;
        pauseTimeLabel.frame = oriPauseTimeRect;
    }
}

- (void)tapUpArrow:(UITapGestureRecognizer*)sender {
    if (_hudInHidenProgress) return;
    NSLog(@"taped upArrow");
}

- (void)tapDownArrow:(UITapGestureRecognizer*)sender {
    if (_hudInHidenProgress) return;
    NSLog(@"taped downArrow");
}

- (void)siriTouch:(SiriRemoteGestureRecognizer*)sender {
//    NSLog(@"taped siriRemote state: %ld %@ location %ld %@",
//          (long)sender.state, sender.stateName, (long)sender.touchLocation, sender.touchLocationName);
    NSLog(@"taped siriRemote state: %@ click %d", sender.stateName, sender.isClick);
    if (sender.state == UIGestureRecognizerStateEnded && sender.isClick) {
        //NSLog(@"taped siriRemote, location %@", sender.touchLocationName);
        NSLog(@"taped click action");
        siriRemoteTouched = NO;
        if (sender.touchLocation == MMSiriRemoteTouchLocationCenter
            || sender.touchLocation == MMSiriRemoteTouchLocationUp
            || sender.touchLocation == MMSiriRemoteTouchLocationDown) {
            [self tapSelect];
        } else if (sender.touchLocation == MMSiriRemoteTouchLocationLeft) {
            [self handleLeftArrow];
        } else if (sender.touchLocation == MMSiriRemoteTouchLocationRight) {
            [self handleRightArrow];
        }
    } else if ((sender.state == UIGestureRecognizerStateEnded
                || sender.state == UIGestureRecognizerStateCancelled)
               && !sender.isClick) {
        NSLog(@"taped not click action");
        siriRemoteTouched=YES;
        if (self.playerState == PS_PAUSED) {
            //here to avoid hide during swipe to adjust seek time
            return;
        }
        if (self.isHudHidden) {
            [self setHidenHud:NO withDelay:NO];
            [self setHidenHud:YES withDelay:YES];
        } else {
            [self setHidenHud:YES withDelay:NO];
        }
    }
}

- (void)tapSelect {
    if (_hudInHidenProgress) return;
    if (isPlayListShowing) return;
    if (self.playerState == PS_PAUSED) {
        if (self.targetProgress != -1) {
            NSLog(@"seek to progress %f", self.targetProgress);
            [self seekToTime:self.targetProgress];
            /*
            [self updatePointTime:self.targetProgress];
            [self.player seekToTime:self.targetProgress completeHandler:^(BOOL finished) {
                self.targetProgress = -1;
                [self.player play];
            }];
             */
        } else {
            [self.player play];
        }
        _isPlaying=!_isPlaying;
        pauseTimeLabel.hidden = YES;
        pauseImageView.hidden = YES;
        _title.hidden = NO;
        _pointTime.textColor = UIColor.whiteColor;
    } else if (self.playerState == PS_PLAYING) {
        _isPlaying=!_isPlaying;
        [self.player pause];
        pauseTimeLabel.text = [self timeToStr: self.player.progress];
        pauseTimeLabel.hidden = NO;
        pauseImageView.hidden = NO;
        _title.hidden = YES;
        _pointTime.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    }
}

- (void)updateTargetProgress: (float)progress {
    
}

- (void)pan:(UIPanGestureRecognizer*)sender {
    if (_hudInHidenProgress) return;
    if (isPlayListShowing) return;
    CGPoint location = [sender translationInView:self.view];
    CGPoint v = [sender velocityInView:eventsLayer];
    {//show logs here
        NSString *stateStr = @"";
        if (sender.state == UIGestureRecognizerStateBegan) {
            stateStr = @"Began";
        } else if (sender.state == UIGestureRecognizerStateChanged) {
            stateStr = @"Changed";
        } else if (sender.state == UIGestureRecognizerStateEnded) {
            stateStr = @"Ended";
            if (self.playerState != PS_PAUSED) {
                if (fabs(v.y)<2000 && v.x > 1000) {
                    NSLog(@"it is ready to show");
                    [self showButtonList];
                } else {
                    NSLog(@"it is not paused, but velocity not good");
                }
            } else {
                NSLog(@"it is paused");
            }
        } else if (sender.state == UIGestureRecognizerStateCancelled) {
            stateStr = @"Cancelled";
        } else if (sender.state == UIGestureRecognizerStateFailed) {
            stateStr = @"Failed";
        } else if (sender.state == UIGestureRecognizerStatePossible) {
            stateStr = @"Possible";
        } else if (sender.state == UIGestureRecognizerStateRecognized) {
            stateStr = @"Recognized";
        } else {
            stateStr = @"Unknown";
        }
        NSLog(@"taped pan event state %@ point %f %f velocity %f %f", stateStr, location.x, location.y, v.x, v.y);
    }
    if (self.playerState != PS_PAUSED) {
        if (self.playerState == PS_PLAYING) {
            if (sender.state == UIGestureRecognizerStateBegan
                || sender.state == UIGestureRecognizerStateChanged) {
                [self setHidenHud:NO withDelay:YES];
            } else if (sender.state == UIGestureRecognizerStateEnded) {
                [self setHidenHud:YES withDelay:YES];
            }
        }
        return;
    }
    if (sender.state == UIGestureRecognizerStateBegan) {
        //NSLog(@"Began");
        //save the init position
        oriPauseImageRect = pauseImageView.frame;
        oriPauseTimeRect = pauseTimeLabel.frame;
        self.targetProgress = -1;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        //NSLog(@"seekEnable %d", self.player.seekEnable);
        if (!self.player.seekEnable) return;
        //NSLog(@"Changed");
        oriPauseImageRect.origin.x += v.x / 300.0f;
        oriPauseTimeRect.origin.x += v.x / 300.0f;
        if (oriPauseImageRect.origin.x < _progress.frame.origin.x) {
            oriPauseImageRect.origin.x = _progress.frame.origin.x;
        } else if (oriPauseImageRect.origin.x > _progress.frame.origin.x + _progress.frame.size.width) {
            oriPauseImageRect.origin.x = (_progress.frame.origin.x + _progress.frame.size.width);
        }
        oriPauseTimeRect.origin.x = oriPauseImageRect.origin.x - 78;
        
        oriPauseImageRect.origin.y = 80;
        oriPauseTimeRect.origin.y = 42;
        
        CGFloat duration = self.player.duration;
        if (videoSource.count>1) duration = videoSource.duration;
        CGFloat targetTime = duration * (oriPauseImageRect.origin.x - _progress.frame.origin.x) / _progress.frame.size.width;
        self.targetProgress = targetTime;
        pauseTimeLabel.text = [self timeToStr:targetTime];
        pauseImageView.frame = oriPauseImageRect;
        pauseTimeLabel.frame = oriPauseTimeRect;
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        //NSLog(@"End");
    } else if (sender.state == UIGestureRecognizerStateCancelled) {
        NSLog(@"Calcelled");
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.player.view.frame = self.view.bounds;
    if (hudInited == NO) {
        [self initHud];
        hudInited = YES;
    }
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

- (void)progressAction:(NSNotification *)notification
{
    SGProgress * progress = [SGProgress progressFromUserInfo:notification.userInfo];
    //NSLog(@"progress: %f %f %f", progress.current, self.player.playableTime, self.player.playableBufferInterval);
    CGFloat offset = 0;
    CGFloat duration = self.player.duration;
    if ([videoSource count]>1) {
        offset = [videoSource getOffsetByIdx:videoSource.current];
        duration=videoSource.duration;
    }
    CGFloat current = offset+progress.current;
    [self updateTimeClock];
    if (fabs(duration)<0.001 && current > 0.001) {
        NSDate *date = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
        //NSInteger seconds = [components second];
        NSInteger hour = [components hour];
        NSInteger minute = [components minute];
        _currentTime.text = [NSString stringWithFormat:@"%02ld:%02d", hour, (minute>30)?30:0];
        _pointTime.text = [NSString stringWithFormat:@"%02ld:%02ld", hour, minute];
        _leftTime.text = [NSString stringWithFormat:@"%02ld:%02d", (minute>30)?hour+1:hour, (minute>30)?0:30];
    } else {
        _currentTime.text = [self timeToStr:current];
        _pointTime.text = [self timeToStr:current];
        _leftTime.text = [self timeToStr: (duration-current)];
    }
    if (currentTime<duration-10.0 && current>duration-10.0) {
        [self showButtonList];
    }
    currentTime=current;
    [self.delegate timeDidChanged:current duration:duration];
}

- (void) setHidenHud: (BOOL) hide withDelay:(BOOL)delay {
    //NSLog(@"delay set Hiden Hud %d _hudInHidenProgress %@", hide, (_hudInHidenProgress)?@"true":@"false");
    if (_hudInHidenProgress) {
        return;
    }
    if (hide) {
        [hudLayer setAlpha:1.0f];
        [_timeLabel setAlpha:1.0f];
        [_presentSizeLabel setAlpha:1.0f];
        if (_hideDelayTimer) {
            [_hideDelayTimer invalidate];
            _hideDelayTimer = nil;
        }
        if (delay) {
            _hideDelayTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
                _hudInHidenProgress = YES;
                [UIView animateWithDuration:1.0f animations:^{
                    [hudLayer setAlpha:0.0f];
                    [_timeLabel setAlpha:0.0f];
                    [_presentSizeLabel setAlpha:0.0f];
                } completion:^(BOOL finished) {
                    [hudLayer setHidden:YES];
                    [_timeLabel setHidden:YES];
                    [_presentSizeLabel setHidden:YES];
                    _hudInHidenProgress = NO;
                    self.isHudHidden = YES;
                }];
            }];
        } else {
            _hudInHidenProgress = YES;
            [UIView animateWithDuration:1.0f animations:^{
                [hudLayer setAlpha:0.0f];
                [_timeLabel setAlpha:0.0f];
                [_presentSizeLabel setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [hudLayer setHidden:YES];
                [_timeLabel setHidden:YES];
                [_presentSizeLabel setHidden:YES];
                _hudInHidenProgress = NO;
                self.isHudHidden = YES;
            }];
        }
    } else {
        if (_hideDelayTimer) {
            [_hideDelayTimer invalidate];
            _hideDelayTimer = nil;
        }
        [_timeLabel setAlpha:1.0f];
        [_timeLabel setHidden:NO];
        [hudLayer setAlpha:1.0f];
        [hudLayer setHidden:NO];
        [_presentSizeLabel setAlpha:1.0f];
        [_presentSizeLabel setHidden:NO];
        self.isHudHidden = NO;
    }
}

- (void)playableAction:(NSNotification *)notification
{
    SGPlayable * playable = [SGPlayable playableFromUserInfo:notification.userInfo];
    CGFloat offset = 0.0f;
    CGFloat duration = _player.duration;
    if (videoSource.segments.count>1) {
        offset = [videoSource getOffsetByIdx:videoSource.current];
        duration = videoSource.duration;
    }
    CGFloat current = offset + playable.current;
    //[_progress setProgress:playable.percent];
    [_progress setProgress: current/duration];
    //NSLog(@"playable time : %f", playable.current);
}

- (void)errorAction:(NSNotification *)notification
{
    SGError * error = [SGError errorFromUserInfo:notification.userInfo];
    NSLog(@"player did error : %@", error.error);
    UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:@"出错了"
                                                                        message:error.error.localizedDescription
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *stopWatching = [UIAlertAction actionWithTitle:@"关闭"
                                                           style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
                                                               [self stop];
                                                           }];
    [errorAlert addAction:stopWatching];
    [self presentViewController:errorAlert animated:YES completion:^{
    }];
}

- (void)notificationState:(PlayerState)state {
    if (self.delegate) {
        [self.delegate playStateDidChanged:state];
    }
}

- (void)stateAction:(NSNotification *)notification
{
    SGState * state = [SGState stateFromUserInfo:notification.userInfo];
    NSString * text;
    if (_BufferingWatchDog && state.current != SGPlayerStateBuffering) {
        [_BufferingWatchDog invalidate];
        _BufferingWatchDog = nil;
    }
    switch (state.current) {
        case SGPlayerStateNone:
            text = @"None";
            [self stopUpdateProgress];
            self.playerState = PS_INIT;
            [self notificationState:PS_INIT];
            break;
        case SGPlayerStateBuffering:
            text = @"Buffering...";
            [loadingIndicator setHidden:NO];
            [loadingIndicator startAnimating];
            [self notificationState:PS_LOADING];
            [self stopUpdateProgress];
            break;
        case SGPlayerStateReadyToPlay:
            text = @"Prepare";
            CGSize videoSize = self.player.presentationSize;
            NSLog(@"presentationSize (%.2f, %.2f)", videoSize.width, videoSize.height);
            _presentSizeLabel.text = [NSString stringWithFormat:@"%dx%d", (int)videoSize.width, (int)videoSize.height];
            //self.totalTimeLabel.text = [self timeStringFromSeconds:self.player.duration];
            _leftTime.text = [self timeToStr:self.player.duration];
            [loadingIndicator setHidden:YES];
            [loadingIndicator stopAnimating];
            self.playerState = PS_INIT;
            [self notificationState:PS_INIT];
            if ((_resumeTime > 0.0f || _realResumeTime > 0.0f) && self.player.duration > 0.0f) {
                NSLog(@"do resume time");
                if (!needResumeDialog) {
                    [self.player seekToTime:_resumeTime completeHandler:^(BOOL finished) {
                        [self.player play];
                    }];
                    _realResumeTime = 0.0f;
                    _resumeTime = 0.0f;
                    return;
                }
                NSString *msg = [NSString stringWithFormat:@"上次观看到 %@ 共 %@ 是否继续观看？",
                                 [self timeToStr: _realResumeTime],
                                 (videoSource.duration>0.1)?[self timeToStr: videoSource.duration]:@"??:??"];
                UIAlertController* continueWatchingAlert = [UIAlertController alertControllerWithTitle:@"视频准备就绪" message:msg preferredStyle:UIAlertControllerStyleActionSheet];
                UIAlertAction *continueWatching = [UIAlertAction actionWithTitle:@"继续观看"
                                                                           style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
                    NSLog(@"continue play from %.2f", _resumeTime);
                    CGFloat resumeTime = _resumeTime;
                    _resumeTime = 0.0f;
                    _realResumeTime = 0.0f;
                    [self.player seekToTime:resumeTime completeHandler:^(BOOL finished) {
                        [self.player play];
                    }];
                }];
                UIAlertAction *startWatching = [UIAlertAction actionWithTitle:@"重新观看"
                                                                        style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
                    [self seekToTime:0.0f];
                    //_resumeTime = 0.0f;
                    [self.player play];
                }];
                UIAlertAction *stopWatching = [UIAlertAction actionWithTitle:@"放弃观看"
                                                                       style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
                                                                           [self stop];
                }];
                [continueWatchingAlert addAction:continueWatching];
                [continueWatchingAlert addAction:startWatching];
                [continueWatchingAlert addAction:stopWatching];
                [self presentViewController:continueWatchingAlert animated:YES completion:nil];
            } else {
                NSLog(@"no need to resume");
                _resumeTime = 0.0f;
                [self.player play];
            }
            break;
        case SGPlayerStatePlaying:
            text = @"Playing";
            [loadingIndicator setHidden:YES];
            [loadingIndicator stopAnimating];
            [self setHidenHud:YES withDelay:YES];
            _isPlaying = YES;
            self.playerState = PS_PLAYING;
            [self notificationState:PS_PLAYING];
            [self startUpdateProgress];
            break;
        case SGPlayerStateSuspend:
            text = @"Suspend";
            [self setHidenHud:NO withDelay:YES];
            _isPlaying = NO;
            self.playerState = PS_PAUSED;
            [self notificationState:PS_PAUSED];
            [self stopUpdateProgress];
            break;
        case SGPlayerStateFinished:
            text = @"Finished";
            [self setHidenHud:NO withDelay:YES];
            _isPlaying = NO;
            self.playerState = PS_FINISH;
            if (videoSource.current == [videoSource count]-1) {
                NSLog(@"real finish");
                if (isPlayListShowing) {
                    [self notificationState:PS_FINISH];
                    [self stopUpdateProgress];
                } else {
                    [self stop];
                }
            } else {//change to next segment
                videoSource.current+=1;
                NSLog(@"current to next %ld/%ld", videoSource.current, videoSource.count);
                NSInteger idx = videoSource.current;
                NSString *url_ = [videoSource.segments objectAtIndex:idx].url;
                CGFloat resumeTime = 0.0f;
                NSMutableDictionary *options = videoSource.options;
                BOOL mp4 = videoSource.mp4;
                NSLog(@"playVideo %@ resumeTime %.2f current idx: %ld/%ld full duration %.2f", url_, resumeTime, idx, [videoSource count],videoSource.duration);
                if (OFFLINE_TEST) {
                    static NSURL * normalVideo = nil;
                    static dispatch_once_t onceToken;
                    dispatch_once(&onceToken, ^{
                        normalVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"i-see-fire" ofType:@"mp4"]];
                    });
                    [self.player replaceVideoWithURL:normalVideo options: options mp4: mp4];
                } else {
                    _resumeTime = resumeTime;
                    NSURL *video = [NSURL URLWithString:url_];
                    if (mp4) {
                        [self.player replaceVideoWithURL:video options:options mp4:mp4];
                    } else {
                        [self.player replaceVideoWithURL:video options: options mp4:mp4];
                    }
                }
            }
            break;
        case SGPlayerStateFailed:
            text = @"Error";
            self.playerState = PS_ERROR;
            [self notificationState:PS_ERROR];
            [self stopUpdateProgress];
            break;
    }
    //self.stateLabel.text = text;
    NSLog(@"stateAction: %@", text);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)timeToStr:(int)time {
    int min = time/60;
    int sec = time-min*60;
    return [NSString stringWithFormat:@"%02d:%02d", min, sec];
}

-(void)play {
    [_player play];
}

-(void)pause {
        [_player pause];
}
-(void)stop {
    //[_player pause];
    [self stopUpdateProgress];
    displayLink.paused = YES;
    [self notificationState:PS_FINISH];
    [_player removePlayerNotificationTarget:self];
    [_player replaceEmpty];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //[self.navigationController popViewControllerAnimated:YES];
        [self dismissViewControllerAnimated:NO completion:^{
            NSLog(@"popViewController finish while stop");
        }];
    });
}

-(void)addDanMu:(NSString*)content
      withStyle:(DanmuStyle)style
      withColor:(UIColor*)color
withStrokeColor:(UIColor*)bgcolor
   withFontSize:(CGFloat)fontSize {
    [danmu addDanMu:content
               withStyle:style
               withColor:color
         withStrokeColor:bgcolor
            withFontSize:fontSize];
}

-(void)setSubTitle:(NSString*)subTitle_ {
    subTitle.text = subTitle_;
}

-(void)setupButtonList:(DMPlaylist*)playlist {
    list = playlist;
}

- (nullable NSIndexPath *)indexPathForPreferredFocusedViewInTableView:(UITableView *)tableView {
    NSLog(@"query indexPathForPreferredFocusedViewInTableView %zd", self.buttonFocusIndex);
    NSIndexPath *path = [NSIndexPath indexPathForRow:self.buttonFocusIndex inSection:0];
    return path;
}

- (void)showButtonList {
    if (list==nil || list.items.count==0) return;
    NSLog(@"show play list");
    bgView.hidden = NO;
    NSLog(@"set hidden no and do animation");
    [UIView animateWithDuration:0.2 delay:0.3 options:0 animations:^{
        CGSize size = bgView.frame.size;
        CGRect frame = CGRectMake(0, 0, size.width, size.height);
        bgView.frame = frame;
    } completion:^(BOOL finished) {
        isPlayListShowing=YES;
        [self setNeedsFocusUpdate];
    }];
}

- (void)initButtonListView {
    CGRect labelRect = CGRectMake(bgView.frame.origin.x, bgView.frame.origin.y, bgView.frame.size.width, 90);
    UILabel *label = [[UILabel alloc] initWithFrame:labelRect];
    [label setTextAlignment:NSTextAlignmentCenter];
    label.text = @"选单(右滑时显示)";
    [bgView.contentView addSubview:label];
    CGRect rect = CGRectMake(bgView.frame.origin.x, bgView.frame.origin.y+90, bgView.frame.size.width-80, bgView.frame.size.height-90);
    playlistTableView = [[UITableView alloc] initWithFrame:rect style:UITableViewStylePlain];
    playlistTableView.rowHeight = 70;
    playlistTableView.delegate = self;
    playlistTableView.dataSource = self;
    [bgView.contentView addSubview:playlistTableView];
    bgView.hidden = YES;
    CGSize size = bgView.frame.size;
    CGRect frame = CGRectMake(-size.width, 0, size.width, size.height);
    bgView.frame = frame;
}

-(void)hideButtonList {
    NSLog(@"hide Play List");
    [UIView animateWithDuration:0.2 delay:0.3 options:0 animations:^{
        CGSize size = bgView.frame.size;
        CGRect frame = CGRectMake(-size.width, 0, size.width, size.height);
        bgView.frame = frame;
    } completion:^(BOOL finished) {
        isPlayListShowing=NO;
        [self setNeedsFocusUpdate];
    }];
}

#if SUPPORT_PLAYLIST
- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments {
    //NSLog(@"query preferredFocusEnvironments %@", isPlayListShowing?@"show":@"hide");
    if (isPlayListShowing) {
        NSLog(@"query focus on buttonList");
        return @[playlistTableView];
    } else {
        if (eventsLayer) {
            NSLog(@"query focus on eventsLayer");
            return @[eventsLayer];
        } else {
            return nil;
        }
    }
}
#endif

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"buttonViewCell"];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.text = [list.items objectAtIndex: indexPath.row].title;
    cell.textLabel.textColor = UIColor.whiteColor;
    cell.textLabel.highlightedTextColor = UIColor.blackColor;
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (list!=nil && list.items !=nil) {
        return list.items.count;
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"didSelectRowAtIndexPath %zd", indexPath.row);
    self.buttonFocusIndex = indexPath.row;
    if (self.buttonClickCallback) {
        [[self.buttonClickCallback.context objectForKeyedSubscript:@"setTimeout"] callWithArguments: @[buttonClickCallback, @0, [NSNumber numberWithInteger:indexPath.row]]];
    }
}
@end
