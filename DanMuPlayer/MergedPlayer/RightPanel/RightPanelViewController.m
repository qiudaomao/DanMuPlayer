//
//  RightPanelViewController.m
//  DanMuPlayer
//
//  Created by zfu on 2019/4/6.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "RightPanelViewController.h"
#import "RightPanelCollectionViewCell.h"

@interface RightPanelViewController () {
    UITapGestureRecognizer *tapGestureRecognizer;
    UISwipeGestureRecognizer *swipeGestureRecognizer;
    BOOL dismissed;
    NSMutableArray *playURLs;
    NSInteger currentIndex;
    clickCallBack clickCB;
    BOOL initScrolled;
}
@end

@implementation RightPanelViewController
@synthesize title = _title;

- (void)setupPlayURLs:(NSMutableArray*)playURLs_
         currentIndex:(NSInteger)currentIndex_ {
    playURLs = playURLs_;
    currentIndex = currentIndex_;
}

- (void)setCallBack:(clickCallBack)clickCallBack {
    clickCB = clickCallBack;
}

- (void)reload {
    [self.collectionView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    dismissed = NO;
    // Do any additional setup after loading the view.
    self.preferredContentSize = CGSizeMake(400, self.view.frame.size.height);
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.fuzhuo.DanMuPlayer"];
    UINib *selectionNib = [UINib nibWithNibName:@"RightPanelCollectionViewCell" bundle:bundle];
    [self.collectionView registerNib:selectionNib forCellWithReuseIdentifier:@"RightPanelCollectionViewCell"];
    self.collectionView.remembersLastFocusedIndexPath = YES;
    self.titleLabel.text = self.title;
}

- (void)viewWillAppear:(BOOL)animated {
    dismissed = NO;
    initScrolled = NO;
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapKey:)];
    tapGestureRecognizer.allowedPressTypes = @[
                                               @(UIPressTypeRightArrow),
                                               @(UIPressTypeLeftArrow),
                                               ];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipRight:)];
    [swipeGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:swipeGestureRecognizer];
}

- (void)viewDidLayoutSubviews {
    if (initScrolled) return;
    initScrolled = YES;
    if (playURLs && playURLs.count > 0 && currentIndex >= 0 && currentIndex < playURLs.count) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:currentIndex inSection:0];
        [_collectionView scrollToItemAtIndexPath:indexPath
                                atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                                        animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.view removeGestureRecognizer:tapGestureRecognizer];
    [self.view removeGestureRecognizer:swipeGestureRecognizer];
}

- (void)swipRight:(UISwipeGestureRecognizer*)sender {
    [self dissmiss];
}

- (void)tapKey:(UITapGestureRecognizer*)sender {
    [self dissmiss];
}

- (void)dissmiss {
    if (!dismissed) {
        dismissed = YES;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(-40, 0, -45, 0);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (playURLs) {
        return playURLs.count;
    }
    return 0;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RightPanelCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"RightPanelCollectionViewCell"
                                                                                    forIndexPath:indexPath];
    //    cell.layer.borderWidth = 1.0f;
    //    cell.layer.borderColor = UIColor.blackColor.CGColor;
    cell.titleLabel.textColor = UIColor.grayColor;
    NSDictionary *dict = [playURLs objectAtIndex:indexPath.item];
    NSString *name = [dict objectForKey:@"name"];
    UIImage *img = [UIImage imageNamed:@"selection"];
    UIImage *templateImg = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.imageView.image = templateImg;
    if (indexPath.item == currentIndex) {
        cell.imageView.alpha = 1.0;
    } else {
        cell.imageView.alpha = 0.0;
    }
    if (name == nil) {
        name = [NSString stringWithFormat:@"链接%lu", indexPath.item+1];
    }
    cell.titleLabel.text = name;
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(370, 30);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(370, 100);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"didSelectItemAtIndexPath %lu", indexPath.item);
    currentIndex = indexPath.item;
    [collectionView reloadData];
    clickCB(indexPath.item);
}

- (NSIndexPath *)indexPathForPreferredFocusedViewInCollectionView:(UICollectionView *)collectionView {
    NSIndexPath *path = [NSIndexPath indexPathForItem:currentIndex inSection:0];
    return path;
}
@end
