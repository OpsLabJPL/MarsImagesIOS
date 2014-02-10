//
//  Model.h
//  Mars-Images
//
//  Created by Mark Powell on 2/4/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Model <NSObject>

- (double) xdim;
- (double) ydim;

- (void) cmod_2d_to_3d: (const double[]) pos2
                  pos3: (double[]) pos3
                 uvec3: (double[]) uvec3;

@end
