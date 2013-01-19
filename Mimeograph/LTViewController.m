//
//  LTViewController.m
//  Mimeograph
//
//  Created by Nick Bolton on 12/12/12.
//  Copyright (c) 2012 Pixelbleed. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "LTViewController.h"
#import "SlideToCancelViewController.h"
#import "LTEdgeDetector.h"
#import "UIAlertView+Utilities.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+Snapshot.h"
#import "MBProgressHUD.h"
#import "UIColor+Utilities.h"
#import "UIButton+Utilities.h"
#import <AudioToolbox/AudioToolbox.h>

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
CGFloat const kLTFindEdgesLowerThreshold = 20.0f;

@interface LTViewController () <
UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate, SlideToCancelDelegate> {

    BOOL _landscape;
    BOOL _jinGuard;
    BOOL _locked;
    BOOL _selectPhotoGuard;
    SystemSoundID _tickSoundID;
}

@property (nonatomic, strong) UIPopoverController *imageSelectionPopoverController;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, strong) UIRotationGestureRecognizer *rotationRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapRecognizer;
@property (nonatomic, strong) ALAssetsLibrary *library;
@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic, strong) UIImage *outlinedImage;
@property (nonatomic, strong) UIImage *invertedOutlinedImage;
@property (nonatomic, strong) UIImage *forwardSliderImage;
@property (nonatomic) CGPoint touchCenter;
@property (nonatomic, strong) SlideToCancelViewController *slideToCancel;
@end

