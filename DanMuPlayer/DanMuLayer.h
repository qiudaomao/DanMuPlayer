//
//  DanMuLayer.h
//  LazyCat
//
//  Created by zfu on 2017/6/3.
//  Copyright © 2017年 zfu. All rights reserved.
//

#ifndef DanMuLayer_h
#define DanMuLayer_h

#import <UIKit/UIKit.h>

typedef enum _DanmuStyle {
    DM_STYLE_NORMAL,
    DM_STYLE_REVERSE,
    DM_STYLE_TOP_CENTER,
    DM_STYLE_BOTTOM_CENTER
} DanmuStyle;

@interface DanMuLayer : UIView
-(void)addDanMu:(NSString*)content
      withStyle:(DanmuStyle)style
      withColor:(UIColor*)color
withStrokeColor:(UIColor*)bgcolor
   withFontSize:(CGFloat)fontSize;
-(void)updateFrame;
-(void)clear;
@end

#endif /* DanMuLayer_h */
