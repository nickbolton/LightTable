//
//  LTTracingWarningViewController.m
//  LightTable
//
//  Created by Nick Bolton on 1/15/13.
//  Copyright (c) 2013 Pixelbleed. All rights reserved.
//

#import "LTTracingWarningViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "LTViewController.h"
#import "LTAppDelegate.h"

@interface LTTracingWarningViewController () {

    SystemSoundID _tickSoundID;
}

@end

@implementation LTTracingWarningViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"tick" ofType:@"mp3"];
    NSURL *filePath = [NSURL fileURLWithPath: path isDirectory: NO];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &_tickSoundID);
}

- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (IBAction)home:(id)sender {
    AudioServicesPlaySystemSound(_tickSoundID);
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kLTPencilWarningShownKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
