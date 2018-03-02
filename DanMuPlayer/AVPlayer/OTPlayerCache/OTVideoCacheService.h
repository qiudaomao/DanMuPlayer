//
//  OTVideoCacheService.h
//  OTPlayerCache
//
//  Created by baiyang on 2017/3/30.
//  Copyright © 2017年 OwlTop All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

typedef void(^OTCacheQueryCompletedBlock)(NSInteger size);
typedef void(^OTCacheCleanCompletedBlock)(NSError * error);

@interface OTVideoCacheService : NSObject

/**
 当前缓存大小，会动态增长
 */
@property (nonatomic, assign) NSUInteger currentCacheSize;

/**
 最大缓存限制，默认300M
 */
@property (nonatomic, assign) NSUInteger maxCacheSize;

/**
 缓存保留比例（0.0 - 1.0)
 */
@property (nonatomic, assign) CGFloat remainRation;

+ (instancetype)sharedService;


/**
 是否可以缓存文件（用户空间剩余 1G， 且没超过最大限制）
 
 @return
 */
- (BOOL)canCacheNewFile;

/**
 清除部分旧文件
 */
- (void)cleanOldCacheFile;

/**
 缓存了新文件，请报告
 
 @param cacheFilePath
 */
- (void)reportAddedNewCacheFile:(NSString *)cacheFilePath;


// =======================================路径相关=============================================

/**
 视频缓存目录
 
 @return 目录
 */
+ (NSString *)videoCachePath;

/**
 临时视频缓存目录
 
 @return 目录
 */
+ (NSString *)videoTempCachePath;


/**
 根据url从视频缓存目录中找到对应的文件路径
 
 @param url 视频url
 @return 路径
 */
+ (NSString *)savedVideoPathWithURL:(NSURL *)url;


/**
 视频缓存目录是否存在对应url的缓存文件
 
 @param url 视频url
 @return 是否存在这个缓存
 */
+ (BOOL)savedVideoExistsWithURL:(NSURL *)url;

// =======================================查询相关=============================================

/**
 获取所有跟视频缓存相关的条目
 
 @param completeBlock 回调
 */
+ (void)queryAllVideoCacheSize:(OTCacheQueryCompletedBlock)completeBlock;

/**
 查询视频缓存空间大小
 
 @param completeBlock 回调
 */
+ (void)queryVideoCacheSize:(OTCacheQueryCompletedBlock)completeBlock;

/**
 查询视频临时缓存目录的大小
 
 @param completeBlock 回调
 */
+ (void)queryVideoTempCacheSize:(OTCacheQueryCompletedBlock)completeBlock;

// =======================================清除相关=============================================


/**
 清除所有跟视频缓存相关的条目
 
 @param completeBlock 回调
 */
+ (void)clearAllVideoCache:(OTCacheCleanCompletedBlock)completeBlock;

/**
 清空视频缓存目录
 
 @param completeBlock 回调
 */
+ (void)clearVideoCache:(OTCacheCleanCompletedBlock)completeBlock;

/**
 清空临时视频缓存目录
 
 @param completeBlock 回调
 */
+ (void)clearVideoTempCache:(OTCacheCleanCompletedBlock)completeBlock;

/**
 智能清除缓存（根据一定规则清除不用的缓存文件）
 
 @param completeBlock 回调
 */
+ (void)smartClearAllOfVideoCache:(OTCacheCleanCompletedBlock)completeBlock;

// =======================================URL相关=============================================

/**
 根据URL来获取文件名称
 
 @param url 视频url
 @return 文件名称（服务器端已经做过md5，所以这里返回的文件名是唯一的）
 */
+ (NSString *)fileNameWithURL:(NSURL *)url;

/**
 清除url对应的缓存文件
 
 @param url url
 @param completeBlock 回调
 */
+ (void)removeVideoCacheWithURL:(NSURL *)url complete:(OTCacheCleanCompletedBlock)completeBlock;

/**
 清楚url对应的临时缓存文件
 
 @param url url
 @param completeBlock 回调
 */
+ (void)removeVideoTempCacheWithURL:(NSURL *)url complete:(OTCacheCleanCompletedBlock)completeBlock;

// =======================================空间相关=============================================

/**
 用户磁盘可用存储空间
 
 @return 空间大小（byte）
 */
+ (unsigned long long)getDiskFreeSize;


@end

