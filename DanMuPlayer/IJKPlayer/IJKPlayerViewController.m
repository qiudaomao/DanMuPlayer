//
//  IJKPlayerViewController.m
//  DanMuPlayer
//
//  Created by zfu on 2019/3/11.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "IJKPlayerViewController.h"

@interface IJKPlayerViewController () {
    HUDView *hudView;
}
@end

@implementation IJKPlayerViewController
@synthesize buttonClickCallback;
@synthesize buttonFocusIndex;
@synthesize danmuView;
@synthesize delegate;
@synthesize timeMode;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"view did Load");
    self.view.backgroundColor = UIColor.blackColor;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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

- (void)pause {
}

- (void)play {
}


- (void)playVideo:(NSString *)url withTitle:(NSString *)title withImg:(NSString *)img withDesciption:(NSString *)desc options:(NSMutableDictionary *)options mp4:(BOOL)mp4 withResumeTime:(CGFloat)resumeTime {
    //init the player
#if 1
    [IJKFFMoviePlayerController setLogReport:YES];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_DEBUG];
#else
    [IJKFFMoviePlayerController setLogReport:NO];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];
#endif
    
    [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];
    // [IJKFFMoviePlayerController checkIfPlayerVersionMatch:YES major:1 minor:0 micro:0];

    IJKFFOptions *ffoptions = [IJKFFOptions optionsByDefault];
//    [ffoptions setFormatOptionIntValue:-2.0 forKey:@"itsoffset"];
    [ffoptions setCodecOptionIntValue:-2.0 forKey:@"itsoffset"];
    [ffoptions setFormatOptionValue:@"file,concat,http,tcp,https,tls,rtmp,rtsp,ijkio,ffio,cache,async,rtp,udp,ijklongurl" forKey:@"protocol_whitelist"];
    [ffoptions setPlayerOptionIntValue:1 forKey:@"enable-accurate-seek"];
    [ffoptions setPlayerOptionIntValue:1 forKey:@"videotoolbox"];
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
    //read options from options
    if ([options.allKeys containsObject:@"ijkOptions"]) {
        NSDictionary *ijkOptions = [options objectForKey:@"ijkOptions"];
        /*
         ijkOptions: {
             "enable-accurate-seek": {
                 "target": "player",
                 "type": "number",
                 "value": @(100)
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

    NSURL *url_ = [NSURL URLWithString:url];
    self.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:url_ withOptions:ffoptions];
    self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.player.view.frame = self.view.bounds;
    self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
    self.player.shouldAutoplay = YES;
    
    self.view.autoresizesSubviews = YES;
    [self.view addSubview:self.player.view];
    
    //init Hud
    hudView = [[HUDView alloc] initWithFrame:self.view.bounds];
    hudView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    hudView.delegate = self;
    [self.view addSubview:hudView];
    [self.player prepareToPlay];
}

- (void)viewWillAppear:(BOOL)animated {
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.player shutdown];
}

- (void)seekToTime:(CGFloat)time {
}


- (void)stop {
    if (self.delegate) {
        [self.delegate playStateDidChanged:PS_FINISH];
        self.delegate=nil;
    }
}

- (void)seekProgress:(NSTimeInterval)time {
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
}

@end
