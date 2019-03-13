//
//  HUDView.h
//  DanMuPlayer
//
//  Created by zfu on 2018/5/11.
//  Copyright © 2018 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DanMuLayer.h"
#import "StrokeUILabel.h"

@protocol HUDViewControlProtocol
- (void)seekProgress:(NSTimeInterval)time;
@end

@interface HUDView : UIView
@property StrokeUILabel *currentTime;
@property StrokeUILabel *leftTime;
@property DanMuLayer *danmu;
@property id<HUDViewControlProtocol> delegate;

- (void)initHud;
- (void)setVideoInfo:(NSString*)title;
- (void)updateProgress:(NSTimeInterval)current
          playableTime:(NSTimeInterval)playableTime
             buffering:(BOOL)buffering
                 total:(NSTimeInterval)total;
- (void)updatePointTime: (CGFloat)time duration: (CGFloat)duration;
@end
