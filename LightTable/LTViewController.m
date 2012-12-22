//
//  LTViewController.m
//  LightTable
//
//  Created by Nick Bolton on 12/12/12.
//  Copyright (c) 2012 Pixelbleed. All rights reserved.
//

#import "LTViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

NSString * const kLTLastImagePathKey = @"last-image-path";
NSString * const kLTLastImageTransformAKey = @"last-image-a";
NSString * const kLTLastImageTransformBKey = @"last-image-b";
NSString * const kLTLastImageTransformCKey = @"last-image-c";
NSString * const kLTLastImageTransformDKey = @"last-image-d";
NSString * const kLTLastImageTransformXKey = @"last-image-x";
NSString * const kLTLastImageTransformYKey = @"last-image-y";

@interface LTViewController () <
UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate> {

}

@property (nonatomic, strong) UIPopoverController *imageSelectionPopoverController;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, strong) UIRotationGestureRecognizer *rotationRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) ALAssetsLibrary *library;
@property (nonatomic) CGPoint scaleCenter;
@property (nonatomic) CGPoint touchCenter;
@property (nonatomic) CGPoint rotationCenter;

@end

@implementation LTViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
    _pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];

    _tapRecognizer.numberOfTapsRequired = 2;

    _panRecognizer.delegate = self;
    _pinchRecognizer.delegate = self;

    [_imageView addGestureRecognizer:_panRecognizer];
    [_imageView addGestureRecognizer:_rotationRecognizer];
    [_imageView addGestureRecognizer:_pinchRecognizer];
    [_imageView addGestureRecognizer:_tapRecognizer];

    self.library = [[ALAssetsLibrary alloc] init];

    NSString *lastImagePath =
    [[NSUserDefaults standardUserDefaults]
     stringForKey:kLTLastImagePathKey];
    

    void (^removeLastImageBlock)(void) = ^{
        [[NSUserDefaults standardUserDefaults]
         removeObjectForKey:kLTLastImagePathKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    };

    if (lastImagePath.length > 0) {

        NSURL *assetURL = [NSURL URLWithString:lastImagePath];

        if (assetURL != nil) {
            [self.library assetForURL:assetURL resultBlock:^(ALAsset *asset) {

                if (asset != nil) {

                    ALAssetRepresentation *rep = [asset defaultRepresentation];
                    
                    CGImageRef iref = [rep fullResolutionImage];
                    if (iref) {

                        _selectionContainer.alpha = 0.0f;
                        UIImage *image = [UIImage imageWithCGImage:iref scale:1.0f orientation:rep.orientation];;

                        self.imageView.image = image;

                        [self updateImageTransform];

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)blank:(id)sender {

    [UIView
     animateWithDuration:.15f
     animations:^{
         _selectionContainer.alpha = 0.0f;
     }];
}

- (IBAction)selectPhoto:(id)sender {
    [self selectPhoto];
}

-(void)reset:(BOOL)animated {

//    UIDeviceOrientation orient = [[UIDevice currentDevice] orientation];
//    CGFloat aspect;
//    CGFloat w;
//    CGFloat h;
//    CGAffineTransform transform = CGAffineTransformIdentity;
//
//    if (orient == UIDeviceOrientationPortrait ||
//        orient == UIDeviceOrientationPortraitUpsideDown) {
//
//        aspect = self.sourceImage.size.height/self.sourceImage.size.width;
//        w = CGRectGetWidth(self.cropRect);
//        h = aspect * w;
//
//    } else {
//
//        aspect = self.sourceImage.size.width/self.sourceImage.size.height;
//        w = CGRectGetHeight(self.cropRect);
//        h = aspect * w;
//
//    }
//
//    self.scale = 1;

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
        self.touchCenter = CGPointMake(self.touchCenter.x + touchLocation.x, self.touchCenter.y +touchLocation.y);
    }];
    self.touchCenter = CGPointMake(self.touchCenter.x/touches.count, self.touchCenter.y/touches.count);
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

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer
{
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

#pragma mark - UIActionSheetDelegate Conformance

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self takePhotoWithCamera];
    } else if (buttonIndex == 1) {
        [self selectPhotoFromLibrary];
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
     presentPopoverFromRect:_photoButton.bounds
     inView:_photoButton
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
     presentPopoverFromRect:_photoButton.bounds
     inView:_photoButton
     permittedArrowDirections:UIPopoverArrowDirectionLeft
     animated:YES];

}

#pragma mark - UIImagePickerControllerDelegate Conformance

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    [_imageSelectionPopoverController dismissPopoverAnimated:YES];

    [UIView
     animateWithDuration:.15f
     animations:^{
         _selectionContainer.alpha = 0.0f;
     } completion:^(BOOL finished) {
         UIImage *image =  [info objectForKey:UIImagePickerControllerOriginalImage];
         NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];

         self.imageView.image = image;

         if (assetURL == nil) {

             [self.library
              writeImageToSavedPhotosAlbum:[image CGImage]
              orientation:image.imageOrientation
              completionBlock:^(NSURL *assetURL, NSError *error){
                  if (error) {
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
              }];
         } else {

             [[NSUserDefaults standardUserDefaults]
              setObject:assetURL.absoluteString forKey:kLTLastImagePathKey];
             [self removeImageTransformValues];
         }
     }];
}

#pragma mark - UIPopoverControllerDelegate Conformance

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.imageSelectionPopoverController = nil;
}

@end
