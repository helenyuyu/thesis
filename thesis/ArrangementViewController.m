//
//  ArrangementViewController.m
//  thesis
//
//  Created by Helen Yu on 3/15/16.
//  Copyright © 2016 Helen Yu. All rights reserved.
//

#import "ArrangementViewController.h"
#import <ModelIO/ModelIO.h>
#import "ChooseScanViewController.h"
#import "ScanManager.h"
#import "FloorplanManager.h"
#import "AppDelegate.h"

@interface ArrangementViewController ()
@property(nonatomic, strong) SCNNode *targetNode;
@property(nonatomic, strong) NSMutableArray *defaultGestureRecognizers;
@property(nonatomic, strong) NSMutableArray *selectModeGestureRecognizers;
@property(nonatomic, strong) FloorplanManager *floorplanManager;
@property(nonatomic, strong) UIBarButtonItem *deleteButton;
@property(nonatomic, strong) UIBarButtonItem *saveButton;
@property(nonatomic, strong) UIBarButtonItem *deselectButton;
@property(nonatomic, strong) NSMutableArray *scans;
@end

@implementation ArrangementViewController
float DEFAULT_WIDTH = 20;
float DEFAULT_HEIGHT = 20;
NSString *planeIdentifier = @"plane";
NSString *cameraIdentifier = @"camera";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createScene];
    [self loadScans];
    [self createGestures];
    
    self.navigationItem.title = _fp.title;
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    _floorplanManager = appDelegate.fpManager;
    
    _saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveScans)];
    
    _deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemTrash target: self action:@selector(deleteSelected)];
    
    _deselectButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone target: self action:@selector(deselect)];
    
    [self switchToSelectMode:NO];
}

#pragma mark - set up

-(void) createScene {
    SCNScene *scene = [SCNScene new];
    _sceneView.scene = scene;
    _sceneView.backgroundColor = [UIColor lightGrayColor];
    _sceneView.autoenablesDefaultLighting = YES;
    _sceneView.allowsCameraControl = YES;
    
    // plane view stuff
    float width = _fp.width.floatValue == 0.0? DEFAULT_WIDTH: [_fp.width floatValue];
    float height = _fp.height.floatValue == 0.0? DEFAULT_HEIGHT: [_fp.height floatValue];
    SCNPlane *planeGeometry = [SCNPlane planeWithWidth:width height:height];
    SCNNode *planeNode = [SCNNode nodeWithGeometry:planeGeometry];
    planeNode.eulerAngles = SCNVector3Make(-M_PI_2, 0, 0);
    planeNode.position = SCNVector3Make(0, 0, 0);
    [scene.rootNode addChildNode:planeNode];
    planeNode.name = planeIdentifier;
    
    SCNMaterial *fpMaterial = [SCNMaterial new];
    fpMaterial.diffuse.contents = [UIImage imageWithData:_fp.image];
    planeGeometry.firstMaterial = fpMaterial;
    
    SCNNode *dummyNode = [SCNNode new];
    dummyNode.position = SCNVector3Make(0, -100, 0);
    
    SCNCamera *camera = [SCNCamera new];
    SCNNode *cameraNode = [SCNNode new];
    cameraNode.camera = camera;
    cameraNode.position = SCNVector3Make(0, MAX(width, height), 0);
    
    cameraNode.eulerAngles = SCNVector3Make(-M_PI_2, 0, 0);
    cameraNode.name = cameraIdentifier;
    
    [_sceneView.scene.rootNode addChildNode:cameraNode];

}

-(void) loadScans {
    _scans = [NSMutableArray new];
    // read in saved scans
    if (_fp.scansData) {
        NSArray *scansFromJson = [NSJSONSerialization JSONObjectWithData:_fp.scansData options:0 error:nil];
        for (NSDictionary *nodeDict in scansFromJson) {
            [self addNodeDictToFloorplan:nodeDict];
        }
    }
}

-(void) createGestures {
    _defaultGestureRecognizers = [NSMutableArray new];
    UITapGestureRecognizer *tapRecognizer = [UITapGestureRecognizer new];
    [tapRecognizer addTarget: self action: @selector(tapGesture:)];
    [_defaultGestureRecognizers addObject: tapRecognizer];
    [_defaultGestureRecognizers addObjectsFromArray:_sceneView.gestureRecognizers];
    
    
    _selectModeGestureRecognizers = [NSMutableArray new];
    UITapGestureRecognizer *translateRecognizer = [UITapGestureRecognizer new];
    [translateRecognizer addTarget: self action: @selector(translateGesture:)];
    [_selectModeGestureRecognizers addObject:translateRecognizer];
    UIPanGestureRecognizer *rotateRecognizer1 = [UIPanGestureRecognizer new];
    [rotateRecognizer1 addTarget: self action:@selector(rotateGesture1:)];
    [_selectModeGestureRecognizers addObject: rotateRecognizer1];
    rotateRecognizer1.maximumNumberOfTouches = 1;
    UIRotationGestureRecognizer *rotateRecognizer2 = [UIRotationGestureRecognizer new];
    [rotateRecognizer2 addTarget: self action:@selector(rotateGesture2:)];
    [_selectModeGestureRecognizers addObject: rotateRecognizer2];
}

-(BOOL) isScan: (SCNNode *) node {
    return [node.name containsString:@".obj"];
}

#pragma mark - button methods

