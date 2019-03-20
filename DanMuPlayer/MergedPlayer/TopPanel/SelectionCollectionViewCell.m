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
    UIUserInterfaceStyle style =  UIScreen.mainScreen.traitCollection.userInterfaceStyle;
    if (style == UIUserInterfaceStyleLight) {
        if (self.focused) {
            self.imageView.tintColor = UIColor.whiteColor;
            self.titleLabel.textColor = UIColor.whiteColor;
        } else {
            self.imageView.tintColor = UIColor.blackColor;
            self.titleLabel.textColor = UIColor.blackColor;
        }
    } else {
        if (self.focused) {
            self.imageView.tintColor = UIColor.whiteColor;
            self.titleLabel.textColor = UIColor.whiteColor;
        } else {
            self.titleLabel.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.6];
            self.imageView.tintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.6];
        }
    }
}
@end
