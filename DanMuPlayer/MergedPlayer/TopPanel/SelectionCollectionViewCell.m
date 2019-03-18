//
//  SelectionCollectionViewCell.m
//  DanMuPlayer
//
//  Created by zfu on 2019/3/17.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "SelectionCollectionViewCell.h"

@implementation SelectionCollectionViewCell
- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context
       withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    if (self.focused) {
        self.imageView.tintColor = UIColor.whiteColor;
        self.titleLabel.textColor = UIColor.whiteColor;
    } else {
        self.imageView.tintColor = UIColor.blackColor;
        self.titleLabel.textColor = UIColor.blackColor;
    }
}
@end
