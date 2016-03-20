//
//  AddFloorplanViewController.h
//  thesis
//
//  Created by Helen Yu on 11/10/15.
//  Copyright © 2015 Helen Yu. All rights reserved.
//

#import "FloorplanManager.h"

@interface FloorplanViewController : UIViewController
@property(strong, nonatomic) IBOutlet UIImageView *imageView;
@property(strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property(strong, nonatomic) IBOutlet UIButton *titleButton;
@property(strong, nonatomic) IBOutlet UIBarButtonItem *dimensionButton;
@property(strong, nonatomic) UIImage *rawImage;
@property(strong, nonatomic) IBOutlet UILabel *helpLabel;
@property (nonatomic, strong) Floorplan *floorplan;
@end
