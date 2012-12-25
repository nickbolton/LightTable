//
//  UIView+Snapshot.m
//  PearsonAdolescentLiterature
//
//  Created by Vishwanth Cherlacolu on 12/13/11.
//  Copyright (c) 2011 Mutual Mobile. All rights reserved.
//

#import "UIView+Snapshot.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIView (Snapshot)

- (NSData*)pngSnapshotData {

    UIGraphicsBeginImageContext(self.bounds.size);

    [self.layer renderInContext:UIGraphicsGetCurrentContext()];

    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return UIImagePNGRepresentation(image);
}

@end
