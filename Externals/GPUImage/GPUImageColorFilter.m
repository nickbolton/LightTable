//
//  GPUImageColorFilter.m
//

#import "GPUImageColorFilter.h"

NSString *const kGPUImageColorFilterFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;

 uniform highp float rMax;
 uniform highp float rMin;
 uniform highp float gMax;
 uniform highp float gMin;
 uniform highp float bMax;
 uniform highp float bMin;

 void main()
 {

     highp vec2 sampleDivisor = vec2(1.0 / 200.0, 1.0 / 320.0);
     highp vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor);
     highp vec4 color = texture2D(inputImageTexture, samplePos );
     mediump vec4 finalColor;

     highp float r = color[0];
     highp float g = color[1];
     highp float b = color[2];
     highp float a = color[3];

     if (r < rMin || r > rMax) {
         r = 0.0;
     }

     if (g < gMin || g > gMax) {
         g = 0.0;
     }

     if (b < bMin || b > bMax) {
         b = 0.0;
     }

     gl_FragColor = vec4(r, g, b, a);
 }
 );

@interface GPUImageColorFilter() {

    GLint _rMinUniform;
    GLint _rMaxUniform;
    GLint _gMinUniform;
    GLint _gMaxUniform;
    GLint _bMinUniform;
    GLint _bMaxUniform;
}

@end

@implementation GPUImageColorFilter

- (id)init; {
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageColorFilterFragmentShaderString])) {
		return nil;
    }

    _rMinUniform = [filterProgram uniformIndex:@"rMin"];
    _rMaxUniform = [filterProgram uniformIndex:@"rMax"];
    _gMinUniform = [filterProgram uniformIndex:@"gMin"];
    _gMaxUniform = [filterProgram uniformIndex:@"gMax"];
    _bMinUniform = [filterProgram uniformIndex:@"bMin"];
    _bMaxUniform = [filterProgram uniformIndex:@"bMax"];

    self.rMin = 0.0f;
    self.rMax = 1.0f;
    self.gMin = 0.0f;
    self.gMax = 1.0f;
    self.bMin = 0.0f;
    self.bMax = 1.0f;

    return self;
}

- (void)setRMin:(CGFloat)rMin {
    _rMin = rMin;
    [self setFloat:_rMin forUniform:_rMinUniform program:filterProgram];
}

- (void)setRMax:(CGFloat)rMax {
    _rMax = rMax;
    [self setFloat:_rMax forUniform:_rMaxUniform program:filterProgram];
}

- (void)setGMin:(CGFloat)gMin {
    _gMin = gMin;
    [self setFloat:_gMin forUniform:_gMinUniform program:filterProgram];
}

- (void)setGMax:(CGFloat)gMax {
    _gMax = gMax;
    [self setFloat:_gMax forUniform:_gMaxUniform program:filterProgram];
}

- (void)setBMin:(CGFloat)bMin {
    _bMin = bMin;
    [self setFloat:_bMin forUniform:_bMinUniform program:filterProgram];
}

- (void)setBMax:(CGFloat)bMax {
    _bMax = bMax;
    [self setFloat:_bMax forUniform:_bMaxUniform program:filterProgram];
}

@end