@implementation LTViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *path = [[NSBundle mainBundle] pathForResource:@"tick" ofType:@"mp3"];
    
    NSURL *filePath = [NSURL fileURLWithPath: path isDirectory: NO];

    AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &_tickSoundID);

    UIFont *buttonFont =
    [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0f];
    UIColor *buttonTitleColor = [UIColor colorWithRGBHex:0x323538];
    UIColor *buttonShadowColor = [UIColor colorWithWhite:1.0f alpha:.5f];
    CGSize buttonShadowOffset = CGSizeMake(0.0f, 1.0f);
    NSArray *buttonStates = @[@(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateSelected)];

    NSArray *buttons = @[
    _sliderLockButton,
    _sliderUnlockButton,
    _clearImageButton,
    _selectImageButton,
    _findEdgesButton,
    _removeEdgesButton,
//    _invertButton,
//    _invertOffButton,
    _lockZoomButton,
    _unlockZoomButton,
    _libraryButton,
    _cameraButton,
    _cancelAddButton,
    ];

    NSArray *buttonTitles = @[
    NSLocalizedString(@"SLIDE TO LOCK", nil),
    NSLocalizedString(@"SLIDE TO UNLOCK", nil),
    NSLocalizedString(@"CLEAR IMAGE", nil),
    NSLocalizedString(@"ADD IMAGE", nil),
    NSLocalizedString(@"OUTLINE", nil),
    NSLocalizedString(@"OUTLINE", nil),
//    NSLocalizedString(@"NEGATIVE", nil),
//    NSLocalizedString(@"NEGATIVE", nil),
    NSLocalizedString(@"LOCK SCALE", nil),
    NSLocalizedString(@"UNLOCK SCALE", nil),
    NSLocalizedString(@"LIBRARY", nil),
    NSLocalizedString(@"CAMERA", nil),
    NSLocalizedString(@"CANCEL", nil),
    ];

    NSAssert(buttons.count == buttonTitles.count, @"buttons.count != buttonTitles");

    for (NSInteger i = 0; i < buttons.count; i++) {

        UIButton *button = [buttons objectAtIndex:i];
        NSString *title = [buttonTitles objectAtIndex:i];

        [button
         configureWithTitle:title
         titleColor:buttonTitleColor
         font:buttonFont
         titleShadowColor:buttonShadowColor
         shadowOffset:buttonShadowOffset
         forControlStates:buttonStates];
    }

    self.forwardSliderImage = [UIImage imageWithData:[_sliderUnlockButton pngSnapshotData]];
    UIImage *reverseSliderImage = [UIImage imageWithData:[_sliderLockButton pngSnapshotData]];
    reverseSliderImage =
    [UIImage
     imageWithCGImage:reverseSliderImage.CGImage
     scale:1.0f
     orientation:UIImageOrientationDown];

    _slideToCancel = [[SlideToCancelViewController alloc] init];
    _slideToCancel.delegate = self;
    _slideToCancel.forwardImage = _forwardSliderImage;
    _slideToCancel.reverseImage = reverseSliderImage;
    _slideToCancel.tapToBounce = NO;
    _slideToCancel.tapToSlide = YES;

    _sliderLockButton.hidden = YES;
    _sliderUnlockButton.hidden = YES;

    [_mainContainer addSubview:_slideToCancel.view];

    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
    _pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    _doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];

    _doubleTapRecognizer.delegate = self;
    _rotationRecognizer.delegate = self;
    _pinchRecognizer.delegate = self;
    _panRecognizer.delegate = self;

    _doubleTapRecognizer.numberOfTapsRequired = 2;

    [_imageView addGestureRecognizer:_panRecognizer];
    [_imageView addGestureRecognizer:_rotationRecognizer];
    [_imageView addGestureRecognizer:_pinchRecognizer];

    _imageView.layer.borderWidth = 5;
    _imageView.layer.borderColor = [UIColor clearColor].CGColor;
    _imageView.layer.shouldRasterize = YES;

    [_mainContainer addGestureRecognizer:_doubleTapRecognizer];

    self.library = [[ALAssetsLibrary alloc] init];

    NSString *lastImagePath =
    [[NSUserDefaults standardUserDefaults]
     stringForKey:kLTLastImagePathKey];

    void (^removeLastImageBlock)(void) = ^{
        [[NSUserDefaults standardUserDefaults]
         removeObjectForKey:kLTLastImagePathKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    };

    [self setControlsEnabled:NO animate:NO];
    
    _selectImageButton.hidden = NO;
    _clearImageButton.hidden = YES;

    _findEdgesButton.hidden = NO;
    _removeEdgesButton.hidden = YES;

    _lockZoomButton.hidden = NO;
    _unlockZoomButton.hidden = YES;

    _invertButton.hidden = NO;
    _invertOffButton.hidden = YES;

    _invertButton.enabled = NO;
    _invertOffButton.enabled = NO;

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

                        BOOL inverted =
                        [[NSUserDefaults standardUserDefaults]
                         boolForKey:kLTLastImageInvertedKey];

                        _findEdgesButton.hidden = edgeDetectionOn;
                        _removeEdgesButton.hidden = !edgeDetectionOn;

                        _lockZoomButton.hidden = lockZoom;
                        _unlockZoomButton.hidden = !lockZoom;

                        _invertButton.hidden = inverted;
                        _invertOffButton.hidden = !inverted;

                        _invertButton.enabled = edgeDetectionOn;
                        _invertOffButton.enabled = edgeDetectionOn;

                        if (edgeDetectionOn) {
                            [self updateEdgeDetectionImage];
                        } else {
                            _mainContainer.backgroundColor = [UIColor whiteColor];
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

    static CGFloat padding = 16.0f;

    CGRect sliderFrame = _mainContainer.bounds;
    sliderFrame.size.width -= 2*padding;
    sliderFrame.origin.x += padding;
    sliderFrame.size.height = _forwardSliderImage.size.height;

    _landscape = UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation);

    sliderFrame.origin.y = CGRectGetHeight(_mainContainer.frame) - _forwardSliderImage.size.height - 32.0f;

    _slideToCancel.view.frame = sliderFrame;
    _slideToCancel.enabled = YES;

    static NSString *hintKey = @"kLTMultitaskingGesturesHintKey";

    [UIAlertView
     showHint:hintKey
     title:NSLocalizedString(@"Multitasking Gestures", nil)
     message:NSLocalizedString(@"This app works best if Multitasking Gestures are turned off. You can find the setting in the General section of System Preferences.", nil)];
}

- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (_slideToCancel.view.alpha > 0.0f) {

        CGRect sliderFrame = _slideToCancel.view.frame;

        sliderFrame.origin.y = CGRectGetHeight(_mainContainer.frame) - _forwardSliderImage.size.height - 32.0f;

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

    if (_slideToCancel.view.alpha > 0.0f) {

        CGRect sliderFrame = _slideToCancel.view.frame;

        sliderFrame.origin.y = CGRectGetHeight(_mainContainer.frame) - _forwardSliderImage.size.height - 32.0f;

        [UIView
         animateWithDuration:.15f
         animations:^{
             _slideToCancel.view.frame = sliderFrame;
         }];
    }
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
    _invertOffButton.enabled = enabled;
    _lockZoomButton.enabled = enabled;
    _unlockZoomButton.enabled = enabled;

    void (^executionBlock)(void) = ^{
        _findEdgesButton.alpha = alpha;
        _removeEdgesButton.alpha = alpha;
        _invertButton.alpha = alpha;
        _invertOffButton.alpha = alpha;
        _lockZoomButton.alpha = alpha;
        _unlockZoomButton.alpha = alpha;
    };

    if (animate) {
        [UIView
         animateWithDuration:.15f
         animations:executionBlock];
    } else {
        executionBlock();
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

    if (_jinGuard == NO && _locked == NO) {

        [UIView
         animateWithDuration:.15f
         animations:^{
             _imageView.alpha = 0.0f;
         } completion:^(BOOL finished) {

             self.originalImage = nil;
             self.outlinedImage = nil;
             self.invertedOutlinedImage = nil;

             _selectImageButton.hidden = NO;
             _clearImageButton.hidden = YES;

             _imageView.image = nil;

             _selectPhotoGuard = NO;

             _mainContainer.backgroundColor = [UIColor whiteColor];

             [self setControlsEnabled:NO animate:YES];
             
             [self resetImageProperties];
             [self reset:NO];
             
             _imageView.alpha = 1.0f;
         }];
    }
}

- (IBAction)addImage:(id)sender {

    if (_jinGuard == NO && _selectPhotoGuard == NO && _locked == NO) {
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

            _invertButton.hidden = NO;
            _invertOffButton.hidden = YES;

            [[NSUserDefaults standardUserDefaults]
             setBool:NO forKey:kLTLastImageInvertedKey];

        } else {

            // turning on

            controlsAlpha = 1.0f;

            if (_outlinedImage != nil) {
                _imageView.image = _outlinedImage;
            } else {
                [self updateEdgeDetectionImage];
            }

            _mainContainer.backgroundColor = [UIColor whiteColor];
        }

        _invertButton.enabled = !edgeDetectionOn;
        _invertOffButton.enabled = !edgeDetectionOn;
        _findEdgesButton.hidden = !edgeDetectionOn;
        _removeEdgesButton.hidden = edgeDetectionOn;

        [[NSUserDefaults standardUserDefaults]
         setBool:!edgeDetectionOn forKey:kLTLastImageEdgeKey];
        [[NSUserDefaults standardUserDefaults] synchronize];

        _jinGuard = NO;
    }
}

