#import "GPUImageFilter.h"

@interface GPUImageColorFilter : GPUImageFilter

@property(readwrite, nonatomic) CGFloat rMin;
@property(readwrite, nonatomic) CGFloat rMax;
@property(readwrite, nonatomic) CGFloat gMin;
@property(readwrite, nonatomic) CGFloat gMax;
@property(readwrite, nonatomic) CGFloat bMin;
@property(readwrite, nonatomic) CGFloat bMax;

@end
