//
//  OTVideoCacheService.m
//  OTPlayerCache
//
//  Created by baiyang on 2017/3/30.
//  Copyright © 2017年 OwlTop All rights reserved.
//

#import "OTVideoCacheService.h"
#import "NSString+OTMD5Addition.h"
#include <sys/param.h>
#include <sys/mount.h>
#import "OTPlayerCache.h"

#define kFreeDiskCanDoCache (1 * 1024 * 1024 * 1024)

@implementation OTVideoCacheService

+ (instancetype)sharedService {
    static OTVideoCacheService *staticInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        staticInstance = [[OTVideoCacheService alloc] init];
        staticInstance.maxCacheSize = 80 * 1024 * 1024;
        staticInstance.remainRation = 0.8;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self.class queryAllVideoCacheSize:^(NSInteger size) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    staticInstance.currentCacheSize = size;
                });
            }];
        });
    });
    return staticInstance;
}

- (BOOL)canCacheNewFile {
    
    // 用户空间剩余 1G， 且没超过最大限制
    if ([self maxCacheSize] > kFreeDiskCanDoCache && self.currentCacheSize < self.maxCacheSize) {
        return YES;
    }
    
    return NO;
}

- (void)reportAddedNewCacheFile:(NSString *)cacheFilePath {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSDictionary * fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:cacheFilePath error:nil];//获取前一个文件信息
        NSNumber * fileSize = [fileInfo objectForKey:NSFileSize];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.currentCacheSize += [fileSize integerValue];
        });
    });
}

- (void)cleanOldCacheFile {
    
    // 1. 排序所有文件列表
    // 2. 获取缓存大小
    // 3. 遍历文件并清除
    
    [self.class queryVideoCacheSize:^(NSInteger size) {
        __block NSUInteger totalFileSize = 0.0;
        totalFileSize = size;
        
        // 需要清理
        if (totalFileSize > self.maxCacheSize * self.remainRation) {
            
            NSArray<NSString *> * sortedPaths = [self sortedVideoCacheFileList];
            //            NSString * currentPlayFileName = [self.class fileNameWithURL:[OTVideoPlayerInstanceService sharedService].playerInstance.URLString];
            
            [sortedPaths enumerateObjectsUsingBlock:^(NSString * _Nonnull filePath, NSUInteger idx, BOOL * _Nonnull stop) {
                // 不是当前播放
                //                if ([self.class string:filePath container:currentPlayFileName] == NO) {
                NSDictionary * fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];//获取前一个文件信息
                NSNumber * fileSize = [fileInfo objectForKey:NSFileSize];
                NSError * error;
                
                if ([filePath isEqualToString:@".DS_Store"] == NO) {
                    [[NSFileManager defaultManager] removeItemAtPath:[[self.class videoCachePath] stringByAppendingPathComponent:filePath] error:&error];
                    if (error) {
                        OTLog(@"文件清除错误 %@", error);
                    }
                    
                    totalFileSize -= [fileSize integerValue];
                    
                    BOOL needClean = totalFileSize < self.maxCacheSize * self.remainRation;
                    if (needClean == NO) {
                        *stop = YES;
                    }
                }
                
                //                }
            }];
            
        }
        
    }];
}

+ (BOOL)string:(NSString *)string container:(NSString *)otherString {
    NSRange range = [string rangeOfString:otherString];
    BOOL contain = (range.length != 0);
    return contain;
}

- (NSArray<NSString *> *)sortedVideoCacheFileList {
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    NSString *rootPath = [self.class videoCachePath];//获取根目录
    
    NSArray *paths = [fileMgr subpathsAtPath:rootPath];//取得文件列表
    return [paths sortedArrayUsingComparator:^(NSString * firstPath, NSString* secondPath) {//
        NSString *firstUrl = [rootPath stringByAppendingPathComponent:firstPath];//获取前一个文件完整路径
        NSString *secondUrl = [rootPath stringByAppendingPathComponent:secondPath];//获取后一个文件完整路径
        NSDictionary *firstFileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:firstUrl error:nil];//获取前一个文件信息
        NSDictionary *secondFileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:secondUrl error:nil];//获取后一个文件信息
        id firstData = [firstFileInfo objectForKey:NSFileModificationDate];//获取前一个文件修改时间
        id secondData = [secondFileInfo objectForKey:NSFileModificationDate];//获取后一个文件修改时间
        return [firstData compare:secondData];//升序
        // return [secondData compare:firstData];//降序
    }];
}

+ (NSString *)getFilePathWithAppendingString:(NSString *)apdStr{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingString:apdStr];
    
    if (![fileManager fileExistsAtPath:path]) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return path;
}

+ (NSString *)savedVideoPathWithURL:(NSURL *)url {
    return [[self videoCachePath] stringByAppendingPathComponent:[self fileNameWithURL:url]];
}

+ (BOOL)savedVideoExistsWithURL:(NSURL *)url {
    NSString * file = [self savedVideoPathWithURL:url];
    return [[NSFileManager defaultManager] fileExistsAtPath:file];
}


