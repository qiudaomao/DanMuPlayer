//
//  PlayerViewController.h
//  tvosPlayer
//
//  Created by zfu on 2017/4/9.
//  Copyright © 2017年 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SGPlayer/SGPlayer.h>
#import "MMVideoSources.h"
#import "DanMuLayer.h"
#import "AbstractPlayer.h"

@interface PlayerViewController : UIViewController<UIGestureRecognizerDelegate, AbstractPlayerProtocol, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, readonly, strong) SGPlayer *player;
@end
