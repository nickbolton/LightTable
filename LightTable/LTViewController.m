//
//  LTViewController.m
//  LightTable
//
//  Created by Nick Bolton on 12/12/12.
//  Copyright (c) 2012 Pixelbleed. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "LTViewController.h"
#import "SlideToCancelViewController.h"
#import "LTEdgeDetector.h"
#import "UIAlertView+Utilities.h"

NSString * const kLTLastImagePathKey = @"last-image-path";
NSString * const kLTLastImageTransformAKey = @"last-image-a";
NSString * const kLTLastImageTransformBKey = @"last-image-b";
NSString * const kLTLastImageTransformCKey = @"last-image-c";
NSString * const kLTLastImageTransformDKey = @"last-image-d";
NSString * const kLTLastImageTransformXKey = @"last-image-x";
NSString * const kLTLastImageTransformYKey = @"last-image-y";
NSString * const kLTLastImageInvertedKey = @"last-image-inv";
NSString * const kLTLastImageLockZoomKey = @"last-image-lock-zoom";
NSString * const kLTLastImageEdgeKey = @"last-image-edge";

@interface LTViewController () <
UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate, SlideToCancelDelegate> {

    BOOL _locked;
    BOOL _landscape;
    BOOL _jinGuard;
    BOOL _selectPhotoGuard;
}

@property (nonatomic, strong) UIPopoverController *imageSelectionPopoverController;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, strong) UIRotationGestureRecognizer *rotationRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *mainViewTapRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *mainViewDoubleTapRecognizer;
@property (nonatomic, strong) ALAssetsLibrary *library;
@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic) CGPoint scaleCenter;
@property (nonatomic) CGPoint touchCenter;
@property (nonatomic) CGPoint rotationCenter;
@property (nonatomic, strong) SlideToCancelViewController *slideToCancel;
@end

