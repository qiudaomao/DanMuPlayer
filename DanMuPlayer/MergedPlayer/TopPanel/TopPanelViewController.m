//
//  TopPanelViewController.m
//  DanMuPlayer
//
//  Created by zfu on 2019/3/16.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "TopPanelViewController.h"
#import "InfoPanelViewController.h"
#import "AudioInfoViewController.h"
#import "PlayerControlViewController.h"
#import "EpisodeViewController.h"

@interface TopPanelViewController () {
    InfoPanelViewController *infovc;
    CurrentMediaInfo *currentMediaInfo;
}
@end

@implementation TopPanelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    UITabBar *tabBar = tabBarController.tabBar;
    tabBar.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.fuzhuo.DanMuPlayer"];
    infovc = [[InfoPanelViewController alloc] initWithNibName:@"InfoPanelViewController" bundle:bundle];
    infovc.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"信息" image:nil tag:0];
    [infovc updateMediaInfo:currentMediaInfo];
    
    AudioInfoViewController *audioVC = [[AudioInfoViewController alloc] initWithNibName:@"AudioInfoViewController" bundle:bundle];
    audioVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"音频" image:nil tag:0];
    audioVC.view.frame = CGRectMake(0, 0, self.view.frame.size.width, 600);
    
    PlayerControlViewController *controlVC = [[PlayerControlViewController alloc] initWithNibName:@"PlayerControlViewController"
                                                                                         bundle:bundle];
    controlVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"控制" image:nil tag:0];
    
    EpisodeViewController *episodeVC = [[EpisodeViewController alloc] initWithNibName:@"EpisodeViewController" bundle:bundle];
    episodeVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"选集" image:nil tag:0];
    tabBarController.viewControllers = @[infovc, controlVC, episodeVC, audioVC];
    [self addChildViewController:tabBarController];
    [tabBarController didMoveToParentViewController:self];
    [self.view addSubview:tabBarController.view];
}

- (void)setCurrentMediaInfo:(CurrentMediaInfo*)mediaInfo {
    currentMediaInfo = [[CurrentMediaInfo alloc] initWithMediaInfo:mediaInfo];
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
