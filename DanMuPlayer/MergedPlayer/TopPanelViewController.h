//
//  TopPanelViewController.h
//  DanMuPlayer
//
//  Created by zfu on 2019/3/16.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CurrentMediaInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface TopPanelViewController : UIViewController
- (void)setCurrentMediaInfo:(CurrentMediaInfo*)mediaInfo;
@end

NS_ASSUME_NONNULL_END
