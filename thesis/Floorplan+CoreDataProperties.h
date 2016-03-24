//
//  Floorplan+CoreDataProperties.h
//  thesis
//
//  Created by Helen Yu on 3/23/16.
//  Copyright © 2016 Helen Yu. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Floorplan.h"

NS_ASSUME_NONNULL_BEGIN

@interface Floorplan (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *created;
@property (nullable, nonatomic, retain) NSNumber *height;
@property (nullable, nonatomic, retain) NSData *image;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) NSNumber *width;
@property (nullable, nonatomic, retain) NSData *scansData;

@end

NS_ASSUME_NONNULL_END
