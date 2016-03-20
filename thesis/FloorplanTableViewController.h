//
//  FloorplanTableViewController.h
//  thesis
//
//  Created by Helen Yu on 11/8/15.
//  Copyright © 2015 Helen Yu. All rights reserved.
//

#import "Floorplan.h"
#import "FloorplanManager.h"

@interface FloorplanTableViewController : UITableViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate>

- (IBAction)takePhoto:  (UIButton *)sender;

@end
