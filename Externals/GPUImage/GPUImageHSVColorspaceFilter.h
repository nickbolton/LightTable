#import "GPUImageFilter.h"

@interface GPUImageHSVColorspaceFilter : GPUImageFilter

@property(readwrite, nonatomic) CGFloat hMin;
@property(readwrite, nonatomic) CGFloat hMax;
@property(readwrite, nonatomic) CGFloat sMin;
@property(readwrite, nonatomic) CGFloat sMax;
@property(readwrite, nonatomic) CGFloat vMin;
@property(readwrite, nonatomic) CGFloat vMax;
@property (nonatomic) BOOL useBinaryColors;

@end
