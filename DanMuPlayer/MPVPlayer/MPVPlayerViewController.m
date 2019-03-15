//
//  MPVPlayerMPVPlayerViewController.m
//  DanMuPlayer
//
//  Created by zfu on 2018/5/9.
//  Copyright © 2018 zfu. All rights reserved.
//

#import "MPVPlayerViewController.h"

@import GLKit;
@import OpenGLES;
@import UIKit;

#import <mpv/client.h>
#import <mpv/opengl_cb.h>

#import <AVKit/AVKit.h>

#import <stdio.h>
#import <stdlib.h>

static inline void check_error(int status)
{
    if (status < 0) {
        printf("mpv API error: %s\n", mpv_error_string(status));
    }
}

static void *get_proc_address(void *ctx, const char *name)
{
    CFStringRef symbolName = CFStringCreateWithCString(kCFAllocatorDefault, name, kCFStringEncodingASCII);
    void *addr = CFBundleGetFunctionPointerForName(CFBundleGetBundleWithIdentifier(CFSTR("com.apple.opengles")), symbolName);
    CFRelease(symbolName);
    return addr;
}

static void glupdate(void *ctx);

@interface MpvClientOGLView : GLKView
@property mpv_opengl_cb_context *mpvGL;
@property NSLock *uninitLock;
@property bool isUninit;
@end

@implementation MpvClientOGLView {
    GLint defaultFBO;
}
@synthesize uninitLock = _uninitLock;
@synthesize isUninit = _isUninit;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    _uninitLock = [[NSLock alloc] init];
    _isUninit = NO;

    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    [EAGLContext setCurrentContext:self.context];

    // Configure renderbuffers created by the view
    self.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    self.drawableDepthFormat = GLKViewDrawableDepthFormatNone;
    self.drawableStencilFormat = GLKViewDrawableStencilFormatNone;

    defaultFBO = -1;
    self.opaque = true;

    [self fillBlack];

    return self;
}

- (void)fillBlack
{
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)drawRect
{
    [_uninitLock lock];
    if (_isUninit) {
        [_uninitLock unlock];
        return;
    }
    if (defaultFBO == -1) {
        glGetIntegerv(GL_FRAMEBUFFER_BINDING, &defaultFBO);
    }

    if (self.mpvGL)
    {
        mpv_opengl_cb_draw(self.mpvGL,
                           defaultFBO,
                           self.bounds.size.width * self.contentScaleFactor,
                           -self.bounds.size.height * self.contentScaleFactor);
    }
    [_uninitLock unlock];
}

- (void)drawRect:(CGRect)rect
{
    [self drawRect];
}
@end
static void wakeup(void *);
static void glupdate(void *ctx)
{
    MpvClientOGLView *glView = (__bridge MpvClientOGLView *)ctx;
    // I'm still not sure what the best way to handle this is, but this
    // works.
    dispatch_async(dispatch_get_main_queue(), ^{
        [glView display];
    });
}

@interface MPVPlayerViewController () {
    mpv_handle *mpv;
    dispatch_queue_t queue;
    UITapGestureRecognizer *menuRecognizer;
    BOOL isViewLayouted;
    HUDView *hudView;
    NSTimer *playTimeTimer;
    NSTimeInterval currentPos;
    NSTimeInterval videoDuration;
    CGSize videoSize;
    BOOL fileLoaded;
    CADisplayLink *displayLink;
}

@property (nonatomic) MpvClientOGLView *glView;
- (void) readEvents;

@end

static void wakeup(void *context)
{
    MPVPlayerViewController *a = (__bridge MPVPlayerViewController *) context;
    [a readEvents];
}
@implementation MPVPlayerViewController
@synthesize delegate;
@synthesize buttonClickCallback;
@synthesize buttonFocusIndex;
@synthesize timeMode;
@synthesize danmuView;

