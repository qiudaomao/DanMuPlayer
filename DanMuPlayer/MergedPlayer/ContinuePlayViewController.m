//
//  ContinuePlayViewController.m
//  DanMuPlayer
//
//  Created by zfu on 2019/4/6.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "ContinuePlayViewController.h"

@interface ContinuePlayViewController () {
    NSTimer *timer;
    BOOL seeked;
}
@end

@implementation ContinuePlayViewController
@synthesize title;
@synthesize resume;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    seeked = NO;
    [self.titleLabel setTitle:self.title forState:UIControlStateNormal];
    __weak typeof(self) weakSelf = self;
    timer = [NSTimer timerWithTimeInterval:8 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [weakSelf dismissViewControllerAnimated:YES completion:^{
        }];
    }];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (IBAction)buttonClicked:(id)sender {
    if (seeked) return;
    seeked = YES;
    [timer invalidate];
    if (resume) {
        resume();
    }
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf dismissViewControllerAnimated:YES completion:^{
        }];
    });
}

@end
