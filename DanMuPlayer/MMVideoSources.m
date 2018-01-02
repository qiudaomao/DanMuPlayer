//
//  MMVideoSources.m
//  DanMuPlayer
//
//  Created by zfu on 2017/12/3.
//  Copyright © 2017年 zfu. All rights reserved.
//

#import "MMVideoSources.h"

@implementation MMVideoSegment
@synthesize url;
@synthesize duration;
-(MMVideoSegment*)init {
    self = [super init];
    self.url = nil;
    self.duration = -1.0f;
    return self;
}
-(MMVideoSegment*)initWithURL:(NSString*)url_ duration:(CGFloat)duration_ {
    self = [super init];
    self.url = url_;
    self.duration = duration_;
    return self;
}
+(MMVideoSegment*)videoSegmentWithURL:(NSString*)url duration:(CGFloat)duration {
    return [[MMVideoSegment alloc] initWithURL:url duration:duration];
}
@end

@implementation MMVideoSources
@synthesize segments = _segments;
@synthesize duration = _duration;
@synthesize current = _current;
-(id)init {
    self = [super init];
    _current = 0;
    _segments = [NSMutableArray array];
    return self;
}

-(NSInteger)count {
    return [_segments count];
}
-(void)clear {
    [_segments removeAllObjects];
    [self updateDuration];
}
-(void)addSegmentWithURL: (NSString*)url duration:(CGFloat)duration {
    MMVideoSegment *seg = [MMVideoSegment videoSegmentWithURL:url duration:duration];
    [_segments addObject:seg];
    [self updateDuration];
}
-(void)updateDuration {
    CGFloat duration = 0.0f;
    for (MMVideoSegment *seg in _segments) {
        duration += seg.duration;
    }
    _duration = duration;
}
-(NSInteger)findIndexByTime:(CGFloat)duration {
    NSInteger idx=0;
    CGFloat d = 0.0;
    for (int i=0; i<[self count]; i++) {
        d += [_segments objectAtIndex:i].duration;
        if (d>duration) {
            idx=i;
            break;
        }
    }
    return idx;
}
-(CGFloat)getOffsetByIdx:(NSInteger)idx {
    CGFloat d = 0.0;
    for (int i=0; i<idx; i++) {
        d+=[_segments objectAtIndex:i].duration;
    }
    return d;
}
+(MMVideoSources*)sourceFromURL:(NSString*)url {
    MMVideoSources *source = [[MMVideoSources alloc] init];
    if (url.length>=6 && [[url substringWithRange:NSMakeRange(0, 6)] isEqualToString:@"edl://"]) {
        NSString *content = [url substringWithRange:NSMakeRange(6, url.length-6)];
        NSArray<NSString*> *items = [content componentsSeparatedByString:@";"];
        for (NSString *item in items) {
            NSString *pattern = @"%([0-9.]+)%(.*)$";
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options: NSRegularExpressionCaseInsensitive error: nil];
            NSArray *matches = [regex matchesInString:item options:0 range:NSMakeRange(0, [item length])];
            if (matches==nil || matches.count != 1) {
                NSLog(@"error parse for %@", item);
            } else {
                NSTextCheckingResult *result = matches[0];
                if (result.numberOfRanges == 3) {
                    NSString *duration = [item substringWithRange:[result rangeAtIndex:1]];
                    NSString *uu = [item substringWithRange:[result rangeAtIndex:2]];
                    [source addSegmentWithURL:uu duration:[duration floatValue]];
                } else {
                    NSLog(@"error parse for %@", item);
                }
            }
        }
    } else {
        [source addSegmentWithURL:url duration:0.0f];
    }
    return source;
}
-(void)dump {
    NSLog(@"----------dump segments--------------");
    NSLog(@"duration    : %.2f", _duration);
    NSLog(@"segment num : %ld", [_segments count]);
    int i=0;
    for (MMVideoSegment *seg in _segments) {
        NSLog(@"segment [%d] duration %.2f url %@", i, seg.duration, seg.url);
        i++;
    }
    NSLog(@"----------dump segments--------------");
}
@end
