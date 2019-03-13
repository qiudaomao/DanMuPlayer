//
//  HUDView.m
//  DanMuPlayer
//
//  Created by zfu on 2018/5/11.
//  Copyright © 2018 zfu. All rights reserved.
//

#import "HUDView.h"

@interface HUDView() {
    UIProgressView *_progress;
    StrokeUILabel *_title;
    StrokeUILabel *_currentTime;
    StrokeUILabel *_leftTime;
    StrokeUILabel *_statLabel;
    StrokeUILabel *_timeLabel;
    StrokeUILabel *_presentSizeLabel;
    UIGestureRecognizer *touchRecognizer;
    UIActivityIndicatorView *loadingIndicator;
    UIImageView *pointImageView;
    UIImageView *pauseImageView;
    StrokeUILabel *pauseTimeLabel;
    StrokeUILabel *_pointTime;
    StrokeUILabel *subTitle;
    CGPoint indicatorStartPoint;
    
    UIView *hudLayer;
    NSTimer *hideTimer;
}
@end

@implementation HUDView
@synthesize currentTime = _currentTime;
@synthesize leftTime = _leftTime;
@synthesize danmu = _danmu;
@synthesize delegate = _delegate;

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)initHud
{
    NSLog(@"initHud");
    CGSize size = [self bounds].size;
    
    _danmu = [[DanMuLayer alloc] initWithFrame:self.bounds];
    [self addSubview:_danmu];
    
    subTitle = [[StrokeUILabel alloc] init];
    subTitle.textColor = [UIColor whiteColor];
    subTitle.strokeColor = [UIColor blackColor];
    subTitle.frame = CGRectMake(0, size.height-130, size.width, 80);
    subTitle.font = [UIFont fontWithName:@"Menlo" size:65];
    subTitle.textAlignment = NSTextAlignmentCenter;
    subTitle.text = @"";
    [self addSubview:subTitle];
    
    hudLayer = [[UIView alloc] init];
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
    
    [self addSubview:hudLayer];
    [self addSubview:loadingIndicator];
    [self addSubview:_timeLabel];
    [self addSubview:_presentSizeLabel];
    
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
}

- (void)updateProgress:(NSTimeInterval)current playableTime:(NSTimeInterval)playableTime buffering:(BOOL)buffering total:(NSTimeInterval)total {
    if (buffering) {
        loadingIndicator.hidden = NO;
        [loadingIndicator startAnimating];
    } else if (loadingIndicator.hidden==NO){
        loadingIndicator.hidden = YES;
        [loadingIndicator stopAnimating];
    }
    if (total > 0.001) {
        _currentTime.text = [self timeToStr:current];
        _leftTime.text = [self timeToStr:(total-current)];
    } else {
        _currentTime.text = @"Live";
        _leftTime.text = @"";
    }
    if (total > 0.0f) _progress.progress = playableTime / total;
    else _progress.progress = 0.0f;
    [self updatePointTime:current duration:total];
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
    self.hidden = NO;
    __weak typeof(self) weakSelf = self;
    hideTimer = [NSTimer timerWithTimeInterval:8.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
        weakSelf.hidden = YES;
    }];
}

- (void)stopHideTimer {
    if (hideTimer && hideTimer.isValid) {
        [hideTimer invalidate];
    }
    self.hidden = NO;
}
- (void)setVideoInfo:(NSString*)title {
    _title.text = title;
}
- (void)updatePointTime: (CGFloat)time duration: (CGFloat)duration
{
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
@end
