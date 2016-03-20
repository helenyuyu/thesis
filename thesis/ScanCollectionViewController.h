//
//  ScanCollectionViewController.h
//  thesis
//
//  Created by Helen Yu on 1/26/16.
//  Copyright © 2016 Helen Yu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScanCollectionViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate>
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@end
