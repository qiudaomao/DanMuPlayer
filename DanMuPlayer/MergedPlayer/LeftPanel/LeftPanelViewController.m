//
//  LeftPanelViewController.m
//  DanMuPlayer
//
//  Created by zfu on 2019/4/5.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "LeftPanelViewController.h"
#import "QuickSelectCollectionViewCell.h"
#import "QuickSelectHeaderViewCollectionReusableView.h"

@interface LeftPanelViewController () {
    UITapGestureRecognizer *tapGestureRecognizer;
    UISwipeGestureRecognizer *swipeGestureRecognizer;
    BOOL dismissed;
}
@end

@implementation LeftPanelViewController
@synthesize title = _title;

- (void)viewDidLoad {
    [super viewDidLoad];
    dismissed = NO;
    // Do any additional setup after loading the view.
    self.preferredContentSize = CGSizeMake(400, self.view.frame.size.height);
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.fuzhuo.DanMuPlayer"];
    UINib *selectionNib = [UINib nibWithNibName:@"QuickSelectCollectionViewCell" bundle:bundle];
    [self.collectionView registerNib:selectionNib forCellWithReuseIdentifier:@"QuickSelectCollectionViewCell"];
    UINib *headerNib = [UINib nibWithNibName:@"QuickSelectHeaderViewCollectionReusableView" bundle:bundle];
    [self.collectionView registerNib:headerNib
          forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                 withReuseIdentifier:@"QuickSelectHeaderViewCollectionReusableView"];
    self.titleLabel.text = self.title;
}

- (void)viewWillAppear:(BOOL)animated {
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapKey:)];
    tapGestureRecognizer.allowedPressTypes = @[
                                               @(UIPressTypeRightArrow),
                                               @(UIPressTypeLeftArrow),
                                               ];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipRight:)];
    [swipeGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.view addGestureRecognizer:swipeGestureRecognizer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.view removeGestureRecognizer:tapGestureRecognizer];
    [self.view removeGestureRecognizer:swipeGestureRecognizer];
}

- (void)swipRight:(UISwipeGestureRecognizer*)sender {
    NSLog(@"swipUp");
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
    return 20;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    QuickSelectCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"QuickSelectCollectionViewCell"
                                                                                    forIndexPath:indexPath];
//    cell.layer.borderWidth = 1.0f;
//    cell.layer.borderColor = UIColor.blackColor.CGColor;
    cell.titleLabel.textColor = UIColor.grayColor;
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

/*
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        QuickSelectHeaderViewCollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"QuickSelectHeaderViewCollectionReusableView" forIndexPath:indexPath];
        view.titleLabel.text = @"选择一个";
        return view;
    }
    return nil;
}
 */

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
}
@end
