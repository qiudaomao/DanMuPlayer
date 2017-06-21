//
//  DanMuLayer.m
//  LazyCat
//
//  Created by zfu on 2017/6/3.
//  Copyright © 2017年 zfu. All rights reserved.
//

#import "DanMuLayer.h"
#import <Foundation/Foundation.h>
#import "StrokeUILabel.h"

#define LINE_HEIGHT 50
@interface DanMuLayer() {
    NSArray<NSMutableArray<StrokeUILabel*>*> *dandao;
    NSArray<NSMutableArray<StrokeUILabel*>*> *dandaoTop;
    NSArray<NSMutableArray<StrokeUILabel*>*> *dandaoBottom;
}
@end

@implementation DanMuLayer

-(instancetype)init {
    self = [super init];
    return self;
}

-(void)addDanMu:(NSString*)content
      withStyle:(DanmuStyle)style
      withColor:(UIColor*)color
withStrokeColor:(UIColor*)bgcolor
   withFontSize:(CGFloat)fontSize {
    CGSize size = [self bounds].size;
    StrokeUILabel *label = [[StrokeUILabel alloc] init];
    label.textColor = color;
    label.strokeColor = bgcolor;
    label.frame = CGRectMake(0, 0, size.width, 80);
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    label.font = font;
    label.textAlignment = NSTextAlignmentLeft;
    label.text = content;
    CGRect frame = label.frame;
    frame.size = [label getRenderSize];
    frame.origin.x = size.width;
    frame.origin.y = 0;
    
    //NSLog(@"add width %.2f x %.2f of %@", frame.size.width, frame.origin.x, content);
    label.speed = -350.0f - 300.0f*frame.size.width/size.width;// * frame.size.width/200;
    if (dandao == nil) {
        NSMutableArray<NSMutableArray<StrokeUILabel*>*> *arr = [NSMutableArray array];
        for (int i=0; i<18; i++) {
            NSMutableArray<StrokeUILabel*> *d = [NSMutableArray array];
            [arr addObject:d];
        }
        dandao = [arr copy];
    }
    if (dandaoTop == nil) {
        NSMutableArray<NSMutableArray<StrokeUILabel*>*> *arr = [NSMutableArray array];
        for (int i=0; i<12; i++) {
            NSMutableArray<StrokeUILabel*> *d = [NSMutableArray array];
            [arr addObject:d];
        }
        dandaoTop = [arr copy];
    }
    if (dandaoBottom == nil) {
        NSMutableArray<NSMutableArray<StrokeUILabel*>*> *arr = [NSMutableArray array];
        for (int i=0; i<12; i++) {
            NSMutableArray<StrokeUILabel*> *d = [NSMutableArray array];
            [arr addObject:d];
        }
        dandaoBottom = [arr copy];
    }
    
    //find a position to insert
    if (style==DM_STYLE_TOP_CENTER) {
        label.textAlignment = NSTextAlignmentCenter;
        frame.origin.x = size.width/2-frame.size.width/2;
        BOOL added = NO;
        int line=0;
        for (NSMutableArray<StrokeUILabel*> *danmus in dandaoTop) {
            if (danmus.count == 0) {
                frame.origin.y = line*LINE_HEIGHT;
                label.delay = 240;
                label.line = line;
                [danmus addObject:label];
                added = YES;
                break;
            }
            line++;
        }
        if (!added) {
            [[dandaoTop objectAtIndex:0] addObject:label];
        }
        label.frame = frame;
        [self addSubview:label];
    } else if (style==DM_STYLE_BOTTOM_CENTER) {
        label.textAlignment = NSTextAlignmentCenter;
        frame.origin.x = size.width/2-frame.size.width/2;
        BOOL added = NO;
        int line=0;
        for (NSMutableArray<StrokeUILabel*> *danmus in dandaoTop) {
            if (danmus.count == 0) {
                frame.origin.y = size.height - 100 - (line+1)*LINE_HEIGHT;
                label.delay = 240;
                label.line = line;
                [danmus addObject:label];
                added = YES;
                break;
            }
            line++;
        }
        if (!added) {
            [[dandaoTop objectAtIndex:0] addObject:label];
        }
        label.frame = frame;
        [self addSubview:label];
    } else {//normal
        BOOL added = NO;
        int line=0;
        for (NSMutableArray<StrokeUILabel*> *danmus in dandao) {
            if ([danmus count]==0) {
                [danmus addObject:label];
                label.line = line;
                frame.origin.y = line*LINE_HEIGHT;
                added=YES;
                NSLog(@"add to empty line %d", line);
                break;
            } else {
                StrokeUILabel *l = [danmus objectAtIndex:[danmus count]-1];
                CGRect f= l.frame;
                //speed test
                CGFloat at = -1.0*(f.origin.x+f.size.width)/l.speed;
                CGFloat bt = -1.0*size.width/label.speed;
//                NSLog(@"line %d x %.2f width %.2f x+width %.2f size.width %.2f %@, at %.2f bt %.2f %@", line,
//                      f.origin.x, f.size.width, f.origin.x + f.size.width,
//                      size.width, (f.origin.x + f.size.width < size.width)?@"true":@"false",
//                      at, bt, (at<bt)?@"true":@"false");
                if ((f.origin.x + f.size.width < size.width) && at<bt) {
                    [danmus addObject:label];
                    label.line = line;
                    frame.origin.y = line*LINE_HEIGHT;
                    added=YES;
                    //NSLog(@"add to line %d", line);
                    break;
                }
            }
            line++;
        }
        if (!added) {
            //NSLog(@"not able to find a line");
            [[dandao objectAtIndex:0] addObject:label];
            frame.origin.y = 0;
        }
        label.frame = frame;
        [self addSubview:label];
    }
}