- (void)loadView {
    [super loadView];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    isViewLayouted = NO;

    // set up the mpv player view
    _glView = [[MpvClientOGLView alloc] initWithFrame:screenBounds];
    mpv = mpv_create();
    if (!mpv) {
        printf("failed creating context\n");
        return;
    }

    // request important errors -- extract this file with iTunes file sharing
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *fileName =[NSString stringWithFormat:@"mpv-%@.log",[NSDate date]];
    NSString *logFile = [documentsDirectory stringByAppendingPathComponent:fileName];
    NSLog(@"%@", logFile);

    check_error(mpv_set_option_string(mpv, "log-file", logFile.UTF8String));
    check_error(mpv_request_log_messages(mpv, "status"));
    check_error(mpv_initialize(mpv));
    check_error(mpv_set_option_string(mpv, "vo", "opengl-cb"));
    check_error(mpv_set_option_string(mpv, "hwdec", "yes"));
    check_error(mpv_set_option_string(mpv, "hwdec-codecs", "all"));
    check_error(mpv_request_log_messages(mpv, "info"));

    mpv_opengl_cb_context *mpvGL = mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB);
    if (!mpvGL) {
        puts("libmpv does not have the opengl-cb sub-API.");
        return;
    }

    [self.glView display];

    // pass the mpvGL context to our view
    self.glView.mpvGL = mpvGL;
    int r = mpv_opengl_cb_init_gl(mpvGL, NULL, get_proc_address, NULL);
    if (r < 0) {
        puts("gl init has failed.");
        return;
    }
    mpv_opengl_cb_set_update_callback(mpvGL, glupdate, (__bridge void *)self.glView);

    // Deal with MPV in the background.
    queue = dispatch_queue_create("mpv", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        // Register to be woken up whenever mpv generates new events.
        mpv_set_wakeup_callback(self->mpv, wakeup, (__bridge void *)self);
        // Load the indicated file

        //const char *cmd[] = {"loadfile", "http://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_640x360.m4v", NULL};
//        const char *cmd[] = {"loadfile", "edl://http://localhost/media/BigBuckBunny_640x360.m4v,length=596;http://localhost/media/BigBuckBunny_640x360.m4v,length=596;", NULL};
        //        NSURL *movieURL = [[NSBundle mainBundle] URLForResource:@"hevc-test-soccer" withExtension:@"mts"];
        //        const char *cmd[] = {"loadfile", [movieURL.absoluteString UTF8String], NULL};
//        check_error(mpv_command(self->mpv, cmd));
        check_error(mpv_set_option_string(self->mpv, "loop", "inf"));
    });

    [self.view addSubview:_glView];

    menuRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapMenu:)];
    menuRecognizer.allowedPressTypes = @[@(UIPressTypeMenu)];
    [self.view addGestureRecognizer:menuRecognizer];
    hudView = [[HUDView alloc] initWithFrame:self.view.bounds];
    hudView.delegate = self;
    [self.view addSubview:hudView];

    playTimeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                     target:self
                                                   selector:@selector(updatePlayTime)
                                                   userInfo:nil
                                                    repeats:YES];
}
-(void)viewDidLoad {
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress)];
    displayLink.paused = YES;
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)updateProgress
{
    if (mpv && fileLoaded) {
        double timePos = 0.0;
//        int64_t cacheSize=0, cacheUsed=0, cacheSpeed=0, demuxerCacheTime=0, cacheBufferingState=0;
//        int pausedForCache = 0;
        [hudView.danmu updateFrame];
        check_error(mpv_get_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &timePos));
//        check_error(mpv_get_property(mpv, "paused-for-cache", MPV_FORMAT_FLAG, &pausedForCache));
//        check_error(mpv_get_property(mpv, "cache-size", MPV_FORMAT_INT64, &cacheSize));
//        check_error(mpv_get_property(mpv, "cache-used", MPV_FORMAT_INT64, &cacheUsed));
//        check_error(mpv_get_property(mpv, "cache-speed", MPV_FORMAT_INT64, &cacheSpeed));
//        check_error(mpv_get_property(mpv, "demuxer-cache-duration", MPV_FORMAT_INT64, &demuxerCacheTime));
//        check_error(mpv_get_property(mpv, "cache-buffering-state", MPV_FORMAT_INT64, &cacheBufferingState));
//        NSLog(@"updatePlayTime %10s %10s %10s %10s %10s %10s %10s", "timePos", "pausedForCache", "cacheSize", "cacheUsed", "cacheSpeed", "demuxerCTime", "bufferingS");
//        NSLog(@"updatePlayTime %10.2f %10d %10lld %10lld %10lld %10lld %10lld", timePos, pausedForCache, cacheSize, cacheUsed, cacheSpeed, demuxerCacheTime, cacheBufferingState);
//        [hudView updatePointTime:timePos duration:videoDuration];
        if (self.delegate) {
            [self.delegate timeDidChangedHD:timePos];
        }
    }
    [hudView.danmu updateFrame];
}

