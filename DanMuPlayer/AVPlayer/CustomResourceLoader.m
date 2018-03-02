//
//  CustomResourceLoader.m
//  DanMuPlayer
//
//  Created by zfu on 2018/1/17.
//  Copyright © 2018年 zfu. All rights reserved.
//

#import "CustomResourceLoader.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface CustomResourceLoader()<NSURLSessionDataDelegate, NSURLSessionTaskDelegate> {
    NSDictionary *additionHeaders;
    NSMutableDictionary *connectionMap;
    NSMutableDictionary *requestMap;
    NSMutableDictionary *dataMap;
    NSInteger totalLength;
}
@property (nonatomic, readwrite, copy) NSString *url;
@property (nonatomic, readwrite, copy) NSString *key;
@end

@implementation CustomResourceLoader
-(instancetype)initWithHeaders:(NSDictionary*)headers {
    self = [super init];
    additionHeaders = headers;
    connectionMap = [NSMutableDictionary dictionary];
    requestMap = [NSMutableDictionary dictionary];
    dataMap = [NSMutableDictionary dictionary];
    return self;
}
#pragma mark - AVAssetResourceLoaderDelegate
- (NSURLSession*)sessionFromLoadingRequest:(AVAssetResourceLoadingRequest*)request {
    if (!request) return nil;
    return [connectionMap objectForKey:[NSString stringWithFormat:@"%p", request]];
}
- (AVAssetResourceLoadingRequest*)loadingRequestFromSession:(NSURLSession*)session {
    if (!session) return nil;
    return [requestMap objectForKey:[NSString stringWithFormat:@"%p", session]];
}
- (void)removeSession:(NSURLSession*)session {
    AVAssetResourceLoadingRequest *loadingRequest = [self loadingRequestFromSession:session];
    [connectionMap removeObjectForKey:[NSString stringWithFormat:@"%p", loadingRequest]];
    [requestMap removeObjectForKey:session];
    [dataMap removeObjectForKey:session];
}
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"call shouldWaitForLoadingOfRequestedResource");
    return [self addLoadingRequest:loadingRequest];
}
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"didCancelLoadingRequest not implement");
    [self removeLoadingRequest:loadingRequest];
}

- (BOOL)addLoadingRequest:(AVAssetResourceLoadingRequest*)loadingRequest {
    NSMutableURLRequest *request = loadingRequest.request.mutableCopy;
    NSURLComponents *comps = [[NSURLComponents alloc] initWithURL:request.URL resolvingAgainstBaseURL:NO];
    comps.scheme = @"http";
    request.URL = comps.URL;
    request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    NSLog(@"");
    NSLog(@"addLoadingRequest----------------------");
    NSLog(@"%@ %@", request.URL.absoluteString, request.allHTTPHeaderFields);
    NSLog(@"Finish addLoadingRequest----------------------");
    NSLog(@"");
    AVAssetResourceLoadingDataRequest *dataRequest = loadingRequest.dataRequest;
    NSString *urlString = request.URL.absoluteString;
    NSString *extString = [urlString substringWithRange:NSMakeRange(urlString.length-3, 3)];
    if ([extString isEqualToString:@".ts"]) {
        NSLog(@"abc");
        //loadingRequest.redirect = request;
        //[loadingRequest finishLoading];
        return NO;
    }
    if (dataRequest) {
        NSLog(@"dataRequest current offset %zd request offset %zd length %zd", dataRequest.currentOffset, dataRequest.requestedOffset, dataRequest.requestedLength);
        NSString *rangeStr = [NSString stringWithFormat:@"bytes=%zd-%zd", dataRequest.requestedOffset, dataRequest.requestedLength-1];
        [request setValue:rangeStr forHTTPHeaderField:@"Range"];
    }
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue currentQueue]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    connectionMap[[NSString stringWithFormat:@"%p", loadingRequest]] = session;
    requestMap[[NSString stringWithFormat:@"%p", session]] = loadingRequest;
    dataMap[[NSString stringWithFormat:@"%p", session]] = [[NSMutableData alloc] init];
    [task resume];
    return YES;
}

- (void)removeLoadingRequest:(AVAssetResourceLoadingRequest*)request {
    NSLog(@"removeLoadingRequest %@", request.request.URL.absoluteString);
    NSURLSession *session = [self sessionFromLoadingRequest:request];
    [self removeSession:session];
}

//server responsed, we can get length here
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    NSLog(@"");
    NSLog(@"response ++++++++++++++++++++");
    NSLog(@"URL %@", response.URL);
    NSLog(@"headers %@", httpResponse.allHeaderFields);
    NSLog(@"finish response ++++++++++++++++++++");
    NSLog(@"");
//    NSString *mimeType = @"video/mp4";
//    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
    completionHandler(NSURLSessionResponseAllow);
    NSString *contentType = [response MIMEType];
    unsigned long long contentLength = [response expectedContentLength];
    NSString *rangeValue = httpResponse.allHeaderFields[@"Content-Range"];
    if (rangeValue) {
        NSArray *rangeItems = [rangeValue componentsSeparatedByString:@"/"];
        if (rangeItems.count > 1) {
            contentLength = [rangeItems[1] longLongValue];
        }
    }
    AVAssetResourceLoadingRequest *loadingRequest = [self loadingRequestFromSession:session];
    loadingRequest.response = response;
    loadingRequest.contentInformationRequest.contentLength = contentLength;
    loadingRequest.contentInformationRequest.contentType = contentType;
//    loadingRequest.contentInformationRequest.contentType = CFBridgingRelease(contentType);
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
}

//server returned data
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSLog(@"did receive data length %zd", data.length);
    //AVAssetResourceLoadingRequest *loadingRequest = [self loadingRequestFromSession:session];
    NSMutableData *sessionData = [dataMap objectForKey:[NSString stringWithFormat:@"%p", session]];
    [sessionData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    AVAssetResourceLoadingRequest *loadingRequest = [self loadingRequestFromSession:session];
    if (error) {
        NSLog(@"URLSession task error %@", error.localizedDescription);
        [loadingRequest finishLoadingWithError:error];
    } else {
        NSMutableData *sessionData = [dataMap objectForKey:[NSString stringWithFormat:@"%p", session]];
        [loadingRequest.dataRequest respondWithData:sessionData];
        NSLog(@"URLSession task no error data length %zd", sessionData.length);
        [loadingRequest finishLoading];
        [self removeSession:session];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    NSLog(@"redirect to request %@", request);
    completionHandler(request);
}
@end
