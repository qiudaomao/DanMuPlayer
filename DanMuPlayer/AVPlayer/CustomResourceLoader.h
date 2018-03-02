//
//  CustomResourceLoader.h
//  DanMuPlayer
//
//  Created by zfu on 2018/1/17.
//  Copyright © 2018年 zfu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>

@interface CustomResourceLoader : NSObject <AVAssetResourceLoaderDelegate>
-(instancetype)initWithHeaders:(NSDictionary*)headers;
@end