-(void)clear {
    for (NSMutableArray<StrokeUILabel*> *danmus in dandao) {
        [danmus removeAllObjects];
    }
}
    
-(void)updateFrame {
    //NSLog(@"updateFrame danmu nums %ld", [danmus count]);
    //dispatch_async(dispatch_get_main_queue(), ^{
        for (NSMutableArray<StrokeUILabel*> *danmus in dandao) {
            NSMutableArray *needRemoveItems = [NSMutableArray array];
            for (StrokeUILabel *label in danmus) {
                CGRect frame = label.frame;
                if (frame.origin.x < -frame.size.width) {
                    //NSLog(@"remove danmu %@", label.text);
                    [needRemoveItems addObject:label];
                    [label removeFromSuperview];
                    continue;
                }
                frame.origin.x += label.speed/60.0f;
                label.frame = frame;
                //NSLog(@"x %.2f %@", frame.origin.x, label.text);
            }
            [danmus removeObjectsInArray:needRemoveItems];
        }
        for (NSMutableArray<StrokeUILabel*> *danmus in dandaoTop) {
            NSMutableArray *needRemoveItems = [NSMutableArray array];
            for (StrokeUILabel *label in danmus) {
                if (label.delay <= 0) {
                    [needRemoveItems addObject:label];
                    [label removeFromSuperview];
                    continue;
                }
                label.delay--;
                //NSLog(@"x %.2f %@", frame.origin.x, label.text);
            }
            [danmus removeObjectsInArray:needRemoveItems];
        }
        for (NSMutableArray<StrokeUILabel*> *danmus in dandaoBottom) {
            NSMutableArray *needRemoveItems = [NSMutableArray array];
            for (StrokeUILabel *label in danmus) {
                if (label.delay <= 0) {
                    //NSLog(@"remove danmu %@", label.text);
                    [needRemoveItems addObject:label];
                    [label removeFromSuperview];
                    continue;
                }
                label.delay--;
                //NSLog(@"x %.2f %@", frame.origin.x, label.text);
            }
            [danmus removeObjectsInArray:needRemoveItems];
        }
    //});
}

@end
