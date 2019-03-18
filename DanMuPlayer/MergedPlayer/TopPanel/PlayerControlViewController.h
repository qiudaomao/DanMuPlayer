//
//  PlayerControlViewController.h
//  DanMuPlayer
//
//  Created by zfu on 2019/3/17.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerControlViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UICollectionView *speedCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *scaleCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *danmuCollectionView;
@property (nonatomic, readwrite, assign) NSInteger danmu;
@property (nonatomic, readwrite, assign) NSInteger scaleMode;
@property (nonatomic, readwrite, assign) NSInteger speedMode;
@end

NS_ASSUME_NONNULL_END
