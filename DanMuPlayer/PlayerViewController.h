//
//  PlayerViewController.h
//  tvosPlayer
//
//  Created by zfu on 2017/4/9.
//  Copyright © 2017年 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SGPlayer/SGPlayer.h>
#import "DanMuLayer.h"

typedef enum _PlayerState {
    PS_INIT = 0,
    PS_PLAYING,
    PS_PAUSED,
    PS_FINISH,
    PS_LOADING,
    PS_ERROR
} PlayerState;

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
+(MMVideoSources*)sourceFromURL:(NSString*)url;
@end

@protocol PlayerStateDelegate <NSObject>
-(void)playStateDidChanged:(PlayerState)state;
-(void)timeDidChanged:(CGFloat)time duration:(CGFloat)duration;
-(void)timeDidChangedHD:(CGFloat)time;
@end

@interface PlayerViewController : UIViewController<UIGestureRecognizerDelegate>
-(id)init;
-(void)play;
-(void)pause;
-(void)stop;
-(void)seekToTime:(CGFloat)time;
-(void)playVideo:(NSString*)url
       withTitle:(NSString*)title
         withImg:(NSString*)img
  withDesciption:(NSString*)desc
         options:(NSMutableDictionary*)options
             mp4:(BOOL)mp4
  withResumeTime:(CGFloat)resumeTime;
-(void)addDanMu:(NSString*)content
      withStyle:(DanmuStyle)style
      withColor:(UIColor*)color
withStrokeColor:(UIColor*)bgcolor
   withFontSize:(CGFloat)fontSize;
-(void)setSubTitle:(NSString*)subTitle;
@property (nonatomic, readwrite, weak) id<PlayerStateDelegate> delegate;
@property (nonatomic, readonly, strong) SGPlayer *player;
@end
