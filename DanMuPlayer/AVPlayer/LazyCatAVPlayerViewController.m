//
//  LazyCatAVPlayerController.m
//  LazyCat
//
//  Created by zfu on 2017/11/4.
//  Copyright © 2017年 zfu. All rights reserved.
//

#import "LazyCatAVPlayerViewController.h"
#import "StrokeUILabel.h"
#import "MMVideoSources.h"
#define SUPPORT_PLAYLIST 1

@interface LazyCatAVPlayerViewController() {
    AVAudioSession *_session;
    NSString *url;
    NSDictionary *headers;
    NSString *title;
    NSString *subTitle;
    NSString *description;
    NSString *artworkImage;
    UITapGestureRecognizer *menuRecognizer;
    UIPanGestureRecognizer *panRecognizer;
    UIPanGestureRecognizer *panButtonListRecognizer;
    UITableView *playlistTableView;
    UIVisualEffectView *bgView;
    AVPlayer *player;
    BOOL isPlayListShowing;
    BOOL isControllerVisible;
    CADisplayLink *displayLink;
    NSTimeInterval currentResumeTime;
    StrokeUILabel *timeLabel;
    StrokeUILabel *subsLabel;
    id timeObserver;
    DanMuLayer *danmu;
    DMPlaylist *list;
    BOOL firstTime;
    PlayerState currentState;
    NSTimeInterval currentTime;
    BOOL playerInited;
}
@end

@implementation LazyCatAVPlayerViewController
@synthesize delegate;
@synthesize buttonClickCallback;
@synthesize buttonFocusIndex;
@synthesize timeMode;

- (id)init {
    self = [super init];
    if (self) {
        playerInited=NO;
    }
    return self;
}

- (void)updateProgress {
    [danmu updateFrame];
    if (self.delegate) {
        NSTimeInterval current = CMTimeGetSeconds(player.currentTime);
        [self.delegate timeDidChangedHD:current];
    }
}

- (void)initButtonListView {
    CGRect labelRect = CGRectMake(bgView.frame.origin.x, bgView.frame.origin.y, bgView.frame.size.width, 90);
    UILabel *label = [[UILabel alloc] initWithFrame:labelRect];
    [label setTextAlignment:NSTextAlignmentCenter];
    label.text = @"选单(左右滑动显隐)";
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

#if SUPPORT_PLAYLIST
- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments {
    NSLog(@"query preferredFocusEnvironments %@", isPlayListShowing?@"show":@"hide");
    if (isPlayListShowing) {
        return @[playlistTableView];
    } else {
        if (self.avPlayerViewController) {
            return @[self.avPlayerViewController.view];
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

- (void)viewDidLoad {
    [super viewDidLoad];
    firstTime=YES;
    self.view.backgroundColor = UIColor.blackColor;
    _session = [AVAudioSession sharedInstance];
    [_session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    menuRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapMenu:)];
    menuRecognizer.allowedPressTypes = @[@(UIPressTypeMenu)];
    [self.view addGestureRecognizer:menuRecognizer];

    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress)];
    displayLink.paused = YES;
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
#if SUPPORT_PLAYLIST
    CGRect rect = CGRectMake(0, 0, 550, UIScreen.mainScreen.bounds.size.height);
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
    bgView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    bgView.frame = rect;
    isPlayListShowing = NO;
    [self setNeedsFocusUpdate];
    
    [self.view addSubview:bgView];
    [self initButtonListView];
    
    panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self.view addGestureRecognizer:panRecognizer];
    
    panButtonListRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panButtonList:)];
    [playlistTableView addGestureRecognizer:panButtonListRecognizer];
#endif

    playerInited=YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    displayLink.paused = YES;
}

- (void)playerItemDidToPlayToEnd:(NSNotification *)notification
{
    if (self.delegate) {
        if (isPlayListShowing) {
            [self.delegate playStateDidChanged:PS_FINISH];
        } else {
            [self stop];
        }
    }
}

