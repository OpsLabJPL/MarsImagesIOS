//
//  Math.h
//  Mars-Images
//
//  Created by Mark Powell on 2/3/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Math : NSObject

#define X_AXIS {1.0, 0.0, 0.0}
#define Y_AXIS {0.0, 1.0, 0.0}
#define Z_AXIS {0.0, 0.0, 1.0}
#define NEG_Z_AXIS {0.0, 0.0, -1.0}

+ (BOOL) epsilonEquals:(double)a b:(double)b;
+ (int) nextHighestPowerOfTwo: (int) n;
+ (int) nextLowestPowerOfTwo: (int) n;
+ (BOOL) isPowerOfTwo: (int) x;
+ (int) ceilingPowerOfTwo: (double) x;
+ (int) floorPowerOfTwo: (double) x;

+ (void) copy: (const double[3]) a
           toB: (double[3]) b;

+ (void) scale: (const double) s
             a: (const double[3]) a
           toB: (double[3])b;

+ (void) sub: (const double[3]) a
           b: (const double[3]) b
         toC: (double[3])c;

+ (void) cross: (const double[3]) a
             b: (const double[3]) b
           toC: (double[3]) c;

+ (double) dot: (const double[3]) a
             b: (const double[3]) b;

+ (double) mag: (const double[3]) a;

+ (void) add: (const double[3]) a
           b: (const double[3]) b
         toC: (double[3]) c;

+ (void) unit: (const double[3]) a
          toB: (double[3]) b;

+ (void) quatva: (const double[3]) v	/* input vector */
              a: (const double) a		/* input angle of rotation */
            toQ: (double[4]) q;         /* output quaternion */

+ (void) multqv: (const double[4]) q    /* input rotation quaternion */
              v: (const double[3]) v	/* input vector */
            toU: (double[3]) u;         /* output vector */

+ (void) sphericalToCartesian: (double)az
                          dec: (double)dec
                       radius: (double)radius
                          xyz: (double[])xyz;

+ (void) cartesianToSpherical:(const double[]) xyz
                       azDecR:(double[]) azDecR;

@end
