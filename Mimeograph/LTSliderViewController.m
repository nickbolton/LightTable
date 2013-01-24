//
//  LTSliderViewController.m
//  Mimeograph
//
//  Created by Nick Bolton on 1/23/13.
//  Copyright (c) 2013 Pixelbleed. All rights reserved.
//

#import "LTSliderViewController.h"

CGFloat const LTSliderMinBouncePercentage = .1f;
CGFloat const LTSliderMinHalfBouncePercentage = .03f;

@interface LTSliderViewController () <UIGestureRecognizerDelegate> {

    BOOL _initialized;
    CGPoint _forwardStartPosition;
    CGPoint _reverseStartPosition;
    CGFloat _maxValue;
}

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

@end

@implementation LTSliderViewController

- (void)setReversed:(BOOL)reversed {
    _reversed = reversed;

    if (_sliderButton != nil) {
        if (_reversed) {
            _sliderButton.image = _reverseImage;
        } else {
            _sliderButton.image = _forwardImage;
        }

        if (_initialized == NO) {

            _forwardStartPosition = CGPointMake(0.0f, 0.0f);
            _reverseStartPosition = CGPointMake(CGRectGetWidth(_sliderButton.superview.frame) - CGRectGetWidth(_sliderButton.frame), 0.0f);

            _maxValue = _reverseStartPosition.x - _forwardStartPosition.x;

            self.tapGesture =
            [[UITapGestureRecognizer alloc]
             initWithTarget:self
             action:@selector(handleTap:)];

            self.panGesture =
            [[UIPanGestureRecognizer alloc]
             initWithTarget:self
             action:@selector(handlePan:)];

            [_sliderButton addGestureRecognizer:_tapGesture];
            [_sliderButton addGestureRecognizer:_panGesture];

            _tapGesture.delegate = self;
            _panGesture.delegate = self;
            
            _initialized = YES;
        }
    }
}

- (void)bounce {

    __block CGRect frame = _sliderButton.frame;

    frame.origin.x += _reversed ? -_maxValue*LTSliderMinBouncePercentage : _maxValue*LTSliderMinBouncePercentage;

    [UIView
     animateWithDuration:.15f
     animations:^{

         _sliderButton.frame = frame;

     } completion:^(BOOL finished) {

         frame.origin.x = _reversed ? _reverseStartPosition.x : _forwardStartPosition.x;

         [UIView
          animateWithDuration:.15f
          animations:^{

              _sliderButton.frame = frame;

          } completion:^(BOOL finished) {

              [self halfBounce];
          }];
     }];
}

- (void)halfBounce {

    __block CGRect frame = _sliderButton.frame;

    CGFloat maxValue = _reverseStartPosition.x - _forwardStartPosition.x;

    frame.origin.x += _reversed ? -maxValue*LTSliderMinHalfBouncePercentage : maxValue*LTSliderMinHalfBouncePercentage;

    [UIView
     animateWithDuration:.1f
     animations:^{

         _sliderButton.frame = frame;

     } completion:^(BOOL finished) {

         frame.origin.x = _reversed ? _reverseStartPosition.x : _forwardStartPosition.x;

         [UIView
          animateWithDuration:.1f
          animations:^{

              _sliderButton.frame = frame;
              
          }];
     }];
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {

    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self bounce];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {

    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:

            [_delegate startedSliding];

        case UIGestureRecognizerStateChanged:
        {
            _tapGesture.enabled = NO;

            CGPoint translation = [gesture translationInView:_sliderButton];

            CGRect frame = _sliderButton.frame;
            frame.origin.x += translation.x;

            frame.origin.x = MAX(_forwardStartPosition.x, frame.origin.x);
            frame.origin.x = MIN(_reverseStartPosition.x, frame.origin.x);

            _sliderButton.frame = frame;

            [gesture setTranslation:CGPointZero inView:_sliderButton];

            break;
        }
        default:

            _tapGesture.enabled = YES;

            [_delegate stoppedSliding];
            
            [self handlePanEnd];
            
            break;
    }
}

- (void)handlePanEnd {

    static CGFloat endThreshold = 50.0f;

    CGFloat xpos = CGRectGetMinX(_sliderButton.frame);

    CGRect frame = _sliderButton.frame;

    if (_reversed) {

        if (xpos - _forwardStartPosition.x <= endThreshold) {
            [_delegate sliderReachedForwardPosition];

            frame.origin.x = _forwardStartPosition.x;

            self.reversed = NO;

        } else {
            frame.origin.x = _reverseStartPosition.x;
        }

    } else {

        if (_reverseStartPosition.x - xpos <= endThreshold) {
            [_delegate sliderReachedReversePosition];

            frame.origin.x = _reverseStartPosition.x;

            self.reversed = YES;
            
        } else {
            frame.origin.x = _forwardStartPosition.x;
        }
    }

    [UIView
     animateWithDuration:.15f
     animations:^{

         _sliderButton.frame = frame;

     } completion:^(BOOL finished) {

         if (_reversed) {

             if (xpos < (_maxValue -_maxValue*LTSliderMinBouncePercentage)) {
                 [self bounce];
             } else if (xpos < (_maxValue - _maxValue*LTSliderMinHalfBouncePercentage)) {
                 [self halfBounce];
             }
         } else {

             if (xpos > _maxValue*LTSliderMinBouncePercentage) {
                 [self bounce];
             } else if (xpos > _maxValue*LTSliderMinHalfBouncePercentage) {
                 [self halfBounce];
             }
         }
     }];
}

#pragma mark - UIGestureRecognizerDelegate Conformance

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
