//
//  CustomResourceLoader.m
//  DanMuPlayer
//
//  Created by zfu on 2018/1/17.
//  Copyright © 2018年 zfu. All rights reserved.
//

#import "CustomResourceLoader.h"

@interface CustomResourceLoader() {
    NSString *schema;
    NSMutableURLRequest *urlRequest;
    NSURLSession *session;
    NSURLSessionDataTask *task;
    NSInteger requestOffset;
    NSInteger requestLength;
    NSInteger totalLength;
    NSTimeInterval requestTimeout;
    AVAssetResourceLoadingRequest *resourceLoadingRequest;
    NSDictionary *additionHeaders;
    NSMutableDictionary *connectionMap;
    NSMutableDictionary *requestMap;
}
@property (nonatomic, readwrite, copy) NSString *url;
@property (nonatomic, readwrite, copy) NSString *key;
@end

@implementation CustomResourceLoader
-(instancetype)initWithHeaders:(NSDictionary*)headers {
    self = [super init];
    additionHeaders = headers;
    totalLength = 0;
    connectionMap = [NSMutableDictionary dictionary];
    requestMap = [NSMutableDictionary dictionary];
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
}
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"call shouldWaitForLoadingOfRequestedResource");
    [self addLoadingRequest:loadingRequest];
    return YES;
}
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"didCancelLoadingRequest not implement");
    [self removeLoadingRequest:loadingRequest];
}

- (void)addLoadingRequest:(AVAssetResourceLoadingRequest*)loadingRequest {
    NSMutableURLRequest *request = loadingRequest.request.mutableCopy;
    NSURLComponents *comps = [[NSURLComponents alloc] initWithURL:request.URL resolvingAgainstBaseURL:NO];
    comps.scheme = @"http";
    request.URL = comps.URL;
    request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    NSLog(@"addLoadingRequest requestURL %@", request.URL.absoluteString);
    session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                            delegate:self
                                       delegateQueue:[NSOperationQueue mainQueue]];
    task = [session dataTaskWithRequest:request];
    connectionMap[[NSString stringWithFormat:@"%p", loadingRequest]] = session;
    requestMap[[NSString stringWithFormat:@"%p", session]] = loadingRequest;
    [task resume];
}

- (void)removeLoadingRequest:(AVAssetResourceLoadingRequest*)request {
    NSLog(@"removeLoadingRequest %@", request.request.URL.absoluteString);
    if (task && task.state==NSURLSessionTaskStateRunning) {
        [task cancel];
        [self removeSession:[self sessionFromLoadingRequest:request]];
    }
}

//server responsed, we can get length here
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    NSLog(@"response %@", response);
    completionHandler(NSURLSessionResponseAllow);
    NSString *contentType = [response MIMEType];
    unsigned long long contentLength = [response expectedContentLength];
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
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
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
}

//server returned data
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSLog(@"did receive data length %zd", data.length);
    [resourceLoadingRequest.dataRequest respondWithData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        NSLog(@"URLSession task error %@", error.localizedDescription);
        [resourceLoadingRequest finishLoadingWithError:error];
    } else {
        NSLog(@"URLSession task no error");
        [resourceLoadingRequest finishLoading];
        [self removeSession:session];
    }
}
@end
