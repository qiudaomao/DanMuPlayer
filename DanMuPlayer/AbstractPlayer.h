//
//  AbstractPlayer.h
//  DanMuPlayer
//
//  Created by zfu on 2017/12/3.
//  Copyright © 2017年 zfu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DanMuLayer.h"

typedef enum _PlayerState {
    PS_INIT = 0,
    PS_PLAYING,
    PS_PAUSED,
    PS_FINISH,
    PS_LOADING,
    PS_ERROR
} PlayerState;

@protocol PlayerStateDelegate <NSObject>
-(void)playStateDidChanged:(PlayerState)state;
-(void)timeDidChanged:(CGFloat)time duration:(CGFloat)duration;
-(void)timeDidChangedHD:(CGFloat)time;
@end

@protocol AbstractPlayerProtocol <NSObject>
@required
-(void)pause;
-(void)play;
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
@end

