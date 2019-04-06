//
//  ContinuePlayViewController.h
//  DanMuPlayer
//
//  Created by zfu on 2019/4/6.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^resumeCB)(void);
@interface ContinuePlayViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *titleLabel;
@property (nonatomic, readwrite, copy) NSString *title;
@property (nonatomic, readwrite, strong) resumeCB resume;
@end

NS_ASSUME_NONNULL_END
