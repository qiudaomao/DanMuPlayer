//
//  OTAssetLoaderDelegate.h
//  OTPlayerCache
//
//  Created by baiyang on 2017/3/30.
//  Copyright © 2017年 OwlTop All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "OTVideoCacheService.h"

@interface OTAssetLoaderDelegate : NSObject <AVAssetResourceLoaderDelegate>

- (void)synthesizeVideoFile;

@end
