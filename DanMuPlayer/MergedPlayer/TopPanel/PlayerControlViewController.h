//
//  PlayerControlViewController.h
//  DanMuPlayer
//
//  Created by zfu on 2019/3/17.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PanelControlProtocol.h"
#import "PanelControlData.h"
#import "TabAnimationVCProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface PlayerControlViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, TabAnimationVCProtocol>
@property (weak, nonatomic) IBOutlet UICollectionView *speedCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *scaleCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *danmuCollectionView;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *bgVisualEffectiView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;
@property (weak, nonatomic, readwrite) id<PanelControlProtocol> delegate;
@property (nonatomic, readwrite, strong) PanelControlData *controlData;
@end

NS_ASSUME_NONNULL_END
