//
//  LTEdgeDetector.m
//  Mimeograph
//
//  Created by Nick Bolton on 12/23/12.
//  Copyright 2012 Pixelbleed. All rights reserved.
//

#import "LTEdgeDetector.h"
#import "UIImage+Utilities.h"
#import "GPUImage.h"

@interface LTEdgeDetector() {
}

@property (nonatomic, strong) GPUImageSketchFilter *sketchFilter;
@property (nonatomic, strong) GPUImagePrewittEdgeDetectionFilter *edgeFilter;
@property (nonatomic, strong) GPUImageClosingFilter *closingFilter;
@property (nonatomic, strong) GPUImageColorInvertFilter *invertFilter;
@end


@implementation LTEdgeDetector

- (void)applyEdgeDetection:(UIImage *)originalImage
                completion:(void(^)(UIImage *resultingImage))completionBlock {

    if (_sketchFilter == nil) {
        self.sketchFilter = [[GPUImageSketchFilter alloc] init];
        self.edgeFilter = [[GPUImagePrewittEdgeDetectionFilter alloc] init];
        self.invertFilter = [[GPUImageColorInvertFilter alloc] init];

        [_edgeFilter addTarget:_invertFilter];
    }

    [_sketchFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *imageOuput, CMTime time) {
        if (completionBlock != nil) {
            completionBlock([imageOuput imageFromCurrentlyProcessedOutputWithOrientation:originalImage.imageOrientation]);
        }
    }];

    [_invertFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *imageOuput, CMTime time) {
        if (completionBlock != nil) {
            completionBlock([imageOuput imageFromCurrentlyProcessedOutputWithOrientation:originalImage.imageOrientation]);
        }
    }];

    [_sketchFilter imageByFilteringImage:originalImage];
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
