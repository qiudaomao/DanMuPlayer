//
//  TabBarTransitionAnimator.m
//  DanMuPlayer
//
//  Created by zfu on 2019/3/20.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "TabBarTransitionAnimator.h"
#import "TabAnimationVCProtocol.h"

@interface TabBarTransitionAnimator() {
    UIViewController *from;
    UIViewController *to;
    NSTimeInterval duration;
    id<UIViewControllerContextTransitioning> savedTransitionContext;
    BOOL rightDirection;
}
@end

@implementation TabBarTransitionAnimator

- (instancetype)initWithFromViewController:(UIViewController*)from_ toViewController:(UIViewController*)to_ duration:(NSTimeInterval)duration_ rightToLeft:(BOOL)direction_ {
    self = [super init];
    from = from_;
    to = to_;
    duration = duration_;
    rightDirection = direction_;
    return self;
}

- (void)animateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    savedTransitionContext = transitionContext;
    UIViewController<TabAnimationVCProtocol> *toViewVC = (UIViewController<TabAnimationVCProtocol>*)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController<TabAnimationVCProtocol> *fromViewVC = (UIViewController<TabAnimationVCProtocol>*)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
//    CGFloat toHeight = toViewVC.contentHeightConstraint.constant;
//    CGFloat fromHeight = fromViewVC.contentHeightConstraint.constant;
//    NSLog(@"fromHeight %.2f toHeight %.2f", fromHeight, toHeight);
    CGRect fromTargetFrame = fromViewVC.view.frame;
    CGRect targetFrame = toViewVC.view.frame;
    [transitionContext.containerView insertSubview:toViewVC.view belowSubview:fromViewVC.view];
    if (rightDirection) {
        toViewVC.view.frame = CGRectMake(targetFrame.size.width, targetFrame.origin.y, targetFrame.size.width, targetFrame.size.height);
    } else {
        toViewVC.view.frame = CGRectMake(-targetFrame.size.width, targetFrame.origin.y, targetFrame.size.width, targetFrame.size.height);
    }
    [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (self->rightDirection) {
            fromViewVC.view.frame = CGRectMake(-fromTargetFrame.size.width, fromTargetFrame.origin.y, fromTargetFrame.size.width, fromTargetFrame.size.height);
        } else {
            fromViewVC.view.frame = CGRectMake(fromTargetFrame.size.width, fromTargetFrame.origin.y, fromTargetFrame.size.width, fromTargetFrame.size.height);
        }
        toViewVC.view.frame = targetFrame;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
    }];
}

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return duration;
}

@end
