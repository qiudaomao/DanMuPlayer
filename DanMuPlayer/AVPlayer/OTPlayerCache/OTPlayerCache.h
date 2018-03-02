//
//  OTPlayerCache.h
//  OTPlayerCache
//
//  Created by baiyang on 2017/4/5.
//  Copyright © 2017年 OwlTop All rights reserved.
//

#ifndef OTPlayerCache_h
#define OTPlayerCache_h

#import "OTAssetLoaderDelegate.h"
#import "OTVideoCacheService.h"
#import "OTVideoDownloadModel.h"

#ifdef DEBUG
    #define OTLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
    #define OTLog(...)
#endif

#endif /* OTPlayerCache_h */
