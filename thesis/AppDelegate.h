//
//  AppDelegate.h
//  thesis
//
//  Created by Helen Yu on 11/8/15.
//  Copyright © 2015 Helen Yu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FloorplanManager.h"
#import "ScanManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (readonly, strong, nonatomic) FloorplanManager *fpManager;
@property (readonly, strong, nonatomic) ScanManager *scanManager;

- (NSURL *)applicationDocumentsDirectory;

@end

