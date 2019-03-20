//
//  PanelControlProtocol.h
//  DanMuPlayer
//
//  Created by zfu on 2019/3/18.
//  Copyright © 2019 zfu. All rights reserved.
//

#ifndef PanelControlProtocol_h
#define PanelControlProtocol_h

typedef NS_ENUM(NSUInteger, PlaySpeedMode) {
    PlaySpeedModeQuarter,
    PlaySpeedModeHalf,
    PlaySpeedModeNormal,
    PlaySpeedModeDouble,
    PlaySpeedModeTriple,
    PlaySpeedModeQuad,
    PlaySpeedModeCount,
};

typedef NS_ENUM(NSUInteger, PlayScaleMode) {
    PlayScaleModeRatio,
    PlayScaleModeClip,
    PlayScaleModeStretch,
    PlayScaleModeCount,
};

typedef NS_ENUM(NSUInteger, PlayDanMuMode) {
    PlayDanMuNoDanMu = -1,
    PlayDanMuOn = 0,
    PlayDanMuOff = 1,
    PlayDanMuModeCount,
};

@protocol PanelControlProtocol <NSObject>
- (void)onPanelChangePlaySpeedMode:(PlaySpeedMode)speedMode;
- (void)onPanelChangePlayScaleMode:(PlayScaleMode)scaleMode;
- (void)onPanelChangeDanMuMode:(PlayDanMuMode)danmuMode;
@end

#endif /* PanelControlProtocol_h */
