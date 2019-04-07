//
//  RightPanelViewController.h
//  DanMuPlayer
//
//  Created by zfu on 2019/4/6.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^clickCallBack)(NSInteger);
@interface RightPanelViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, readwrite, assign) BOOL left;
@property (nonatomic, readwrite, copy) NSString *title;
- (void)setupPlayURLs:(NSMutableArray*)playURLs
         currentIndex:(NSInteger)currentIndex;
- (void)setCallBack:(clickCallBack)clickCallBack;
- (void)reload;
@end

NS_ASSUME_NONNULL_END
