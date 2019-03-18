//
//  CurrentMediaInfo.m
//  DanMuPlayer
//
//  Created by zfu on 2019/3/17.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "CurrentMediaInfo.h"

@implementation CurrentMediaInfo
@synthesize title;
@synthesize description;
@synthesize resolution;
@synthesize imgURL;
@synthesize duration;
@synthesize fps;
@synthesize artwork;
@synthesize image;

- (instancetype)initWithMediaInfo:(CurrentMediaInfo*)info {
    self = [super init];
    self.title = info.title;
    self.description = info.description;
    self.resolution = info.resolution;
    self.imgURL = info.imgURL;
    self.duration = info.duration;
    self.fps = info.fps;
    self.artwork = info.artwork;
    self.image = info.image;
    return self;
}

@end