- (IBAction)toggleLockZoom:(id)sender {

    if (_jinGuard == NO && _locked == NO) {
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
}

- (IBAction)invertImage:(id)sender {

    if (_jinGuard == NO && _locked == NO) {
        BOOL edgeDetectionOn =
        [[NSUserDefaults standardUserDefaults]
         boolForKey:kLTLastImageEdgeKey];

        if (edgeDetectionOn) {
            BOOL inverted =
            [[NSUserDefaults standardUserDefaults]
             boolForKey:kLTLastImageInvertedKey];

            inverted = !inverted;

            [[NSUserDefaults standardUserDefaults]
             setBool:inverted forKey:kLTLastImageInvertedKey];
            [[NSUserDefaults standardUserDefaults] synchronize];

            _invertButton.hidden = inverted;
            _invertOffButton.hidden = !inverted;

            if (inverted) {
                if (_invertedOutlinedImage != nil) {
                    _imageView.image = _invertedOutlinedImage;
                    _mainContainer.backgroundColor = [UIColor blackColor];
                } else {
                    [self updateEdgeDetectionImage];
                }
            } else {
                if (_outlinedImage != nil) {
                    _imageView.image = _outlinedImage;
                    _mainContainer.backgroundColor = [UIColor whiteColor];
                } else {
                    [self updateEdgeDetectionImage];
                }
            }
        }
    }
}

-(void)reset:(BOOL)animated {

    void (^doReset)(void) = ^{

        BOOL lockZoom =
        [[NSUserDefaults standardUserDefaults]
         boolForKey:kLTLastImageLockZoomKey];

        if (lockZoom) {

            CGAffineTransform transform = self.imageView.transform;

            CGFloat a = transform.a;
            CGFloat c = transform.c;

            CGFloat scale = sqrtf(a*a+c*c);

            transform = CGAffineTransformMakeScale(scale, scale);

            self.imageView.transform = transform;

        } else {
            self.imageView.transform = CGAffineTransformIdentity;
        }
    };

    if(animated) {
        _mainContainer.userInteractionEnabled = NO;
        [UIView animateWithDuration:.15f animations:doReset completion:^(BOOL finished) {
            _mainContainer.userInteractionEnabled = YES;
        }];
    } else {
        doReset();
    }
}

- (void)handleTouches:(NSSet*)touches {
    self.touchCenter = CGPointZero;

    [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        UITouch *touch = (UITouch*)obj;
        CGPoint touchLocation = [touch locationInView:self.imageView];
        self.touchCenter = CGPointMake(self.touchCenter.x + touchLocation.x, self.touchCenter.y +touchLocation.y);
    }];

    CGFloat x = self.touchCenter.x/touches.count;
    CGFloat y = self.touchCenter.y/touches.count;

    x = MIN(MAX(0.0f, x), CGRectGetWidth(self.imageView.frame));
    y = MIN(MAX(0.0f, y), CGRectGetHeight(self.imageView.frame));

    self.touchCenter = CGPointMake(x, y);

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

- (void)handleRotation:(UIRotationGestureRecognizer*)recognizer {

    if(recognizer.state == UIGestureRecognizerStateBegan ||
       recognizer.state == UIGestureRecognizerStateChanged) {

        CGFloat deltaX = self.touchCenter.x-self.imageView.bounds.size.width/2;
        CGFloat deltaY = self.touchCenter.y-self.imageView.bounds.size.height/2;

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

    static CGFloat maxScale = 5.0f;
    static CGFloat minScale = 0.5f;

    BOOL lockZoom =
    [[NSUserDefaults standardUserDefaults]
     boolForKey:kLTLastImageLockZoomKey];

    if (lockZoom == NO) {
        if(recognizer.state == UIGestureRecognizerStateBegan ||
           recognizer.state == UIGestureRecognizerStateChanged) {

            CGFloat deltaX = self.touchCenter.x-self.imageView.bounds.size.width/2.0;
            CGFloat deltaY = self.touchCenter.y-self.imageView.bounds.size.height/2.0;

            CGAffineTransform transform =  CGAffineTransformTranslate(self.imageView.transform, deltaX, deltaY);
            transform = CGAffineTransformScale(transform, recognizer.scale, recognizer.scale);
            transform = CGAffineTransformTranslate(transform, -deltaX, -deltaY);

            CGFloat a = transform.a;
            CGFloat c = transform.c;

            CGFloat newScale = sqrtf(a*a+c*c);

            if (minScale < newScale && newScale < maxScale) {
                self.imageView.transform = transform;
            }

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

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    [self reset:YES];
}

- (void)updateEdgeDetectionImage {

    __block UIImage *updatedImage = nil;

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:_mainContainer];
    hud.labelText = NSLocalizedString(@"Applying Filter...", nil);

    [_mainContainer addSubview:hud];
    [hud show:YES];

    BOOL inverted =
    [[NSUserDefaults standardUserDefaults]
     boolForKey:kLTLastImageInvertedKey];

    float delayInSeconds = .5f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void){

        updatedImage =
        [[LTEdgeDetector sharedInstance]
         applyEdgeDetection:_originalImage
         lowThreshold:kLTFindEdgesLowerThreshold
         inverted:inverted];

        dispatch_async(dispatch_get_main_queue(), ^{

            if (inverted) {
                self.invertedOutlinedImage = updatedImage;
            } else {
                self.outlinedImage = updatedImage;
            }
            
            _mainContainer.backgroundColor = inverted ? [UIColor blackColor] : [UIColor whiteColor];
            _imageView.image = updatedImage;
            [hud hide:YES];
        });
    });
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)selectPhoto {

    if (_jinGuard == NO) {
        _jinGuard = YES;

        BOOL cameraAvailable =
        [UIImagePickerController
         isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];

        _addImageContainer.hidden = NO;
        _cameraButton.hidden = !cameraAvailable;

        [UIView
         animateWithDuration:.15f
         animations:^{

             CGRect frame = _libraryButton.frame;
             frame.origin.y = 12.0f;
             _libraryButton.frame = frame;

             frame = _cameraButton.frame;
             frame.origin.y = 67.0f;
             _cameraButton.frame = frame;

         } completion:^(BOOL finished) {

             _jinGuard = NO;
             _selectImageButton.hidden = YES;
             _cancelAddButton.hidden = NO;
         }];
    }
}

- (void)removeImageSelectionOptions {

    if (_jinGuard == NO) {
        _jinGuard = YES;

        [UIView
         animateWithDuration:.15f
         animations:^{

             CGRect frame = _libraryButton.frame;
             frame.origin.y = -114.0f;
             _libraryButton.frame = frame;

             frame = _cameraButton.frame;
             frame.origin.y = -59.0f;
             _cameraButton.frame = frame;

         } completion:^(BOOL finished) {

             _jinGuard = NO;
             _selectPhotoGuard = NO;
             _selectImageButton.hidden = NO;
             _cancelAddButton.hidden = YES;
             _addImageContainer.hidden = YES;
         }];
    }
}

- (IBAction)selectFromLibrary:(id)sender {
    if (_jinGuard == NO && _locked == NO) {
        [self selectPhotoFromLibrary];
    }
}

- (IBAction)useCamera:(id)sender {
    if (_jinGuard == NO && _locked == NO) {
        [self takePhotoWithCamera];
    }
}

- (IBAction)cancelAddImage:(id)sender {

    [self removeImageSelectionOptions];
}

#pragma mark - SlideToCancelDelegate Conformance

- (void)startedSliding {
    _jinGuard = YES;
}

- (void)stoppedSliding {
    _jinGuard = NO;
}

- (void)sliderReachedForwardPosition {

    _slideToCancel.tapToBounce = NO;
    _slideToCancel.tapToSlide = YES;

    for (UIGestureRecognizer *gesture in _mainContainer.gestureRecognizers) {
        gesture.enabled = YES;
    }

    for (UIGestureRecognizer *gesture in _imageView.gestureRecognizers) {
        gesture.enabled = YES;
    }

    _slideToCancel.reversed = YES;
    _locked = NO;

    AudioServicesPlaySystemSound(_tickSoundID);

    [UIView
     animateWithDuration:.15f
     animations:^{
         _selectionContainer.alpha = 1.0f;
         _selectImageButton.alpha = 1.0f;
         _clearImageButton.alpha = 1.0f;
         _addImageContainer.alpha = 1.0f;
         _cancelAddButton.alpha = 1.0f;
     }];
}

- (void)sliderReachedReversePosition {

    _slideToCancel.tapToBounce = YES;
    _slideToCancel.tapToSlide = NO;

    [UIView
     animateWithDuration:.15f
     animations:^{
         _selectImageButton.alpha = 0.0f;
         _clearImageButton.alpha = 0.0f;
         _selectionContainer.alpha = 0.0f;
         _addImageContainer.alpha = 0.0f;
         _cancelAddButton.alpha = 0.0f;
     } completion:^(BOOL finished) {
         _slideToCancel.reversed = NO;
     }];

    _locked = YES;

    AudioServicesPlaySystemSound(_tickSoundID);

    for (UIGestureRecognizer *gesture in _mainContainer.gestureRecognizers) {
        gesture.enabled = NO;
    }

    for (UIGestureRecognizer *gesture in _imageView.gestureRecognizers) {
        gesture.enabled = NO;
    }
}

- (void)takePhotoWithCamera {

    UIImagePickerController *imagePickerController =
    [[UIImagePickerController alloc] init];

    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.delegate = self;

    self.imageSelectionPopoverController =
    [[UIPopoverController alloc] initWithContentViewController:imagePickerController];

    _imageSelectionPopoverController.delegate = self;

    [_imageSelectionPopoverController
     presentPopoverFromRect:_cameraButton.bounds
     inView:_cameraButton
     permittedArrowDirections:UIPopoverArrowDirectionLeft
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

    [_imageSelectionPopoverController
     presentPopoverFromRect:_libraryButton.bounds
     inView:_libraryButton
     permittedArrowDirections:UIPopoverArrowDirectionLeft
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
    _selectImageButton.hidden = YES;
    _clearImageButton.hidden = NO;
    _lockZoomButton.hidden = NO;
    _unlockZoomButton.hidden = YES;
    _findEdgesButton.hidden = NO;
    _removeEdgesButton.hidden = YES;
    _invertButton.hidden = NO;
    _invertOffButton.hidden = YES;
    _invertButton.enabled = NO;

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
             [self removeImageSelectionOptions];
         }];
    } else {

        [[NSUserDefaults standardUserDefaults]
         setObject:assetURL.absoluteString forKey:kLTLastImagePathKey];
        [self removeImageTransformValues];
        [self removeImageSelectionOptions];
    }
}

#pragma mark - UIPopoverControllerDelegate Conformance

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.imageSelectionPopoverController = nil;
    [self removeImageSelectionOptions];
}

@end
