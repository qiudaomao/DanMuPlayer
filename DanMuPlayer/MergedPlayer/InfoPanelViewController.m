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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleLabel.text = @" ";
    self.descLabel.text = @" ";
    self.fpsLabel.text = @" ";
    self.resolutionLabel.text = @" ";
    
    if (_currentMediaInfo) {
        self.titleLabel.text = _currentMediaInfo.title;
        self.descLabel.text = _currentMediaInfo.description;
        if (_currentMediaInfo.fps <= 0.01) {
            self.fpsLabel.text = @" ";
        } else {
            self.fpsLabel.text = [NSString stringWithFormat:@"%.2f 帧/秒", _currentMediaInfo.fps];
        }
        self.resolutionLabel.text = _currentMediaInfo.resolution;
        self.durationLabel.text = [self timeToStr:_currentMediaInfo.duration];
    }
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
    if (time <= 0) {
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
