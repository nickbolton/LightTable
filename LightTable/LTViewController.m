//
//  LTViewController.m
//  LightTable
//
//  Created by Nick Bolton on 12/12/12.
//  Copyright (c) 2012 Pixelbleed. All rights reserved.
//

#import "LTViewController.h"

@interface LTViewController () <
UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate> {

}

@property (nonatomic, strong) UIPopoverController *imageSelectionPopoverController;

@end

@implementation LTViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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

    [UIView
     animateWithDuration:.15f
     animations:^{
         _selectionContainer.alpha = 0.0f;
     } completion:^(BOOL finished) {
         [self selectPhoto];
     }];
}

#pragma mark - LTSelectionDelegate Conformance

- (void)selectPhoto {

    UIImagePickerController *imagePickerController =
    [[UIImagePickerController alloc] init];

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }

    imagePickerController.delegate = self;

    self.imageSelectionPopoverController =
    [[UIPopoverController alloc] initWithContentViewController:imagePickerController];

    _imageSelectionPopoverController.delegate = self;
    [_imageSelectionPopoverController
     presentPopoverFromRect:self.view.bounds
     inView:self.view
     permittedArrowDirections:UIPopoverArrowDirectionAny
     animated:YES];

}

#pragma mark - UIImagePickerControllerDelegate Conformance

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];

    _imageView.image = image;

    self.imageSelectionPopoverController = nil;
}

#pragma mark - UIPopoverControllerDelegate Conformance

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.imageSelectionPopoverController = nil;
}

@end
