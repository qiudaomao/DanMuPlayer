//
//  CustomResourceLoader.m
//  DanMuPlayer
//
//  Created by zfu on 2018/1/17.
//  Copyright © 2018年 zfu. All rights reserved.
//

#import "CustomResourceLoader.h"
#import <MobileCoreServices/MobileCoreServices.h>
//#import "LazyCat-Swift.h"

@interface CustomResourceLoader()<NSURLSessionDataDelegate, NSURLSessionTaskDelegate> {
    NSDictionary *additionHeaders;
    NSMutableDictionary *connectionMap;
    NSMutableDictionary *requestMap;
    NSMutableDictionary *dataMap;
    long long totalLength;
    NSString *scheme;
    NSString *realScheme;
//    YYetsDecrypt *decrypt;
}
@property (nonatomic, readwrite, copy) NSString *url;
@end

@implementation CustomResourceLoader
-(instancetype)initWithHeaders:(NSDictionary*)headers scheme:(NSString*)scheme_ {
    self = [super init];
    additionHeaders = headers;
    if ([additionHeaders.allKeys containsObject:@"yyets_secret"]) {
        NSString *keystr = [additionHeaders objectForKey:@"yyets_secret"];
        NSLog(@"key %@", keystr);
        NSMutableData *keydata = [NSMutableData data];
        for (NSInteger i=0; i<keystr.length/2; i++) {
            const char *str = [keystr substringWithRange:NSMakeRange(i*2, 2)].UTF8String;
            unsigned char num[2];
            for (int j=0; j<2; j++) {
                if (str[j]>='0' && str[j]<='9') {
                    num[j]= str[j]-'0';
                } else {
                    num[j]= 10 + str[j]-'a';
                }
            }
            unsigned char n = num[0]<<4 | num[1];
            [keydata appendBytes:&n length:1];
        }
//        decrypt = [[YYetsDecrypt alloc] initWithKey:keydata];
    }
    realScheme = @"http";
    if ([additionHeaders.allKeys containsObject:@"real_scheme"]) {
        realScheme = [additionHeaders objectForKey:@"real_scheme"];
    }
    connectionMap = [NSMutableDictionary dictionary];
    requestMap = [NSMutableDictionary dictionary];
    dataMap = [NSMutableDictionary dictionary];
    scheme = scheme_;
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
    //NSLog(@"call shouldWaitForLoadingOfRequestedResource");
    return [self addLoadingRequest:loadingRequest];
}
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    //NSLog(@"didCancelLoadingRequest not implement");
    if (loadingRequest) {
        [self removeLoadingRequest:loadingRequest];
    }
}

- (BOOL)addLoadingRequest:(AVAssetResourceLoadingRequest*)loadingRequest {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:loadingRequest.request.URL];//loadingRequest.request.mutableCopy;
    NSURLComponents *comps = [[NSURLComponents alloc] initWithURL:request.URL resolvingAgainstBaseURL:NO];
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    comps.scheme = realScheme;
    request.URL = comps.URL;
    request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    AVAssetResourceLoadingDataRequest *dataRequest = loadingRequest.dataRequest;
    NSString *urlString = request.URL.absoluteString;
    NSString *extString = [urlString substringWithRange:NSMakeRange(urlString.length-3, 3)];
    if ([extString isEqualToString:@".ts"]) {
        //NSLog(@"abc");
        //loadingRequest.redirect = request;
        //[loadingRequest finishLoading];
        return NO;
    }
    if (additionHeaders) {
        for (NSString *key in loadingRequest.request.allHTTPHeaderFields) {
            NSString *value = [additionHeaders objectForKey:key];
            if (![key isEqualToString:@"X-Playback-Session-Id"] && ![key isEqualToString:@"yyets_secret"] && ![key isEqualToString:@"real_scheme"]) {
                [request setValue:value forHTTPHeaderField:key];
            }
        }
        for (NSString *key in additionHeaders.allKeys) {
            NSString *value = [additionHeaders objectForKey:key];
            if (![key isEqualToString:@"yyets_secret"] && ![key isEqualToString:@"real_scheme"]) {
                [request setValue:value forHTTPHeaderField:key];
            }
        }
    }
    if (dataRequest) {
        long long maxRequestSize = 128*1024;
        long long size = (dataRequest.requestedLength > maxRequestSize)? maxRequestSize : dataRequest.requestedLength;
        //NSLog(@"dataRequest current offset %lld request offset %lld length %zd", dataRequest.currentOffset, dataRequest.requestedOffset, dataRequest.requestedLength);
        NSString *rangeStr = [NSString stringWithFormat:@"bytes=%lld-%lld", dataRequest.requestedOffset,
                              dataRequest.requestedOffset+size-1];
        //NSLog(@"original rangeStr %@ totalLength %lld size %lld", rangeStr, totalLength, size);
        if ([scheme isEqualToString:@"yyets"] && dataRequest.requestedLength!=2) {
            long long pages = dataRequest.requestedOffset/4096;
            long long page_align_size = (dataRequest.requestedLength + (4096-1))/4096;
            if ((pages+page_align_size)*4906 > totalLength) {
                size = (dataRequest.requestedLength > maxRequestSize)? maxRequestSize : dataRequest.requestedLength;
                rangeStr = [NSString stringWithFormat:@"bytes=%lld-%lld", pages*4096, dataRequest.requestedOffset+size-1];
            } else {
                rangeStr = [NSString stringWithFormat:@"bytes=%lld-%lld", pages*4096, (pages+page_align_size)*4096-1];
            }
        }
        NSLog(@"final rangeStr %@ totalLength %lld", rangeStr, totalLength);
        [request setValue:rangeStr forHTTPHeaderField:@"Range"];
    }
    if (true) {
        NSLog(@"");
        NSLog(@"addLoadingRequest----------------------");
        NSLog(@"%@ %@", request.URL.absoluteString, request.allHTTPHeaderFields);
        NSLog(@"Finish addLoadingRequest----------------------");
        NSLog(@"");
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
    //NSLog(@"removeLoadingRequest %@", request.request.URL.absoluteString);
    NSURLSession *session = [self sessionFromLoadingRequest:request];
    if (session) {
        [self removeSession:session];
    }
}

