//
//  OpenCVHelper.h
//  thesis
//
//  Created by Helen Yu on 11/16/15.
//  Copyright © 2015 Helen Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVHelper : NSObject
+ (cv::Mat)cvMatFromUIImage:(UIImage *)image;
+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;
+ (cv::Mat) scanImage: (cv::Mat) orig;
@end
