//
//  UIImage+Utilities.m
//  Mimeograph
//
//  Created by Nick Bolton on 12/23/12.
//  Copyright (c) 2012 Pixelbleed. All rights reserved.
//

#import "UIImage+Utilities.h"

@implementation UIImage (Utilities)

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
