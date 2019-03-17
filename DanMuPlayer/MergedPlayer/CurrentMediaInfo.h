//
//  CurrentMediaInfo.h
//  DanMuPlayer
//
//  Created by zfu on 2019/3/17.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface CurrentMediaInfo : NSObject
@property (nonatomic, readwrite, copy) NSString *title;
@property (nonatomic, readwrite, copy) NSString *description;
@property (nonatomic, readwrite, copy) NSString *resolution;
@property (nonatomic, readwrite, copy) NSString *imgURL;
@property (nonatomic, readwrite, assign) NSInteger duration;
@property (nonatomic, readwrite, assign) CGFloat fps;
- (instancetype)initWithMediaInfo:(CurrentMediaInfo*)info;
@end

NS_ASSUME_NONNULL_END
