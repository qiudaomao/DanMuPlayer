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
@synthesize resumeTime;
@synthesize options;
@synthesize artworkImageURL;
@synthesize mp4;
-(instancetype)init {
    self = [super init];
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