- (void)updatePlayTime {
    double timePos = 0.0;
    int64_t cacheSize=0, cacheUsed=0, cacheSpeed=0, demuxerCacheTime=0, cacheBufferingState=0;
    int pausedForCache = 0;
    if (mpv && fileLoaded) {
        check_error(mpv_get_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &timePos));
        check_error(mpv_get_property(mpv, "paused-for-cache", MPV_FORMAT_FLAG, &pausedForCache));
        check_error(mpv_get_property(mpv, "cache-size", MPV_FORMAT_INT64, &cacheSize));
        check_error(mpv_get_property(mpv, "cache-used", MPV_FORMAT_INT64, &cacheUsed));
        check_error(mpv_get_property(mpv, "cache-speed", MPV_FORMAT_INT64, &cacheSpeed));
        check_error(mpv_get_property(mpv, "demuxer-cache-duration", MPV_FORMAT_INT64, &demuxerCacheTime));
        check_error(mpv_get_property(mpv, "cache-buffering-state", MPV_FORMAT_INT64, &cacheBufferingState));
//        NSLog(@"updatePlayTime %10s %10s %10s %10s %10s %10s %10s", "timePos", "pausedForCache", "cacheSize", "cacheUsed", "cacheSpeed", "demuxerCTime", "bufferingS");
//        NSLog(@"updatePlayTime %10.2f %10d %10lld %10lld %10lld %10lld %10lld", timePos, pausedForCache, cacheSize, cacheUsed, cacheSpeed, demuxerCacheTime, cacheBufferingState);
        if (self.delegate) {
            [self.delegate timeDidChanged:timePos duration:videoDuration];
        }
        [hudView updateProgress:timePos playableTime:(timePos+demuxerCacheTime) buffering:pausedForCache>0 total:videoDuration];
    }
}

- (void)viewDidLayoutSubviews {
    if (isViewLayouted) return;
    isViewLayouted = YES;
    [hudView initHud];
}

- (void)tapMenu:(UITapGestureRecognizer*)sender {
    NSLog(@"tapMenu");
    [self stop];
}

- (void)handleEvent:(mpv_event *)event
{
    switch (event->event_id) {
        case MPV_EVENT_SHUTDOWN: {
            NSLog(@"event: shutdown start");
            [self.glView.uninitLock lock];
            if (self.glView.isUninit) {
                [self.glView.uninitLock unlock];
                return;
            }
            mpv_opengl_cb_uninit_gl(self.glView.mpvGL);
            mpv_detach_destroy(mpv);
            mpv = NULL;
            NSLog(@"event: shutdown start finish");
            [self.glView.uninitLock unlock];
            break;
        }
        case MPV_EVENT_LOG_MESSAGE: {
            struct mpv_event_log_message *msg = (struct mpv_event_log_message *)event->data;
            NSLog(@"mpv: [%s] %s: %s", msg->prefix, msg->level, msg->text);
            break;
        }
        case MPV_EVENT_PLAYBACK_RESTART: {
            NSLog(@"mpv: mpv_event_playback_restart");
            break;
        }
        case MPV_EVENT_PROPERTY_CHANGE: {
            NSLog(@"mpv: mpv_event_property_change");
            break;
        }
        case MPV_EVENT_UNPAUSE: {
            NSLog(@"mpv: mpv_event_unpause");
            displayLink.paused = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication.sharedApplication setIdleTimerDisabled:YES];
            });
            break;
        }
        case MPV_EVENT_PAUSE: {
            NSLog(@"mpv: mpv_event_pause");
            displayLink.paused = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication.sharedApplication setIdleTimerDisabled:NO];
            });
            break;
        }
        case MPV_EVENT_FILE_LOADED: {
            int64_t width, height;
            double duration;
            check_error(mpv_get_property(mpv, "width", MPV_FORMAT_INT64, &width));
            check_error(mpv_get_property(mpv, "height", MPV_FORMAT_INT64, &height));
            check_error(mpv_get_property(mpv, "duration", MPV_FORMAT_DOUBLE, &duration));
            videoSize = CGSizeMake(width, height);
            videoDuration = duration;
            fileLoaded = YES;
            displayLink.paused = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication.sharedApplication setIdleTimerDisabled:YES];
            });
            break;
        }
        default:
            printf("event: %s\n", mpv_event_name(event->event_id));
    }
}