@implementation LTViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _slideToCancel = [[SlideToCancelViewController alloc] init];
    _slideToCancel.delegate = self;
    _slideToCancel.forwardText = NSLocalizedString(@"Slide to lock", nil);
    _slideToCancel.reverseText = NSLocalizedString(@"Slide to unlock", nil);

    [self.view addSubview:_slideToCancel.view];

    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
    _pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _mainViewTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    _mainViewDoubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];

    [_tapRecognizer requireGestureRecognizerToFail:_doubleTapRecognizer];
    [_mainViewTapRecognizer requireGestureRecognizerToFail:_mainViewDoubleTapRecognizer];

    _doubleTapRecognizer.numberOfTapsRequired = 2;
    _mainViewDoubleTapRecognizer.numberOfTapsRequired = 2;

    _panRecognizer.delegate = self;
    _pinchRecognizer.delegate = self;

    [_imageView addGestureRecognizer:_panRecognizer];
    [_imageView addGestureRecognizer:_rotationRecognizer];
    [_imageView addGestureRecognizer:_pinchRecognizer];
    [_imageView addGestureRecognizer:_tapRecognizer];
    [_imageView addGestureRecognizer:_doubleTapRecognizer];
    
    [self.view addGestureRecognizer:_mainViewTapRecognizer];
    [self.view addGestureRecognizer:_mainViewDoubleTapRecognizer];

    self.library = [[ALAssetsLibrary alloc] init];

    NSString *lastImagePath =
    [[NSUserDefaults standardUserDefaults]
     stringForKey:kLTLastImagePathKey];

    void (^removeLastImageBlock)(void) = ^{
        [[NSUserDefaults standardUserDefaults]
         removeObjectForKey:kLTLastImagePathKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    };

    _edgeControlsContainer.alpha = 0.0f;

    [self setControlsEnabled:NO animate:NO];
    
    _selectImageButton.hidden = NO;
    _clearImageButton.hidden = YES;

    _findEdgesButton.hidden = NO;
    _removeEdgesButton.hidden = YES;

    _lockZoomButton.hidden = NO;
    _unlockZoomButton.hidden = YES;

    if (lastImagePath.length > 0) {

        NSURL *assetURL = [NSURL URLWithString:lastImagePath];

        if (assetURL != nil) {
            [self.library assetForURL:assetURL resultBlock:^(ALAsset *asset) {

                if (asset != nil) {

                    ALAssetRepresentation *rep = [asset defaultRepresentation];
                    
                    CGImageRef iref = [rep fullResolutionImage];
                    if (iref) {

                        UIImage *image = [UIImage imageWithCGImage:iref scale:1.0f orientation:(UIImageOrientation)rep.orientation];;

                        self.imageView.image = image;
                        self.originalImage = image;

                        [self setControlsEnabled:YES animate:YES];

                        _selectImageButton.hidden = YES;
                        _clearImageButton.hidden = NO;

                        [self updateImageTransform];

                        BOOL edgeDetectionOn =
                        [[NSUserDefaults standardUserDefaults]
                         boolForKey:kLTLastImageEdgeKey];

                        BOOL lockZoom =
                        [[NSUserDefaults standardUserDefaults]
                         boolForKey:kLTLastImageLockZoomKey];

                        _edgeControlsContainer.alpha = edgeDetectionOn ? 1.0f : 0.0f;

                        _findEdgesButton.hidden = edgeDetectionOn;
                        _removeEdgesButton.hidden = !edgeDetectionOn;

                        _lockZoomButton.hidden = lockZoom;
                        _unlockZoomButton.hidden = !lockZoom;

                        if (edgeDetectionOn) {
                            [self updateEdgeDetectionImage];
                        } else {
                            self.view.backgroundColor = [UIColor whiteColor];
                        }

                    } else {
                        removeLastImageBlock();
                    }

                } else {
                    removeLastImageBlock();
                }

            } failureBlock:^(NSError *error) {

                NSLog(@"Error: %@", error);

                removeLastImageBlock();
            }];
        } else {
            removeLastImageBlock();
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    CGRect sliderFrame = _slideToCancel.view.frame;

    _landscape = UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation);

    if (_landscape) {
        sliderFrame.origin.y = CGRectGetWidth(self.view.frame) - CGRectGetHeight(sliderFrame);
        sliderFrame.size.width = CGRectGetHeight(self.view.frame);
    } else {
        sliderFrame.origin.y = CGRectGetHeight(self.view.frame) - CGRectGetHeight(sliderFrame);
        sliderFrame.size.width = CGRectGetWidth(self.view.frame);
    }

    _slideToCancel.view.frame = sliderFrame;
    _slideToCancel.enabled = YES;

    static NSString *hintKey = @"kLTMultitaskingGesturesHintKey";

    [UIAlertView
     showHint:hintKey
     title:NSLocalizedString(@"Multitasking Gestures", nil)
     message:NSLocalizedString(@"This app works best if Multitasking Gestures are turned off. You can find the setting in the General section of System Preferences.", nil)];
}

- (UIView *)rotatingFooterView {
    return _slideToCancel.view;
}

//- (BOOL)shouldAutorotate {
//    return YES;
//}
//
//- (NSUInteger)supportedInterfaceOrientations {
//    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
//}
//
//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
//    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
//}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (_slideToCancel.view.alpha > 0.0f) {

        CGFloat ypos;

        CGRect sliderFrame = _slideToCancel.view.frame;

        if (_landscape) {
            ypos = CGRectGetHeight(self.view.frame) - CGRectGetHeight(sliderFrame);
        } else {
            ypos = CGRectGetWidth(self.view.frame) - CGRectGetHeight(sliderFrame);
        }

        sliderFrame.origin.y = ypos;

        [UIView
         animateWithDuration:duration
         animations:^{
             _slideToCancel.view.frame = sliderFrame;
         }];
    }

}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    _landscape = UIDeviceOrientationIsLandscape((UIDeviceOrientation)fromInterfaceOrientation) == NO;

    BOOL enabled = _slideToCancel.enabled;

    _slideToCancel.enabled = YES;

    _slideToCancel.enabled = enabled;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setControlsEnabled:(BOOL)enabled animate:(BOOL)animate {

    CGFloat alpha = enabled ? 1.0f : 0.0f;

    _findEdgesButton.enabled = enabled;
    _removeEdgesButton.enabled = enabled;
    _invertButton.enabled = enabled;
    _lockZoomButton.enabled = enabled;
    _unlockZoomButton.enabled = enabled;

    if (animate) {
        [UIView
         animateWithDuration:.15f
         animations:^{
             _findEdgesButton.alpha = alpha;
             _removeEdgesButton.alpha = alpha;
             _invertButton.alpha = alpha;
             _lockZoomButton.alpha = alpha;
             _unlockZoomButton.alpha = alpha;
         }];
    } else {
        _findEdgesButton.alpha = alpha;
        _removeEdgesButton.alpha = alpha;
        _invertButton.alpha = alpha;
        _lockZoomButton.alpha = alpha;
        _unlockZoomButton.alpha = alpha;
    }
}