- (void)playerItemFailedToPlayToEndTime:(NSNotification *)notification
{
    NSError *error = notification.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey];
    NSLog(@"error %@", error.localizedDescription);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"observeValueForKeyPath %@", keyPath);
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *playerItem = (AVPlayerItem*)object;
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            if (!firstTime) return;
            firstTime=NO;
            NSLog(@"Item is ready, and will play");
            //resume
            if (currentResumeTime < 0.01) {
                [player play];//if no need to resume
                return;
            }
            NSTimeInterval duration = CMTimeGetSeconds(self.avPlayerViewController.player.currentItem.duration);
            NSString *msg = [NSString stringWithFormat:@"上次观看到 %@ 共 %@ 是否继续观看？",
                             [self timeToStr: currentResumeTime],
                             (duration>0.1)?[self timeToStr: duration]:@"??:??"];
            UIAlertController* continueWatchingAlert = [UIAlertController alertControllerWithTitle:@"视频准备就绪" message:msg preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *continueWatching = [UIAlertAction actionWithTitle:@"继续观看"
                                                                       style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
                                                                           NSLog(@"continue play from %.2f", currentResumeTime);
                                                                           [self seekToTime:currentResumeTime];
                                                                           [player play];
                                                                       }];
            UIAlertAction *startWatching = [UIAlertAction actionWithTitle:@"重新观看"
                                                                    style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
                                                                        [self seekToTime:0.0f];
                                                                        //_resumeTime = 0.0f;
                                                                        [player play];
                                                                    }];
            UIAlertAction *stopWatching = [UIAlertAction actionWithTitle:@"放弃观看"
                                                                   style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
                                                                       [self stop];
                                                                   }];
            [continueWatchingAlert addAction:continueWatching];
            [continueWatchingAlert addAction:startWatching];
            [continueWatchingAlert addAction:stopWatching];
            [self presentViewController:continueWatchingAlert animated:YES completion:nil];
        } else if (playerItem.status == AVPlayerItemStatusFailed) {
            if (self.delegate) {
                [self.delegate playStateDidChanged:PS_ERROR];
            }
            NSLog(@"Item is failed to play");
        } else if (playerItem.status == AVPlayerItemStatusUnknown) {
            NSLog(@"Item is unknown");
            if (self.delegate) {
                [self.delegate playStateDidChanged:PS_ERROR];
            }
        }
    } else if ([keyPath isEqualToString:@"rate"]) {
        NSLog(@"current rate %.2f", player.rate);
    } else if ([keyPath isEqualToString:@"timeControlStatus"]) {
        if (player.timeControlStatus == AVPlayerTimeControlStatusPaused) {
            NSLog(@"timeControlStatus paused");
            currentState = PS_PAUSED;
            displayLink.paused = YES;
        } else if (player.timeControlStatus == AVPlayerTimeControlStatusPlaying) {
            NSLog(@"timeControlStatus playing");
            currentState = PS_PLAYING;
            displayLink.paused = NO;
        } else if (player.timeControlStatus == AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate) {
            NSLog(@"timeControlStatus WaitingToPlayAtSpecifiedRate");
            currentState = PS_LOADING;
            displayLink.paused = YES;
        }
    }
}

- (NSMutableArray*)externalMetaData {
    NSMutableArray *array = [NSMutableArray array];
    if (title) {
        [array addObject:[self metadataItem:title identifier:AVMetadataCommonIdentifierTitle]];
    }
    if (subTitle) {
        [array addObject:[self metadataItem:subTitle identifier:AVMetadataIdentifierQuickTimeMetadataGenre]];
    }
    if (!description || [description isEqualToString:@""]) {
        description = @" ";
    }
    [array addObject:[self metadataItem:description identifier:AVMetadataCommonIdentifierDescription]];
    if (artworkImage) {
        AVMutableMetadataItem *item = [[AVMutableMetadataItem alloc] init];
        NSURL *url = [NSURL URLWithString:artworkImage];
        NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:nil];
        if (data) {
            item.identifier = AVMetadataCommonIdentifierArtwork;
            item.value = data;
            item.dataType = (__bridge NSString* _Nullable)kCMMetadataBaseDataType_JPEG;
            item.extendedLanguageTag = @"und";
            [array addObject:item];
        }
    }
    return array;
}

