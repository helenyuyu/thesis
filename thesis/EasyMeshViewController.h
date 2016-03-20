//
//  EasyMeshViewController.h
//  thesis
//
//  Created by Helen Yu on 2/20/16.
//  Copyright © 2016 Helen Yu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Scan.h"
#import <SceneKit/SceneKit.h>


@interface EasyMeshViewController : UIViewController
@property (nonatomic, strong) Scan *scan;
@property (nonatomic, strong) IBOutlet SCNView *sceneView;
-(IBAction) deleteScan:(id) sender;
@end
