//
//  Scan.h
//  thesis
//
//  Created by Helen Yu on 2/3/16.
//  Copyright © 2016 Helen Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface Scan : NSManagedObject

@property (nonatomic, strong) NSData *screenshot;

@end

NS_ASSUME_NONNULL_END

#import "Scan+CoreDataProperties.h"
