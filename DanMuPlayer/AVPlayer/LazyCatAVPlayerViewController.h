//
//  LazyCatAVPlayerController.h
//  LazyCat
//
//  Created by zfu on 2017/11/4.
//  Copyright © 2017年 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AbstractPlayer.h"
@import JavaScriptCore;

@interface LazyCatAVPlayerViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, AbstractPlayerProtocol, AVPlayerViewControllerDelegate>
@property (nonatomic,weak,readwrite) UINavigationController *controller;
@property (nonatomic,strong,readwrite) AVPlayerViewController *avPlayerViewController;
@end
