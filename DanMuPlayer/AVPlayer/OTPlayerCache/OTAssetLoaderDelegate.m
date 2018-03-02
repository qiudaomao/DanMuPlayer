//
//  OTAssetLoaderDelegate.m
//  OTPlayerCache
//
//  Created by baiyang on 2017/3/30.
//  Copyright © 2017年 OwlTop All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "OTVideoDownloadModel.h"
#import "OTVideoCacheService.h"
#import "OTAssetLoaderDelegate.h"
#import "OTPlayerCache.h"

@interface OTAssetLoaderDelegate () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>


@property (nonatomic, strong) NSMutableArray<OTVideoDownloadModel *> * requestList;
@property (nonatomic, strong) NSURL * url;

@property (nonatomic, assign) long long writeLength;
@property (nonatomic, strong) NSFileHandle * fileHandler; // 文件句柄
@property (nonatomic, assign) long long fileLength;


@end

@implementation OTAssetLoaderDelegate

- (instancetype)init
{
    if (self = [super init]) {
        self.requestList = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSMutableURLRequest * request = loadingRequest.request.mutableCopy;
    NSURLComponents * comps = [[NSURLComponents alloc] initWithURL:request.URL resolvingAgainstBaseURL:NO];
    comps.scheme = @"http";
    request.URL = comps.URL;
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    OTLog(@"request: %@", request.allHTTPHeaderFields[@"Range"]);
    
    NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    
    OTVideoDownloadModel * model = [OTVideoDownloadModel new];
    model.AVPlayerRequest = loadingRequest;
    model.connection = connection;
    model.url = request.URL;
    [self.requestList addObject:model];
    
    [connection start];
    
    self.url = request.URL;
    
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self removeRequest:loadingRequest];
}

#pragma mark - Connection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSString *contentType = [response MIMEType];
    unsigned long long contentLength = [response expectedContentLength];
    
    // 自己解析文件总大小
    NSString *rangeValue = [(NSHTTPURLResponse *)response allHeaderFields][@"Content-Range"];
    if (rangeValue)
    {
        NSArray *rangeItems = [rangeValue componentsSeparatedByString:@"/"];
        if (rangeItems.count > 1)
        {
            contentLength = [rangeItems[1] longLongValue];
        }
        else
        {
            contentLength = [response expectedContentLength];
        }
    }
    
    AVAssetResourceLoadingRequest * request = [self loadingRequestForConnection:connection];
    request.response = response;
    request.contentInformationRequest.contentLength = contentLength;
    request.contentInformationRequest.contentType = contentType;
    request.contentInformationRequest.byteRangeAccessSupported = YES;
    self.fileLength = contentLength;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    AVAssetResourceLoadingRequest * request = [self loadingRequestForConnection:connection];
    [request.dataRequest respondWithData:data];
    
    OTVideoDownloadModel * model = [self downloadModelWithConnection:connection];
    [model openFileWriterIfNeed];
    model.realRequestedLength += data.length;
    [model.fileHandler seekToEndOfFile];
    [model.fileHandler writeData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    OTLog(@"request finished: %@", connection.originalRequest.allHTTPHeaderFields[@"Range"]);
    AVAssetResourceLoadingRequest * request = [self loadingRequestForConnection:connection];
    [request finishLoading];
    [self removeRequest:request];
    
    OTVideoDownloadModel * model = [self downloadModelWithConnection:connection];
    [model.fileHandler closeFile];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    OTLog(@"request failed: %@, error: %@", connection.originalRequest.allHTTPHeaderFields[@"Range"], error);
    
    AVAssetResourceLoadingRequest * request = [self loadingRequestForConnection:connection];
    [request finishLoadingWithError:error];
    [self removeRequest:request];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    AVAssetResourceLoadingRequest * loadingRequest = [self loadingRequestForConnection:connection];
    loadingRequest.redirect = request;
    return request;
}

#pragma mark - Funs

- (NSURLConnection *)connectionForLoadingRequest:(AVAssetResourceLoadingRequest *)request
{
    OTVideoDownloadModel * target = [self downloadModelWithAVRequest:request];
    return target.connection;
}

- (AVAssetResourceLoadingRequest *)loadingRequestForConnection:(NSURLConnection *)connection
{
    OTVideoDownloadModel * target = [self downloadModelWithConnection:connection];
    return target.AVPlayerRequest;
}

- (OTVideoDownloadModel *)downloadModelWithConnection:(NSURLConnection *)connection {
    if (!connection) {
        return nil;
    }
    
    __block OTVideoDownloadModel * target;
    [self.requestList enumerateObjectsUsingBlock:^(OTVideoDownloadModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.connection == connection) {
            target = obj;
            *stop = YES;
        }
    }];
    return target;
}

