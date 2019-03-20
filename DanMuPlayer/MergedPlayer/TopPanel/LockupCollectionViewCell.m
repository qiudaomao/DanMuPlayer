//
//  LockupCollectionViewCell.m
//  DanMuPlayer
//
//  Created by zfu on 2019/3/17.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "LockupCollectionViewCell.h"

@interface LockupCollectionViewCell() {
    NSLayoutConstraint *focusedSpacingConstraint;
    NSLayoutConstraint *unFocusedSpacingConstraint;
}
@end

@implementation LockupCollectionViewCell
- (void)awakeFromNib {
    [super awakeFromNib];
    self.imageView.adjustsImageWhenAncestorFocused = YES;
    self.imageView.clipsToBounds = NO;
    focusedSpacingConstraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
                                                            attribute:NSLayoutAttributeTop
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.imageView.focusedFrameGuide
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1
                                                             constant:10];
    focusedSpacingConstraint.active = NO;
    unFocusedSpacingConstraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
                                                            attribute:NSLayoutAttributeTop
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.imageView
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1
                                                             constant:12];
    unFocusedSpacingConstraint.active = NO;
}

- (void)updateConstraints {
    [super updateConstraints];
//    NSLog(@"updateConstraint self.focused %@ %@", self, @(self.focused));
    focusedSpacingConstraint.active = self.focused;
    unFocusedSpacingConstraint.active = !self.focused;
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context
       withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    UIUserInterfaceStyle style =  UIScreen.mainScreen.traitCollection.userInterfaceStyle;
    if (style == UIUserInterfaceStyleLight) {
        if (self.focused) {
            self.titleLabel.textColor = UIColor.whiteColor;
        } else {
            self.titleLabel.textColor = UIColor.blackColor;
        }
    } else {
        if (self.focused) {
            self.titleLabel.textColor = UIColor.whiteColor;
        } else {
            self.titleLabel.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.6];
        }
    }
    [self setNeedsUpdateConstraints];
    [coordinator addCoordinatedAnimations:^{
        [self layoutIfNeeded];
    } completion:nil];
}
@end
