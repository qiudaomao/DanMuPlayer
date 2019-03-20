//
//  TopPanelViewController.h
//  DanMuPlayer
//
//  Created by zfu on 2019/3/16.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CurrentMediaInfo.h"
#import "PanelControlProtocol.h"
#import "PanelControlData.h"
#import "DMPlaylist.h"

NS_ASSUME_NONNULL_BEGIN

@interface TopPanelViewController : UIViewController <UITabBarControllerDelegate>
- (void)setCurrentMediaInfo:(CurrentMediaInfo*)mediaInfo;
@property (weak, readwrite) id<PanelControlProtocol> delegate;
@property (nonatomic, readwrite, strong) PanelControlData *controlData;
- (void)setupButtonList:(DMPlaylist*)playlist clickCallBack:(JSValue*)callback focusIndex:(NSInteger)focusIndex;
@end

NS_ASSUME_NONNULL_END
