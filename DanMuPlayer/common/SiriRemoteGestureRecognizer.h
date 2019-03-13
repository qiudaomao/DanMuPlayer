//
//  SiriRemoteGestureRecognizer.h
//  LazyCat
//
//  Created by zfu on 2017/6/2.
//  Copyright © 2017年 zfu. All rights reserved.
//

#ifndef SiriRemoteGestureRecognizer_h
#define SiriRemoteGestureRecognizer_h

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SiriRemoteTouchLocation) {
    MMSiriRemoteTouchLocationUnknown,
    MMSiriRemoteTouchLocationLeft,
    MMSiriRemoteTouchLocationRight,
    MMSiriRemoteTouchLocationUp,
    MMSiriRemoteTouchLocationDown,
    MMSiriRemoteTouchLocationCenter,
};

@interface SiriRemoteGestureRecognizer : UIGestureRecognizer
@property (nonatomic, readonly) SiriRemoteTouchLocation touchLocation;
@property (nonatomic, readonly) NSString *touchLocationName;
@property (nonatomic, readonly) NSString *stateName;
@property (nonatomic, readonly, getter=isClick) BOOL click;
@end
#endif /* SiriRemoteGestureRecognizer_h */
