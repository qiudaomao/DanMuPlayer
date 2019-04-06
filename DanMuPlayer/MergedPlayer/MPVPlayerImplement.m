//
//  MPVPlayerImplement.m
//  DanMuPlayer
//
//  Created by zfu on 2019/3/26.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "MPVPlayerImplement.h"
@import GLKit;
@import OpenGLES;
@import UIKit;

#import <mpv/client.h>
#import <mpv/opengl_cb.h>

#import <AVKit/AVKit.h>

#import <stdio.h>
#import <stdlib.h>

static inline void check_error(int status, const char *property)
{
    if (status < 0) {
        printf("mpv API error: %s when change %s\n", mpv_error_string(status), property);
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
@property CGRect mBounds;
@property CGFloat scaleFactor;
@property dispatch_queue_t mpvGLQueue;
@end

@implementation MpvClientOGLView {
    GLint defaultFBO;
}
@synthesize uninitLock = _uninitLock;
@synthesize isUninit = _isUninit;
@synthesize mpvGLQueue = _mpvGLQueue;
@synthesize mBounds = _mBounds;
@synthesize scaleFactor = _scaleFactor;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    _uninitLock = [[NSLock alloc] init];
    _isUninit = NO;
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, 0);
    _mpvGLQueue = dispatch_queue_create("com.fuzhuo.lazycat.mpvgl", attr);
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        return self;
    }
    [EAGLContext setCurrentContext:self.context];
    
    // Configure renderbuffers created by the view
    self.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    self.drawableDepthFormat = GLKViewDrawableDepthFormatNone;
    self.drawableStencilFormat = GLKViewDrawableStencilFormatNone;
    
    defaultFBO = -1;
    self.opaque = true;
    
    _mBounds = self.bounds;
    _scaleFactor = self.contentScaleFactor;
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
    __weak typeof(self) weakSelf = self;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        CGRect bounds = weakSelf.bounds;
//        CGFloat contentScaleFactor = weakSelf.contentScaleFactor;
        dispatch_async(self->_mpvGLQueue, ^{
            typeof(self) strongSelf = weakSelf;
            [self->_uninitLock lock];
            if (self->_isUninit) {
                [self->_uninitLock unlock];
                return;
            }
            if (self->defaultFBO == -1) {
                glGetIntegerv(GL_FRAMEBUFFER_BINDING, &self->defaultFBO);
            }
            
            if (strongSelf.mpvGL) {
                mpv_opengl_cb_draw(strongSelf.mpvGL,
                                   self->defaultFBO,
                                   self->_mBounds.size.width * self->_scaleFactor,
                                   -self->_mBounds.size.height * self->_scaleFactor);
            }
            [self->_uninitLock unlock];
        });
//    });
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
    dispatch_async(glView.mpvGLQueue, ^{
        [glView display];
//        [glView setNeedsDisplay];
//        [glView.layer setDrawsAsynchronously:YES];
    });
}

@interface MPVPlayerImplement () {
    mpv_handle *mpv;
    dispatch_queue_t queue;
    UITapGestureRecognizer *menuRecognizer;
    BOOL isViewLayouted;
    NSTimer *playTimeTimer;
    NSTimeInterval currentPos;
    NSTimeInterval videoDuration;
    NSTimeInterval playAbleTime;
    CGSize videoSize;
    BOOL fileLoaded;
    BOOL paused;
    BOOL currentPausedForCache;
}

@property (nonatomic) MpvClientOGLView *glView;
- (void) readEvents;

@end

static void wakeup(void *context)
{
    MPVPlayerImplement *a = (__bridge MPVPlayerImplement *) context;
    [a readEvents];
}
@implementation MPVPlayerImplement
@synthesize videoView;
@synthesize videoSize;
@synthesize delegate;

- (void)loadView {
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
    NSString *fileName =[NSString stringWithFormat:@"mpv.log"];//, [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970] * 1000]];//[NSDate date]];
    NSString *logFile = [documentsDirectory stringByAppendingPathComponent:fileName];
    NSLog(@"%@", logFile);
    
    check_error(mpv_set_option_string(mpv, "log-file", logFile.UTF8String), "log-file");
    check_error(mpv_request_log_messages(mpv, "info"), "request_log_message info");
    check_error(mpv_initialize(mpv), "initial");
    check_error(mpv_set_option_string(mpv, "vo", "opengl-cb"), "vo");
    check_error(mpv_set_option_string(mpv, "hwdec", "auto"), "hwdec");
    check_error(mpv_set_option_string(mpv, "hwdec-codecs", "all"), "hwdec-codecs");
    check_error(mpv_set_option_string(mpv, "sub-ass", "yes"), "sub-ass");
    check_error(mpv_set_option_string(mpv, "sub-auto", "all"), "sub-auto");

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
        check_error(mpv_set_option_string(self->mpv, "loop", "inf"), "loop");
    });
    
    self.videoView = _glView;
    paused = YES;
    currentPausedForCache = YES;
    playTimeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                     target:self
                                                   selector:@selector(updatePlayTime)
                                                   userInfo:nil
                                                    repeats:YES];
}

