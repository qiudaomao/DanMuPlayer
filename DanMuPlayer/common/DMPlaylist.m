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

-(instancetype)init {
    self = [super init];
    self.player = @"";
    self.resumeTime = 0;
    self.duration = 0;
    self.image = nil;
    self.downloadImageFailed = NO;
    return self;
}
+(void)setup:(JSContext*)context {
    context[@"MMMediaItem"] = ^DMMediaItem*{
        return [[DMMediaItem alloc] init];
    };
    context[@"DMMediaItem"] = ^DMMediaItem*{
        return [[DMMediaItem alloc] init];
    };
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
    context[@"MMPlaylist"] = ^DMPlaylist*{
        return [[DMPlaylist alloc] init];
    };
    context[@"DMPlaylist"] = ^DMPlaylist*{
        return [[DMPlaylist alloc] init];
    };
}
@end
