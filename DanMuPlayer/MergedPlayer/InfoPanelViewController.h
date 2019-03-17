//
//  InfoPanelViewController.h
//  DanMuPlayer
//
//  Created by zfu on 2019/3/16.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CurrentMediaInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface InfoPanelViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *resolutionLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
- (void)updateMediaInfo:(CurrentMediaInfo*)currentMediaInfo;
@end

NS_ASSUME_NONNULL_END
