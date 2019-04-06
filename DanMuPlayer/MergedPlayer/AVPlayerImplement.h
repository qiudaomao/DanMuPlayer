//
//  AVPlayerImplement.h
//  DanMuPlayer
//
//  Created by zfu on 2019/4/5.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <CoreMedia/CoreMedia.h>
#import "PlayerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface AVPlayerImplement : NSObject <PlayerProtocol, AVPlayerViewControllerDelegate>
@property (nonatomic, readwrite, strong) AVPlayerViewController *avPlayerViewController;
@end

NS_ASSUME_NONNULL_END
