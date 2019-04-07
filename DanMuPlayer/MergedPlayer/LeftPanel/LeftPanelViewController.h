//
//  LeftPanelViewController.h
//  DanMuPlayer
//
//  Created by zfu on 2019/4/5.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DMPlaylist.h"

NS_ASSUME_NONNULL_BEGIN
typedef void(^clickCallBack)(NSInteger);
@interface LeftPanelViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, readwrite, copy) NSString *title;
- (void)setupPlayList:(DMPlaylist*)playlist
        clickCallBack:(clickCallBack)clickCallBack
         currentIndex:(NSInteger)currentIndex;
@end

NS_ASSUME_NONNULL_END
