//
//  DanMuView.m
//  JSCats
//
//  Created by zfu on 2019/3/2.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "DanMuView.h"
#import <Foundation/Foundation.h>
#define LINE_HEIGHT 50
#define TOP_OFFSET 8

@interface DanMu : NSObject
@property (nonatomic, readwrite, copy) NSString *content;
@property (nonatomic, readwrite, copy) NSAttributedString *fillAttributedString;
@property (nonatomic, readwrite, copy) NSAttributedString *strokeAttributedString;
@property (nonatomic, readwrite, assign) CGRect frame;
@property (nonatomic, readwrite, assign) NSTimeInterval insertTime;
@property (nonatomic, readwrite, assign) NSTextAlignment textAlignment;
@property (nonatomic, readwrite, assign) DanmuStyle style;
@property (nonatomic, readwrite, assign) CGFloat speed;
@property (nonatomic, readwrite, strong) UIColor *fillColor;
@property (nonatomic, readwrite, strong) UIColor *strokeColor;
@end

@implementation DanMu
@synthesize content;
@synthesize frame;
@synthesize insertTime;
@synthesize textAlignment;
@synthesize speed;
@synthesize fillColor;
@synthesize strokeColor;
@synthesize style;
@end

@interface DanMuView() {
    NSMutableArray<NSMutableArray<DanMu*>*> *dandaoNormal;
    NSMutableArray<NSMutableArray<DanMu*>*> *dandaoTop;
    NSMutableArray<NSMutableArray<DanMu*>*> *dandaoBottom;
    NSMutableArray<DanMu*> *recycleDanMuObjects;
    DanMu *subtitle;
    BOOL dandaoInited;
}
@end

@implementation DanMuView

-(instancetype)initWithFrame:(CGRect)frameRect {
    self = [super initWithFrame:frameRect];
    [self setBackgroundColor:[UIColor clearColor]];
    dandaoInited = NO;
    [self initDanDao];
    return self;
}

-(void)drawRect:(CGRect)dirtyRect {
    [super drawRect:dirtyRect];
    // Drawing code here.
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, dirtyRect);
    NSArray *dandaos = @[dandaoTop, dandaoBottom, dandaoNormal];
    for (NSMutableArray<NSMutableArray<DanMu*>*> *dandao in dandaos) {
        for (NSMutableArray<DanMu*> *danmus in dandao) {
            for (DanMu *danmu in danmus) {
//                NSLog(@"draw %@ %.2f %.2f", danmu.content, danmu.frame.origin.x, danmu.frame.origin.y);
                CGContextSetTextDrawingMode(context, kCGTextFillStroke);
                [danmu.fillAttributedString drawAtPoint:danmu.frame.origin];
                
//                CGContextSetTextDrawingMode(context, kCGTextStroke);
//                [danmu.strokeAttributedString drawAtPoint:danmu.frame.origin];
            }
        }
    }
    //draw subtitle
    if (subtitle) {
        [subtitle.fillAttributedString drawAtPoint:subtitle.frame.origin];
        [subtitle.strokeAttributedString drawAtPoint:subtitle.frame.origin];
    }
}

-(void)initDanDao {
    if (dandaoInited) return;
    recycleDanMuObjects = [NSMutableArray array];
    dandaoNormal = [NSMutableArray array];
    for (NSInteger i=0; i<8; i++) {
        NSMutableArray<DanMu*> *dandao = [NSMutableArray array];
        [dandaoNormal addObject:dandao];
    }
    dandaoTop = [NSMutableArray array];
    for (NSInteger i=0; i<12; i++) {
        NSMutableArray<DanMu*> *dandao = [NSMutableArray array];
        [dandaoTop addObject:dandao];
    }
    dandaoBottom = [NSMutableArray array];
    for (NSInteger i=0; i<8; i++) {
        NSMutableArray<DanMu*> *dandao = [NSMutableArray array];
        [dandaoBottom addObject:dandao];
    }
    dandaoInited = YES;
}

-(void)addDanMu:(NSString*)content
      withStyle:(DanmuStyle)style
      withColor:(UIColor*)color
