//
//  LTEdgeDetector.m
//  LightTable
//
//  Created by Nick Bolton on 12/23/12.
//  Copyright 2012 Pixelbleed. All rights reserved.
//

#import "LTEdgeDetector.h"
#import <opencv2/opencv.hpp>
#import "UIImage+Utilities.h"

using namespace cv;

@implementation LTEdgeDetector

- (UIImage *)applyEdgeDetection:(UIImage *)originalImage
                   lowThreshold:(CGFloat)lowThreshold
                       inverted:(BOOL)inverted {

    Mat src = [originalImage cvMat];
    Mat src_gray;
    Mat dst, detected_edges;

    /// Create a matrix of the same type and size as src (for dst)
    dst.create( src.size(), src.type() );

    /// Convert the image to grayscale
    cvtColor( src, src_gray, CV_BGR2GRAY );

    /// Reduce noise with a kernel 3x3
    blur( src_gray, detected_edges, Size2i(5,5) );

    /// Canny detector
    Canny( detected_edges, detected_edges, lowThreshold, lowThreshold*3, 3 );

    /// Using Canny's output as a mask, we display our result
    dst = Scalar::all(0);

    src.copyTo( dst, detected_edges);

    UIImage *result;

    if (inverted == NO) {

        Mat dst_inverted;

        threshold(dst, dst_inverted, 0, 255, THRESH_BINARY_INV);

        result = [UIImage imageWithCVMat:dst_inverted];
    } else {

        Mat bw;
        
        threshold(dst, bw, 0, 255, THRESH_BINARY);

        result = [UIImage imageWithCVMat:bw];
    }

    return result;
}

- (UIImage *)blah:(UIImage *)originalImage
     lowThreshold:(CGFloat)lowThreshold
         inverted:(BOOL)inverted {

    Mat src = [originalImage cvMat];
    Mat dst, detected_edges, blured;

    /// Create a matrix of the same type and size as src (for dst)
    dst.create( src.size(), src.type() );

    /// Reduce noise with a kernel 3x3
    blur( src, blured, Size2i(3,3) );

    /// Canny detector
    Canny( blured, detected_edges, lowThreshold, lowThreshold*3);

    /// Convert the image to grayscale
    cvtColor( detected_edges, detected_edges, CV_BGR2GRAY );

    //    Mat bw = gray > 128;

    /// Using Canny's output as a mask, we display our result
    dst = Scalar::all(0);

    src.copyTo( dst, detected_edges);

    UIImage *result;

    if (inverted == NO) {

        Mat dst_inverted;

        threshold(dst, dst_inverted, 0, 255, THRESH_BINARY_INV);

        result = [UIImage imageWithCVMat:dst_inverted];
    } else {

        result = [UIImage imageWithCVMat:dst];
    }
    
    return result;
}

#pragma mark - Singleton Methods

static dispatch_once_t predicate_;
static LTEdgeDetector *sharedInstance_ = nil;

+ (id)sharedInstance {
    
    dispatch_once(&predicate_, ^{
        sharedInstance_ = [LTEdgeDetector alloc];
        sharedInstance_ = [sharedInstance_ init];
    });
    
    return sharedInstance_;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
