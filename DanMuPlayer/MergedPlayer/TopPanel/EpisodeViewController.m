//
//  EpisodeViewController.m
//  DanMuPlayer
//
//  Created by zfu on 2019/3/17.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "EpisodeViewController.h"
#import "LockupCollectionViewCell.h"

@interface EpisodeViewController () {
    DMPlaylist *playlist;
    clickCallBack buttonCallback;
    NSInteger focusIndex;
    BOOL initScrolled;
}
@end

@implementation EpisodeViewController
@synthesize visiableView;
@synthesize contentHeightConstraint;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.fuzhuo.DanMuPlayer"];
    UINib *selectionNib = [UINib nibWithNibName:@"LockupCollectionViewCell" bundle:bundle];
    [self.collectionView registerNib:selectionNib forCellWithReuseIdentifier:@"LockupCollectionViewCell"];
    self.collectionView.remembersLastFocusedIndexPath = YES;
    
    UICollectionViewFlowLayout *layout = UICollectionViewFlowLayout.new;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(220, 190);
    layout.minimumInteritemSpacing = 10;
    self.collectionView.collectionViewLayout = layout;
    visiableView = _bgVisualEffectView;
    contentHeightConstraint = _heightConstraint;
    initScrolled = NO;
}

- (void)viewDidLayoutSubviews {
    if (initScrolled) return;
    initScrolled = YES;
    if (playlist && playlist.items.count > 0 && focusIndex >= 0 && focusIndex<playlist.items.count) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:focusIndex inSection:0];
        [_collectionView scrollToItemAtIndexPath:indexPath
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                        animated:NO];
    }
}

- (void)setupPlayList:(DMPlaylist*)playlist_ clickCallBack:(clickCallBack)callback_ focusIndex:(NSInteger)focusIndex_ {
    playlist = playlist_;
    buttonCallback = callback_;
    focusIndex = focusIndex_;
}

- (BOOL)_tvTabBarShouldAutohide {
    return NO;
}

- (BOOL)_tvTabBarShouldOverlap {
    return YES;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (playlist) return playlist.items.count;
    else return 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LockupCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LockupCollectionViewCell"
                                                                            forIndexPath:indexPath];
    cell.titleLabel.text = [NSString stringWithFormat:@"标题%lu", indexPath.item];
    //check
    DMMediaItem *item = [playlist.items objectAtIndex:indexPath.item];
    cell.titleLabel.text = item.title;
    if (item.size.width > 0 && item.size.height > 0) {
        CGFloat width = item.size.width * 120.0 / item.size.height;
        cell.widthConstraint.constant = width;
        [cell setNeedsUpdateConstraints];
    }
    if (item.resumeTime > 0 && item.duration > 0) {
        [cell updateProgress:item.resumeTime/item.duration];
    }
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    DMMediaItem *item = [playlist.items objectAtIndex:indexPath.item];
    if (item.size.width > 0 && item.size.height > 0) {
        CGFloat width = item.size.width * 120.0 / item.size.height;
        return CGSizeMake(width+20, 190);
    }
    return CGSizeMake(220, 190);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"select item %lu %lu", indexPath.section, indexPath.item);
    if (focusIndex != indexPath.item) {
        focusIndex = indexPath.item;
        buttonCallback(indexPath.item);
    }
}

- (NSIndexPath *)indexPathForPreferredFocusedViewInCollectionView:(UICollectionView *)collectionView {
    NSIndexPath *path = [NSIndexPath indexPathForItem:focusIndex inSection:0];
    return path;
}
@end