-(void) addScanToFloorplan: (Scan *) scan {
    NSURL *meshURL = [ScanManager getMeshURL: scan];
    SCNScene *scene = [SCNScene sceneWithURL: meshURL options: nil error: nil];
    SCNNode *childNode = scene.rootNode.childNodes[0];
    SCNVector3 min = SCNVector3Zero;
    SCNVector3 max = SCNVector3Zero;
    [childNode getBoundingBoxMin:&min max:&max];
    childNode.pivot = SCNMatrix4MakeTranslation((max.x - min.x)/2, 0, (max.z - min.z)/2);
    childNode.rotation = SCNVector4Make(1, 0, 0, M_PI);
    childNode.position = SCNVector3Make(0, (max.y), 0);
    childNode.name = scan.meshFilename;
    [_scans addObject: childNode];
    [_sceneView.scene.rootNode addChildNode:childNode];
}


-(void) addNodeDictToFloorplan: (NSDictionary *) nodeDict {
    NSString *filename = nodeDict[@"filename"];
    NSURL *meshURL = [ScanManager getMeshURLFromFilename:filename];
    SCNScene *scene = [SCNScene sceneWithURL: meshURL options: nil error: nil];
    SCNNode *childNode = scene.rootNode.childNodes[0];
    childNode.position = SCNVector3Make([nodeDict[@"px"] floatValue], [nodeDict[@"py"] floatValue], [nodeDict[@"pz"] floatValue]);
    childNode.eulerAngles = SCNVector3Make([nodeDict[@"ex"] floatValue], [nodeDict[@"ey"] floatValue], [nodeDict[@"ez"] floatValue]);
    SCNVector3 min = SCNVector3Zero;
    SCNVector3 max = SCNVector3Zero;
    [childNode getBoundingBoxMin:&min max:&max];
    childNode.pivot = SCNMatrix4MakeTranslation((max.x - min.x)/2, 0, (max.z - min.z)/2);
    childNode.name = filename;
    [_scans addObject: childNode];
    [_sceneView.scene.rootNode addChildNode:childNode];
}


-(void) saveScans {
    NSMutableArray *nodeDicts = [NSMutableArray new];
    for (SCNNode *node in _scans) {
        NSDictionary *dict = @{@"filename": node.name,
                               @"px":@(node.position.x), @"py":@(node.position.y), @"pz":@(node.position.z),
                               @"ex":@(node.eulerAngles.x), @"ey":@(node.eulerAngles.y), @"ez":@(node.eulerAngles.z)};
        [nodeDicts addObject: dict];
    }

    _fp.scansData = [NSJSONSerialization dataWithJSONObject:nodeDicts options:NSJSONWritingPrettyPrinted error:nil];
    [_floorplanManager saveChanges];
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Arrangement saved"
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                               style:UIAlertActionStyleDefault
                               handler:nil];
    [alertController addAction: okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void) deleteSelected {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Remove from arrangement?"
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
                                   [_scans removeObject: _targetNode];
                                   [_targetNode removeFromParentNode];
                                   [self switchToSelectMode:NO];
                               }];
    [alertController addAction: okAction];
    [alertController addAction: cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

-(void) deselect {
    [self switchToSelectMode:NO];
}

-(void) switchToSelectMode: (BOOL) selectMode {
    if (selectMode) {
        self.navigationItem.rightBarButtonItems = @[_deselectButton, _deleteButton];
        _sceneView.gestureRecognizers = _selectModeGestureRecognizers;
        _targetNode.opacity = .5;
    }
    else {
        self.navigationItem.rightBarButtonItems = @[_saveButton, _addButton];
        _sceneView.gestureRecognizers = _defaultGestureRecognizers;
        if (_targetNode) {
            _targetNode.opacity = 1;
            _targetNode = nil;
        }
    }
}


#pragma mark - gestures

-(void) tapGesture: (UITapGestureRecognizer*) recognizer {
    CGPoint location = [recognizer locationInView:_sceneView];
    
    NSArray<SCNHitTestResult *> * hitResults = [_sceneView hitTest: location options: nil];
    for (SCNHitTestResult * result in hitResults) {
        SCNNode* node = result.node;
        // found first best match
        if ([self isScan: node]) {
            _targetNode = node;
            [self switchToSelectMode:YES];
            break;
        }
    }
}


-(void) translateGesture: (UITapGestureRecognizer*) recognizer {
    CGPoint location = [recognizer locationInView:_sceneView];
    
    NSArray<SCNHitTestResult *> * hitResults = [_sceneView hitTest: location options: nil];
    for (SCNHitTestResult * result in hitResults) {
        SCNNode* node = result.node;
        if ([node.name isEqualToString:planeIdentifier]) {
            float xcoord = result.localCoordinates.x;
            float zcoord = -result.localCoordinates.y;
            _targetNode.position = SCNVector3Make(xcoord, _targetNode.position.y, zcoord);
            return;
        }
    }
}


// rotate gesture
-(void) rotateGesture1: (UIPanGestureRecognizer*) sender {
    CGPoint translation = [sender translationInView:sender.view];
    float newAngle = ((float) translation.x)*(float)(M_PI)/180.0/100;
    _targetNode.eulerAngles = SCNVector3Make(_targetNode.eulerAngles.x, _targetNode.eulerAngles.y + newAngle, _targetNode.eulerAngles.z);
}



// 2nd rotate gesture
-(void) rotateGesture2: (UIRotationGestureRecognizer*) sender {
    float newAngle = -sender.rotation*M_PI/180.0;
    _targetNode.eulerAngles = SCNVector3Make(_targetNode.eulerAngles.x, _targetNode.eulerAngles.y + newAngle, _targetNode.eulerAngles.z);
}


# pragma mark - segue

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"addModelToFloorplan"]) {
        // dumb hack oops
        UINavigationController *nav = (UINavigationController*) segue.destinationViewController;
        ChooseScanViewController *dest = nav.viewControllers.firstObject;
        dest.presenter = self;

    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
