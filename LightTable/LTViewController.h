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
@property (nonatomic, strong) IBOutlet UIView *edgeControlsContainer;
@property (nonatomic, strong) IBOutlet UIButton *selectImageButton;
@property (nonatomic, strong) IBOutlet UIButton *clearImageButton;
@property (nonatomic, strong) IBOutlet UIButton *invertButton;
@property (nonatomic, strong) IBOutlet UIButton *findEdgesButton;
@property (nonatomic, strong) IBOutlet UIButton *removeEdgesButton;
@property (nonatomic, strong) IBOutlet UIButton *lockZoomButton;
@property (nonatomic, strong) IBOutlet UIButton *unlockZoomButton;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UISlider *edgeLowThresholdSlider;
@property (nonatomic, strong) IBOutlet UILabel *edgeLowThresholdLabel;

- (IBAction)selectPhoto:(id)sender;
- (IBAction)findEdges:(id)sender;
- (IBAction)invertImage:(id)sender;
- (IBAction)toggleLockZoom:(id)sender;
- (IBAction)edgeLowThresholdChanged:(id)sender;

@end
