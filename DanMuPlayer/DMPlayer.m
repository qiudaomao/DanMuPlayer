//
//  DMPlayer.m
//  LazyCat
//
//  Created by zfu on 2017/5/8.
//  Copyright © 2017年 zfu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DMPlayer.h"

@implementation DMPlayerEvent
@synthesize name;
@synthesize params;
@synthesize callback;
@synthesize eventType;
@end

@interface DMPlayer() {
    PlayerViewController *player;
    NSInteger currentIndex;
    CGFloat oldTime;
}
@end

@interface DMPlayer() {
}
@property (nonatomic, weak) UINavigationController *controller;
@end

@implementation DMPlayer
@synthesize playlist;
@synthesize currentMediaItemDuration;
@synthesize playbackState;
@synthesize currentMediaItem;
@synthesize previousMediaItem;
@synthesize nextMediaItem;
@synthesize events;
+(void)setup:(JSContext*)context controller:(UINavigationController*)controller {
    context[@"DMPlayer"] = ^DMPlayer*{
        DMPlayer *player = [[DMPlayer alloc] init];
        player.controller = controller;
        return player;
    };
}
-(id)init
{
    if (self = [super init]) {
        player = [[PlayerViewController alloc] init];
        self.events = [[NSMutableArray alloc] init];
        player.delegate = self;
        currentIndex=-1;
        oldTime = -1.0;
    }
    return self;
}
-(void)play
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.playlist.count>0) {
            [self.controller presentViewController:player animated:YES completion:^{
                NSLog(@"show ok");
                [self changeToMediaAtIndex:0];
            }];
        }
    });
}
-(void)pause
{
    [player pause];
}
-(void)stop
{
    [player stop];
}
-(void)seekToTime:(JSValue*)time
{
    [player seekToTime: [time toDouble]];
}
-(void)changeToMediaAtIndex:(NSInteger)index
{
    if (index < self.playlist.count) {
        DMMediaItem *item = self.playlist.items[index];
        currentIndex = index;
        NSString *url = item.url;
        if (url.length > 0) {
            NSMutableDictionary *options = [item.options mutableCopy];
            [player playVideo:item.url
                    withTitle:item.title
                      withImg:item.artworkImageURL
               withDesciption:item.description
                      options:options
                          mp4:item.mp4
               withResumeTime:item.resumeTime];
        }
    }
}
-(void)next
{
    if (currentIndex < self.playlist.count) {
        [self changeToMediaAtIndex:currentIndex+1];
    }
}
-(void)previous
{
    if (currentIndex > 0) {
        [self changeToMediaAtIndex:currentIndex-1];
    }
}

-(void)addEventListener:(NSString*)event :(JSValue*)callback :(JSValue *)params
{
    DMPlayerEvent *e = [[DMPlayerEvent alloc] init];
    e.name = event;
    e.callback = callback;
    e.params = params;
    if (params.isArray) e.paramsArray = params.toArray;
    else e.paramsArray=nil;
    if ([e.name isEqualToString:@"stateDidChange"]) e.eventType = EVENT_TYPE_STATE_DID_CHANGE;
    else if ([e.name isEqualToString:@"timeDidChange"]) e.eventType = EVENT_TYPE_TIME_DID_CHANGE;
    else if ([e.name isEqualToString:@"timeBoundaryDidCross"]) e.eventType = EVENT_TYPE_TIME_BOUNDARY_DID_CROSS;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.events addObject:e];
    });
}

-(void)removeEventListener:(NSString*)event :(JSValue*)callback :(JSValue *)params
{
    for (DMPlayerEvent *e in self.events) {
        if ([e.name isEqualToString:event] && e.callback==callback && e.params == params) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.events removeObject:e];
            });
            break;
        }
    }
}

