//
//  UIImage+Utilities.h
//  LightTable
//
//  Created by Nick Bolton on 12/23/12.
//  Copyright (c) 2012 Pixelbleed. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>

@interface UIImage (Utilities)

- (cv::Mat)cvMat;

+ (UIImage *)imageWithCVMat:(const cv::Mat&)cvMat;

@end