- (void)resetImageProperties {
    [[NSUserDefaults standardUserDefaults]
     removeObjectForKey:kLTLastImagePathKey];
    [[NSUserDefaults standardUserDefaults]
     removeObjectForKey:kLTLastImageInvertedKey];
    [[NSUserDefaults standardUserDefaults]
     removeObjectForKey:kLTLastImageLockZoomKey];
    [[NSUserDefaults standardUserDefaults]
     removeObjectForKey:kLTLastImageEdgeKey];
    [self removeImageTransformValues];
}

- (IBAction)blank:(id)sender {

    [UIView
     animateWithDuration:.15f
     animations:^{
         _imageView.alpha = 0.0f;
     } completion:^(BOOL finished) {

         _selectImageButton.hidden = NO;
         _clearImageButton.hidden = YES;

         _imageView.image = nil;

         _selectPhotoGuard = NO;

         self.view.backgroundColor = [UIColor whiteColor];

         [self setControlsEnabled:NO animate:YES];

         [self resetImageProperties];
         [self reset:NO];

         _imageView.alpha = 1.0f;
     }];
}

- (IBAction)selectPhoto:(id)sender {

    if (_jinGuard == NO && _selectPhotoGuard == NO) {
        _selectPhotoGuard = YES;
        
        if (_imageView.image != nil) {

            [self blank:sender];
            
        } else {

            [self resetImageProperties];
            [self reset:NO];
            
            [self selectPhoto];
            
        }
    }
}

- (IBAction)findEdges:(id)sender {
    
    if (_jinGuard == NO && _imageView.image != nil) {

        _jinGuard = YES;

        BOOL edgeDetectionOn =
        [[NSUserDefaults standardUserDefaults]
         boolForKey:kLTLastImageEdgeKey];

        CGFloat controlsAlpha;

        if (edgeDetectionOn) {

            // turning off

            controlsAlpha = 0.0f;

            _imageView.image = self.originalImage;

        } else {

            // turning on

            controlsAlpha = 1.0f;

            [self updateEdgeDetectionImage];

            self.view.backgroundColor = [UIColor whiteColor];
        }

        [UIView
         animateWithDuration:.15f
         animations:^{
             _edgeControlsContainer.alpha = controlsAlpha;
         } completion:^(BOOL finished) {

             _findEdgesButton.hidden = !edgeDetectionOn;
             _removeEdgesButton.hidden = edgeDetectionOn;

             [[NSUserDefaults standardUserDefaults]
              setBool:!edgeDetectionOn forKey:kLTLastImageEdgeKey];
             [[NSUserDefaults standardUserDefaults] synchronize];

             _jinGuard = NO;
         }];
    }
}

- (IBAction)toggleLockZoom:(id)sender {

    BOOL lockZoom =
    [[NSUserDefaults standardUserDefaults]
     boolForKey:kLTLastImageLockZoomKey];

    [[NSUserDefaults standardUserDefaults]
     setBool:!lockZoom forKey:kLTLastImageLockZoomKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    _lockZoomButton.hidden = !lockZoom;
    _unlockZoomButton.hidden = lockZoom;

    [_lockZoomButton setNeedsDisplay];
}

- (IBAction)invertImage:(id)sender {

    BOOL edgeDetectionOn =
    [[NSUserDefaults standardUserDefaults]
     boolForKey:kLTLastImageEdgeKey];

    if (edgeDetectionOn) {
        BOOL inverted =
        [[NSUserDefaults standardUserDefaults]
         boolForKey:kLTLastImageInvertedKey];

        [[NSUserDefaults standardUserDefaults]
         setBool:!inverted forKey:kLTLastImageInvertedKey];
        [[NSUserDefaults standardUserDefaults] synchronize];

        [self updateEdgeDetectionImage];
    }
}

-(void)reset:(BOOL)animated {

    void (^doReset)(void) = ^{
        self.imageView.transform = CGAffineTransformIdentity;
    };

    if(animated) {
        self.view.userInteractionEnabled = NO;
        [UIView animateWithDuration:.15f animations:doReset completion:^(BOOL finished) {
            self.view.userInteractionEnabled = YES;
        }];
    } else {
        doReset();
    }
}

- (void)handleTouches:(NSSet*)touches {
    self.touchCenter = CGPointZero;
    if(touches.count < 2) return;

    [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        UITouch *touch = (UITouch*)obj;
        CGPoint touchLocation = [touch locationInView:self.imageView];
        if (_landscape) {
            self.touchCenter = CGPointMake(self.touchCenter.y + touchLocation.y, self.touchCenter.x +touchLocation.x);
        } else {
            self.touchCenter = CGPointMake(self.touchCenter.x + touchLocation.x, self.touchCenter.y +touchLocation.y);
        }
    }];

    if (_landscape) {
        self.touchCenter = CGPointMake(self.touchCenter.y/touches.count, self.touchCenter.x/touches.count);
    } else {
        self.touchCenter = CGPointMake(self.touchCenter.x/touches.count, self.touchCenter.y/touches.count);
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouches:[event allTouches]];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouches:[event allTouches]];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouches:[event allTouches]];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouches:[event allTouches]];
}

