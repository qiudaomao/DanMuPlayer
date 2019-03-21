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
    UIProgressView *progressView;
    CGFloat progress;
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

    progressView = [[UIProgressView alloc] init];
    progressView.translatesAutoresizingMaskIntoConstraints = NO;
    progressView.hidden = YES;
    /*
    CGRect frame = self.imageView.frame;
    CGRect overlayframe = self.imageView.overlayContentView.frame;
    overlayframe.size.width = frame.size.width;
    self.imageView.overlayContentView.frame = overlayframe;
     */
    
    NSLayoutConstraint *leading, *trailing, *bottom, *height;
    leading = [NSLayoutConstraint constraintWithItem:progressView
                                           attribute:NSLayoutAttributeLeading
                                           relatedBy:NSLayoutRelationEqual
                                              toItem:self.imageView.overlayContentView
                                           attribute:NSLayoutAttributeLeading
                                          multiplier:1.0 constant:20];
    trailing = [NSLayoutConstraint constraintWithItem:progressView
                                            attribute:NSLayoutAttributeTrailing
                                            relatedBy:NSLayoutRelationEqual
                                               toItem:self.imageView.overlayContentView
                                            attribute:NSLayoutAttributeTrailing
                                           multiplier:1.0 constant:-20];
    bottom = [NSLayoutConstraint constraintWithItem:progressView
                                          attribute:NSLayoutAttributeBottom
                                          relatedBy:NSLayoutRelationEqual
                                             toItem:self.imageView.overlayContentView
                                          attribute:NSLayoutAttributeBottom
                                         multiplier:1.0 constant:-10];
    height = [NSLayoutConstraint constraintWithItem:progressView
                                          attribute:NSLayoutAttributeHeight
                                          relatedBy:NSLayoutRelationEqual
                                             toItem:nil
                                          attribute:NSLayoutAttributeNotAnAttribute
                                         multiplier:1.0 constant:4];
//    leading.active = YES;
//    trailing.active = YES;
//    bottom.active = YES;
//    height.active = YES;
    [self.imageView.overlayContentView addSubview:progressView];
    [self.imageView.overlayContentView addConstraints:@[leading, trailing, bottom, height]];
    [self layoutIfNeeded];
}

- (void)updateProgress:(CGFloat)progress_ {
    progress = progress_;
    if (progress < 0.01) {
        progressView.hidden = YES;
    } else {
        progressView.hidden = NO;
        [progressView setProgress:progress animated:YES];
    }
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
