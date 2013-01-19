//
//  SlideToCancelViewController.m
//  SlideToCancel
//
// The slider track and thumb images were made from a screen shot of the iPhone's home
// screen. Apple may object to use of these images in an app. I have not yet had an app 
// approved (or rejected either) using these images. Use at your own risk.
//
// Please note that THIS CODE ONLY DISPLAYS TEXT IN ROMAN ALPHABETS. For use with
// non-Roman (i.e. Asian) alphabets, the code in method
// - (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)theContext
// must be re-written to use glyphs. See Apple's "Quartz 2D Programming Guide" 
// chapter "Drawing Text" for more info.

#import <QuartzCore/QuartzCore.h>
#import "SlideToCancelViewController.h"

@interface SlideToCancelViewController() <UIGestureRecognizerDelegate> {

    CGFloat _touchDownValue;
    BOOL _touchValueChanged;

}

- (void) setGradientLocations:(CGFloat)leftEdge;
- (void) startTimer;
- (void) stopTimer;

@end

static const CGFloat gradientWidth = 0.2;
static const CGFloat gradientDimAlpha = 0.5;
static const int animationFramesPerSec = 8;
static const CGFloat maxValue = 1.0f;

@implementation SlideToCancelViewController

@synthesize delegate;

// Implement the "enabled" property
- (BOOL) enabled {
	return slider.enabled;
}

- (void) setEnabled:(BOOL)enabled{
	slider.enabled = enabled;
	label.enabled = enabled;
	if (enabled) {

        label.center = CGPointMake(CGRectGetMidX(label.superview.bounds), CGRectGetMidY(label.superview.bounds));

		slider.value = 0.0;
		label.alpha = 1.0;
		touchIsDown = NO;
		[self startTimer];
	} else {
		[self stopTimer];
	}
}

- (void)setReversed:(BOOL)reversed {

    if (_reversed == reversed) return;

    _reversed = reversed;

    UIImage *thumbImage;

    if (_reversed) {

        slider.transform = CGAffineTransformMakeRotation(M_PI);

        label.text = self.reverseText;

        slider.value = 0.0f;

        thumbImage = _reverseImage;
        
    } else {

        slider.transform = CGAffineTransformIdentity;

        label.text = self.forwardText;

        slider.value = 0.0f;

        thumbImage = _forwardImage;

    }

//    [UIView
//     animateWithDuration:.15f
//     animations:^{
//
//         slider.alpha = 0.0f;
//         
//     } completion:^(BOOL finished) {

         [slider setThumbImage:thumbImage forState:UIControlStateNormal];

         [UIView
          animateWithDuration:.15f
          animations:^{
              label.alpha = 1.0f;
              slider.alpha = 1.0f;
          } completion:^(BOOL finished) {
              [self startTimer];
          }];
//     }];
}

- (void)handleTap {

    if (_tapToSlide) {
//        [slider setValue:slider.maximumValue animated:YES];

        [UIView
         animateWithDuration:.25f
         animations:^{
             slider.value = slider.maximumValue;
         } completion:^(BOOL finished) {
             //tell the delagate we are slid all the way to the right

             if (_reversed) {
                 [delegate sliderReachedReversePosition];

             } else {
                 [delegate sliderReachedForwardPosition];

             }
         }];

    } else if (_tapToBounce) {

        [UIView
         animateWithDuration:.15f
         animations:^{

             slider.value = slider.maximumValue * .1f;
         } completion:^(BOOL finished) {


             [UIView
              animateWithDuration:.15f
              animations:^{

                  slider.value = 0.0f;
              } completion:^(BOOL finished) {

                  [UIView
                   animateWithDuration:.1f
                   animations:^{

                       slider.value = slider.maximumValue * .03f;
                   } completion:^(BOOL finished) {

                       [UIView
                        animateWithDuration:.15f
                        animations:^{
                            slider.value = 0.0f;
                        }];
                   }];
              }];
         }];
    }
}

