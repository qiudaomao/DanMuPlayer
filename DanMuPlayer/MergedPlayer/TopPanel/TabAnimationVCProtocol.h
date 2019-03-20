//
//  TabAnimationVCProtocol.h
//  DanMuPlayer
//
//  Created by zfu on 2019/3/20.
//  Copyright © 2019 zfu. All rights reserved.
//

#ifndef TabAnimationVCProtocol_h
#define TabAnimationVCProtocol_h

@protocol TabAnimationVCProtocol <NSObject>
@property (nonatomic, readwrite, weak) UIView *visiableView;
@property (nonatomic, readwrite, weak) NSLayoutConstraint *contentHeightConstraint;
@end

#endif /* TabAnimationVCProtocol_h */
