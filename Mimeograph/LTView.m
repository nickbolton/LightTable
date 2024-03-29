//
//  LTView.m
//  Mimeograph
//
//  Created by Nick Bolton on 12/25/12.
//  Copyright (c) 2012 Pixelbleed. All rights reserved.
//

#import "LTView.h"

@interface LTView()

@property (nonatomic, strong) NSMutableArray *tappableViews;

@end


@implementation LTView

- (NSMutableArray *)tappableViews {
    if (_tappableViews == nil) {
        self.tappableViews = [NSMutableArray array];
    }
    return _tappableViews;
}

- (void)addTappableView:(UIView *)view {

    [self.tappableViews addObject:view];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

    UITouch *touch = touches.anyObject;

    for (UIView *view in self.tappableViews) {
        if ([view hitTest:[touch locationInView:view.superview] withEvent:event]) {
            return;
        }
    }

    [super touchesBegan:touches withEvent:event];
}

@end