- (void)handlePan:(UIPanGestureRecognizer*)recognizer
{
    if(recognizer.state == UIGestureRecognizerStateBegan ||
       recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:self.imageView];
        CGAffineTransform transform = CGAffineTransformTranslate( self.imageView.transform, translation.x, translation.y);
        self.imageView.transform = transform;

        [recognizer setTranslation:CGPointMake(0, 0) inView:self.imageView];
    } else {
        [self saveImageTransformValues];
    }

}

- (void)handleRotation:(UIRotationGestureRecognizer*)recognizer
{
    if(recognizer.state == UIGestureRecognizerStateBegan ||
       recognizer.state == UIGestureRecognizerStateChanged) {

        if(recognizer.state == UIGestureRecognizerStateBegan){
            self.rotationCenter = self.touchCenter;
        }
        CGFloat deltaX = self.rotationCenter.x-self.imageView.bounds.size.width/2;
        CGFloat deltaY = self.rotationCenter.y-self.imageView.bounds.size.height/2;

        CGAffineTransform transform =  CGAffineTransformTranslate(self.imageView.transform,deltaX,deltaY);
        transform = CGAffineTransformRotate(transform, recognizer.rotation);
        transform = CGAffineTransformTranslate(transform, -deltaX, -deltaY);
        self.imageView.transform = transform;

        recognizer.rotation = 0;
    } else {
        [self saveImageTransformValues];
    }

}

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {

    BOOL lockZoom =
    [[NSUserDefaults standardUserDefaults]
     boolForKey:kLTLastImageLockZoomKey];

    if (lockZoom == NO) {
        if(recognizer.state == UIGestureRecognizerStateBegan ||
           recognizer.state == UIGestureRecognizerStateChanged) {

            if(recognizer.state == UIGestureRecognizerStateBegan){
                self.scaleCenter = self.touchCenter;
            }
            CGFloat deltaX = self.scaleCenter.x-self.imageView.bounds.size.width/2.0;
            CGFloat deltaY = self.scaleCenter.y-self.imageView.bounds.size.height/2.0;

            CGAffineTransform transform =  CGAffineTransformTranslate(self.imageView.transform, deltaX, deltaY);
            transform = CGAffineTransformScale(transform, recognizer.scale, recognizer.scale);
            transform = CGAffineTransformTranslate(transform, -deltaX, -deltaY);

            self.imageView.transform = transform;

            recognizer.scale = 1;
        } else {
            [self saveImageTransformValues];
        }
    }
}

