//
//  CAHV.h
//  Mars-Images
//
//  Created by Mark Powell on 2/3/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

@interface CAHV : NSObject<Model>
{
    int xdim;
    int ydim;
    double c[3];
    double a[3];
    double h[3];
    double v[3];
}

- (double) xdim;
- (double) ydim;
- (void) setXdim: (int)width;
- (void) setYdim: (int)height;

- (void) setC:(double)x y:(double)y z:(double)z;
- (void) setA:(double)x y:(double)y z:(double)z;
- (void) setH:(double)x y:(double)y z:(double)z;
- (void) setV:(double)x y:(double)y z:(double)z;

- (void) cmod_2d_to_3d: (const double[]) pos2
                  pos3: (double[]) pos3
                 uvec3: (double[]) uvec3;
@end
