//
//  PushLeftAnimator.h
//  DanMuPlayer
//
//  Created by zfu on 2019/4/5.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PushLeftRightAnimator : NSObject<UIViewControllerAnimatedTransitioning>
-(instancetype)initWithDirection:(BOOL)left;
@end

NS_ASSUME_NONNULL_END