+ (NSString *)videoTempCachePath {
    return [self getFilePathWithAppendingString:@"/_video_cache_temp"];
}

+ (NSString *)videoCachePath {
    return [self getFilePathWithAppendingString:@"/_video_cache_saved"];
}

+ (NSString *)fileNameWithURL:(NSURL *)url {
    return [url.absoluteString.lastPathComponent componentsSeparatedByString:@"?"].firstObject;
}

+ (unsigned long long)getDiskFreeSize {
    struct statfs buf;
    unsigned long long freespace = -1;
    if(statfs("/var", &buf) >= 0){
        freespace = (long long)(buf.f_bsize * buf.f_bfree);
    }
    return freespace;
}

+ (void)queryAllVideoCacheSize:(OTCacheQueryCompletedBlock)completeBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        __block NSInteger totalSize = 0;
        [self queryVideoCacheSize:^(NSInteger size) {
            totalSize += size;
            [self queryVideoTempCacheSize:^(NSInteger size) {
                totalSize += size;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completeBlock) {
                        completeBlock(totalSize);
                    }
                });
            }];
        }];
    });
}

+ (void)queryVideoCacheSize:(OTCacheQueryCompletedBlock)completeBlock {
    [self getSizeWithDirectoryPath:@[[self videoCachePath]] completion:^(NSInteger totalSize) {
        if (completeBlock) {
            completeBlock(totalSize);
        }
    }];
}

+ (void)queryVideoTempCacheSize:(OTCacheQueryCompletedBlock)completeBlock {
    [self getSizeWithDirectoryPath:@[[self videoTempCachePath]] completion:^(NSInteger totalSize) {
        if (completeBlock) {
            completeBlock(totalSize);
        }
    }];
}

+ (void)clearAllVideoCache:(OTCacheCleanCompletedBlock)completeBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self clearVideoCache:^(NSError *error) {
            [self clearVideoTempCache:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completeBlock) {
                        completeBlock(error);
                    }
                });
            }];
        }];
    });
}

+ (void)clearVideoCache:(OTCacheCleanCompletedBlock)completeBlock {
    [self clearPath:[self videoCachePath] completeBlock:completeBlock];
}

+ (void)clearVideoTempCache:(OTCacheCleanCompletedBlock)completeBlock {
    [self clearPath:[self videoTempCachePath] completeBlock:completeBlock];
}

+ (void)smartClearAllOfVideoCache:(OTCacheCleanCompletedBlock)completeBlock {
    [self clearPath:[self videoTempCachePath] completeBlock:completeBlock];
}

+ (void)removeVideoCacheWithURL:(NSURL *)url complete:(OTCacheCleanCompletedBlock)completeBlock {
    NSString * path = [self savedVideoPathWithURL:url];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError * error;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (completeBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completeBlock(error);
            });
            
        }
    });
    
}

+ (void)removeVideoTempCacheWithURL:(NSURL *)url complete:(OTCacheCleanCompletedBlock)completeBlock {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString * tempCacheDictionarPath = [self videoTempCachePath];
        __block NSError * error;
        
        NSArray<NSString *> * files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:tempCacheDictionarPath error:&error];
        if (error) {
            return ;
        }
        
        NSString * fileName = [self fileNameWithURL:url];
        
        [files enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([self string:obj container:fileName] && [obj isEqualToString:@".DS_Store"] == NO) {
                [[NSFileManager defaultManager] removeItemAtPath:[[self videoTempCachePath] stringByAppendingPathComponent:obj] error:&error];
            }
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completeBlock) {
                completeBlock(error);
            }
        });
    });
    
}

+ (void)clearPath:(NSString *)path completeBlock:(OTCacheCleanCompletedBlock)completeBlock {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError * error;
        [fileManager removeItemAtPath:path error:&error];
        if (completeBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completeBlock(error);
            });
        }
    });
}

+(void)getSizeWithDirectoryPath:(NSArray *)directoryPathArr completion:(void(^)(NSInteger))completionBlock {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSFileManager *manager = [NSFileManager defaultManager];
        NSInteger totalSize = 0;
        for (NSString *directoryPath in directoryPathArr) {
            BOOL isDir;
            BOOL isFileExists = [manager fileExistsAtPath:directoryPath isDirectory:&isDir];
            
            if (isFileExists && isDir) {
                NSArray *subPaths = [manager subpathsAtPath:directoryPath];
                for (NSString *subPath in subPaths) {
                    NSString *fullPath = [directoryPath stringByAppendingPathComponent:subPath];
                    if ([fullPath respondsToSelector:@selector(containsString:)] && [fullPath containsString:@".DS"]) continue;
                    BOOL isDirectory;
                    BOOL isFile = [manager fileExistsAtPath:fullPath isDirectory:&isDirectory];
                    if (!isFile || isDirectory) continue;
                    NSDictionary *attr = [manager attributesOfItemAtPath:fullPath error:nil];
                    totalSize += [attr fileSize];
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(totalSize);
            }
        });
    });
}

@end

