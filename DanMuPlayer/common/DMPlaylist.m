//
//  DMPlaylist.m
//  DanMuPlayer
//
//  Created by zfu on 2018/1/5.
//  Copyright © 2018年 zfu. All rights reserved.
//
#include "DMPlaylist.h"

@implementation DMMediaItem
@synthesize url;
@synthesize title;
@synthesize description;
@synthesize duration;
@synthesize resumeTime;
@synthesize options;
@synthesize artworkImageURL;
@synthesize mp4;
@synthesize player;
@synthesize size;
@synthesize image;
@synthesize downloadImageFailed;
@synthesize priv;
@synthesize type;
@synthesize imageHeaders;

-(instancetype)init {
    self = [super init];
    self.player = @"";
    self.resumeTime = 0;
    self.duration = 0;
    self.image = nil;
    self.downloadImageFailed = NO;
    self.type = @"video";
    self.imageHeaders = nil;
    return self;
}

+(void)setup:(JSContext*)context {
    [context setObject:DMMediaItem.class forKeyedSubscript:@"MMMediaItem"];
    [context setObject:DMMediaItem.class forKeyedSubscript:@"DMMediaItem"];
    /*
    context[@"MMMediaItem"] = ^DMMediaItem*{
        return [[DMMediaItem alloc] init];
    };
    context[@"DMMediaItem"] = ^DMMediaItem*{
        return [[DMMediaItem alloc] init];
    };
     */
}
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
    [context setObject:DMPlaylist.class forKeyedSubscript:@"MMPlaylist"];
    [context setObject:DMPlaylist.class forKeyedSubscript:@"DMPlaylist"];
    /*
    context[@"MMPlaylist"] = ^DMPlaylist*{
        return [[DMPlaylist alloc] init];
    };
    context[@"DMPlaylist"] = ^DMPlaylist*{
        return [[DMPlaylist alloc] init];
    };
     */
}
@end