- (void)readEvents
{
    dispatch_async(queue, ^{
        while (self->mpv) {
            mpv_event *event = mpv_wait_event(self->mpv, 0);
            if (event->event_id == MPV_EVENT_NONE) {
                break;
            }
            [self handleEvent:event];
        }
    });
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    _glView.frame = CGRectMake(0, 0, size.width, size.height);
}

-(void)pause {
    int pause = 1;
    check_error(mpv_set_property(mpv, "pause", MPV_FORMAT_FLAG, &pause));
}
-(void)play {
    int pause = 0;
    check_error(mpv_set_property(mpv, "pause", MPV_FORMAT_FLAG, &pause));
}
-(void)stop {
    const char *cmd[] = { "quit", NULL };
    NSLog(@"mpv destroy");
    [displayLink invalidate];
    displayLink = nil;
    check_error(mpv_command(mpv, cmd));
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication.sharedApplication setIdleTimerDisabled:NO];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:NO completion:^{
            NSLog(@"popViewController finish while stop");
        }];
    });
}

-(void)seekToTime:(CGFloat)time {
    NSString *value = [NSString stringWithFormat:@"%f", time];
    const char *cmd[] = {"seek", value.UTF8String, "absolute+exact", NULL};
    check_error(mpv_command(mpv, cmd));
}

- (void)seekProgress:(NSTimeInterval)time {
    [self seekToTime:time];
}

-(void)playVideo:(NSString*)url
       withTitle:(NSString*)title
         withImg:(NSString*)img
  withDesciption:(NSString*)desc
         options:(NSMutableDictionary*)options
             mp4:(BOOL)mp4
  withResumeTime:(CGFloat)resumeTime {
    fileLoaded = NO;
    [hudView setVideoInfo:title];
    if ([options.allKeys containsObject:@"User-Agent"]) {
        NSString *ua = [options objectForKey:@"User-Agent"];
        NSLog(@"set --user-agent: %@", ua);
        check_error(mpv_set_option_string(mpv, "user-agent", ua.UTF8String));
    }
    if ([options.allKeys containsObject:@"headers"]) {
        NSDictionary *headers = [options objectForKey:@"headers"];
        NSString *headerStr = @"";
        for (NSString *key in headers.allKeys) {
            NSString *value = [headers objectForKey:key];
            NSString *item = [NSString stringWithFormat:@"%@:%@;", key, value];
            headerStr = [headerStr stringByAppendingString:item];
        }
        NSLog(@"set --http-header-fields %@", headerStr);
        check_error(mpv_set_option_string(mpv, "http-header-fields", headerStr.UTF8String));
    }
    if (url) {
        NSString *videoURL = url;
        NSString *audioURL = nil;
        if ([url rangeOfString:@"%%"].location != NSNotFound) {
            NSRange range = [url rangeOfString:@"%%"];
            videoURL = [url substringWithRange:NSMakeRange(0, range.location)];
            audioURL = [url substringWithRange:NSMakeRange(range.location+2, url.length-range.location-2)];
            NSLog(@"load video file %@", videoURL);
            NSLog(@"load audio file %@", audioURL);
        }
        dispatch_async(queue, ^{
            const char *cmd[] = {"loadfile", videoURL.UTF8String, NULL};
            check_error(mpv_command(self->mpv, cmd));
            if (audioURL) {
                check_error(mpv_set_option_string(self->mpv, "audio-files", audioURL.UTF8String));
            }
        });
    }
}
-(void)addDanMu:(NSString*)content
      withStyle:(DanmuStyle)style
      withColor:(UIColor*)color
withStrokeColor:(UIColor*)bgcolor
   withFontSize:(CGFloat)fontSize {
    [hudView.danmu addDanMu:content
                  withStyle:style
                  withColor:color
            withStrokeColor:bgcolor
               withFontSize:fontSize];
}

-(void)setSubTitle:(NSString*)subTitle {
}
-(void)setupButtonList:(DMPlaylist*)playlist {
}
@end
