//
//  FloorplanTableViewController.m
//  thesis
//
//  Created by Helen Yu on 11/8/15.
//  Copyright © 2015 Helen Yu. All rights reserved.
//

#import "FloorplanTableViewController.h"
#import "FloorplanViewController.h"
#import "AppDelegate.h"
#import "FloorplanTableViewCell.h"
#import "ArrangementViewController.h"

@interface FloorplanTableViewController ()
@property(strong, nonatomic) FloorplanManager *manager;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation FloorplanTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    _manager = appDelegate.fpManager;

    _dateFormatter = [NSDateFormatter new];
    [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [_dateFormatter setTimeStyle: NSDateFormatterShortStyle];
}

- (void) viewDidAppear:(BOOL)animated {
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _manager.floorplans.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
        FloorplanTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"floorplanCell" forIndexPath:indexPath];
        Floorplan* fp = _manager.floorplans[indexPath.row];
        cell.titleLabel.text = fp.title;
        cell.dateLabel.text = [NSString stringWithFormat: @"Created: %@", [_dateFormatter stringFromDate: fp.created]];
        cell.thumbnailView.image = [UIImage imageWithData:fp.image];
        return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [_manager deleteFloorplanAtIndex: indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    }
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIAlertController* actionSheet = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    Floorplan *fp = _manager.floorplans[indexPath.row];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Furnish" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self performSegueWithIdentifier:@"viewFloorplan" sender:fp];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Annotate floorplan" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self performSegueWithIdentifier:@"annotateFloorplan" sender:fp];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Duplicate floorplan" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        Floorplan *fp2 = [_manager createFloorplanWithImageData:fp.image];
        fp2.width = fp.width;
        fp2.height = fp.height;
        fp2.title = [NSString stringWithFormat:@"%@_2", fp.title];
        [_manager saveChanges];
        [self.tableView reloadData];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Delete arrangement" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [_manager deleteFloorplanAtIndex: indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        // do nothing.
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}


- (IBAction)takePhoto:(UIButton *)sender {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Scan your floorplan"
                                          message:@"Make sure your paper is against a contrasting background, and all four corners are visible. "
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action){
                               
                                   if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                                       UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                                       picker.delegate = self;
                                       picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                                       
                                       [self presentViewController:picker animated:YES completion:NULL];
                                       
                                   }
                                   else {
                                       UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                                       picker.delegate = self;
                                       picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                                       [self presentViewController:picker animated:YES completion:NULL];
                                   }
                               
                               
                               }];
    [alertController addAction: okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];


    
}
#pragma mark - image picker

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    // lead to new view controller
    [self performSegueWithIdentifier:@"addFloorplan" sender:chosenImage];

    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"addFloorplan"]) {
        FloorplanViewController *destViewController = (FloorplanViewController *)[segue destinationViewController];
        destViewController.rawImage = (UIImage *) sender;
    }
    else if ([segue.identifier isEqualToString:@"viewFloorplan"]) {
        ArrangementViewController *destViewController = (ArrangementViewController *) [segue destinationViewController];
        destViewController.fp = (Floorplan*) sender;
    }
    else if ([segue.identifier isEqualToString:@"annotateFloorplan"]) {
        FloorplanViewController *destViewController = (FloorplanViewController *)[segue destinationViewController];
        destViewController.floorplan = (Floorplan*) sender;
    }
}


@end