- (void)updatePlayTime {
    double timePos = 0.0;
    double demuxerCacheDuration = 0.0;
    double demuxerCacheTime = 0.0;
    double duration = 0.0;
//    int64_t cacheSize=0, cacheUsed=0, cacheSpeed=0, cacheBufferingState=0;
    int pausedForCache = 0;
    if (mpv && fileLoaded) {
        check_error(mpv_get_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &timePos), "time-pos");
        check_error(mpv_get_property(mpv, "paused-for-cache", MPV_FORMAT_FLAG, &pausedForCache), "paused-for-cache");
//        check_error(mpv_get_property(mpv, "cache-size", MPV_FORMAT_INT64, &cacheSize));
//        check_error(mpv_get_property(mpv, "cache-used", MPV_FORMAT_INT64, &cacheUsed));
//        check_error(mpv_get_property(mpv, "cache-speed", MPV_FORMAT_INT64, &cacheSpeed));
        check_error(mpv_get_property(mpv, "demuxer-cache-time", MPV_FORMAT_DOUBLE, &demuxerCacheTime), "demuxer-cache-time");
        check_error(mpv_get_property(mpv, "demuxer-cache-duration", MPV_FORMAT_DOUBLE, &demuxerCacheDuration), "demuxer-cache-duration");
        check_error(mpv_get_property(mpv, "duration", MPV_FORMAT_DOUBLE, &duration), "duration");
//        check_error(mpv_get_property(mpv, "cache-buffering-state", MPV_FORMAT_INT64, &cacheBufferingState));
//        NSLog(@"updatePlayTime %10s %10s %10s %10s %10s %10s %10s", "timePos", "pausedForCache", "cacheSize", "cacheUsed", "cacheSpeed", "demuxerCTime", "bufferingS");
        currentPos = timePos;
        if (self.delegate) {
            if (currentPausedForCache != pausedForCache) {
                currentPausedForCache = pausedForCache;
                if (pausedForCache) {
                    [self.delegate bufferring];
                } else {
                    [self.delegate stopBufferring];
                }
            }
        }
        if (paused) return;
        NSLog(@"updatePlayTime pos %.2f paused %d cache-time %.2f cache-duration %.2f duration %.2f",
              timePos, pausedForCache, demuxerCacheTime, demuxerCacheDuration, duration);
        if (self.delegate) {
            playAbleTime = demuxerCacheTime;
            [self.delegate updateProgress:timePos playableTime:demuxerCacheTime buffering:NO total:videoDuration];
        }
    }
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
            self.glView.mpvGL = nil;
            mpv_detach_destroy(mpv);
            mpv = NULL;
            NSLog(@"event: shutdown finish");
            [self.glView.uninitLock unlock];
            if (self.delegate) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->delegate onEnd];
                });
            }
            break;
        }
        case MPV_EVENT_LOG_MESSAGE: {
            struct mpv_event_log_message *msg = (struct mpv_event_log_message *)event->data;
            NSLog(@"mpv: [%s] %s: %s", msg->prefix, msg->level, msg->text);
            break;
        }
        case MPV_EVENT_PLAYBACK_RESTART: {
            NSLog(@"mpv: mpv_event_playback_restart");
            paused = NO;
            if (self.delegate) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->delegate onPlay];
                });
            }
            break;
        }
        case MPV_EVENT_PROPERTY_CHANGE: {
            NSLog(@"mpv: mpv_event_property_change");
            break;
        }
        case MPV_EVENT_UNPAUSE: {
            NSLog(@"mpv: mpv_event_unpause");
            paused = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication.sharedApplication setIdleTimerDisabled:YES];
            });
            if (self.delegate) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->delegate onPlay];
                });
            }
            break;
        }
        case MPV_EVENT_PAUSE: {
            NSLog(@"mpv: mpv_event_pause");
            paused = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication.sharedApplication setIdleTimerDisabled:NO];
            });
            if (self.delegate) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->delegate onPause];
                });
            }
            break;
        }
        case MPV_EVENT_FILE_LOADED: {
            int64_t width, height;
            double duration;
            double fps;
            check_error(mpv_get_property(mpv, "width", MPV_FORMAT_INT64, &width), "width");
            check_error(mpv_get_property(mpv, "height", MPV_FORMAT_INT64, &height), "height");
            check_error(mpv_get_property(mpv, "duration", MPV_FORMAT_DOUBLE, &duration), "duration");
            check_error(mpv_get_property(mpv, "container-fps", MPV_FORMAT_DOUBLE, &fps), "container-fps");
            videoSize = CGSizeMake(width, height);
            videoDuration = duration;
            fileLoaded = YES;
            if (self.delegate) {
                [self.delegate onVideoSizeChanged:videoSize];
                [self.delegate onVideoFPSChanged:fps];
            }
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
    check_error(mpv_set_property(mpv, "pause", MPV_FORMAT_FLAG, &pause), "pause");
}

