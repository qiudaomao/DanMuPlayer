//
//  MPVPlayerViewController.h
//  DanMuPlayer
//
//  Created by zfu on 2018/5/9.
//  Copyright © 2018 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AbstractPlayer.h"
#import "HUDView.h"

@import JavaScriptCore;

@interface MPVPlayerViewController : UIViewController <AbstractPlayerProtocol, HUDViewControlProtocol>

@end
