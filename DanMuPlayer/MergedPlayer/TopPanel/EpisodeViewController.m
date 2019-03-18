//
//  EpisodeViewController.m
//  DanMuPlayer
//
//  Created by zfu on 2019/3/17.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "EpisodeViewController.h"
#import "LockupCollectionViewCell.h"

@interface EpisodeViewController ()

@end

@implementation EpisodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.fuzhuo.DanMuPlayer"];
    UINib *selectionNib = [UINib nibWithNibName:@"LockupCollectionViewCell" bundle:bundle];
    [self.collectionView registerNib:selectionNib forCellWithReuseIdentifier:@"LockupCollectionViewCell"];
    
    UICollectionViewFlowLayout *layout = UICollectionViewFlowLayout.new;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(220, 190);
    layout.minimumInteritemSpacing = 10;
    self.collectionView.collectionViewLayout = layout;
}

- (BOOL)_tvTabBarShouldAutohide {
    return NO;
}

- (BOOL)_tvTabBarShouldOverlap {
    return YES;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 16;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LockupCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LockupCollectionViewCell"
                                                                            forIndexPath:indexPath];
    cell.titleLabel.text = [NSString stringWithFormat:@"标题%lu", indexPath.item];
    return cell;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(220, 190);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"select item %lu %lu", indexPath.section, indexPath.item);
}
@end
