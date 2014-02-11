//
//  CAHVORE.h
//  Mars-Images
//
//  Created by Mark Powell on 2/3/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import "CAHVOR.h"
#import "Model.h"

@interface CAHVORE : CAHVOR<Model>
{
    double e[3];
    double t;
    double p;
}

- (void) setE:(double)x y:(double)y z:(double)z;
- (void) setT: (double)type;
- (void) setP: (double)param;

- (void) cmod_2d_to_3d: (const double[]) pos2
                  pos3: (double[]) pos3
                 uvec3: (double[]) uvec3;
@end
