//
//  ScanManager.m
//  thesis
//
//  Created by Helen Yu on 2/3/16.
//  Copyright © 2016 Helen Yu. All rights reserved.
//

#import "ScanManager.h"

@implementation ScanManager
@synthesize managedObjectContext = _managedObjectContext;
static NSString *bucketName = @"hom3design";

-(id) initWithContext: (NSManagedObjectContext*) managedObjectContext {
    self = [super init];
    // populate from context
    
    _managedObjectContext = managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Scan" inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    NSError *error;
    _session = [self backgroundSession];
    _transferManager = [AWSS3TransferManager defaultS3TransferManager];
    
    _scans = [[NSMutableArray alloc] initWithArray:[_managedObjectContext executeFetchRequest:fetchRequest error:nil]];

    for (Scan *scan in _scans) {
        
        scan.screenshot = [NSData dataWithContentsOfFile:[ScanManager getScreenshotPath: scan] options: 0 error: &error];
        if (error)
        {
            NSLog(@"Failed to read file, error %@", error);
        }
    }

    return self;
}


- (NSURLSession *)backgroundSession
{
    /*
     Using dispatch_once here ensures that multiple background sessions with the same identifier are not created in this instance of the application. If you want to support multiple background sessions within a single process, you should create each session with its own identifier.
     */
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"uploadMeshes"];
        configuration.discretionary = YES;
        session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    });
    return session;
}



-(Scan*) createScanWithMeshFilename: (NSString *) meshFilename andScreenshotFilename: (NSString *) screenshotFilename
                       andTitle: (NSString *) title andCategory: (NSString *) category;
{
    Scan *scan = [NSEntityDescription
                            insertNewObjectForEntityForName:@"Scan"
                            inManagedObjectContext:_managedObjectContext];
    scan.title = title;
    scan.created = [NSDate date];
    scan.screenshotFilename = screenshotFilename;
    scan.meshFilename = meshFilename;
    scan.screenshot = [NSData dataWithContentsOfFile:[ScanManager getScreenshotPath: scan]];
    
    [_scans addObject: scan];
    [self saveChanges];
    [self uploadMesh: meshFilename];
    return scan;
}

+ (NSString *) getScreenshotPath: (Scan *) scan {
    NSString* dir = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES ) objectAtIndex:0];
    return [dir stringByAppendingPathComponent:scan.screenshotFilename];
}

+ (NSString *) getMeshPath: (Scan *) scan {
    NSString* dir = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES ) objectAtIndex:0];
    return [dir stringByAppendingPathComponent:scan.meshFilename];
}

+ (NSURL *) getMeshURL: (Scan *) scan {
    return [NSURL fileURLWithPath:[ScanManager getMeshPath: scan]];
}

+ (NSURL *) getMeshURLFromFilename: (NSString *) meshFilename {
    NSString* dir = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES ) objectAtIndex:0];
    NSString* fullPath = [dir stringByAppendingPathComponent:meshFilename];
    return [NSURL fileURLWithPath:fullPath];
}

+ (NSURL *) getTextureURLFromFilename: (NSString *) meshFilename{
    NSString* dir = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES ) objectAtIndex:0];
    NSString *textureFilename = [[meshFilename stringByDeletingPathExtension] stringByAppendingPathExtension:@"jpg"];
    NSString *texturePath =[dir stringByAppendingPathComponent:textureFilename];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:texturePath])
        return [NSURL fileURLWithPath:texturePath];
    else return nil;
}

-(void) deleteScanAtIndex: (NSInteger) index {
    Scan *scan = [_scans objectAtIndex: index];
    [_scans removeObjectAtIndex:index];

    NSString *screenshotPath = [ScanManager getScreenshotPath: scan];
    NSString *meshPath = [ScanManager getMeshPath: scan];
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:screenshotPath error:&error];
    if (error) {
        NSLog(@"Could not delete screenshot at path %@", screenshotPath);
    }
    [[NSFileManager defaultManager] removeItemAtPath:meshPath error:&error];
    if (error) {
        NSLog(@"Could not delete mesh file at path %@", meshPath);
    }
    
    [_managedObjectContext deleteObject: scan];
    
    [self saveChanges];
    
}

-(void) deleteScan: (Scan*) scan{
    [_scans removeObject: scan];
    
    // don't delete in case some of the floorplans have it.......
    
    NSString *screenshotPath = [ScanManager getScreenshotPath: scan];
    NSString *meshPath = [ScanManager getMeshPath: scan];
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:screenshotPath error:&error];
    if (error) {
        NSLog(@"Could not delete screenshot at path %@", screenshotPath);
    }
    [[NSFileManager defaultManager] removeItemAtPath:meshPath error:&error];
    if (error) {
        NSLog(@"Could not delete mesh file at path %@", meshPath);
    }
    
    [_managedObjectContext deleteObject: scan];
    
    [self saveChanges];
    
}


-(void) saveChanges {
    NSError *error = nil;
    if (_managedObjectContext != nil) {
        if ([_managedObjectContext hasChanges] && ![_managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


-(void) uploadMesh: (NSString *) meshFilename {
    NSURL *meshUrl = [ScanManager getMeshURLFromFilename: meshFilename];
    NSURL *textureUrl = [ScanManager getTextureURLFromFilename: meshFilename];
    [self uploadFromFileUrl:meshUrl withContentType:@"text/plain"];
    [self uploadFromFileUrl:textureUrl withContentType:@"image"];
}


-(void) uploadFromFileUrl: (NSURL *) url withContentType: (NSString *) contentType{
    if (url) {
        AWSS3GetPreSignedURLRequest *getPreSignedURLRequest = [AWSS3GetPreSignedURLRequest new];
        getPreSignedURLRequest.bucket = bucketName;
        getPreSignedURLRequest.key = [[url absoluteString] lastPathComponent];
        getPreSignedURLRequest.HTTPMethod = AWSHTTPMethodPUT;
        getPreSignedURLRequest.expires = [NSDate dateWithTimeIntervalSinceNow:3600];
        
        getPreSignedURLRequest.contentType = contentType;
        
        [[[AWSS3PreSignedURLBuilder defaultS3PreSignedURLBuilder] getPreSignedURL:getPreSignedURLRequest]
         continueWithBlock:^id(AWSTask *task) {
             
             if (task.error) {
                 NSLog(@"Error: %@",task.error);
             } else {
                 
                 NSURL *presignedURL = task.result;
                 
                 NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:presignedURL];
                 request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
                 [request setHTTPMethod:@"PUT"];
                 [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
                 
                 NSURLSessionUploadTask *uploadTask = [_session uploadTaskWithRequest:request fromFile:url];
                 [uploadTask resume];
                 
             }
             return nil;
         }];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        NSLog(@"background upload task failed with error %@", error);
    }
    else {
        NSLog(@"background upload task completed");
    }
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    NSLog(@"session did receive challenge");
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

@end
