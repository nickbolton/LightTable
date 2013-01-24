//
//  LTSliderViewController.h
//  Mimeograph
//
//  Created by Nick Bolton on 1/23/13.
//  Copyright (c) 2013 Pixelbleed. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LTSliderDelegate <NSObject>

@required
- (void)sliderReachedForwardPosition;
- (void)sliderReachedReversePosition;
- (void)startedSliding;
- (void)stoppedSliding;

@end

@interface LTSliderViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIImageView *sliderButton;
@property (nonatomic, strong) IBOutlet UIView *sliderContainer;

@property (nonatomic, strong) UIImage *forwardImage;
@property (nonatomic, strong) UIImage *reverseImage;
@property (nonatomic, strong) UIImage *forwardPressedImage;
@property (nonatomic, strong) UIImage *reversePressedImage;
@property (nonatomic, weak) id <LTSliderDelegate> delegate;
@property (nonatomic, getter = isReversed) BOOL reversed;

@end
