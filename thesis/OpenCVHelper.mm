//
//  OpenCVHelper.mm
//  thesis
//
//  Created by Helen Yu on 11/16/15.
//  Copyright © 2015 Helen Yu. All rights reserved.
//

#import "OpenCVHelper.h"

@implementation OpenCVHelper


+ (UIImage*) rotateImage:(UIImage* )src {
    
    UIImageOrientation orientation = src.imageOrientation;
    
    UIGraphicsBeginImageContext(src.size);
    
    [src drawAtPoint:CGPointMake(0, 0)];
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orientation == UIImageOrientationRight) {
        CGContextRotateCTM (context, M_PI/2);
    } else if (orientation == UIImageOrientationLeft) {
        CGContextRotateCTM (context, -M_PI/2);
    } else if (orientation == UIImageOrientationDown) {
        CGContextRotateCTM (context, M_PI);
    }
    
    return UIGraphicsGetImageFromCurrentImageContext();

}

+ (cv::Mat)cvMatFromUIImage:(UIImage *)inputImage
{
    UIImage *image = [OpenCVHelper rotateImage: inputImage];
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

+(cv::Mat) scanImage: (cv::Mat) orig {
    // compute the ratio of the old height to the new height, and resize it
    double ratio = 500.0/orig.rows;
    cv::Mat image;
    cv::resize(orig, image, cv::Size(), ratio, ratio, cv::INTER_AREA);
    
    std::vector<cv::Point> corners = [OpenCVHelper findCorners:image];
    // do perspective transform
    cv::Mat warped = [OpenCVHelper fourPointTransform: orig withCorners: corners andRatio: 1/ratio];
    
    // convert the warped image to grayscale, then threshold it
    return [OpenCVHelper threshold: warped];
}


+ (std::vector<cv::Point2f>) orderPoints: (std::vector<cv::Point>) inputPoints andScale:(double) ratio {
    int minDif = 0;
    int maxDif = 0;
    int minSum = 0;
    int maxSum = 0;
    for (int i = 0; i < 4; i ++) {
        if (inputPoints[i].x + inputPoints[i].y < inputPoints[minSum].x + inputPoints[minSum].y)
            minSum = i;
        if (inputPoints[i].x + inputPoints[i].y > inputPoints[maxSum].x + inputPoints[maxSum].y)
            maxSum = i;
        if (inputPoints[i].x - inputPoints[i].y < inputPoints[minDif].x - inputPoints[minDif].y)
            minDif = i;
        if (inputPoints[i].x - inputPoints[i].y > inputPoints[maxDif].x - inputPoints[maxDif].y)
            maxDif = i;
    }
    std::vector<cv::Point2f> ordered(4);
    ordered[0] = cv::Point2f(inputPoints[minSum].x*ratio, inputPoints[minSum].y*ratio);
    ordered[1] = cv::Point2f(inputPoints[maxDif].x*ratio, inputPoints[maxDif].y*ratio);
    ordered[2] = cv::Point2f(inputPoints[maxSum].x*ratio, inputPoints[maxSum].y*ratio);
    ordered[3] = cv::Point2f(inputPoints[minDif].x*ratio, inputPoints[minDif].y*ratio);
    return ordered;
}


+ (cv::Mat) fourPointTransform: (cv::Mat) image withCorners: (std::vector<cv::Point>) corners andRatio: (double) ratio {
    // obtain a consistent order of the points and unpack them individually
    std::vector<cv::Point2f> ordered = [OpenCVHelper orderPoints: corners andScale:ratio];
    cv::Point2f tl = ordered[0];
    cv::Point2f tr = ordered[1];
    cv::Point2f br = ordered[2];
    cv::Point2f bl = ordered[3];
    
    // compute the width of the new image
    double widthA = sqrt((br.x - bl.x)*(br.x - bl.x) + (br.y - bl.y)*(br.y - bl.y));
    double widthB = sqrt((tr.x - tl.x)*(tr.x - tl.x) + (tr.y - tl.y)*(tr.y - tl.y));
    double maxWidth = std::max(int(widthA), int(widthB));
    
    // compute the height of the new image
    double heightA = sqrt((tr.x - br.x)*(tr.x - br.x) + (tr.y - br.y)*(tr.y - br.y));
    double heightB = sqrt((tl.x - bl.x)*(tl.x - bl.x) + (tl.y - bl.y)*(tl.y - bl.y));
    double maxHeight = std::max(int(heightA), int(heightB));
    
    std::vector<cv::Point2f> dst (4);
    dst[0] = cv::Point2f(0, 0);
    dst[1] = cv::Point2f(maxWidth - 1, 0);
    dst[2] = cv::Point2f(maxWidth - 1, maxHeight - 1);
    dst[3] = cv::Point2f(0, maxHeight - 1);
    
    
    // compute the perspective transform matrix and then apply it
    cv::Mat M = cv::getPerspectiveTransform(ordered, dst);
    cv::Mat warped;
    cv::warpPerspective(image, warped, M, cv::Size(maxWidth, maxHeight));
    
    return warped;
}

+ (std::vector<cv::Point>) findCorners: (cv::Mat) image {
    
    //convert the image to grayscale, blur it, and find edges in the image
    cv::Mat gray;
    cv::cvtColor(image, gray, cv::COLOR_BGR2GRAY);
    cv::Mat blurred;
    cv::GaussianBlur(gray, blurred, cv::Size(5, 5), 0);
    cv::Mat edged;
    cv::Canny(blurred, edged, 75, 200);
    
    
    // find the contours in the edged image, keeping only the largest ones, and initialize the screen contour
    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(edged, contours, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);
    // TODO: prefilter by finding 5 largest ones by contour area
    
    std::vector<cv::Point> screenCnt;
    double best = -1.0;
    // loop over the contours
    for (int i = 0; i < contours.size(); i++) {
        std::vector<cv::Point> c = contours[i];
        
        // approximate the contour
        double peri = cv::arcLength(c, true);
        std::vector<cv::Point> approx;
        cv::approxPolyDP(c, approx, 0.05 * peri, true);
        
        //if our approximated contour has four points, then we can assume that we have found our screen
        if (approx.size() == 4 && cv::contourArea(c) > best) {
            screenCnt = approx;
            best = cv::contourArea(c);
        }
    }
    // TODO: display contour to user and ask for approval
    //    cv::Scalar color = cv::Scalar(255, 0, 0);
    //    std::vector<std::vector<cv::Point>> approxContours(1);
    //    approxContours[0] = screenCnt;
    //    cv::drawContours(image, approxContours, 0, color);
    return screenCnt;
}


+ (cv::Mat) threshold: (cv::Mat) inputMat {
    cv::Mat greyMat;
    cv::cvtColor(inputMat, greyMat, CV_BGR2GRAY);
    cv::Mat binaryMat;
    cv::adaptiveThreshold(greyMat, binaryMat, 255,cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY,251,10);
    return binaryMat;
}

@end
