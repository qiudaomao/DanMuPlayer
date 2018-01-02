//
//  LazyCatAVPlayerController.m
//  LazyCat
//
//  Created by zfu on 2017/11/4.
//  Copyright © 2017年 zfu. All rights reserved.
//

#import "LazyCatAVPlayerViewController.h"
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
    UITableView *playlistTableView;
    UIVisualEffectView *bgView;
    AVPlayer *player;
    BOOL isPlayListShowing;
    CADisplayLink *displayLink;
    NSTimeInterval currentResumeTime;
    id timeObserver;
}
@end

@implementation LazyCatAVPlayerViewController
@synthesize delegate;

- (void)updateProgress {
    if (self.delegate) {
        NSTimeInterval current = CMTimeGetSeconds(player.currentTime);
        [self.delegate timeDidChangedHD:current];
    }
}

- (void)initVideoPlayListView {
    CGRect rect = CGRectMake(bgView.frame.origin.x, bgView.frame.origin.y, bgView.frame.size.width-80, bgView.frame.size.height);
    playlistTableView = [[UITableView alloc] initWithFrame:rect style:UITableViewStylePlain];
    playlistTableView.rowHeight = 70;
    playlistTableView.delegate = self;
    playlistTableView.dataSource = self;
    [bgView.contentView addSubview:playlistTableView];
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
    cell.textLabel.text = [NSString stringWithFormat:@"第%zd集", indexPath.row];
    cell.textLabel.textColor = UIColor.whiteColor;
    cell.textLabel.highlightedTextColor = UIColor.blackColor;
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 8;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"didSelectRowAtIndexPath %zd", indexPath.row);
}

- (void)viewDidLoad {
    [super viewDidLoad];
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
    CGRect rect = CGRectMake(0, 0, 500, UIScreen.mainScreen.bounds.size.height);
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    bgView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    bgView.frame = rect;
    isPlayListShowing = YES;
    [self setNeedsFocusUpdate];
    
    panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self.view addGestureRecognizer:panRecognizer];
    [self.view addSubview:bgView];
    [self initVideoPlayListView];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"hide Play List");
        [UIView animateWithDuration:0.2 delay:0.3 options:0 animations:^{
            CGSize size = bgView.frame.size;
            CGRect frame = CGRectMake(-size.width, 0, size.width, size.height);
            bgView.frame = frame;
        } completion:^(BOOL finished) {
            isPlayListShowing=NO;
            [self setNeedsFocusUpdate];
        }];
    });
#endif
}

- (void)viewDidDisappear:(BOOL)animated {
    displayLink.paused = YES;
    [displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)playerItemDidToPlayToEnd:(NSNotification *)notification
{
    if (self.delegate) {
        [self.delegate playStateDidChanged:PS_FINISH];
    }
}

- (void)playerItemFailedToPlayToEndTime:(NSNotification *)notification
{
    NSError *error = notification.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey];
    NSLog(@"error %@", error.localizedDescription);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem*)object;
    if ([keyPath isEqualToString:@"status"]) {
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
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
            if (fabs(v.y)<2000 && fabs(v.x) > 2000) {
                NSLog(@"show play list");
                [UIView animateWithDuration:0.2 delay:0.3 options:0 animations:^{
                    CGSize size = bgView.frame.size;
                    CGRect frame = CGRectMake(0, 0, size.width, size.height);
                    bgView.frame = frame;
                } completion:^(BOOL finished) {
                    isPlayListShowing=YES;
                    [self setNeedsFocusUpdate];
                }];
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

- (void)tapMenu:(UITapGestureRecognizer*)sender {
    NSLog(@"taped Menu Key");
    if (isPlayListShowing) {
        NSLog(@"hide Play List");
        [UIView animateWithDuration:0.2 delay:0.3 options:0 animations:^{
            CGSize size = bgView.frame.size;
            CGRect frame = CGRectMake(-size.width, 0, size.width, size.height);
            bgView.frame = frame;
        } completion:^(BOOL finished) {
            isPlayListShowing=NO;
            [self setNeedsFocusUpdate];
        }];
    } else {
        NSLog(@"try exit");
        [player pause];
        [self.delegate playStateDidChanged:PS_FINISH];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(instancetype)initWithItem:(JSValue*)item controller:(UINavigationController*)controller_ {
    isPlayListShowing = NO;
    self = [super init];
    self.controller = controller_;
    if ([item hasProperty:@"url"]) {
        url = [item objectForKeyedSubscript:@"url"].toString;
    }
    if ([item hasProperty:@"headers"]) {
        headers = [item objectForKeyedSubscript:@"headers"].toDictionary;
    }
    if ([item hasProperty:@"title"]) {
        title = [item objectForKeyedSubscript:@"title"].toString;
    }
    if ([item hasProperty:@"subTitle"]) {
        subTitle = [item objectForKeyedSubscript:@"subTitle"].toString;
    }
    if ([item hasProperty:@"description"]) {
        description = [item objectForKeyedSubscript:@"description"].toString;
    }
    if ([item hasProperty:@"artworkImage"]) {
        artworkImage = [item objectForKeyedSubscript:@"artworkImage"].toString;
    }
    return self;
}

-(void)play {
    [player play];
}

-(void)pause {
    [player pause];
}
-(void)stop {
    //[player pause];
    [player removeTimeObserver:timeObserver];
    [self.delegate playStateDidChanged:PS_FINISH];
    [self.navigationController popViewControllerAnimated:YES];
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
    if ([options.allKeys containsObject:@"headers"]) {
        headers = [options objectForKey:@"headers"];
    }
    AVURLAsset *asset = nil;
    if (headers) {
        asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:url]
                                    options:@{@"AVURLAssetHTTPHeaderFieldsKey": headers}];
    } else {
        asset = [AVURLAsset assetWithURL:[NSURL URLWithString:url]];
    }
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset: asset];
    item.externalMetadata = [self externalMetaData];
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
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
    
    __weak typeof(self) weakSelf = self;
    timeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        NSTimeInterval current = CMTimeGetSeconds(time);
        NSTimeInterval duration = CMTimeGetSeconds(weakSelf.avPlayerViewController.player.currentItem.duration);
        NSLog(@"time %.2f/%.2f", current, duration);
        if (weakSelf.delegate) {
            [weakSelf.delegate timeDidChanged:current duration:duration];
        }
    }];

    [player setActionAtItemEnd:AVPlayerActionAtItemEndNone];
    self.avPlayerViewController.player = player;
    
    self.avPlayerViewController.videoGravity = AVLayerVideoGravityResizeAspect;
    self.avPlayerViewController.showsPlaybackControls = YES;
    [self.view insertSubview:self.avPlayerViewController.view belowSubview:bgView];
    self.avPlayerViewController.view.frame = self.view.frame;
    [self setNeedsFocusUpdate];
}

-(void)addDanMu:(NSString*)content
      withStyle:(DanmuStyle)style
      withColor:(UIColor*)color
withStrokeColor:(UIColor*)bgcolor
   withFontSize:(CGFloat)fontSize {
}

-(void)setSubTitle:(NSString*)subTitle {
}

- (NSString*)timeToStr:(int)time {
    int min = time/60;
    int sec = time-min*60;
    return [NSString stringWithFormat:@"%02d:%02d", min, sec];
}
@end
