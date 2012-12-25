//
//  LTViewController.h
//  LightTable
//
//  Created by Nick Bolton on 12/12/12.
//  Copyright (c) 2012 Pixelbleed. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LTViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIView *selectionContainer;
@property (nonatomic, strong) IBOutlet UIView *mainContainer;
@property (nonatomic, strong) IBOutlet UIButton *selectImageButton;
@property (nonatomic, strong) IBOutlet UIButton *clearImageButton;
@property (nonatomic, strong) IBOutlet UIButton *invertButton;
@property (nonatomic, strong) IBOutlet UIButton *invertOffButton;
@property (nonatomic, strong) IBOutlet UIButton *findEdgesButton;
@property (nonatomic, strong) IBOutlet UIButton *removeEdgesButton;
@property (nonatomic, strong) IBOutlet UIButton *lockZoomButton;
@property (nonatomic, strong) IBOutlet UIButton *unlockZoomButton;
@property (nonatomic, strong) IBOutlet UIButton *sliderLockButton;
@property (nonatomic, strong) IBOutlet UIButton *sliderUnlockButton;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;

- (IBAction)selectPhoto:(id)sender;
- (IBAction)findEdges:(id)sender;
- (IBAction)invertImage:(id)sender;
- (IBAction)toggleLockZoom:(id)sender;

@end