- (void)saveImageTransformValues {

    CGAffineTransform t = self.imageView.transform;

    [[NSUserDefaults standardUserDefaults]
     setFloat:t.a forKey:kLTLastImageTransformAKey];

    [[NSUserDefaults standardUserDefaults]
     setFloat:t.b forKey:kLTLastImageTransformBKey];

    [[NSUserDefaults standardUserDefaults]
     setFloat:t.c forKey:kLTLastImageTransformCKey];

    [[NSUserDefaults standardUserDefaults]
     setFloat:t.d forKey:kLTLastImageTransformDKey];

    [[NSUserDefaults standardUserDefaults]
     setFloat:t.tx forKey:kLTLastImageTransformXKey];

    [[NSUserDefaults standardUserDefaults]
     setFloat:t.ty forKey:kLTLastImageTransformYKey];

    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeImageTransformValues {

    [[NSUserDefaults standardUserDefaults]
     removeObjectForKey:kLTLastImageTransformAKey];

    [[NSUserDefaults standardUserDefaults]
     removeObjectForKey:kLTLastImageTransformBKey];

    [[NSUserDefaults standardUserDefaults]
     removeObjectForKey:kLTLastImageTransformCKey];

    [[NSUserDefaults standardUserDefaults]
     removeObjectForKey:kLTLastImageTransformDKey];

    [[NSUserDefaults standardUserDefaults]
     removeObjectForKey:kLTLastImageTransformXKey];

    [[NSUserDefaults standardUserDefaults]
     removeObjectForKey:kLTLastImageTransformYKey];

    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)updateImageTransform {

    NSNumber *a =
    [[NSUserDefaults standardUserDefaults] objectForKey:kLTLastImageTransformAKey];

    NSNumber *b =
    [[NSUserDefaults standardUserDefaults] objectForKey:kLTLastImageTransformBKey];

    NSNumber *c =
    [[NSUserDefaults standardUserDefaults] objectForKey:kLTLastImageTransformCKey];

    NSNumber *d =
    [[NSUserDefaults standardUserDefaults] objectForKey:kLTLastImageTransformDKey];

    NSNumber *x =
    [[NSUserDefaults standardUserDefaults] objectForKey:kLTLastImageTransformXKey];

    NSNumber *y =
    [[NSUserDefaults standardUserDefaults] objectForKey:kLTLastImageTransformYKey];

    CGAffineTransform transform = CGAffineTransformIdentity;

    if (a != nil) {
        transform.a = a.floatValue;
        transform.b = b.floatValue;
        transform.c = c.floatValue;
        transform.d = d.floatValue;
        transform.tx = x.floatValue;
        transform.ty = y.floatValue;
    }

    self.imageView.transform = transform;
}

- (CGFloat)imageRotation {
    return atan2(self.imageView.transform.b, self.imageView.transform.a);
}

- (CGFloat)imageScale {
    return sqrtf(self.imageView.transform.a*self.imageView.transform.a +
                 self.imageView.transform.c*self.imageView.transform.c);
}

- (CGFloat)imageXTranslation {
    return self.imageView.transform.tx;
}

- (CGFloat)imageYTranslation {
    return self.imageView.transform.ty;
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {

    CGFloat ypos;
    CGFloat alpha;

    if (_slideToCancel.view.alpha > 0.0f) {

        ypos = CGRectGetMaxY(_slideToCancel.view.frame);

        alpha = 0.0f;
    } else {

        CGRect sliderFrame = _slideToCancel.view.frame;

        if (_landscape) {
            ypos = CGRectGetWidth(self.view.frame) - CGRectGetHeight(sliderFrame);
        } else {
            ypos = CGRectGetHeight(self.view.frame) - CGRectGetHeight(sliderFrame);
        }

        sliderFrame.origin.y = CGRectGetMaxY(_slideToCancel.view.frame);
        _slideToCancel.view.frame = sliderFrame;
        _slideToCancel.view.alpha = 1.0f;

        alpha = 1.0f;
    }

    CGRect frame = _slideToCancel.view.frame;
    frame.origin.y = ypos;

    [UIView
     animateWithDuration:.15f
     animations:^{
         _slideToCancel.view.frame = frame;
     } completion:^(BOOL finished) {
         _slideToCancel.view.alpha = alpha;
     }];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    [self reset:YES];
}

- (IBAction)edgeLowThresholdChanged:(id)sender {
    _edgeLowThresholdLabel.text =
    [NSString stringWithFormat:@"Thres: %.1f", _edgeLowThresholdSlider.value];
    [self updateEdgeDetectionImage];
}

- (void)updateEdgeDetectionImage {

    BOOL inverted =
    [[NSUserDefaults standardUserDefaults]
     boolForKey:kLTLastImageInvertedKey];
    
    UIImage *updatedImage =
    [[LTEdgeDetector sharedInstance]
     applyEdgeDetection:_originalImage
     lowThreshold:_edgeLowThresholdSlider.value
     inverted:inverted];

    self.view.backgroundColor = inverted ? [UIColor blackColor] : [UIColor whiteColor];

    _imageView.image = updatedImage;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - LTSelectionDelegate Conformance

- (void)selectPhoto {

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIActionSheet *actionSheet =
        [[UIActionSheet alloc]
         initWithTitle:@""
         delegate:self
         cancelButtonTitle:nil
         destructiveButtonTitle:nil
         otherButtonTitles:
         NSLocalizedString(@"Take Photo With Camera", nil),
         NSLocalizedString(@"Select Photo From Library", nil),
         NSLocalizedString(@"Cancel", nil),
         nil];

        actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
        [actionSheet showInView:self.view];
    }

}

#pragma mark - SlideToCancelDelegate Conformance

- (void)sliderReachedForwardPosition {

    _locked = YES;

    for (UIGestureRecognizer *gesture in self.view.gestureRecognizers) {
        if (gesture != _mainViewTapRecognizer) {
            gesture.enabled = NO;
        }
    }

    for (UIGestureRecognizer *gesture in _imageView.gestureRecognizers) {
        if (gesture != _tapRecognizer) {
            gesture.enabled = NO;
        }
    }

    [UIView
     animateWithDuration:.15f
     animations:^{
         _slideToCancel.view.alpha = 0.0f;
         _selectionContainer.alpha = 0.0f;
     } completion:^(BOOL finished) {
         _slideToCancel.reversed = YES;
     }];
}

- (void)sliderReachedReversePosition {
    _locked = NO;
    _slideToCancel.reversed = NO;

    [UIView
     animateWithDuration:.15f
     animations:^{
         _selectionContainer.alpha = 1.0f;
     }];

    for (UIGestureRecognizer *gesture in self.view.gestureRecognizers) {
        gesture.enabled = YES;
    }

    for (UIGestureRecognizer *gesture in _imageView.gestureRecognizers) {
        gesture.enabled = YES;
    }
}

#pragma mark - UIActionSheetDelegate Conformance

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self takePhotoWithCamera];
    } else if (buttonIndex == 1) {
        [self selectPhotoFromLibrary];
    } else {
        _selectPhotoGuard = NO;
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    _selectPhotoGuard = NO;
}

