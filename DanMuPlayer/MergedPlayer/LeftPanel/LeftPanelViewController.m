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
    DMPlaylist *playlist;
    NSInteger currentIndex;
    BOOL initScrolled;
    clickCallBack clickCB;
}
@end

@implementation LeftPanelViewController
@synthesize title = _title;

- (void)viewDidLoad {
    [super viewDidLoad];
    dismissed = NO;
    initScrolled = NO;
    // Do any additional setup after loading the view.
    self.preferredContentSize = CGSizeMake(400, self.view.frame.size.height);
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.fuzhuo.DanMuPlayer"];
    UINib *selectionNib = [UINib nibWithNibName:@"QuickSelectCollectionViewCell" bundle:bundle];
    [self.collectionView registerNib:selectionNib forCellWithReuseIdentifier:@"QuickSelectCollectionViewCell"];
    UINib *headerNib = [UINib nibWithNibName:@"QuickSelectHeaderViewCollectionReusableView" bundle:bundle];
    [self.collectionView registerNib:headerNib
          forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                 withReuseIdentifier:@"QuickSelectHeaderViewCollectionReusableView"];
    self.collectionView.remembersLastFocusedIndexPath = YES;
    self.titleLabel.text = self.title;
}

- (void)setupPlayList:(DMPlaylist*)playlist_
        clickCallBack:(clickCallBack)clickCallBack_
         currentIndex:(NSInteger)currentIndex_ {
    playlist = playlist_;
    currentIndex = currentIndex_;
    clickCB = clickCallBack_;
}

- (void)viewWillAppear:(BOOL)animated {
    dismissed = NO;
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

- (void)viewDidLayoutSubviews {
    if (initScrolled) return;
    initScrolled = YES;
    if (playlist && playlist.items.count > 0 && currentIndex >= 0 && currentIndex < playlist.items.count) {
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
    return playlist.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    QuickSelectCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"QuickSelectCollectionViewCell"
                                                                                    forIndexPath:indexPath];
    cell.titleLabel.textColor = UIColor.grayColor;
    DMMediaItem *item = [playlist.items objectAtIndex:indexPath.item];
    cell.titleLabel.text = item.title;
    if (item.artworkImageURL && [item.artworkImageURL hasPrefix:@"http"] && !item.downloadImageFailed) {
        //setup image and donwload
        if (item.image) {
            cell.imageView.image = item.image;
        } else {
            //start download
            NSURL *url = [NSURL URLWithString:item.artworkImageURL];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            [request setValue:@"" forHTTPHeaderField:@"User-Agent"];
            if (item.imageHeaders) {
                for (NSString *key in item.imageHeaders.allKeys) {
                    NSString *value = [item.imageHeaders objectForKey:key];
                    [request setValue:value forHTTPHeaderField:key];
                }
            }
            NSURLSession *session = NSURLSession.sharedSession;
            NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (!error && data) {
                    item.image = [UIImage imageWithData:data];
                } else {
                    NSLog(@"Error download artwork from URL %@", item.artworkImageURL);
                    item.downloadImageFailed = YES;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->_collectionView reloadItemsAtIndexPaths:@[indexPath]];
                });
            }];
            [task resume];
        }
    } else {
        NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.fuzhuo.DanMuPlayer"];
        if (item.size.width > item.size.height || item.size.width==0 || item.size.height==0) {
            cell.imageView.image = [UIImage imageNamed:@"lazycat"
                                              inBundle:bundle
                         compatibleWithTraitCollection:nil];
        } else {
            cell.imageView.image = [UIImage imageNamed:@"lazycat_v"
                                              inBundle:bundle
                         compatibleWithTraitCollection:nil];
        }
    }
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
    clickCB(indexPath.item);
}

- (NSIndexPath *)indexPathForPreferredFocusedViewInCollectionView:(UICollectionView *)collectionView {
    NSIndexPath *path = [NSIndexPath indexPathForItem:currentIndex inSection:0];
    return path;
}
@end