- (UILabel *)label {
	// Access the view, which will force loadView to be called
	// if it hasn't already been, which will create the label
	(void)[self view];
	
	return label;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	// Load the track background    

	UIImage *trackImage = nil;
    [UIImage imageNamed:@"sliderTrack.png"];

    CGFloat midPoint = trackImage.size.width/2.0f;

    UIImage *stretchableImage =
    [trackImage
     resizableImageWithCapInsets:
     UIEdgeInsetsMake(0.0f, midPoint, 0.0f, midPoint+1.0f)];

	sliderBackground = [[UIImageView alloc] initWithImage:stretchableImage];
    sliderBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    CGRect frame = sliderBackground.frame;
    frame.size.height = _forwardImage.size.height;
	
	// Create the superview same size as track backround, and add the background image to it
	UIView *view = [[UIView alloc] initWithFrame:frame];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//	[view addSubview:sliderBackground];

	// Add the slider with correct geometry centered over the track
	slider = [[UISlider alloc] initWithFrame:frame];
    slider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	CGRect sliderFrame = slider.frame;
	sliderFrame.size.width -= 0; //each "edge" of the track is 23 pixels wide
	slider.frame = sliderFrame;
	slider.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
	slider.backgroundColor = [UIColor clearColor];
	[slider setMinimumTrackImage:[UIImage imageNamed:@"sliderMaxMin-02.png"] forState:UIControlStateNormal];
	[slider setMaximumTrackImage:[UIImage imageNamed:@"sliderMaxMin-02.png"] forState:UIControlStateNormal];
	slider.minimumValue = 0.0;
	slider.maximumValue = maxValue;
	slider.continuous = YES;
	slider.value = 0.0;
	
	// Set the slider action methods
	[slider addTarget:self
			   action:@selector(sliderUp:)
	 forControlEvents:UIControlEventTouchUpInside];
	[slider addTarget:self
			   action:@selector(sliderUp:)
	 forControlEvents:UIControlEventTouchUpOutside];
	[slider addTarget:self
			   action:@selector(sliderDown:) 
	 forControlEvents:UIControlEventTouchDown];
	[slider addTarget:self 
			   action:@selector(sliderChanged:) 
	 forControlEvents:UIControlEventValueChanged];

	// Create the label with the actual size required by the text
	// If you change the text, font, or font size by using the "label" property,
	// you may need to recalculate the label's frame.

    UIFont *labelFont = [UIFont systemFontOfSize:24];

    CGSize reverseTextSize = [self.reverseText sizeWithFont:labelFont];
	NSString *labelText = self.forwardText;

	CGSize labelSize = [labelText sizeWithFont:labelFont];
    labelSize.width = MAX(labelSize.width, reverseTextSize.width);

	label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, labelSize.width, labelSize.height)];
	
	// Center the label over the slidable portion of the track
	CGFloat labelHorizontalCenter = slider.center.x + (_forwardImage.size.width / 2);
	label.center = CGPointMake(labelHorizontalCenter, slider.center.y);
    label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	
	// Set other label attributes and add it to the view
	label.textColor = [UIColor whiteColor];
	label.textAlignment = UITextAlignmentCenter;
	label.backgroundColor = [UIColor clearColor];
	label.font = labelFont;
	label.text = labelText;
	[view addSubview:label];
	
	[view addSubview:slider];

	// This property is set to NO (disabled) on creation.
	// The caller must set it to YES to animate the slider.
	// It should be set to NO (disabled) when the view is not visible, in order
	// to turn off the timer and conserve CPU resources.
	self.enabled = NO;
	
	// Render the label text animation using our custom drawing code in
	// the label's layer.
	label.layer.delegate = self;
	
	// Set the view controller's view property to all of the above
	self.view = view;
	
	// The view is retained by the superclass, so release our copy
	[view release];

    self.reversed = YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	[self stopTimer];
	[sliderBackground release], sliderBackground = nil;
	[slider release], slider = nil;
	[label release], label = nil;
}

// UISlider actions
- (void)sliderUp:(UISlider *)sender {
	//filter out duplicate sliderUp events
	if (touchIsDown) {
		touchIsDown = NO;

        if (_touchValueChanged == NO) {
            // tap event
            [self handleTap];
        } else {

            [delegate stoppedSliding];

            if (slider.value != maxValue)  //if the value is not the max, slide this bad boy back to zero
            {
                [slider setValue: 0 animated: YES];
                label.alpha = 1.0;
                [self startTimer];
            }
            else {
                //tell the delagate we are slid all the way to the right

                if (_reversed) {
                    [delegate sliderReachedReversePosition];
                    
                } else {
                    [delegate sliderReachedForwardPosition];
                    
                }
                
            }
        }
	}
}

- (void)sliderDown:(UISlider *)sender {
	touchIsDown = YES;
    _touchDownValue = slider.value;
    _touchValueChanged = NO;
    [delegate startedSliding];
}

- (void)sliderChanged:(UISlider *)sender {
	// Fade the text as the slider moves to the right. This code makes the
	// text totally dissapear when the slider is 35% of the way to the right.
	label.alpha = MAX(0.0, maxValue - (slider.value * 3.5));
	
	// Stop the animation if the slider moved off the zero point
	if (slider.value != 0) {
		[self stopTimer];
		[label.layer setNeedsDisplay];
	}

    if (_touchDownValue != slider.value) {
        _touchValueChanged = YES;
    }
}

// animationTimer methods
- (void)animationTimerFired:(NSTimer*)theTimer {
	// Let the timer run for 2 * FPS rate before resetting.
	// This gives one second of sliding the highlight off to the right, plus one
	// additional second of uniform dimness
	if (++animationTimerCount == (2 * animationFramesPerSec)) {
		animationTimerCount = 0;
	}
	
	// Update the gradient for the next frame
	[self setGradientLocations:((CGFloat)animationTimerCount/(CGFloat)animationFramesPerSec)];
}