withStrokeColor:(UIColor*)bgcolor
   withFontSize:(CGFloat)fontSize {
    //init dandao
//    NSLog(@"DanMuView addDanMu %@", content);
    CGSize winSize = [self bounds].size;
    NSMutableArray<NSMutableArray<DanMu*>*> *dd = nil;
    if (style == DM_STYLE_TOP_CENTER) {
        dd = dandaoTop;
    } else if (style == DM_STYLE_TOP_CENTER) {
        dd = dandaoBottom;
    } else {//normal
        dd = dandaoNormal;
    }
    NSInteger line = -1;
    BOOL found = NO;
    UIFont *font_ = [UIFont systemFontOfSize:fontSize];
    NSRange range = NSMakeRange(0, content.length);
    NSDictionary<NSAttributedStringKey, id> *attrs = @{
                                                       NSFontAttributeName: font_,
                                                       NSForegroundColorAttributeName: color,
                                                       NSStrokeWidthAttributeName: @(1.0),
                                                       NSStrokeColorAttributeName: bgcolor,
                                                       };
    NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithString:content attributes:attrs];
    [as addAttribute:NSFontAttributeName value:font_ range:range];
    
    NSDictionary<NSAttributedStringKey, id> *bg_attrs = @{
                                                          NSFontAttributeName: font_,
                                                          NSForegroundColorAttributeName: color,
                                                          NSStrokeWidthAttributeName: @(3.0),
                                                          NSStrokeColorAttributeName: bgcolor,
                                                          };
    NSMutableAttributedString *bg_as = [[NSMutableAttributedString alloc] initWithString:content attributes:bg_attrs];
    [bg_as addAttribute:NSFontAttributeName value:font_ range:range];
    
    CGSize size = [content sizeWithAttributes:attrs];
    CGFloat speed = -300.0f - 300.0f * size.width / winSize.width;
    for (NSInteger idx = 0; idx<dd.count; idx++) {
        NSMutableArray<DanMu*> *dandao = [dd objectAtIndex:idx];
        if (style == DM_STYLE_TOP_CENTER || style == DM_STYLE_BOTTOM_CENTER) {
            if (dandao.count == 0) {
                line = idx;
                found = YES;
                break;
            }
        } else {//check the last one, if overlapped
            if (dandao.count == 0) {
                line = idx;
                found = YES;
                break;
            } else {
                DanMu *prevDM = dandao.lastObject;
                //check right size bounds
                CGFloat at = -1.0 * (prevDM.frame.origin.x + prevDM.frame.size.width)/prevDM.speed;
                CGFloat bt = -1.0 * (winSize.width)/speed;
                if (prevDM.frame.origin.x + prevDM.frame.size.width < winSize.width && at<=bt) {
                    line = idx;
                    found = YES;
                    break;
                }
            }
        }
    }
    if (found) {//yes find a place to place danmu
        DanMu *danmu = nil;
        if (recycleDanMuObjects.count > 0) {
            danmu = recycleDanMuObjects.firstObject;
            [recycleDanMuObjects removeObject:danmu];
        } else {
            danmu = DanMu.new;
        }
        danmu.content = content;
        danmu.fillAttributedString = [as copy];
        danmu.strokeAttributedString = [bg_as copy];
        danmu.frame = CGRectMake(winSize.width, TOP_OFFSET+LINE_HEIGHT*line, size.width, size.height);
        if (style == DM_STYLE_TOP_CENTER) {
            danmu.frame = CGRectMake(winSize.width/2-size.width/2, TOP_OFFSET+LINE_HEIGHT*line, size.width, size.height);
        } else if (style == DM_STYLE_BOTTOM_CENTER) {
            danmu.frame = CGRectMake(winSize.width/2-size.width/2, winSize.height-size.height-LINE_HEIGHT*line-TOP_OFFSET, size.width, size.height);
        }
        danmu.speed = speed;
        danmu.fillColor = color;
        danmu.strokeColor = bgcolor;
        danmu.insertTime = [[NSDate date] timeIntervalSince1970];
        danmu.style = style;
        if (style == DM_STYLE_TOP_CENTER) {
            danmu.textAlignment = NSTextAlignmentCenter;
        } else if (style == DM_STYLE_TOP_CENTER) {
            danmu.textAlignment = NSTextAlignmentCenter;
        } else {//normal
            danmu.textAlignment = NSTextAlignmentNatural;
        }
//        NSLog(@"add DanMu %@ %@ %.2f %.2f %.2f", danmu, danmu.content, size.width, size.height, danmu.speed);
        [[dd objectAtIndex:line] addObject:danmu];
    } else {
        NSLog(@"not found danmu %@", content);
    }
}

