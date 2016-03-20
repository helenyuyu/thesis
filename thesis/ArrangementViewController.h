//
//  ArrangementViewController.h
//  thesis
//
//  Created by Helen Yu on 3/15/16.
//  Copyright © 2016 Helen Yu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Floorplan.h"
#import "SceneKit/SceneKit.h"
#import "Scan.h"

@interface ArrangementViewController : UIViewController
@property(nonatomic, strong) Floorplan* fp;
@property (nonatomic, strong) IBOutlet SCNView *sceneView;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *addButton;
-(void) addScanToFloorplan: (Scan *) scan;
@end
