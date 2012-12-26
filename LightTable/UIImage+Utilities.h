//
//  UIImage+Utilities.h
//  LightTable
//
//  Created by Nick Bolton on 12/23/12.
//  Copyright (c) 2012 Pixelbleed. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>

using namespace cv;

@interface UIImage (Utilities)

- (Mat)cvMat;

+ (UIImage *)imageWithCVMat:(const Mat&)cvMat
                orientation:(UIImageOrientation)orientation;

@end