-(void)playStateDidChanged:(PlayerState)state {
    for (DMPlayerEvent *e in self.events) {
        if (e.eventType == EVENT_TYPE_STATE_DID_CHANGE) {
            JSValue *callback = e.callback;
            if (callback) {
                NSArray *PlayerStateString = @[
                                               @"init",
                                               @"playing",
                                               @"paused",
                                               @"end",
                                               @"loading",
                                               @"error"
                                               ];
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                [dict setValue:PlayerStateString[state] forKey:@"state"];
                [[callback.context objectForKeyedSubscript:@"setTimeout"] callWithArguments: @[callback, @0, dict]];
            } else {
                NSLog(@"Error callback is null");
            }
        }
    }
}

-(void)timeDidChanged:(CGFloat)time {
    for (DMPlayerEvent *e in self.events) {
        if (e.eventType == EVENT_TYPE_TIME_DID_CHANGE) {
            JSValue *callback = e.callback;
            if (callback) {
                NSNumber *interval = (NSNumber*)[e.params.toDictionary objectForKey:@"interval"];
                int iVal = 1;
                if (interval) iVal = [interval intValue];
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                [dict setValue:[NSNumber numberWithFloat:player.player.duration] forKey:@"duration"];
                [dict setValue:[NSNumber numberWithFloat:time] forKey:@"time"];
                [dict setValue:@"timeDidChange" forKey:@"type"];
                //[callback callWithArguments:@[dict]];
                [[callback.context objectForKeyedSubscript:@"setTimeout"] callWithArguments: @[callback, @0, dict]];
                currentMediaItemDuration = player.player.duration;
            } else {
                NSLog(@"Error callback is null");
            }
        }
    }
}

-(void)timeDidChangedHD:(CGFloat)time {
    //dispatch_async(dispatch_get_main_queue(), ^{
        for (DMPlayerEvent *e in self.events) {
            JSValue *callback = e.callback;
            if (e.eventType == EVENT_TYPE_TIME_BOUNDARY_DID_CROSS && callback) {
                //NSLog(@"timeBoundaryDidCross: oldTime %.2f time %.2f", oldTime, time);
                if (e.paramsArray) {
                    for (NSNumber *t in e.paramsArray) {
                        CGFloat tt = t.floatValue;
                        //NSLog(@"timeBoundaryDidCross: oldTime %.2f tt %.2f time %.2f", oldTime, tt, time);
                        if (tt<oldTime) continue;
                        if (tt>=oldTime && tt<=time) {
                            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                            [dict setValue:[NSNumber numberWithFloat:time] forKey:@"timeStamp"];
                            [dict setValue:[NSNumber numberWithFloat:tt] forKey:@"boundary"];
                            [dict setValue:@"timeBoundaryDidCross" forKey:@"type"];
                            //[callback callWithArguments:@[dict]];
                            [[callback.context objectForKeyedSubscript:@"setTimeout"] callWithArguments: @[callback, @0, dict]];
                        }
                    }
                }
            }
        }
    //});
    oldTime = time;
}
-(void)addDanMu:(NSString*)content :(NSInteger)color :(CGFloat)fontSize :(NSInteger)style {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat b = (int)(color & 0xFF)/255.0;
        CGFloat g = (int)(color>>8 & 0xFF)/255.0;
        CGFloat r = (int)(color>>16 & 0xFF)/255.0;
        CGFloat a = 1.0;
        //NSLog(@"add DanMu %@ 0x%lx [%.2f, %.2f, %.2f, %.2f]", content, (long)color, r, g, b, a);
        UIColor *color = [UIColor colorWithRed:r green:g blue:b alpha:a];
        UIColor *bgcolor = [UIColor blackColor];
        if ((r<0.5 & g<0.5) || (g<0.5 && b<0.5) || (r<0.5 && b<0.5)) {
            bgcolor = [UIColor whiteColor];
        }
        DanmuStyle s = DM_STYLE_NORMAL;
        if (style==1) s = DM_STYLE_TOP_CENTER;
        else if (style==2) s = DM_STYLE_BOTTOM_CENTER;
        [player addDanMu:content
               withStyle:s
               withColor:color
         withStrokeColor:bgcolor
            withFontSize:fontSize];
    });
}
@end
