//
//  UIButton+Utilities.m
//  Mimeograph
//
//  Created by Nick Bolton on 12/27/12.
//  Copyright (c) 2012 Pixelbleed. All rights reserved.
//

#import "UIButton+Utilities.h"

@implementation UIButton (Utilities)

- (void)configureWithTitle:(NSString *)title
                titleColor:(UIColor *)titleColor
                      font:(UIFont *)font
          titleShadowColor:(UIColor *)titleShadowColor
              shadowOffset:(CGSize)shadowOffset
          forControlStates:(NSArray *)controlStates {

    self.titleLabel.font = font;
    self.titleLabel.shadowOffset = shadowOffset;

    for (NSNumber *controlState in controlStates) {
        [self setTitle:title forState:controlState.integerValue];
        [self setTitleColor:titleColor forState:controlState.integerValue];
        [self setTitleShadowColor:titleShadowColor forState:controlState.integerValue];
    }
}

@end
