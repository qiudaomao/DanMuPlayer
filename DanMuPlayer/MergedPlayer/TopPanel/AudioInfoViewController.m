//
//  AudioInfoViewController.m
//  DanMuPlayer
//
//  Created by zfu on 2019/3/16.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "AudioInfoViewController.h"
#import <UIKit/UIKit.h>

@interface AudioInfoViewController ()

@end

@implementation AudioInfoViewController
@synthesize visiableView;
@synthesize contentHeightConstraint;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CGRect frame = self.bgVisualEffectView.frame;
    AVRoutePickerView *view = [[AVRoutePickerView alloc] initWithFrame:CGRectMake(frame.size.width/2-30, frame.size.height/2-30, 60, 60)];
    view.activeTintColor = UIColor.blueColor;
    view.delegate = self;
    [self.bgVisualEffectView.contentView addSubview:view];
    view.userInteractionEnabled = YES;
    visiableView = _bgVisualEffectView;
    contentHeightConstraint = _heightConstraint;
}

- (BOOL)_tvTabBarShouldOverlap {
    return NO;
}

- (BOOL)_tvTabBarShouldAutohide {
    return NO;
}

- (void)routePickerViewWillBeginPresentingRoutes:(AVRoutePickerView *)routePickerView {
    NSLog(@"begin");
}

- (void)routePickerViewDidEndPresentingRoutes:(AVRoutePickerView *)routePickerView {
    NSLog(@"did end");
}
@end
