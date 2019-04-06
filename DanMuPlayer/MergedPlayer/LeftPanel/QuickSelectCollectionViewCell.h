//
//  QuickSelectCollectionViewCell.h
//  DanMuPlayer
//
//  Created by zfu on 2019/4/5.
//  Copyright © 2019 zfu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface QuickSelectCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

NS_ASSUME_NONNULL_END
