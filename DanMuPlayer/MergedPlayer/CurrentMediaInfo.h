//
//  CurrentMediaInfo.h
//  DanMuPlayer
//
//  Created by zfu on 2019/3/17.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGBase.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
NS_ASSUME_NONNULL_BEGIN

@interface CurrentMediaInfo : NSObject
@property (nonatomic, readwrite, copy) NSString *title;
@property (nonatomic, readwrite, copy) NSString *description;
@property (nonatomic, readwrite, copy) NSString *resolution;
@property (nonatomic, readwrite, copy) NSString *imgURL;
@property (nonatomic, readwrite, assign) NSInteger duration;
@property (nonatomic, readwrite, assign) CGFloat fps;
@property (nonatomic, readwrite, strong) MPMediaItemArtwork *__nullable artwork;
@property (nonatomic, readwrite, strong) UIImage *__nullable image;
- (instancetype)initWithMediaInfo:(CurrentMediaInfo*)info;
@end

NS_ASSUME_NONNULL_END
