//
//  PanelControlData.h
//  DanMuPlayer
//
//  Created by zfu on 2019/3/18.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PanelControlProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface PanelControlData : NSObject
@property (nonatomic, readwrite, assign) PlaySpeedMode speedMode;
@property (nonatomic, readwrite, assign) PlayScaleMode scaleMode;
@property (nonatomic, readwrite, assign) PlayDanMuMode danmuMode;
@end

NS_ASSUME_NONNULL_END
