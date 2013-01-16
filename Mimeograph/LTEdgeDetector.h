//
//  LTEdgeDetector.h
//  Mimeograph
//
//  Created by Nick Bolton on 12/23/12.
//  Copyright 2012 Pixelbleed. All rights reserved.
//

@interface LTEdgeDetector : NSObject

+ (LTEdgeDetector *)sharedInstance;

- (UIImage *)applyEdgeDetection:(UIImage *)originalImage
                   lowThreshold:(CGFloat)lowThreshold
                       inverted:(BOOL)inverted;

@end
