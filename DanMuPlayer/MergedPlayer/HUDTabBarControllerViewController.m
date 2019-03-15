//
//  HUDTabBarControllerViewController.m
//  DanMuPlayer
//
//  Created by zfu on 2019/3/14.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "HUDTabBarControllerViewController.h"
#import "InfoTabViewController.h"

@interface HUDTabBarControllerViewController ()

@end

@implementation HUDTabBarControllerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    InfoTabViewController *infoVc = [[InfoTabViewController alloc] initWithNibName:@"InfoTabViewController"
                                                                            bundle:nil];
    infoVc.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"简介" image:nil tag:0];
    self.viewControllers = @[infoVc];
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
