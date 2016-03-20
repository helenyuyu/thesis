//
//  ChooseScanViewController.h
//  thesis
//
//  Created by Helen Yu on 3/15/16.
//  Copyright © 2016 Helen Yu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ArrangementViewController.h"

@interface ChooseScanViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate>
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) ArrangementViewController *presenter;
-(IBAction) cancelButtonPressed: (id) sender;

@end
