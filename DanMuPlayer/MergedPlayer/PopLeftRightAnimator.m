//
//  PopLeftAnimator.m
//  DanMuPlayer
//
//  Created by zfu on 2019/4/5.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "PopLeftRightAnimator.h"

@interface PopLeftRightAnimator() {
    BOOL left;
}
@end

@implementation PopLeftRightAnimator
-(instancetype)initWithDirection:(BOOL)left_ {
    self = [super init];
    left = left_;
    return self;
}

- (void)animateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    CGRect toRect = CGRectOffset(toVC.view.frame, -400, 0);
    CGRect fromRect = CGRectOffset(fromVC.view.frame, -400, 0);
    if (!left) {
        toRect = CGRectOffset(toVC.view.frame, 400, 0);
        fromRect = CGRectOffset(fromVC.view.frame, 400, 0);
    }
//    [transitionContext.containerView addSubview:toVC.view];
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         toVC.view.frame = toRect;
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
