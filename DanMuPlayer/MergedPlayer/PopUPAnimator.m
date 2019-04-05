//
//  PopUPAnimator.m
//  DanMuPlayer
//
//  Created by zfu on 2019/4/4.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "PopUPAnimator.h"

@implementation PopUPAnimator
- (void)animateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    CGRect initialFrame = [transitionContext initialFrameForViewController:fromVC];
    CGRect finalRect = CGRectOffset(initialFrame, 0, -fromVC.view.frame.size.height);
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         fromVC.view.frame = finalRect;
                     }
                     completion:^(BOOL finished) {
                         BOOL cancelled = transitionContext.transitionWasCancelled;
                         [transitionContext completeTransition:!cancelled];
                     }];
}

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.5f;
}
@end