- (AVMutableMetadataItem*)metadataItem:(NSString*)value identifier:(NSString*)identifier {
    AVMutableMetadataItem *item = [[AVMutableMetadataItem alloc] init];
    item.value = value;
    item.identifier = identifier;
    item.extendedLanguageTag = @"und";
    return item;
}

- (void)panButtonList:(UIPanGestureRecognizer*)sender {
#if SUPPORT_PLAYLIST
    //CGPoint location = [sender translationInView:self.view];
    CGPoint v = [sender velocityInView:self.view];
    {//show logs here
        NSString *stateStr = @"";
        if (sender.state == UIGestureRecognizerStateBegan) {
            stateStr = @"Began";
        } else if (sender.state == UIGestureRecognizerStateChanged) {
            stateStr = @"Changed";
        } else if (sender.state == UIGestureRecognizerStateEnded) {
            stateStr = @"Ended";
            if (isPlayListShowing && currentState != PS_PAUSED && fabs(v.y)<2000 && v.x < -600) {
                [self hideButtonList];
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
        //NSLog(@"taped pan event state %@ point %f %f velocity %f %f", stateStr, location.x, location.y, v.x, v.y);
    }
#endif
}

- (void)pan:(UIPanGestureRecognizer*)sender {
#if SUPPORT_PLAYLIST
    //CGPoint location = [sender translationInView:self.view];
    CGPoint v = [sender velocityInView:self.view];
    {//show logs here
        NSString *stateStr = @"";
        if (sender.state == UIGestureRecognizerStateBegan) {
            stateStr = @"Began";
        } else if (sender.state == UIGestureRecognizerStateChanged) {
            stateStr = @"Changed";
        } else if (sender.state == UIGestureRecognizerStateEnded) {
            stateStr = @"Ended";
            if (currentState != PS_PAUSED && fabs(v.y)<2000 && v.x > 600) {
                [self showButtonList];
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
        //NSLog(@"taped pan event state %@ point %f %f velocity %f %f", stateStr, location.x, location.y, v.x, v.y);
    }
#endif
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

- (void)tapMenu:(UITapGestureRecognizer*)sender {
    NSLog(@"taped Menu Key");
    if (isPlayListShowing) {
        NSLog(@"hide Button List");
        [self hideButtonList];
    } else {
        if (currentState != PS_PAUSED) {
            NSLog(@"try exit");
            [self stop];
            /*
            [player pause];
            [self.delegate playStateDidChanged:PS_FINISH];
            [self.navigationController popViewControllerAnimated:YES];
             */
        } else {
            [player play];
        }
    }
}

-(void)play {
    [player play];
}

-(void)pause {
    [player pause];
}
-(void)stop {
    //[player pause];
    if (self.avPlayerViewController==nil) return;
    if (!playerInited) {
        NSLog(@"player not inited, no need do stop");
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (danmu) {
            [danmu removeFromSuperview];
        }
        if (player.currentItem) {
            [player.currentItem cancelPendingSeeks];
            [player.currentItem.asset cancelLoading];
            @try{
                [player.currentItem removeObserver:self forKeyPath:@"status" context:nil];
            } @catch(id anException){}
        }
        [player replaceCurrentItemWithPlayerItem:nil];
        @try{
            [player removeObserver:self forKeyPath:@"rate" context:nil];
        } @catch(id anException){}
        @try{
            [player removeTimeObserver:timeObserver];
        } @catch(id anException){}
        if (self.delegate) {
            [self.delegate playStateDidChanged:PS_FINISH];
            self.delegate=nil;
        }
        [self dismissViewControllerAnimated:NO completion:^{
            NSLog(@"stop dissmiss viewcontroller");
        }];
//        if (self.navigationController.topViewController == self) {
//            [self.navigationController popViewControllerAnimated:YES];
//        }
        /*
        if (displayLink) {
            @try {
                [displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            } @catch(id anException){}
        }
         */
        playerInited=NO;
    });
}

-(void)seekToTime:(CGFloat)time {
    [player seekToTime:CMTimeMake(time, 1)];
}

-(void)playVideo:(NSString*)url
       withTitle:(NSString*)_title
         withImg:(NSString*)img
  withDesciption:(NSString*)desc
         options:(NSMutableDictionary*)options
             mp4:(BOOL)mp4
  withResumeTime:(CGFloat)resumeTime {
    currentResumeTime = resumeTime;
    title = _title;
    description = desc;
    artworkImage = img;
    NSLog(@"AVPlayer playVideo %@", url);
    self.avPlayerViewController = [[AVPlayerViewController alloc] init];
    self.avPlayerViewController.delegate = self;
    if ([options.allKeys containsObject:@"headers"]) {
        headers = [options objectForKey:@"headers"];
    }
    MMVideoSources *videosSource = [MMVideoSources sourceFromURL:url];
    [videosSource dump];
    if (videosSource.segments.count==1) {
        AVURLAsset *asset = nil;
        if (headers) {
            asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:url]
                                        options:@{@"AVURLAssetHTTPHeaderFieldsKey": headers}];
        } else {
            asset = [AVURLAsset assetWithURL:[NSURL URLWithString:url]];
        }
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset: asset];
        item.externalMetadata = [self externalMetaData];
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
        //[player replaceCurrentItemWithPlayerItem:item];
        player = [[AVPlayer alloc] initWithPlayerItem:item];
    } else {
        NSMutableArray *items = [NSMutableArray array];
        for (MMVideoSegment *seg in videosSource.segments) {
            AVURLAsset *asset = nil;
            if (headers) {
                asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:seg.url]
                                            options:@{@"AVURLAssetHTTPHeaderFieldsKey": headers}];
            } else {
                asset = [AVURLAsset assetWithURL:[NSURL URLWithString:seg.url]];
            }
            AVPlayerItem *item = [AVPlayerItem playerItemWithAsset: asset];
            item.externalMetadata = [self externalMetaData];
            [items addObject:item];
        }
        player = [AVQueuePlayer queuePlayerWithItems:[items copy]];
    }
    [player addObserver:self
             forKeyPath:@"rate"
                options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                context:nil];
    [player addObserver:self
             forKeyPath:@"timeControlStatus"
                options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                context:nil];

    __weak typeof(self) weakSelf = self;
    timeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [weakSelf updateTimeClock];
        NSTimeInterval current = CMTimeGetSeconds(time);
        NSTimeInterval duration = CMTimeGetSeconds(weakSelf.avPlayerViewController.player.currentItem.duration);
        if (current > duration) current=duration;
        if (currentTime<duration-10.0 && current>= duration-10.0 && !isPlayListShowing) {
            [weakSelf showButtonList];
        }
        currentTime = current;
        //NSLog(@"time %.2f/%.2f", current, duration);
        if (weakSelf.delegate) {
            [weakSelf.delegate timeDidChanged:current duration:duration];
        }
    }];

    [player setActionAtItemEnd:AVPlayerActionAtItemEndNone];
    self.avPlayerViewController.player = player;
    
    self.avPlayerViewController.videoGravity = AVLayerVideoGravityResizeAspect;
    self.avPlayerViewController.showsPlaybackControls = YES;
    if (bgView) {
        [self.view insertSubview:self.avPlayerViewController.view belowSubview:bgView];
    } else {
        [self.view addSubview:self.avPlayerViewController.view];
    }
    danmu = [[DanMuLayer alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:danmu];
    
    timeLabel = [[StrokeUILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width-280, 60, 200, 60)];
    timeLabel.text = @"";
    timeLabel.textAlignment = NSTextAlignmentRight;
    timeLabel.font = [UIFont fontWithName:@"Menlo" size:50];
    timeLabel.textColor = [UIColor whiteColor];
    //[self.view addSubview:timeLabel];
    self.avPlayerViewController.view.frame = self.view.frame;
    [self.avPlayerViewController.contentOverlayView addSubview:timeLabel];

#if SUPPORT_PLAYLIST
    [self setNeedsFocusUpdate];
#endif
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

-(void)setSubTitle:(NSString*)subTitle {
    if (subsLabel==nil) {
        CGSize size = self.view.frame.size;
        subsLabel = [[StrokeUILabel alloc] init];
        subsLabel.textColor = [UIColor whiteColor];
        subsLabel.strokeColor = [UIColor blackColor];
        subsLabel.frame = CGRectMake(0, size.height-130, size.width, 80);
        subsLabel.font = [UIFont fontWithName:@"Menlo" size:65];
        subsLabel.textAlignment = NSTextAlignmentCenter;
        subsLabel.text = @"";
        [self.view addSubview:subsLabel];
    }
    subsLabel.text = subTitle;
}

- (NSString*)timeToStr:(int)time {
    int min = time/60;
    int sec = time-min*60;
    return [NSString stringWithFormat:@"%02d:%02d", min, sec];
}

- (void)updateTimeClock {
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
    //NSInteger seconds = [components second];
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];
    //NSLog(@"timeMode %zd", self.timeMode);
    if (self.timeMode==TIMEMODE_NONE && !isControllerVisible) {
        timeLabel.text = @"";
    } else if (self.timeMode==TIMEMODE_QUARTER) {
        if (minute%15==0) {
            timeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", hour, minute];
        } else {
            timeLabel.text = @"";
        }
    } else if (self.timeMode==TIMEMODE_HALF) {
        if (minute%30==0) {
            timeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", hour, minute];
        } else {
            timeLabel.text = @"";
        }
    } else {//ALWAYS
        timeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", hour, minute];
    }
    //NSLog(@"update Time: %@", timeLabel.text);
}

