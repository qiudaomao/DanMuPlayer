//
//  IJKPlayerViewController.h
//  DanMuPlayer
//
//  Created by zfu on 2019/3/11.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "./IJKMediaPlayerFramework/IJKMediaFramework/IJKMediaFramework.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#import "AbstractPlayer.h"
#import "HUDView.h"
@import JavaScriptCore;
@class IJKMediaControl;

NS_ASSUME_NONNULL_BEGIN

@interface IJKPlayerViewController : UIViewController <AbstractPlayerProtocol, HUDViewControlProtocol>
@property(atomic, retain) id<IJKMediaPlayback> player;
@end

NS_ASSUME_NONNULL_END
