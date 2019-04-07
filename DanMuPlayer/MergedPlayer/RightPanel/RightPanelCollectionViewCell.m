//
//  RightPanelCollectionViewCell.m
//  DanMuPlayer
//
//  Created by zfu on 2019/4/6.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "RightPanelCollectionViewCell.h"

@implementation RightPanelCollectionViewCell

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context
       withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    if (!self.focused) {
        self.titleLabel.textColor = UIColor.grayColor;
        //        self.layer.borderColor = UIColor.blackColor.CGColor;
        //        self.layer.borderWidth = 0.0f;
        self.layer.backgroundColor = UIColor.clearColor.CGColor;
        self.imageView.tintColor = UIColor.grayColor;
    } else {
        self.titleLabel.textColor = UIColor.whiteColor;
        self.imageView.tintColor = UIColor.whiteColor;
        //        self.layer.borderColor = UIColor.orangeColor.CGColor;
        //        self.layer.borderWidth = 3.0f;
        self.layer.backgroundColor = UIColor.orangeColor.CGColor;
    }
}
@end