-(void)updateFrame {
//    CGSize winSize = [self bounds].size;
    NSArray *dandaos = @[dandaoTop, dandaoBottom, dandaoNormal];
    for (NSMutableArray<NSMutableArray<DanMu*>*> *dandao in dandaos) {
        for (NSMutableArray<DanMu*> *danmus in dandao) {
            NSMutableArray<DanMu*> *needsRemove = [NSMutableArray array];
            for (DanMu *danmu in danmus) {
                if (danmu.style == DM_STYLE_NORMAL) {
                    CGRect frame = danmu.frame;
                    frame.origin.x += danmu.speed/60.0f;
                    danmu.frame = frame;
                    if (frame.origin.x + frame.size.width <= 0) {//out of screen
                        [needsRemove addObject:danmu];
                    }
                } else if (danmu.style == DM_STYLE_TOP_CENTER || danmu.style == DM_STYLE_BOTTOM_CENTER){
                    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
                    if ((now - danmu.insertTime) > 3) {
                        [needsRemove addObject:danmu];
                    }
                }
            }
            for (DanMu *danmu in needsRemove) {
//                NSLog(@"remove danmu %@ %@", danmu.content, danmu);
                [recycleDanMuObjects addObject:danmu];
                [danmus removeObject:danmu];
            }
        }
    }
    [self setNeedsDisplayInRect:self.frame];
}

-(void)clear {
    NSArray *dandaos = @[dandaoTop, dandaoBottom, dandaoNormal];
    for (NSMutableArray<NSMutableArray<DanMu*>*> *dandao in dandaos) {
        for (NSMutableArray<DanMu*> *danmus in dandao) {
            [danmus removeAllObjects];
        }
    }
}

-(void)setSubTitle:(NSString*)content
         withColor:(UIColor*)color
   withStrokeColor:(UIColor*)strokeColor
      withFontSize:(CGFloat)fontSize {
    CGSize winSize = [self bounds].size;
    if (subtitle == nil) {
        subtitle = DanMu.new;
    }
    UIFont *font_ = [UIFont fontWithName:@"Helvetica-Bold" size:fontSize];
//    UIFont *font_ = [UIFont systemFontOfSize:fontSize];
    NSRange range = NSMakeRange(0, content.length);
    NSDictionary<NSAttributedStringKey, id> *attrs = @{
                                                       NSFontAttributeName: font_,
                                                       NSForegroundColorAttributeName: color,
                                                       };
    NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithString:content attributes:attrs];
    [as addAttribute:NSFontAttributeName value:font_ range:range];
    
    NSDictionary<NSAttributedStringKey, id> *bg_attrs = @{
                                                          NSFontAttributeName: font_,
                                                          NSForegroundColorAttributeName: color,
                                                          NSStrokeWidthAttributeName: @(1.0),
                                                          NSStrokeColorAttributeName: strokeColor,
                                                          NSStrokeWidthAttributeName: @(0.2),
                                                          };
    NSMutableAttributedString *bg_as = [[NSMutableAttributedString alloc] initWithString:content attributes:bg_attrs];
    [bg_as addAttribute:NSFontAttributeName value:font_ range:range];
    CGSize size = [content sizeWithAttributes:attrs];
    subtitle.content = content;
    subtitle.fillAttributedString = [as copy];
    subtitle.strokeAttributedString = [bg_as copy];
    subtitle.frame = CGRectMake(winSize.width/2-size.width/2, 40, size.width, size.height);
    subtitle.speed = 0;
    subtitle.fillColor = color;
    subtitle.strokeColor = strokeColor;
    subtitle.insertTime = [[NSDate date] timeIntervalSince1970];
    subtitle.style = DM_STYLE_SUBTITLE;
}

@end
