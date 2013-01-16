//
//  LTTracingWarningViewController.h
//  Mimeograph
//
//  Created by Nick Bolton on 1/15/13.
//  Copyright (c) 2013 Pixelbleed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LTViewController;

@interface LTTracingWarningViewController : UIViewController

@property (nonatomic, strong) IBOutlet LTViewController *mainViewController;

- (IBAction)home:(id)sender;

@end
