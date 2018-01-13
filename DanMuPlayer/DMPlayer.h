//
//  DMPlayer.h
//  LazyCat
//
//  Created by zfu on 2017/5/8.
//  Copyright © 2017年 zfu. All rights reserved.
//

#ifndef DMPlayer_h
#define DMPlayer_h

#import <UIKit/UIKit.h>
#import <TVMLKit/TVMLKit.h>
#import "SGPlayer/PlayerViewController.h"
#import "AVPlayer/LazyCatAVPlayerViewController.h"
#import "DMPlaylist.h"
@import JavaScriptCore;

/*-----------------------------------------------------------------------------*/
/*
 * DMPlayer is a video player, hold a PlayerViewController
 * will present a UI
 */

typedef enum _DMPlayerEventType {
    EVENT_TYPE_STATE_DID_CHANGE,
    EVENT_TYPE_TIME_DID_CHANGE,
    EVENT_TYPE_TIME_BOUNDARY_DID_CROSS
} DMPlayerEventType;
@interface DMPlayerEvent : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) JSContext *ctx;
@property (nonatomic, strong) JSValue *params;
@property (nonatomic, strong) NSArray<NSNumber*> *paramsArray;
@property (nonatomic, strong) JSValue *callback;
@property (nonatomic, assign) DMPlayerEventType eventType;
@end

@protocol DMPlayerJSB <JSExport>
-(void)play;
-(void)pause;
-(void)stop;
-(void)seekToTime:(JSValue*)time;
-(void)addEventListener:(NSString*)event :(JSValue*)callback :(JSValue *)params;
-(void)removeEventListener:(NSString*)event :(JSValue*)callback :(JSValue *)params;
-(void)changeToMediaAtIndex:(NSInteger)index;
-(void)next;
-(void)previous;
-(void)addDanMu:(NSString*)content :(NSInteger)color :(CGFloat)fontSize :(NSInteger)style;
-(void)addSubTitle:(NSString*)subTitle;
@property (nonatomic) DMPlaylist *playlist;
@property (nonatomic) DMPlaylist *buttonList;
@property (nonatomic) JSValue *buttonClickCallback;
@property (nonatomic, assign, readwrite) NSInteger buttonFocusIndex;
@property (nonatomic) NSMutableArray<DMPlayerEvent*> *events;
@property (nonatomic, readonly) NSString *playbackState;
@property (nonatomic, readonly) DMMediaItem *currentMediaItem;
@property (nonatomic, readonly) CGFloat currentMediaItemDuration;
@property (nonatomic, readonly) DMMediaItem *previousMediaItem;
@property (nonatomic, readonly) DMMediaItem *nextMediaItem;
@property (nonatomic, readwrite) NSInteger timeMode;
@end

@interface DMPlayer : NSObject<DMPlayerJSB, PlayerStateDelegate>
+(void)setup:(JSContext*)context controller:(UINavigationController*)controller;
@property (nonatomic, weak) UINavigationController *controller;
@end

#endif /* DMPlayer_h */
