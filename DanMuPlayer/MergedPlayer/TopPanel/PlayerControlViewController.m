//
//  PlayerControlViewController.m
//  DanMuPlayer
//
//  Created by zfu on 2019/3/17.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "PlayerControlViewController.h"
#import "SelectionCollectionViewCell.h"
#import "headerCollectionReusableView.h"

@interface PlayerControlViewController () {
}
@end

@implementation PlayerControlViewController
@synthesize delegate;
@synthesize controlData;
@synthesize visiableView;
@synthesize contentHeightConstraint;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.fuzhuo.DanMuPlayer"];
    UINib *headerNib = [UINib nibWithNibName:@"headerCollectionReusableView" bundle:bundle];
    UINib *selectionNib = [UINib nibWithNibName:@"SelectionCollectionViewCell" bundle:bundle];
    
    [self.speedCollectionView registerNib:headerNib forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    [self.speedCollectionView registerNib:selectionNib forCellWithReuseIdentifier:@"SelectionViewCell"];
    
    [self.scaleCollectionView registerNib:headerNib forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    [self.scaleCollectionView registerNib:selectionNib forCellWithReuseIdentifier:@"SelectionViewCell"];
    
    [self.danmuCollectionView registerNib:headerNib forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    [self.danmuCollectionView registerNib:selectionNib forCellWithReuseIdentifier:@"SelectionViewCell"];
    
    visiableView = _bgVisualEffectiView;
    contentHeightConstraint = _heightConstraint;
}

- (BOOL)_tvTabBarShouldOverlap {
    return YES;
}

- (BOOL)_tvTabBarShouldAutohide {
    return NO;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.speedCollectionView) {
        return PlaySpeedModeCount;
    } else if (collectionView == self.scaleCollectionView) {
        return PlayScaleModeCount;
    } else if (collectionView == self.danmuCollectionView) {
        return PlayDanMuModeCount;
    }
    return 0;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SelectionCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SelectionViewCell" forIndexPath:indexPath];
//    NSBundle *avkitBundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/AVKit.framework"];
//    UIImage *img = [UIImage imageNamed:@"NowPlayingCheckmark" inBundle:avkitBundle compatibleWithTraitCollection:nil];
    UIImage *img = [UIImage imageNamed:@"selection"];
    UIImage *templateImg = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIUserInterfaceStyle style =  UIScreen.mainScreen.traitCollection.userInterfaceStyle;
    if (style == UIUserInterfaceStyleLight) {
        cell.imageView.tintColor = UIColor.blackColor;
        cell.titleLabel.textColor = UIColor.blackColor;
    } else {
        cell.imageView.tintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.6];
        cell.titleLabel.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.6];
    }
    if (collectionView == self.speedCollectionView) {
        NSArray *options = @[
                             @"1/4倍速",
                             @"1/2倍速",
                             @"1.0倍速",
                             @"2.0倍速",
                             @"3.0倍速",
                             @"4.0倍速",
                             ];
        cell.titleLabel.text = [options objectAtIndex:indexPath.item];
        [cell.imageView setImage:templateImg];
        if (indexPath.item == controlData.speedMode) {
            cell.imageView.alpha = 1.0f;
        } else {
            cell.imageView.alpha = 0.0f;
        }
    } else if (collectionView == self.scaleCollectionView) {
        NSArray *options = @[
                             @"等比缩放",
                             @"裁剪缩放",
                             @"拉伸缩放",
                             ];
        cell.titleLabel.text = [options objectAtIndex:indexPath.item];
        [cell.imageView setImage:templateImg];
        if (indexPath.item == controlData.scaleMode) {
            cell.imageView.alpha = 1.0f;
        } else {
            cell.imageView.alpha = 0.0f;
        }
    } else if (collectionView == self.danmuCollectionView) {
        NSArray *options = @[
                             @"显示弹幕(如果有)",
                             @"关闭弹幕",
                             ];
        cell.titleLabel.text = [options objectAtIndex:indexPath.item];
        [cell.imageView setImage:templateImg];
        if (indexPath.item == controlData.danmuMode) {
            cell.imageView.alpha = 1.0f;
        } else {
            cell.imageView.alpha = 0.0f;
        }
    }
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        headerCollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];
        if (collectionView == self.speedCollectionView) {
            view.titleLabel.text = @"播放速度";
        } else if (collectionView == self.scaleCollectionView){
            view.titleLabel.text = @"缩放方式";
        } else {
            view.titleLabel.text = @"弹幕控制";
        }
        return view;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(300, 60);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(300, 32);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"select item %lu %lu", indexPath.section, indexPath.item);
    BOOL changed = NO;
    if (collectionView == self.speedCollectionView) {
        if (controlData.speedMode != indexPath.item) {
            controlData.speedMode = indexPath.item;
            if (self.delegate) {
                [self.delegate onPanelChangePlaySpeedMode:controlData.speedMode];
            }
            changed = YES;
        }
    } else if (collectionView == self.scaleCollectionView) {
        if (controlData.scaleMode != indexPath.item) {
            controlData.scaleMode = indexPath.item;
            if (self.delegate) {
                [self.delegate onPanelChangePlayScaleMode:controlData.scaleMode];
            }
            changed = YES;
        }
    } else {
        if (controlData.danmuMode != indexPath.item) {
            controlData.danmuMode = indexPath.item;
            if (self.delegate) {
                [self.delegate onPanelChangeDanMuMode:controlData.danmuMode];
            }
            changed = YES;
        }
    }
    if (changed) {
        [collectionView reloadData];
    }
}
@end
