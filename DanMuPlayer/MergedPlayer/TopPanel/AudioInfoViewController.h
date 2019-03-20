//
//  AudioInfoViewController.h
//  DanMuPlayer
//
//  Created by zfu on 2019/3/16.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import "TabAnimationVCProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface AudioInfoViewController : UIViewController <AVRoutePickerViewDelegate, TabAnimationVCProtocol>
@property (weak, nonatomic) IBOutlet UIVisualEffectView *bgVisualEffectView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;

@end

NS_ASSUME_NONNULL_END
