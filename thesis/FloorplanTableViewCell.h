//
//  FloorplanTableViewCell.h
//  thesis
//
//  Created by Helen Yu on 2/15/16.
//  Copyright © 2016 Helen Yu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FloorplanTableViewCell : UITableViewCell
@property (nonatomic, strong) IBOutlet UIImageView *thumbnailView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@end
