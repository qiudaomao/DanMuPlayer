//
//  PlayerProtocol.h
//  JSCats
//
//  Created by zfu on 2018/11/4.
//  Copyright © 2018 zfu. All rights reserved.
//

#ifndef PlayerProtocol_h
#define PlayerProtocol_h
#import <UIKit/UIKit.h>

@protocol PlayerImplementProtocol <NSObject>
- (void)videSizeChanged:(CGSize)size;
- (void)onPause;
- (void)onPlay;
- (void)onEnd;
- (void)onError:(NSString*)msg;
- (void)updateProgress:(NSTimeInterval)current playableTime:(NSTimeInterval)playableTime buffering:(BOOL)buffering total:(NSTimeInterval)total;
@optional
- (void)bufferring;
- (void)stopBufferring;
@end

@protocol PlayerProtocol <NSObject>
- (void)play;
- (void)pause;
- (void)empty;
- (void)stop;
- (void)seekToTime:(NSTimeInterval)time;
- (NSTimeInterval)currentTime;
- (NSTimeInterval)duration;
- (NSTimeInterval)playableTime;
- (void)playVideo:(NSString*)url
        withTitle:(NSString*)title
          withImg:(NSString*)img
   withDesciption:(NSString*)desc
          options:(NSMutableDictionary*)options
              mp4:(BOOL)mp4
   withResumeTime:(CGFloat)resumeTime;
@property (nonatomic, readwrite, strong) UIView *videoView;
@property (nonatomic, readwrite, assign) CGSize videoSize;
@property (nonatomic, readwrite, weak) id<PlayerImplementProtocol> delegate;
@end

#endif /* PlayerProtocol_h */
