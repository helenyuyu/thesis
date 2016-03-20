//
//  AddFloorplanViewController.mm
//  thesis
//
//  Created by Helen Yu on 11/10/15.
//  Copyright © 2015 Helen Yu. All rights reserved.
//

#import "FloorplanViewController.h"
#import "OpenCVHelper.h"
#import "Floorplan.h"
#import "BJImageCropper.h"
#import "AppDelegate.h"


@interface FloorplanViewController ()
@property(strong, nonatomic) FloorplanManager *manager;
@property (nonatomic, strong) BJImageCropper *imageCropper;
@property (nonatomic) BOOL isAnnotating;

@end

@implementation FloorplanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    _manager = appDelegate.fpManager;
    
    _helpLabel.text = @"Resize and move the square to align with a room whose dimensions you know. When done, press Set to enter the dimensions.";
    _helpLabel.hidden = YES;
    
    if (_rawImage) {
        _imageView.image = _rawImage;
        [self.dimensionButton setEnabled:NO];
        [self.dimensionButton setTintColor: [UIColor clearColor]];
        [_spinner startAnimating];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            cv::Mat outmat = [OpenCVHelper scanImage: [OpenCVHelper cvMatFromUIImage: _rawImage] ];
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImage *image = [OpenCVHelper UIImageFromCVMat: outmat];
                _imageView.image = image;
                [_spinner stopAnimating];
                _floorplan = [_manager createFloorplanWithImage:image];
                [_titleButton setTitle:_floorplan.title forState:UIControlStateNormal];
                [self.dimensionButton setEnabled:YES];
                [self.dimensionButton setTintColor:nil];
            });
        });
    }
    else {
        _imageView.image = [UIImage imageWithData:_floorplan.image];
        [_titleButton setTitle:_floorplan.title forState:UIControlStateNormal];
    }
}


-(IBAction) nameFloorplan: (id) sender {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Rename"
                                              message:nil
                                              preferredStyle:UIAlertControllerStyleAlert];
    
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
         {
             textField.clearButtonMode = UITextFieldViewModeWhileEditing;
             textField.text = _floorplan.title;
         }];
    
        UIAlertAction *cancelAction = [UIAlertAction
                                       actionWithTitle:@"Cancel"
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction *action)
                                       {
                                           NSLog(@"Cancel change floorplan title");
                                       }];
    
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:@"OK"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       UITextField *titleField = alertController.textFields.firstObject;
                                       _floorplan.title = titleField.text;
                                       [_manager saveChanges];
                                       [(UIButton *)sender setTitle:titleField.text forState:UIControlStateNormal];
                                   }];
        [alertController addAction: okAction];
        [alertController addAction: cancelAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    
}

-(IBAction) annotateButtonPressed: (id)sender {
    if (_isAnnotating) {
        [(UIBarButtonItem *)sender setTitle: @"Dimension"];
        _helpLabel.hidden = YES;
        [self finishedAddingDimension];
    }
    else {
        [(UIBarButtonItem *)sender setTitle: @"Set"];
        _helpLabel.hidden = NO;
        [self addDimension];
    }
    _isAnnotating = !_isAnnotating;
    
}


-(void) addDimension {
    _imageCropper = [[BJImageCropper alloc] initWithImage:_imageView.image andMaxSize:_imageView.frame.size];
    [self.view addSubview:_imageCropper];
    _imageCropper.center = _imageView.center;
}

-(void) finishedAddingDimension {
    [_imageCropper removeFromSuperview];
    CGSize rect = _imageCropper.crop.size; // selected rectangle size
    CGSize frame = _imageView.image.size; // image frame size
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Set dimension"
                                          message:@"Add width and height (in feet)"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.keyboardType = UIKeyboardTypeDecimalPad;
         textField.placeholder = @"Width";
     }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.keyboardType = UIKeyboardTypeDecimalPad;
         textField.placeholder = @"Height";
     }];
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"Cancel add dimension");
                                   }];
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   UITextField *widthField = alertController.textFields[0];
                                   UITextField *heightField = alertController.textFields[1];
                                   [self setWidth: widthField.text andHeight: heightField.text fromRect: rect withFrame: frame];
                                   
                               }];
    [alertController addAction: okAction];
    [alertController addAction: cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

-(void) setWidth: (NSString*) widthText andHeight: (NSString *) heightText fromRect: (CGSize) rect withFrame: (CGSize) picture {

    double width = [widthText doubleValue];
    double height = [heightText doubleValue];

    double scaledWidth = width*picture.width/rect.width;
    double scaledHeight = height*picture.height/rect.height;
    
    double feetToMeters = 0.3048;
    _floorplan.width = @(scaledWidth*feetToMeters);
    _floorplan.height = @(scaledHeight*feetToMeters);
    [_manager saveChanges];
}




@end
