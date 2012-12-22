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
@property (nonatomic, strong) IBOutlet UIButton *photoButton;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;

- (IBAction)blank:(id)sender;
- (IBAction)selectPhoto:(id)sender;

@end