//server responsed, we can get length here
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    if (true) {
        NSLog(@"");
        NSLog(@"response ++++++++++++++++++++");
        NSLog(@"URL %@", response.URL);
        NSLog(@"headers %@", httpResponse.allHeaderFields);
        NSLog(@"finish response ++++++++++++++++++++");
        NSLog(@"");
    }
    NSString *mimeType = @"video/mp4";
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
    completionHandler(NSURLSessionResponseAllow);
    unsigned long long contentLength = [response expectedContentLength];
    unsigned long long offset = 0;
    NSString *rangeValue = httpResponse.allHeaderFields[@"Content-Range"];
    if (rangeValue) {
        NSArray *rangeItems = [rangeValue componentsSeparatedByString:@"/"];
        if (rangeItems.count > 1) {
            contentLength = [rangeItems[1] longLongValue];
            offset = [rangeItems[0] longLongValue];
        }
    }
    AVAssetResourceLoadingRequest *loadingRequest = [self loadingRequestFromSession:session];
    loadingRequest.response = response;
    loadingRequest.contentInformationRequest.contentLength = contentLength;
    //NSString *contentType = [response MIMEType];
    //loadingRequest.contentInformationRequest.contentType = contentType;
    totalLength = contentLength;
    loadingRequest.contentInformationRequest.contentType = CFBridgingRelease(contentType);
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
}

//server returned data
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
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
        if ([scheme isEqualToString:@"yyets"]) {
            /*
            long long offset = loadingRequest.dataRequest.requestedOffset % 4096;
            for (long long i=0; i<=sessionData.length/4096; i++) {
                if (sessionData.length >= i*4096+16) {
                    NSData *head16bits = [sessionData subdataWithRange:NSMakeRange(i*4096, 16)];
                    NSData *dData = [decrypt yyets_decrypt:head16bits];
                    [sessionData replaceBytesInRange:NSMakeRange(i*4096, 16) withBytes:dData.bytes length:16];
                }
            }
            long long len = sessionData.length - offset;
            NSRange range = NSMakeRange(offset, len);
            NSData *data = [sessionData subdataWithRange:range];
            [loadingRequest.dataRequest respondWithData:data];
             */
        } else {
            NSLog(@"respondWithData ++");
            [loadingRequest.dataRequest respondWithData:sessionData];
        }
        AVAssetResourceLoadingDataRequest *dataRequest = loadingRequest.dataRequest;
        NSLog(@"URLSession task no error data length %zd start %lld -> %llu", sessionData.length,
              dataRequest.requestedOffset, dataRequest.requestedOffset + sessionData.length-1);
        [loadingRequest finishLoading];
        [self removeSession:session];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    //NSLog(@"redirect to request %@", request);
    completionHandler(request);
}
@end
