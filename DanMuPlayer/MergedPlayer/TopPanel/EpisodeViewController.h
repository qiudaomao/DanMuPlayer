//
//  EpisodeViewController.h
//  DanMuPlayer
//
//  Created by zfu on 2019/3/17.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TabAnimationVCProtocol.h"
#import "DMPlaylist.h"

NS_ASSUME_NONNULL_BEGIN

@interface EpisodeViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, TabAnimationVCProtocol>
@property (weak, nonatomic) IBOutlet UIVisualEffectView *bgVisualEffectView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;
- (void)setupButtonList:(DMPlaylist*)playlist clickCallBack:(JSValue*)callback focusIndex:(NSInteger)focusIndex;
@end

NS_ASSUME_NONNULL_END
