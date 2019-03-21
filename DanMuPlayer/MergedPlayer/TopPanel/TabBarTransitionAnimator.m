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
    CGFloat toHeight = toViewVC.contentHeightConstraint.constant;
    CGFloat fromHeight = fromViewVC.contentHeightConstraint.constant;
    NSLog(@"fromHeight %.2f toHeight %.2f", fromHeight, toHeight);

    /*
    //first set toView not visiable with alpha
    //resize toView to the same size as fromview
    toViewVC.contentHeightConstraint.constant = fromHeight;
    //then insert toView below fromView
    [transitionContext.containerView insertSubview:toViewVC.view belowSubview:fromViewVC.view];
    toViewVC.view.alpha = 0.0f;
    //after animation
    [toViewVC.view setNeedsUpdateConstraints];
    [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        //set fromView invisiable with alpha
        fromViewVC.view.alpha = 0.0f;
        //set toView visiable with alpha, and correct size
        toViewVC.view.alpha = 1.0f;
        toViewVC.contentHeightConstraint.constant = toHeight;
        [toViewVC.view setNeedsUpdateConstraints];
        [toViewVC.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
    }];
     */
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

//- (void)animationEnded:(BOOL)transitionCompleted {
//    if (savedTransitionContext) {
//        [savedTransitionContext completeTransition:!savedTransitionContext.transitionWasCancelled];
//    }
//    savedTransitionContext = nil;
//}
@end
