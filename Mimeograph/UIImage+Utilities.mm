//
//  UIImage+Utilities.m
//  Mimeograph
//
//  Created by Nick Bolton on 12/23/12.
//  Copyright (c) 2012 Pixelbleed. All rights reserved.
//

#import "UIImage+Utilities.h"

@implementation UIImage (Utilities)

- (Mat)cvMat {

    CGColorSpaceRef colorSpace = CGImageGetColorSpace(self.CGImage);
    CGFloat cols = self.size.width;
    CGFloat rows = self.size.height;

    if (self.imageOrientation == UIImageOrientationLeft ||
        self.imageOrientation == UIImageOrientationRight) {
        cols = self.size.height;
        rows = self.size.width;
    }

    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels

    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags

    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), self.CGImage);
    CGContextRelease(contextRef);

    return cvMat;
}

+ (UIImage *)imageWithCVMat:(const Mat&)cvMat
                orientation:(UIImageOrientation)orientation {

    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];

    CGColorSpaceRef colorSpace;

    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }

    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                     // Width
                                        cvMat.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * cvMat.elemSize(),                           // Bits per pixel
                                        cvMat.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent

    UIImage *image =
    [[UIImage alloc]
     initWithCGImage:imageRef
     scale:1.0f
     orientation:orientation];

    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

- (UIImage *)resizeImageToSize:(CGSize)size {
    float width = size.width;
    float height = size.height;

    UIGraphicsBeginImageContext(size);
    CGRect rect = CGRectMake(0, 0, width, height);

    float widthRatio = self.size.width / width;
    float heightRatio = self.size.height / height;
    float divisor = widthRatio > heightRatio ? widthRatio : heightRatio;

    width = self.size.width / divisor;
    height = self.size.height / divisor;

    rect.size.width  = width;
    rect.size.height = height;

    if(height < width)
        rect.origin.y = height / 3;

    [self drawInRect: rect];

    UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
    
    return smallImage;
}

@end
