//
//  LTEdgeDetector.h
//  Mimeograph
//
//  Created by Nick Bolton on 12/23/12.
//  Copyright 2012 Pixelbleed. All rights reserved.
//

@interface LTEdgeDetector : NSObject

+ (LTEdgeDetector *)sharedInstance;

- (void)applyEdgeDetection:(UIImage *)originalImage
                completion:(void(^)(UIImage *resultingImage))completionBlock;

@end
