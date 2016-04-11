//
//  ScanManager.h
//  thesis
//
//  Created by Helen Yu on 2/3/16.
//  Copyright © 2016 Helen Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Scan.h"
#import <AWSS3/AWSS3.h>
#import <AWSCore/AWSCore.h>

@interface ScanManager : NSObject<NSURLSessionTaskDelegate>

@property (nonatomic,strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic) NSURLSession *session;
@property (nonatomic) AWSS3TransferManager *transferManager;
@property (nonatomic, strong) NSMutableArray *scans; // modifications should only happen in this class
-(id) initWithContext: (NSManagedObjectContext*) managedObjectContext;
-(Scan*) createScanWithMeshFilename: (NSString *) meshFilename
              andScreenshotFilename: (NSString *) screenshotFilename
                           andTitle: (NSString *) title andCategory: (NSString *) category;
//-(void) deleteScanAtIndex: (NSInteger) index;
-(void) deleteScan: (Scan*) scan;
-(void) saveChanges;
//+ (NSString *) getScreenshotPath: (Scan *) scan;
+ (NSURL *) getMeshURL: (Scan *) scan;
+ (NSURL *) getMeshURLFromFilename: (NSString *) meshFilename;
+ (NSURL *) getTextureURLFromFilename: (NSString *) meshFilename;

@end
