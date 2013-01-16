//
//  UIButton+Utilities.h
//  Mimeograph
//
//  Created by Nick Bolton on 12/27/12.
//  Copyright (c) 2012 Pixelbleed. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton (Utilities)

- (void)configureWithTitle:(NSString *)title
                titleColor:(UIColor *)titleColor
                      font:(UIFont *)font
          titleShadowColor:(UIColor *)titleShadowColor
              shadowOffset:(CGSize)shadowOffset
          forControlStates:(NSArray *)controlStates;

@end
