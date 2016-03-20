//
//  FloorplanManager.h
//  thesis
//
//  Created by Helen Yu on 1/5/16.
//  Copyright © 2016 Helen Yu. All rights reserved.
//

#import "Floorplan.h"

@interface FloorplanManager : NSObject

@property (nonatomic,strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) NSMutableArray *floorplans; // modifications should only happen in this class
-(id) initWithContext: (NSManagedObjectContext*) managedObjectContext;
-(Floorplan*) createFloorplanWithImage: (UIImage *) image;
-(Floorplan*) createFloorplanWithImageData: (NSData *) image;
-(void) deleteFloorplanAtIndex: (NSInteger) index;
-(void) saveChanges;

@end
