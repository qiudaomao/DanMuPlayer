//
//  StrokeUILabel.h
//  tvosPlayer
//
//  Created by zfu on 2017/4/10.
//  Copyright © 2017年 zfu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface StrokeUILabel : UILabel
-(CGSize)getRenderSize;
@property (nonatomic) UIColor *strokeColor;
@property (nonatomic) CGFloat speed;
@property (nonatomic) NSInteger delay;
@property (nonatomic) NSInteger line;
@end
