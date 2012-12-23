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
@property (nonatomic, strong) IBOutlet UIButton *photoButton;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UISlider *edgeLowThresholdSlider;
@property (nonatomic, strong) IBOutlet UILabel *edgeLowThresholdLabel;

- (IBAction)blank:(id)sender;
- (IBAction)selectPhoto:(id)sender;
- (IBAction)edgeLowThresholdChanged:(id)sender;

@end
