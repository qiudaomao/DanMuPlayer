//
//  DanMuView.h
//  JSCats
//
//  Created by zfu on 2019/3/2.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DanMuLayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface DanMuView : UIView
-(void)addDanMu:(NSString*)content
      withStyle:(DanmuStyle)style
      withColor:(UIColor*)color
withStrokeColor:(UIColor*)bgcolor
   withFontSize:(CGFloat)fontSize;
-(void)setSubTitle:(NSString*)content
         withColor:(UIColor*)color
   withStrokeColor:(UIColor*)strokeColor
      withFontSize:(CGFloat)fontSize;
-(void)updateFrame;
-(void)clear;
@end

NS_ASSUME_NONNULL_END
