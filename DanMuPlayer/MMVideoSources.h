//
//  MMVideoSources.h
//  DanMuPlayer
//
//  Created by zfu on 2017/12/3.
//  Copyright © 2017年 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface MMVideoSegment : NSObject
@property (nonatomic, readwrite, copy) NSString *url;
@property (nonatomic, readwrite, assign) CGFloat duration;
-(MMVideoSegment*)initWithURL:(NSString*)url_ duration:(CGFloat)duration_;
+(MMVideoSegment*)videoSegmentWithURL:(NSString*)url duration:(CGFloat)duration;
@end

@interface MMVideoSources : NSObject
@property (nonatomic, readonly, strong) NSMutableArray<MMVideoSegment*> *segments;
@property (nonatomic, readonly, assign) CGFloat duration;//total duration for all segments
@property (nonatomic, readwrite, assign) NSInteger current;//total duration for all segments
@property (nonatomic, readwrite, copy) NSString *url;
@property (nonatomic, readwrite, copy) NSString *title;
@property (nonatomic, readwrite, copy) NSString *img;
@property (nonatomic, readwrite, copy) NSString *desc;
@property (nonatomic, readwrite, assign) BOOL mp4;
@property (nonatomic, readwrite, copy) NSMutableDictionary *options;
-(NSInteger)findIndexByTime:(CGFloat)duration;
-(void)clear;
-(void)addSegmentWithURL: (NSString*)url duration:(CGFloat)duration;
-(NSInteger)count;
-(void)updateDuration;
-(void)dump;
-(CGFloat)getOffsetByIdx:(NSInteger)idx;
+(MMVideoSources*)sourceFromURL:(NSString*)url;
@end