- (OTVideoDownloadModel *)downloadModelWithAVRequest:(AVAssetResourceLoadingRequest *)avRequest {
    if (!avRequest) {
        return nil;
    }
    
    __block OTVideoDownloadModel * target;
    [self.requestList enumerateObjectsUsingBlock:^(OTVideoDownloadModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.AVPlayerRequest == avRequest) {
            target = obj;
            *stop = YES;
        }
    }];
    return target;
}

- (void)removeConnection:(NSURLConnection *)connection
{
    AVAssetResourceLoadingRequest * request = [self loadingRequestForConnection:connection];
    [self removeRequest:request];
}

- (void)removeRequest:(AVAssetResourceLoadingRequest *)request
{
    if (!request) {
        return;
    }
    
    NSURLConnection * c = [self connectionForLoadingRequest:request];
    [c cancel];
    
    OTVideoDownloadModel * model = [self downloadModelWithAVRequest:request];
    model.state = OTVideoDownloadStateRemove;
    [model renameFileNameForRealLength];
}

#pragma mark - Funs - synthesize video File

- (void)createNeedSavedVideoFile {
    NSString * filePath = [[OTVideoCacheService videoCachePath] stringByAppendingPathComponent:[OTVideoCacheService fileNameWithURL:self.url]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
    }
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    self.fileHandler = [NSFileHandle fileHandleForWritingAtPath:filePath];
}

- (void)synthesizeVideoFile {
    
    // 是否已经有缓存了
    if ([OTVideoCacheService savedVideoExistsWithURL:self.url]) {
        return ;
    }
    
    [self createNeedSavedVideoFile];
    
    [self.requestList sortUsingComparator:^NSComparisonResult(OTVideoDownloadModel *  _Nonnull obj1, OTVideoDownloadModel *  _Nonnull obj2) {
        NSArray<NSString *> * obj1Arr = [obj1.filePath componentsSeparatedByString:@"-"];
        NSArray<NSString *> * obj2Arr = [obj2.filePath componentsSeparatedByString:@"-"];
        
        if ([obj1Arr[obj1Arr.count - 2] integerValue] > [obj2Arr[obj2Arr.count - 2] integerValue]) {
            return NSOrderedDescending;
        } else if ([obj1Arr[obj1Arr.count - 2] integerValue] < [obj2Arr[obj2Arr.count - 2] integerValue]) {
            return NSOrderedAscending;
        } else {
            if ([obj1Arr[obj1Arr.count - 1] integerValue] > [obj2Arr[obj2Arr.count - 1] integerValue]) {
                return NSOrderedDescending;
            } else if ([obj1Arr[obj1Arr.count - 1] integerValue] < [obj2Arr[obj2Arr.count - 1] integerValue]) {
                return NSOrderedAscending;
            } else {
                return NSOrderedSame;
            }
        }
        return [obj1.filePath compare:obj2.filePath];
    }];
    
    __block NSInteger writedLength = 0;
    
    [self.requestList enumerateObjectsUsingBlock:^(OTVideoDownloadModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        OTLog(@"file list %@", obj.filePath);
        NSData * writeData = [NSData dataWithContentsOfFile:obj.filePath];
        
        if (obj.AVPlayerRequest.dataRequest.requestedOffset > self.writeLength) {
            OTLog(@"文件有缺失， 停止合成");
            [self.fileHandler closeFile];
            [OTVideoCacheService removeVideoCacheWithURL:self.url complete:nil];
            return ;
        }
        
        if (obj.AVPlayerRequest.dataRequest.requestedOffset + writeData.length <= self.writeLength) {
            // 已经有的数据
        } else {
            if (obj.AVPlayerRequest.dataRequest.requestedOffset < self.writeLength) {
                long cha = self.writeLength - obj.AVPlayerRequest.dataRequest.requestedOffset;
                writeData = [writeData subdataWithRange:NSMakeRange(cha, writeData.length - cha)];
            }
            
            [self.fileHandler seekToEndOfFile];
            [self.fileHandler writeData:writeData];
            writedLength += writeData.length;
            
            self.writeLength += writeData.length;
        }
        
    }];
    
    [self.fileHandler closeFile];
    
    //    [OTVideoCacheService removeVideoTempCacheWithURL:self.url complete:nil];
    
    if (writedLength <= 0 || writedLength != self.fileLength) {
        [OTVideoCacheService removeVideoCacheWithURL:self.url complete:nil];
    } else {
        [[OTVideoCacheService sharedService] reportAddedNewCacheFile:[OTVideoCacheService savedVideoPathWithURL:self.url]];
        [[OTVideoCacheService sharedService] cleanOldCacheFile];
    }
}

@end
