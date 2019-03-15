//
//  SiriRemoteGestureRecognizer.m
//  LazyCat
//
//  Created by zfu on 2017/6/2.
//  Copyright © 2017年 zfu. All rights reserved.
//

#import "SiriRemoteGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface UIEvent (SiriRemoteTouchLocation)
- (CGPoint)location;
@end

@interface SiriRemoteGestureRecognizer() {
    CGPoint _location;
    CGPoint _oldLocation;
    CGPoint _velocity;
    NSTimeInterval _oldTime;
}
@end

@implementation SiriRemoteGestureRecognizer
@dynamic delegate;
@dynamic location;
@dynamic velocity;

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    self = [super initWithTarget:target action:action];
    if (self) {
        self.allowedTouchTypes = @[@(UITouchTypeIndirect)];
        self.allowedPressTypes = @[@(UIPressTypeSelect)];
        _touchLocationName = @"unknown";
        _touchLocation = MMSiriRemoteTouchLocationUnknown;
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _click = NO;
    [self updateTouchLocationWithEvent:event];
    self.state = UIGestureRecognizerStateBegan;
    _stateName = @"Began";
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateTouchLocationWithEvent:event];
    self.state = UIGestureRecognizerStateChanged;
    _stateName = @"Changed";
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateTouchLocationWithEvent:event];
    self.state = UIGestureRecognizerStateCancelled;
    _stateName = @"Cancelled";
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateTouchLocation:MMSiriRemoteTouchLocationUnknown];
    self.state = UIGestureRecognizerStateCancelled;
    _stateName = @"Cancelled";
}

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    if ([self.allowedPressTypes containsObject:@(presses.anyObject.type)]) {
        _click = YES;
        self.state = UIGestureRecognizerStateChanged;
        _stateName = @"Changed";
    }
}

- (CGPoint)location {
    return _location;
}

- (CGPoint)velocity {
    return _velocity;
}

- (void)pressesChanged:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    self.state = UIGestureRecognizerStateChanged;
    _stateName = @"Changed";
}

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    if (_click) {
        if (self.touchLocation == MMSiriRemoteTouchLocationUnknown) {
            _touchLocation = MMSiriRemoteTouchLocationCenter;
            _touchLocationName = @"center";
        }
        self.state = UIGestureRecognizerStateEnded;
        _stateName = @"Ended";
    }
}

- (void)pressesCancelled:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    self.state = UIGestureRecognizerStateCancelled;
    _stateName = @"Cancelled";
}

- (void)updateTouchLocationWithEvent: (UIEvent*)event {
    CGPoint location = [event location];
    _location = location;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    //calculate velocity
    _velocity = CGPointMake((location.x-_oldLocation.x)/(now-_oldTime),
                                (location.y-_oldLocation.y)/(now-_oldTime));
    _oldTime = now;
    _oldLocation = location;
    SiriRemoteTouchLocation l = MMSiriRemoteTouchLocationUnknown;
    //NSLog(@"updateTouchLocation (%.2f, %.2f)", location.x, location.y);
    if (location.x <= 1/4.0 && location.y >= 1/4.0 && location.y <= 3/4.0) {
        l = MMSiriRemoteTouchLocationLeft;
    } else if (location.x >= 3/4.0 && location.y >= 1/4.0 && location.y <= 3/4.0) {
        l = MMSiriRemoteTouchLocationRight;
    } else if (location.x >= 1/4.0 && location.x <= 3/4.0 && location.y <= 1/4.0) {
        l = MMSiriRemoteTouchLocationUp;
    } else if (location.x >= 1/4.0 && location.x <= 3/4.0 && location.y >= 3/4.0) {
        l = MMSiriRemoteTouchLocationDown;
    } else if (location.x >= 1/4.0 && location.x <= 2/4.0
               && location.y >= 1/4.0 && location.y <= 3/4.0) {
        l = MMSiriRemoteTouchLocationCenter;
    }
    [self updateTouchLocation:l];
}

- (void)updateTouchLocation: (SiriRemoteTouchLocation) location {
    if (_touchLocation == location) return;
    _touchLocation = location;
    switch (location) {
        case MMSiriRemoteTouchLocationUnknown:
            _touchLocationName = @"unknown";
            break;
        case MMSiriRemoteTouchLocationUp:
            _touchLocationName = @"up";
            break;
        case MMSiriRemoteTouchLocationDown:
            _touchLocationName = @"down";
            break;
        case MMSiriRemoteTouchLocationLeft:
            _touchLocationName = @"left";
            break;
        case MMSiriRemoteTouchLocationRight:
            _touchLocationName = @"right";
            break;
        case MMSiriRemoteTouchLocationCenter:
            _touchLocationName = @"center";
            break;
            
        default:
            break;
    }
}
@end

@implementation UIEvent (SiriRemoteTouchLocation)

- (CGPoint)location {
    NSString *key = [@"digitiz" stringByAppendingString:@"erLocation"];
    NSNumber *value = [self valueForKey:key];
    if ([value isKindOfClass:[NSValue class]]) {
        return [value CGPointValue];
    }
    return CGPointMake(0.5,0.5);
}

@end