- (CGRect) videoRect {
    CGRect theVideoRect = CGRectZero;
    // Replace this with whatever frame your AVPlayer is playing inside of:
    CGRect theLayerRect = self.view.frame;
    AVAssetTrack *track = [player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo][0];
    CGSize theNaturalSize = [track naturalSize];
    theNaturalSize = CGSizeApplyAffineTransform(theNaturalSize, track.preferredTransform);
    theNaturalSize.width = fabs(theNaturalSize.width);
    theNaturalSize.height = fabs(theNaturalSize.height);
    
    CGFloat movieAspectRatio = theNaturalSize.width / theNaturalSize.height;
    CGFloat viewAspectRatio = theLayerRect.size.width / theLayerRect.size.height;
    
    // Note change this *greater than* to a *less than* if your video will play in aspect fit mode (as opposed to aspect fill mode)
    if (viewAspectRatio > movieAspectRatio) {
        theVideoRect.size.width = theLayerRect.size.width;
        theVideoRect.size.height = theLayerRect.size.width / movieAspectRatio;
        theVideoRect.origin.x = 0;
        theVideoRect.origin.y = (theLayerRect.size.height - theVideoRect.size.height) / 2;
    } else if (viewAspectRatio < movieAspectRatio) {
        theVideoRect.size.width = movieAspectRatio * theLayerRect.size.height;
        theVideoRect.size.height = theLayerRect.size.height;
        theVideoRect.origin.x = (theLayerRect.size.width - theVideoRect.size.width) / 2;
        theVideoRect.origin.y = 0;
    }
    return theVideoRect;
}
-(void)setupButtonList:(DMPlaylist*)playlist {
    list = playlist;
}
- (nullable NSIndexPath *)indexPathForPreferredFocusedViewInTableView:(UITableView *)tableView {
    NSLog(@"query indexPathForPreferredFocusedViewInTableView %zd", self.buttonFocusIndex);
    NSIndexPath *path = [NSIndexPath indexPathForRow:self.buttonFocusIndex inSection:0];
    return path;
}
- (void)playerViewController:(AVPlayerViewController *)playerViewController willTransitionToVisibilityOfTransportBar:(BOOL)visible withAnimationCoordinator:(id<AVPlayerViewControllerAnimationCoordinator>)coordinator {
    NSLog(@"willTransitionToVisibilityOfTransportBar %@", visible?@"true":@"false");
    isControllerVisible = visible;
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
    //NSInteger seconds = [components second];
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];
    NSLog(@"timeMode %zd", self.timeMode);
    //NSLog(@"update Time: %@", timeLabel.text);
    NSLog(@"do willTransitionToVisibilityOfTransportBar %@", visible?@"true":@"false");
    if (visible) {
        timeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", hour, minute];
    }
    if (timeMode!=TIMEMODE_ALWAYS && !visible) {
        timeLabel.text = @"";
    }
}
@end