- (void)takePhotoWithCamera {

    UIImagePickerController *imagePickerController =
    [[UIImagePickerController alloc] init];

    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.delegate = self;

    self.imageSelectionPopoverController =
    [[UIPopoverController alloc] initWithContentViewController:imagePickerController];

    _imageSelectionPopoverController.delegate = self;

    UIView *view = _selectImageButton.hidden ? _clearImageButton : _selectImageButton;

    [_imageSelectionPopoverController
     presentPopoverFromRect:view.bounds
     inView:view
     permittedArrowDirections:UIPopoverArrowDirectionRight
     animated:YES];

}

- (void)selectPhotoFromLibrary {

    UIImagePickerController *imagePickerController =
    [[UIImagePickerController alloc] init];

    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;

    self.imageSelectionPopoverController =
    [[UIPopoverController alloc] initWithContentViewController:imagePickerController];

    _imageSelectionPopoverController.delegate = self;

    UIView *view = _selectImageButton.hidden ? _clearImageButton : _selectImageButton;

    [_imageSelectionPopoverController
     presentPopoverFromRect:view.bounds
     inView:view
     permittedArrowDirections:UIPopoverArrowDirectionRight
     animated:YES];

}

#pragma mark - UIImagePickerControllerDelegate Conformance

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    [_imageSelectionPopoverController dismissPopoverAnimated:YES];

    UIImage *image =  [info objectForKey:UIImagePickerControllerOriginalImage];
    NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];

    self.imageView.image = image;
    self.originalImage = image;

    [self setControlsEnabled:YES animate:YES];

    _selectImageButton.hidden = YES;
    _clearImageButton.hidden = NO;

    [[NSUserDefaults standardUserDefaults]
     removeObjectForKey:kLTLastImageEdgeKey];

    if (assetURL == nil) {

        [self.library
         writeImageToSavedPhotosAlbum:[image CGImage]
         orientation:(ALAssetOrientation)image.imageOrientation
         completionBlock:^(NSURL *assetURL, NSError *error){
             if (error) {

                 [[NSUserDefaults standardUserDefaults] synchronize];

                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Saving"
                                                                 message:[error localizedDescription]
                                                                delegate:nil
                                                       cancelButtonTitle:@"Ok"
                                                       otherButtonTitles: nil];
                 [alert show];
             } else {

                 [[NSUserDefaults standardUserDefaults]
                  setObject:assetURL.absoluteString forKey:kLTLastImagePathKey];
                 [self removeImageTransformValues];
             }
             _selectPhotoGuard = NO;
         }];
    } else {
        _selectPhotoGuard = NO;

        [[NSUserDefaults standardUserDefaults]
         setObject:assetURL.absoluteString forKey:kLTLastImagePathKey];
        [self removeImageTransformValues];
    }
}

#pragma mark - UIPopoverControllerDelegate Conformance

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.imageSelectionPopoverController = nil;
    _selectPhotoGuard = NO;
}

@end
