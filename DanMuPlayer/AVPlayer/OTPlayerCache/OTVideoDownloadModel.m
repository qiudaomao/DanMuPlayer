//
//  OTVideoDownloadModel.m
//  OTVideoPlayer
//
//  Created by baiyang on 2017/3/30.
//  Copyright © 2017年 OwlTop Ltd. All rights reserved.
//

#import "OTVideoDownloadModel.h"
#include <sys/param.h>
#include <sys/mount.h>
#import "OTVideoCacheService.h"
#import "OTPlayerCache.h"

@implementation OTVideoDownloadModel

- (NSString *)filePath {
    if (_filePath == nil) {
        NSString *document = [OTVideoCacheService videoTempCachePath];
        OTLog(@"%@", document);
        NSString * tempFileName = [NSString stringWithFormat:@"%@-%lld-%ld", [OTVideoCacheService fileNameWithURL:self.url], self.AVPlayerRequest.dataRequest.requestedOffset, self.AVPlayerRequest.dataRequest.requestedLength];
        _filePath =  [document stringByAppendingPathComponent:tempFileName];
    }
    
    return _filePath;
}

- (NSFileHandle *)fileHandler {
    if (_fileHandler == nil) {
        self.fileHandler = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
    }
    return _fileHandler;
}

- (void)renameFileNameForRealLength {
    NSString *document = [OTVideoCacheService videoTempCachePath];
    NSString * tempFileName = [NSString stringWithFormat:@"%@-%lld-%lld", [OTVideoCacheService fileNameWithURL:self.url], self.AVPlayerRequest.dataRequest.requestedOffset, self.realRequestedLength];
    NSString * tempPath =  [document stringByAppendingPathComponent:tempFileName];
    
    NSError * error;
    [[NSFileManager defaultManager] moveItemAtURL:[NSURL fileURLWithPath:self.filePath] toURL:[NSURL fileURLWithPath:tempPath] error:&error];
    
    if (error) {
        OTLog(@"file error : %@", error.localizedDescription);
    } else {
        self.filePath = tempPath;
    }
}

- (void)openFileWriterIfNeed {
    if (self.fileHandler) {
        return ;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.filePath isDirectory:NULL]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:NULL];
    }
    [[NSFileManager defaultManager] createFileAtPath:self.filePath contents:nil attributes:nil];
    self.fileHandler = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
}

+ (NSURL *)getSchemeVideoURL:(NSURL *)url {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = @"streaming";
    return [components URL];
}

@end
