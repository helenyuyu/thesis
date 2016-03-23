//
//  EasyMeshViewController.m
//  thesis
//
//  Created by Helen Yu on 2/20/16.
//  Copyright © 2016 Helen Yu. All rights reserved.
//

#import "EasyMeshViewController.h"
#import "ScanManager.h"
#import <ModelIO/ModelIO.h>
#import "AppDelegate.h"

@interface EasyMeshViewController ()
@end

@implementation EasyMeshViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = _scan.title;
    
    NSURL *meshURL = [ScanManager getMeshURL: _scan];
    _sceneView.scene = [SCNScene sceneWithURL: meshURL options: nil error: nil];
    _sceneView.allowsCameraControl = YES;
    _sceneView.backgroundColor = [UIColor lightGrayColor];

    SCNNode *cameraNode = _sceneView.pointOfView;
    SCNVector3 position = cameraNode.position;
    cameraNode.rotation = SCNVector4Make(1, 0, 0, M_PI); //hard coded oops
    cameraNode.position = SCNVector3Make(position.x, position.y, -position.z);
    
    _sceneView.autoenablesDefaultLighting = YES;
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(IBAction) deleteScan:(id) sender {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Delete scan?"
                                              message:nil
                                              preferredStyle:UIAlertControllerStyleAlert];
    
        UIAlertAction *cancelAction = [UIAlertAction
                                       actionWithTitle:@"Cancel"
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction *action)
                                       {
                                       }];
        
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:@"OK"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
                                       ScanManager *scanManager = appDelegate.scanManager;
                                       [scanManager deleteScan: _scan];
                                       // remove view from stack
                                       [self.navigationController popViewControllerAnimated:YES];
                                   }];
        [alertController addAction: okAction];
        [alertController addAction: cancelAction];
        
        [self presentViewController:alertController animated:YES completion:nil];

    
}



@end
