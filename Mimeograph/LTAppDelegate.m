//
//  LTAppDelegate.m
//  Mimeograph
//
//  Created by Nick Bolton on 12/12/12.
//  Copyright (c) 2012 Pixelbleed. All rights reserved.
//

#import "LTAppDelegate.h"
#import "LTTracingWarningViewController.h"

NSString * const kLTPencilWarningShownKey = @"warning-shown";

@interface LTAppDelegate() {

    CGFloat _previousBrightness;
}

@end


@implementation LTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    BOOL warningShown =
    [[NSUserDefaults standardUserDefaults] boolForKey:kLTPencilWarningShownKey];

    if (NO && warningShown == NO) {

        UIStoryboard *storyboard =
        [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];

        LTTracingWarningViewController *tracingWarningViewController =
        [storyboard instantiateViewControllerWithIdentifier:@"LTTracingWarningViewController"];

        self.window.rootViewController = tracingWarningViewController;
    }

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application {
    [[UIScreen mainScreen] setBrightness:_previousBrightness];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    _previousBrightness = [UIScreen mainScreen].brightness;
    [UIScreen mainScreen].brightness = 1.0f;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[UIScreen mainScreen] setBrightness:_previousBrightness];
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

@end
