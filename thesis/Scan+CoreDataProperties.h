//
//  Scan+CoreDataProperties.h
//  thesis
//
//  Created by Helen Yu on 2/8/16.
//  Copyright © 2016 Helen Yu. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Scan.h"

NS_ASSUME_NONNULL_BEGIN

@interface Scan (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *category;
@property (nullable, nonatomic, retain) NSDate *created;
@property (nullable, nonatomic, retain) NSString *meshFilename;
@property (nullable, nonatomic, retain) NSString *screenshotFilename;
@property (nullable, nonatomic, retain) NSString *title;

@end

NS_ASSUME_NONNULL_END
