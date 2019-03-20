//
//  TabBarTransitionAnimator.h
//  DanMuPlayer
//
//  Created by zfu on 2019/3/20.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TabBarTransitionAnimator : NSObject<UIViewControllerAnimatedTransitioning>
- (instancetype)initWithFromViewController:(UIViewController*)from toViewController:(UIViewController*)to duration:(NSTimeInterval)duration;
@end

NS_ASSUME_NONNULL_END
