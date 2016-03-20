//
//  FloorplanManager.m
//  thesis
//
//  Created by Helen Yu on 1/5/16.
//  Copyright © 2016 Helen Yu. All rights reserved.
//

#import "FloorplanManager.h"

@implementation FloorplanManager
@synthesize managedObjectContext = _managedObjectContext;


-(id) initWithContext: (NSManagedObjectContext*) managedObjectContext {
    self = [super init];
    // populate from context

    _managedObjectContext = managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Floorplan" inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    NSError *error;
    _floorplans = [[NSMutableArray alloc] initWithArray:[_managedObjectContext executeFetchRequest:fetchRequest error:&error]];
    
    return self;
    
}

-(Floorplan*) createFloorplanWithImage: (UIImage *) image {
    return [self createFloorplanWithImageData: UIImageJPEGRepresentation(image, 1)];
}

-(Floorplan*) createFloorplanWithImageData: (NSData *) imageData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger count = [defaults integerForKey:@"floorplanCount"];
    NSString *title = [NSString stringWithFormat:@"floorplan%ld", (long)count++];
    [defaults setInteger:count forKey:@"floorplanCount"];
    
    Floorplan *floorplan = [NSEntityDescription
                            insertNewObjectForEntityForName:@"Floorplan"
                            inManagedObjectContext:_managedObjectContext];
    floorplan.title = title;
    floorplan.created = [NSDate date];
    floorplan.image = imageData;
    
    [_floorplans addObject: floorplan];
    [self saveChanges];
    return floorplan;
}


-(void) deleteFloorplanAtIndex: (NSInteger) index {
    Floorplan *floorplan = [_floorplans objectAtIndex: index];
    [_floorplans removeObjectAtIndex:index];
    
    [_managedObjectContext deleteObject: floorplan];
    
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

@end
