#import "GPUImageFilter.h"

@interface GPUImageColorDistanceMask : GPUImageFilter

@property (strong, nonatomic) UIColor *referenceColor;
@property (nonatomic) CGFloat threshold;
@property (nonatomic) BOOL useBinaryColors;


@end
