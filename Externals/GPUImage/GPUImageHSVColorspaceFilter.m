//
//  GPUImageHSVColorspaceFilter.m
//

#import "GPUImageHSVColorspaceFilter.h"

NSString *const kGPUImageHSVColorspaceFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;

 uniform highp float hMax;
 uniform highp float hMin;
 uniform highp float sMax;
 uniform highp float sMin;
 uniform highp float vMax;
 uniform highp float vMin;
 uniform int useBinaryColors;

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

     highp float delta;
     highp float min = min(min( r, g), b);
     highp float max = max(max( r, g), b);

     highp float h = -1.0;
     highp float s = 0.0;
     highp float v = max;       // v

     delta = v - min;
     
     if( v != 0.0 ) {

         s = delta / v;		// s

         if( r == v ) {
             h = 60.0 * ( g - b ) / s;
         } else if( g == v ) {
             h = 120.0 + (60.0 * ( b - r ) / s);
         } else {
             h = 240.0 + (60.0 * ( r - g ) / s);
         }

         if( h < 0.0 ) {
             h += 360.0;
         }
     }

     if (h < hMin || h > hMax) {
         h = 0.0;
     }

     if (s < sMin || s > sMax) {
         s = 0.0;
     }

     if (v < vMin || v > vMax) {
         v = 0.0;
     }

     if (useBinaryColors > 0) {
         if (h + s + v > 0.0) {
             gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
         } else {
             gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
         }
     } else {
         gl_FragColor = vec4(h / 360.0, s, v, a);
     }
 }
 );

@interface GPUImageHSVColorspaceFilter() {

    GLint _hMinUniform;
    GLint _hMaxUniform;
    GLint _sMinUniform;
    GLint _sMaxUniform;
    GLint _vMinUniform;
    GLint _vMaxUniform;
    GLint _useBinaryColorsUniform;
}

@end

@implementation GPUImageHSVColorspaceFilter

- (id)init; {
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageHSVColorspaceFragmentShaderString])) {
		return nil;
    }

    _hMinUniform = [filterProgram uniformIndex:@"hMin"];
    _hMaxUniform = [filterProgram uniformIndex:@"hMax"];
    _sMinUniform = [filterProgram uniformIndex:@"sMin"];
    _sMaxUniform = [filterProgram uniformIndex:@"sMax"];
    _vMinUniform = [filterProgram uniformIndex:@"vMin"];
    _vMaxUniform = [filterProgram uniformIndex:@"vMax"];
    _useBinaryColorsUniform = [filterProgram uniformIndex:@"useBinaryColors"];

    self.hMin = 0.0f;
    self.hMax = 360.0f;
    self.sMin = 0.0f;
    self.sMax = 1.0f;
    self.vMin = 0.0f;
    self.vMax = 1.0f;

    return self;
}

- (void)setHMin:(CGFloat)hMin {
    _hMin = hMin;
    [self setFloat:_hMin forUniform:_hMinUniform program:filterProgram];
}

- (void)setHMax:(CGFloat)hMax {
    _hMax = hMax;
    [self setFloat:_hMax forUniform:_hMaxUniform program:filterProgram];
}

- (void)setSMin:(CGFloat)sMin {
    _sMin = sMin;
    [self setFloat:_sMin forUniform:_sMinUniform program:filterProgram];
}

- (void)setSMax:(CGFloat)sMax {
    _sMax = sMax;
    [self setFloat:_sMax forUniform:_sMaxUniform program:filterProgram];
}

- (void)setVMin:(CGFloat)vMin {
    _vMin = vMin;
    [self setFloat:_vMin forUniform:_vMinUniform program:filterProgram];
}

- (void)setVMax:(CGFloat)vMax {
    _vMax = vMax;
    [self setFloat:_vMax forUniform:_vMaxUniform program:filterProgram];
}

- (void)setUseBinaryColors:(BOOL)useBinaryColors {
    _useBinaryColors = useBinaryColors;
    [self setInteger:_useBinaryColors ? 1 : 0 forUniform:_useBinaryColorsUniform program:filterProgram];
}

@end
