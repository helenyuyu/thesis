//
//  ScanCollectionViewController.m
//  thesis
//
//  Created by Helen Yu on 1/26/16.
//  Copyright © 2016 Helen Yu. All rights reserved.
//

#import "ScanCollectionViewController.h"
#import "ScanManager.h"
#import "MeshViewCell.h"
#import "AppDelegate.h"
#import "EasyMeshViewController.h"


@interface ScanCollectionViewController ()
@property (strong, nonatomic) ScanManager *scanManager;
@end

@implementation ScanCollectionViewController


- (void)viewDidLoad {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    _scanManager = appDelegate.scanManager;
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
}

- (void) viewDidAppear:(BOOL)animated {
    [_collectionView reloadData];
}


#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return _scanManager.scans.count;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MeshViewCell *cell = (MeshViewCell*)[cv dequeueReusableCellWithReuseIdentifier:@"MeshViewCell" forIndexPath:indexPath];
    Scan *scan = _scanManager.scans[indexPath.row];
    cell.imageView.image = [UIImage imageWithData:scan.screenshot];

    return cell;
}

#pragma mark - UICollectionView Delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Scan *scan = _scanManager.scans[indexPath.row];
    [self performSegueWithIdentifier:@"showModelSegue" sender:scan];
}


-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString: @"showModelSegue"]) {
        EasyMeshViewController *meshViewController = (EasyMeshViewController *) segue.destinationViewController;
        meshViewController.scan = (Scan *) sender;
    }
}


- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    float width = collectionView.frame.size.width/3 - 2;
    return CGSizeMake(width, width);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.collectionView performBatchUpdates:nil completion:nil];
}



@end
