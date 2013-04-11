//
//  GPUImageColorDistanceMask.m
//

#import "GPUImageColorDistanceMask.h"

NSString *const kGPUImageColorDistanceMaskFragmentShaderString = SHADER_STRING
(
 varying mediump vec2 textureCoordinate;
 precision mediump float;
 uniform sampler2D inputImageTexture;

 uniform vec4 inputColor;
 uniform vec4 onColor;
 uniform vec4 offColor;
 uniform float threshold;
 uniform int useBinaryColors;

 vec3 normalizeColor(vec3 color)
{
    return color / max(dot(color, vec3(1.0/3.0)), 0.3);
}

 vec4 maskPixel(vec4 pixelColor, vec4 maskColor)
{
    float  d;
    vec4   calculatedColor;

    // Compute distance between current pixel color and reference color
    d = distance(normalizeColor(pixelColor.rgb), normalizeColor(maskColor.rgb));

    // If color difference is larger than threshold, return black.
    calculatedColor =  (d > threshold)  ?  vec4(0.0)  :  vec4(1.0);

	//Multiply color by texture
	return calculatedColor;
}

 void main()
{
	float d;
	vec4 pixelColor;
    vec4 maskedColor;

	pixelColor = texture2D(inputImageTexture, textureCoordinate);
	maskedColor = maskPixel(pixelColor, inputColor);

    if (useBinaryColors > 0) {
        pixelColor[0] = 1.0;
        pixelColor[1] = 1.0;
        pixelColor[2] = 1.0;
        gl_FragColor = (maskedColor.a == 1.0) ? pixelColor : maskedColor;
    } else {
        gl_FragColor = (maskedColor.a == 1.0) ? pixelColor : maskedColor;
    }
}
);

@interface GPUImageColorDistanceMask() {

    GLint _inputColorUniform;
    GLint _thresholdUniform;
    GLint _useBinaryColorsUniform;
    GLint _useOnColorUniform;
}

@end

@implementation GPUImageColorDistanceMask

- (id)init; {
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageColorDistanceMaskFragmentShaderString])) {
		return nil;
    }

    _inputColorUniform = [filterProgram uniformIndex:@"inputColor"];
    _useBinaryColorsUniform = [filterProgram uniformIndex:@"useBinaryColors"];
    _thresholdUniform = [filterProgram uniformIndex:@"threshold"];

    self.referenceColor = [UIColor blackColor];
    self.threshold = 1.0f;

    return self;
}

- (void)setUniform:(GLint)uniform asVectorForColor:(UIColor *)color {

    CGFloat red = 0.0f;
    CGFloat blue = 0.0f;
    CGFloat green = 0.0f;

    [color getRed:&red green:&green blue:&blue alpha:nil];

    GPUVector4 colorVector;
    colorVector.one = red;
    colorVector.two = green;
    colorVector.three = blue;
    colorVector.four = 1.0f;

    [self setVec4:colorVector forUniform:uniform program:filterProgram];
}

- (void)setReferenceColor:(UIColor *)referenceColor {
    _referenceColor = referenceColor;
    [self setUniform:_inputColorUniform asVectorForColor:_referenceColor];
}

- (void)setUseBinaryColors:(BOOL)useBinaryColors {
    _useBinaryColors = useBinaryColors;
    [self setInteger:_useBinaryColors ? 1 : 0 forUniform:_useBinaryColorsUniform program:filterProgram];
}

- (void)setThreshold:(CGFloat)threshold {
    _threshold = threshold;
    [self setFloat:_threshold forUniform:_thresholdUniform program:filterProgram];
}

@end
