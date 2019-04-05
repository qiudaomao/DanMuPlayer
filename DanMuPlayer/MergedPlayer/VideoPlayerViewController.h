//
//  VideoPlayerViewController.h
//  DanMuPlayer
//
//  Created by zfu on 2019/3/15.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerProtocol.h"
#import "../common/AbstractPlayer.h"
#import "DanMuLayer.h"
#import "DanMuView.h"
#import "StrokeUILabel.h"
#import "TopPanel/PanelControlProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface VideoPlayerViewController : UIViewController <AbstractPlayerProtocol, PlayerImplementProtocol, UIGestureRecognizerDelegate, PanelControlProtocol, UIViewControllerTransitioningDelegate>
@property (nonatomic, readwrite, strong) StrokeUILabel *currentTime;
@property (nonatomic, readwrite, strong) StrokeUILabel *leftTime;
@property (nonatomic, readwrite, strong) DanMuLayer *danmu;
@property (nonatomic, readwrite, copy) NSString *playerType;
@end

NS_ASSUME_NONNULL_END
