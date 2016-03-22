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
//@property(nonatomic, strong) UIActivityIndicatorView *spinner;
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
    
    [self showButtonsInSelectMode:NO];
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
    
    SCNCamera *camera = [SCNCamera new];
    SCNNode *cameraNode = [SCNNode new];
    cameraNode.camera = camera;
    cameraNode.position = SCNVector3Make(0, MAX(width, height)*2, 0);
    cameraNode.name = cameraIdentifier;
    
    SCNLookAtConstraint* constraint = [SCNLookAtConstraint lookAtConstraintWithTarget:planeNode];
    constraint.gimbalLockEnabled = YES;
    cameraNode.constraints = @[constraint];
    [scene.rootNode addChildNode:cameraNode];
}

-(void) loadScans {
    _scans = [NSMutableArray new];
    // read in saved scans
    if (_fp.scans) {
        for (SCNNode *origNode in _fp.scans) {
            SCNNode *node = [origNode clone];
            NSURL *textureURL = [ScanManager getTextureURLFromFilename:node.name];
            if (textureURL) {
                node.geometry.firstMaterial.diffuse.contents = textureURL;
            }
            [_sceneView.scene.rootNode addChildNode:node];
            [_scans addObject: node];
        }
    }
}

-(void) createGestures {
    _defaultGestureRecognizers = [NSMutableArray new];
    UITapGestureRecognizer *tapRecognizer = [UITapGestureRecognizer new];
    [tapRecognizer addTarget: self action: @selector(tapGesture:)];
    [_defaultGestureRecognizers addObject: tapRecognizer];
    [_defaultGestureRecognizers addObjectsFromArray:_sceneView.gestureRecognizers];
    _sceneView.gestureRecognizers = _defaultGestureRecognizers;
    
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
    [_sceneView.scene.rootNode addChildNode:childNode];
    SCNVector3 min = SCNVector3Zero;
    SCNVector3 max = SCNVector3Zero;
    [childNode getBoundingBoxMin:&min max:&max];
    childNode.pivot = SCNMatrix4MakeTranslation((max.x - min.x)/2, 0, (max.z - min.z)/2);
    childNode.rotation = SCNVector4Make(1, 0, 0, M_PI);
    childNode.position = SCNVector3Make(0, (max.y), 0);
    childNode.name = scan.meshFilename;
    [_scans addObject: childNode];
}


-(void) saveScans {
    _fp.scans = _scans;
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
    [_scans removeObject: _targetNode];
    [_targetNode removeFromParentNode];
    _targetNode = nil;
    [self showButtonsInSelectMode:NO];
    _sceneView.gestureRecognizers = _defaultGestureRecognizers;
}

-(void) deselect {
    _targetNode.opacity = 1;
    _targetNode = nil;
    _sceneView.gestureRecognizers = _defaultGestureRecognizers;
    [self showButtonsInSelectMode:NO];
}

-(void) showButtonsInSelectMode: (BOOL) selectMode {
    if (!selectMode) {
        self.navigationItem.rightBarButtonItems = @[_saveButton, _addButton];
    }
    else {
        self.navigationItem.rightBarButtonItems = @[_deselectButton, _deleteButton];
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
            _sceneView.gestureRecognizers = _selectModeGestureRecognizers;
            node.opacity = .5;
            [self showButtonsInSelectMode:YES];
            break;
        }
    }
}

// allow deselect as well, probably won't use
//-(void) selectModeTapGesture: (UITapGestureRecognizer*) recognizer {
//    CGPoint location = [recognizer locationInView:_sceneView];
//    
//    NSArray<SCNHitTestResult *> * hitResults = [_sceneView hitTest: location options: nil];
//    SCNVector3 planeCoords;
//    BOOL hitPlane = NO;
//    for (SCNHitTestResult * result in hitResults) {
//        SCNNode* node = result.node;
//        // deselect
//        if (_targetNode == node) {
//            _targetNode = nil;
//            _sceneView.gestureRecognizers = _defaultGestureRecognizers;
//            node.opacity = 1;
//            [self showButtonsInSelectMode:NO];
//            return;
//        }
//        else if ([node.name isEqualToString:planeIdentifier]) { // trying to translate
//            planeCoords = result.localCoordinates;
//            hitPlane = YES;
//        }
//    }
//    // just do plain translation
//    if (hitPlane) {
//        // restrict the translation to the bounds of the plane
//        float xcoord = planeCoords.x;
//        float zcoord = -planeCoords.y;
//        _targetNode.position = SCNVector3Make(xcoord, _targetNode.position.y, zcoord);
//    }
//}

// only translation
-(void) translateGesture: (UITapGestureRecognizer*) recognizer {
    CGPoint location = [recognizer locationInView:_sceneView];
    
    NSArray<SCNHitTestResult *> * hitResults = [_sceneView hitTest: location options: nil];
    for (SCNHitTestResult * result in hitResults) {
        SCNNode* node = result.node;
        if ([node.name isEqualToString:planeIdentifier]) {
            float xcoord = result.localCoordinates.x;
            float zcoord = -result.localCoordinates.y;
            _targetNode.position = SCNVector3Make(xcoord, _targetNode.position.y, zcoord);
        }
    }
}


// rotate gesture
-(void) rotateGesture1: (UIPanGestureRecognizer*) sender {
    CGPoint translation = [sender translationInView:sender.view];
    float newAngle = (float)(translation.x)*(float)(M_PI)/180.0/100;
    _targetNode.eulerAngles = SCNVector3Make(_targetNode.eulerAngles.x, _targetNode.eulerAngles.y + newAngle, _targetNode.eulerAngles.z);
}



// rotate gestures
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