- (void) startTimer {
//	if (!animationTimer) {
//		animationTimerCount = 0;
//		[self setGradientLocations:0];
//		animationTimer = [[NSTimer 
//						   scheduledTimerWithTimeInterval:1.0/animationFramesPerSec 
//						   target:self 
//						   selector:@selector(animationTimerFired:) 
//						   userInfo:nil 
//						   repeats:YES] retain];
//	}
}

- (void) stopTimer {
//	if (animationTimer) {
//		[animationTimer invalidate];
//		[animationTimer release], animationTimer = nil;
//	}
}

// label's layer delegate method
- (void)drawLayer:(CALayer *)theLayer
        inContext:(CGContextRef)theContext
{
	// Set the font
	const char *labelFontName = [label.font.fontName UTF8String];
	
	// Note: due to use of kCGEncodingMacRoman, this code only works with Roman alphabets! 
	// In order to support non-Roman alphabets, you need to add code generate glyphs,
	// and use CGContextShowGlyphsAtPoint
	CGContextSelectFont(theContext, labelFontName, label.font.pointSize, kCGEncodingMacRoman);

	// Set Text Matrix
	CGAffineTransform xform = CGAffineTransformMake(1.0,  0.0,
													0.0, -1.0,
													0.0,  0.0);
	CGContextSetTextMatrix(theContext, xform);
	
	// Set Drawing Mode to clipping path, to clip the gradient created below
	CGContextSetTextDrawingMode (theContext, kCGTextClip);
	
	// Draw the label's text
	const char *text = [label.text cStringUsingEncoding:NSMacOSRomanStringEncoding];
	CGContextShowTextAtPoint(
		theContext, 
		0, 
		(size_t)label.font.ascender,
		text, 
		strlen(text));

	// Calculate text width
	CGPoint textEnd = CGContextGetTextPosition(theContext);
	
	// Get the foreground text color from the UILabel.
	// Note: UIColor color space may be either monochrome or RGB.
	// If monochrome, there are 2 components, including alpha.
	// If RGB, there are 4 components, including alpha.
	CGColorRef textColor = label.textColor.CGColor;
	const CGFloat *components = CGColorGetComponents(textColor);
	size_t numberOfComponents = CGColorGetNumberOfComponents(textColor);
	BOOL isRGB = (numberOfComponents == 4);
	CGFloat red = components[0];
	CGFloat green = isRGB ? components[1] : components[0];
	CGFloat blue = isRGB ? components[2] : components[0];
	CGFloat alpha = isRGB ? components[3] : components[1];

	// The gradient has 4 sections, whose relative positions are defined by
	// the "gradientLocations" array:
	// 1) from 0.0 to gradientLocations[0] (dim)
	// 2) from gradientLocations[0] to gradientLocations[1] (increasing brightness)
	// 3) from gradientLocations[1] to gradientLocations[2] (decreasing brightness)
	// 4) from gradientLocations[3] to 1.0 (dim)
	size_t num_locations = 3;
	
	// The gradientComponents array is a 4 x 3 matrix. Each row of the matrix
	// defines the R, G, B, and alpha values to be used by the corresponding
	// element of the gradientLocations array
	CGFloat gradientComponents[12];
	for (int row = 0; row < num_locations; row++) {
		int index = 4 * row;
		gradientComponents[index++] = red;
		gradientComponents[index++] = green;
		gradientComponents[index++] = blue;
		gradientComponents[index] = alpha * gradientDimAlpha;
	}

	// If animating, set the center of the gradient to be bright (maximum alpha)
	// Otherwise it stays dim (as set above) leaving the text at uniform
	// dim brightness
	if (animationTimer) {
		gradientComponents[7] = alpha;
	}

	// Load RGB Colorspace
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	
	// Create Gradient
	CGGradientRef gradient = CGGradientCreateWithColorComponents (colorspace, gradientComponents,
																  gradientLocations, num_locations);
	// Draw the gradient (using label text as the clipping path)
	CGContextDrawLinearGradient (theContext, gradient, label.bounds.origin, textEnd, 0);
	
	// Cleanup
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorspace);
}

- (void) setGradientLocations:(CGFloat) leftEdge {
	// Subtract the gradient width to start the animation with the brightest 
	// part (center) of the gradient at left edge of the label text
	leftEdge -= gradientWidth;
	
	//position the bright segment of the gradient, keeping all segments within the range 0..1
	gradientLocations[0] = leftEdge < 0.0 ? 0.0 : (leftEdge > 1.0 ? 1.0 : leftEdge);
	gradientLocations[1] = MIN(leftEdge + gradientWidth, 1.0);
	gradientLocations[2] = MIN(gradientLocations[1] + gradientWidth, 1.0);
	
	// Re-render the label text
	[label.layer setNeedsDisplay];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)dealloc {
	[self stopTimer];
	[self viewDidUnload];

    [_forwardText release], _forwardText = nil;
    [_reverseText release], _reverseText = nil;
    [_forwardImage release], _forwardImage = nil;
    [_reverseImage release], _reverseImage = nil;
    
    [super dealloc];
}

@end