-(void)play {
    int pause = 0;
    check_error(mpv_set_property(mpv, "pause", MPV_FORMAT_FLAG, &pause), "pause");
}

-(void)stop {
    const char *cmd[] = { "quit", NULL };
    NSLog(@"mpv destroy");
    check_error(mpv_command(mpv, cmd), "cmd quit");
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication.sharedApplication setIdleTimerDisabled:NO];
    });
//    if (self.delegate) {
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//            [self.delegate onEnd];
//        });
//    }
}

-(void)seekToTime:(CGFloat)time {
    NSString *value = [NSString stringWithFormat:@"%f", time];
    const char *cmd[] = {"seek", value.UTF8String, "absolute+exact", NULL};
    check_error(mpv_command(mpv, cmd), "cmd seek");
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
    [self loadView];
    fileLoaded = NO;
    if ([options.allKeys containsObject:@"User-Agent"]) {
        NSString *ua = [options objectForKey:@"User-Agent"];
        NSLog(@"set --user-agent: %@", ua);
        check_error(mpv_set_option_string(mpv, "user-agent", ua.UTF8String), "user-agent");
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
        check_error(mpv_set_option_string(mpv, "http-header-fields", headerStr.UTF8String), "--http-header-fields");
    }
    //demuxer-lavf-o=protocol_whitelist=[file,http,https,tls,rtp,tcp,udp,crypto,httpproxy]
    check_error(mpv_set_option_string(mpv, "demuxer-lavf-o",
                                      "protocol_whitelist=[file,http,https,tls,rtp,rtmp, rtsp,tcp,udp,crypto,httpproxy,ftp]"), "demuxer-lavf-o");
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
            check_error(mpv_command(self->mpv, cmd), "loadfile");
            if (audioURL) {
                check_error(mpv_set_option_string(self->mpv, "audio-files", audioURL.UTF8String), "audio-files");
            }
        });
        if ([options.allKeys containsObject:@"sub-file"]) {
            NSString *subPath = [options objectForKey:@"sub-file"];
//            check_error(mpv_set_option_string(self->mpv, "sub-files", subPath.UTF8String));
            dispatch_async(queue, ^{
                const char *cmd[] = {"sub-add", subPath.UTF8String, NULL};
                check_error(mpv_command(self->mpv, cmd), "sub-add");
            });
            check_error(mpv_set_option_string(mpv, "sub-scale-by-window", "yes"), "sub-scale-by-window");
            /*
            check_error(mpv_set_option_string(mpv, "sub-font", "Helvetica"));
            int64_t fontSize = 24;
            check_error(mpv_set_option(mpv, "sub-font-size", MPV_FORMAT_INT64, &fontSize));
            int64_t sid = 1;
            check_error(mpv_set_option(mpv, "sid", MPV_FORMAT_INT64, &sid));
             */
        }
    }
}

- (NSTimeInterval)currentTime {
    return currentPos;
}


- (NSTimeInterval)duration {
    return videoDuration;
}


- (void)empty {
}


- (NSTimeInterval)playableTime {
    return playAbleTime;
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
    check_error(mpv_set_property(mpv, "speed", MPV_FORMAT_DOUBLE, &speed), "speed");
}

- (void)changeScaleMode:(PlayScaleMode)scaleMode {
    NSLog(@"onPanelChangeScaleMode %lu", scaleMode);
    return;
    char *aspect = NULL;//"ratio";
    char *unscale = "no";
    switch (scaleMode) {
        case PlayScaleModeRatio:
            aspect = "-1";
            break;
        case PlayScaleModeClip:
            unscale = "-1";
            break;
        case PlayScaleModeStretch:
            aspect = "1920:1080";
            break;
            
        default:
            break;
    }
    check_error(mpv_set_property(mpv, "video-aspect", MPV_FORMAT_STRING, aspect), "video-aspect");
}

@end

