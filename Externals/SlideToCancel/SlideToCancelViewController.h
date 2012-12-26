//
//  SlideToCancelViewController.h
//  SlideToCancel
//

#import <UIKit/UIKit.h>

@protocol SlideToCancelDelegate;

@interface SlideToCancelViewController : UIViewController {
	UIImageView *sliderBackground;
	UISlider *slider;
	UILabel *label;
	NSTimer *animationTimer;
	id <SlideToCancelDelegate> delegate;
	BOOL touchIsDown;
	CGFloat gradientLocations[3];
	int animationTimerCount;
}

@property (nonatomic, assign) id <SlideToCancelDelegate> delegate;

// This property is set to NO (disabled) on creation.
// The caller must set it to YES to animate the slider.
// It should be set to NO (disabled) when the view is not visible, in order
// to turn off the timer and conserve CPU resources.
@property (nonatomic) BOOL enabled;

// Access the UILabel, e.g. to change text or color
@property (nonatomic, readonly) UILabel *label;

@property (nonatomic, retain) NSString *forwardText;
@property (nonatomic, retain) NSString *reverseText;
@property (nonatomic, retain) UIImage *forwardImage;
@property (nonatomic, retain) UIImage *reverseImage;
@property (nonatomic, assign, getter = isReversed) BOOL reversed;

@end

@protocol SlideToCancelDelegate

@required
- (void)sliderReachedForwardPosition;
- (void)sliderReachedReversePosition;
- (void)startedSliding;
- (void)stoppedSliding;

@end
