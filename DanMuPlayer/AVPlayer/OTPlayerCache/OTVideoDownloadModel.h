//
//  OTVideoDownloadModel.h
//  OTVideoPlayer
//
//  Created by baiyang on 2017/3/30.
//  Copyright © 2017年 OwlTop All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, OTVideoDownloadState) {
    OTVideoDownloadStateNormal,
    OTVideoDownloadStateDone,
    OTVideoDownloadStateRemove,
};

@interface OTVideoDownloadModel : NSObject

@property (nonatomic, strong) NSURLConnection * connection;                    // 请求
@property (nonatomic, strong) AVAssetResourceLoadingRequest * AVPlayerRequest; // 系统请求
@property (nonatomic, strong) NSURL * url;                                  // 请求url
@property (nonatomic, copy) NSString * filePath;                            // 文件路径
@property (nonatomic, strong) NSFileHandle * fileHandler;                   // 文件句柄
@property (nonatomic, assign) OTVideoDownloadState state;                  // 是否已完成
@property (nonatomic, assign) long long realRequestedStart;
@property (nonatomic, assign) long long realRequestedLength;                // 请求可能被系统cancel，所以保存实际请求数量

/**
 打开文件句柄
 */
- (void)openFileWriterIfNeed;

/**
 根据真实数据来重命名文件名称
 */
- (void)renameFileNameForRealLength;

/**
 替换scheme
 
 @param url 视频url
 @return 替换后的url
 */
+ (NSURL *)getSchemeVideoURL:(NSURL *)url;

@end

