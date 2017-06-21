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
#import "PlayerViewController.h"
@import JavaScriptCore;

/*-----------------------------------------------------------------------------*/
/*
 * DMMeidaItem
 * Each item contains a playable online media
 */
@protocol DMMediaItemJSB <JSExport>
@property (nonatomic) NSString *url;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *description;
@property (nonatomic) CGFloat resumeTime;
@property (nonatomic) NSString *artworkImageURL;
@property (nonatomic) NSDictionary *options;
@property (nonatomic, assign) BOOL mp4;
@end

@interface DMMediaItem : NSObject<DMMediaItemJSB>
+(void)setup:(JSContext*)context;
@end

@implementation DMMediaItem
@synthesize url;
@synthesize title;
@synthesize description;
@synthesize resumeTime;
@synthesize options;
@synthesize artworkImageURL;
@synthesize mp4;
+(void)setup:(JSContext*)context {
    context[@"MMMediaItem"] = ^DMMediaItem*{
        return [[DMMediaItem alloc] init];
    };
    context[@"DMMediaItem"] = ^DMMediaItem*{
        return [[DMMediaItem alloc] init];
    };
}
@end

/*-----------------------------------------------------------------------------*/
/*
 * A DMPlaylist contains many DMMediaItem
 */
@protocol DMPlaylistJSB <JSExport>
-(void)push:(DMMediaItem*)item;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic) NSMutableArray<DMMediaItem*> *items;
@end

@interface DMPlaylist : NSObject<DMPlaylistJSB>
+(void)setup:(JSContext*)context;
@end

@implementation DMPlaylist
@synthesize count;
@synthesize items;
-(id)init {
    self = [super init];
    self.items = [[NSMutableArray alloc] init];
    return self;
}

-(void)push:(DMMediaItem*)item {
    [self.items addObject:item];
    self.count = [self.items count];
}

+(void)setup:(JSContext*)context {
    context[@"MMPlaylist"] = ^DMPlaylist*{
        return [[DMPlaylist alloc] init];
    };
    context[@"DMPlaylist"] = ^DMPlaylist*{
        return [[DMPlaylist alloc] init];
    };
}
@end

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
@property (nonatomic) NSString *name;
@property (nonatomic) JSValue *params;
@property (nonatomic) NSArray<NSNumber*> *paramsArray;
@property (nonatomic) JSValue *callback;
@property (assign) DMPlayerEventType eventType;
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
@property (nonatomic) DMPlaylist *playlist;
@property (nonatomic) NSMutableArray<DMPlayerEvent*> *events;
@property (nonatomic, readonly) NSString *playbackState;
@property (nonatomic, readonly) DMMediaItem *currentMediaItem;
@property (nonatomic, readonly) CGFloat currentMediaItemDuration;
@property (nonatomic, readonly) DMMediaItem *previousMediaItem;
@property (nonatomic, readonly) DMMediaItem *nextMediaItem;
@end

@interface DMPlayer : NSObject<DMPlayerJSB, PlayerStateDelegate>
+(void)setup:(JSContext*)context controller:(UINavigationController*)controller;
@end

#endif /* DMPlayer_h */
