//
//  InfoPanelViewController.m
//  DanMuPlayer
//
//  Created by zfu on 2019/3/16.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "InfoPanelViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface InfoPanelViewController () {
    CurrentMediaInfo *_currentMediaInfo;
}
@end

@implementation InfoPanelViewController
@synthesize visiableView;
@synthesize contentHeightConstraint;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleLabel.text = @" ";
    self.descLabel.text = @"无";
    self.fpsLabel.text = @" ";
    self.resolutionLabel.text = @" ";
    
    if (_currentMediaInfo) {
        self.titleLabel.text = _currentMediaInfo.title;
        if (_currentMediaInfo.description.length > 0) {
            self.descLabel.text = _currentMediaInfo.description;
        }
        if (_currentMediaInfo.fps <= 0.01) {
            self.fpsLabel.text = @" ";
        } else {
            self.fpsLabel.text = [NSString stringWithFormat:@"%.2f 帧/秒", _currentMediaInfo.fps];
        }
        self.resolutionLabel.text = _currentMediaInfo.resolution;
        self.durationLabel.text = [self timeToStr:_currentMediaInfo.duration];
    }
    if (_currentMediaInfo.image) {
        self.artworkImageView.image = _currentMediaInfo.image;
    }
    contentHeightConstraint = _heightConstraint;
    visiableView = _bgVisualEffectView;
}

- (BOOL)_tvTabBarShouldOverlap {
    return NO;
}

- (BOOL)_tvTabBarShouldAutohide {
    return NO;
}

- (void)updateMediaInfo:(CurrentMediaInfo*)currentMediaInfo {
    _currentMediaInfo = [[CurrentMediaInfo alloc] initWithMediaInfo:currentMediaInfo];
}

- (NSString*)timeToStr:(NSInteger)time {
    if (time < 0) {
        return @"直播流";
    } else if (time < 0.1) {
        return @" ";
    }
    NSInteger hour = time/3600;
    NSInteger min = (time-hour*3600)/60;
    NSInteger sec = time-hour*3600-min*60;
    if (hour > 0) {
        return [NSString stringWithFormat:@"%ld小时%ld分", hour, min];
    } else if (min > 0) {
        return [NSString stringWithFormat:@"%ld分%ld秒", min, sec];
    } else {
        return [NSString stringWithFormat:@"%ld秒", sec];
    }
}

@end
