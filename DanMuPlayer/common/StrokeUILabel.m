//
//  StrokeUILabel.m
//  tvosPlayer
//
//  Created by zfu on 2017/4/10.
//  Copyright © 2017年 zfu. All rights reserved.
//

#import "StrokeUILabel.h"

@implementation StrokeUILabel
@synthesize strokeColor;
@synthesize speed;
@synthesize line;

- (instancetype)init {
    self = [super init];
    self.strokeColor = [UIColor blackColor];
    return self;
}

- (void)drawTextInRect: (CGRect)rect {
    CGSize shadowOffset = self.shadowOffset;
    UIColor *textColor = self.textColor;
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(c, 2);
    CGContextSetLineJoin(c, kCGLineJoinRound);
    
    CGContextSetTextDrawingMode(c, kCGTextStroke);
    self.textColor = self.strokeColor;//[UIColor blackColor];
    [super drawTextInRect:rect];
    
    CGContextSetTextDrawingMode(c, kCGTextFill);
    self.textColor = textColor;
    self.shadowOffset = CGSizeMake(0, 0);
    [super drawTextInRect:rect];
    
    self.shadowOffset = shadowOffset;
}

- (CGSize)getRenderSize {
    CGSize size = [self.text sizeWithAttributes:@{NSFontAttributeName: self.font}];
    return size;
}
@end
