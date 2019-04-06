//
//  PushLeftAnimator.m
//  DanMuPlayer
//
//  Created by zfu on 2019/4/5.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "PushLeftRightAnimator.h"

@interface PushLeftRightAnimator() {
    BOOL left;
}
@end

@implementation PushLeftRightAnimator
-(instancetype)initWithDirection:(BOOL)left_ {
    self = [super init];
    left = left_;
    NSLog(@"%@ left: %@", self, @(left));
    return self;
}

- (void)animateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    CGRect finalRect = [transitionContext finalFrameForViewController:toVC];
    toVC.view.frame = CGRectOffset(finalRect, -400, 0);
    CGRect fromRect = CGRectOffset(fromVC.view.frame, 400, 0);
    NSLog(@"%@ left: %@", self, @(left));
    if (!left) {
        toVC.view.frame = CGRectOffset(finalRect, 400, 0);//right out of screen
//        finalRect = CGRectOffset(toVC.view.frame, -400, 0);
        fromRect = CGRectOffset(fromVC.view.frame, -400, 0);
    }
    [transitionContext.containerView addSubview:toVC.view];
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         toVC.view.frame = finalRect;
                         fromVC.view.frame = fromRect;
                     }
                     completion:^(BOOL finished) {
                         [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
                     }];
}

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.4f;
}
@end
