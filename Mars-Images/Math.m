//
//  Math.m
//  Mars-Images
//
//  Created by Mark Powell on 2/3/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import "Math.h"

@implementation Math

#ifndef MAT3_EPSILON
#define MAT3_EPSILON (1e-7)
#endif

+ (BOOL) epsilonEquals:(double)a b:(double)b {
    return fabs(a-b) <= 0.001;
}

+ (BOOL) isPowerOfTwo: (int) x {
    return !(x == 0) && !(x & (x - 1));
}

+ (int) ceilingPowerOfTwo: (double) x {
    double y = ceil(log2(x));
    return (int)pow(2, y);
}

+ (int) floorPowerOfTwo: (double) x {
    double y = floor(log2(x));
    return (int)pow(2, y);
}

+ (int) nextHighestPowerOfTwo: (int) n {
    double y = floor(log2(n));
    return (int)pow(2, y + 1);
}

+ (int) nextLowestPowerOfTwo: (int) n {
    double y = floor(log2(n));
    return (int)pow(2, y - 1);
}

+ (void) copy: (const double[3]) a
    toB: (double[3]) b {
    b[0] = a[0];
    b[1] = a[1];
    b[2] = a[2];
}

+ (void) scale: (const double) s
             a: (const double[3]) a
           toB: (double[3])b {
    b[0] = s*a[0];
    b[1] = s*a[1];
    b[2] = s*a[2];
}

+ (void) add: (const double[3]) a
           b: (const double[3]) b
         toC: (double[3])c {
    c[0] = a[0]+b[0];
    c[1] = a[1]+b[1];
    c[2] = a[2]+b[2];
}

+ (void) sub: (const double[3]) a
           b: (const double[3]) b
         toC: (double[3])c {
    c[0] = a[0]-b[0];
    c[1] = a[1]-b[1];
    c[2] = a[2]-b[2];
}

+ (void) cross: (const double[3]) a
             b: (const double[3]) b
           toC: (double[3]) c {
    
    c[0]  =  a[1] * b[2] - a[2] * b[1];
    c[1]  =  a[2] * b[0] - a[0] * b[2];
    c[2]  =  a[0] * b[1] - a[1] * b[0];
}

+ (double) dot: (const double[3]) a
             b: (const double[3]) b {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

+ (double) mag: (const double[3]) a {
    return sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2]);
}

+ (void) unit: (const double[3]) a
          toB: (double[3]) b {
    double mag = sqrt(a[0] * a[0]  +  a[1] * a[1]  +  a[2] * a[2]);
    b[0] = a[0] / mag;
    b[1] = a[1] / mag;
    b[2] = a[2] / mag;
}

+ (void) quatva: (const double[3]) v
              a: (const double) a
            toQ: (double[4]) q {
    double c;
    double s;
    double vmag;
    
    /* Precompute some needed quantities */
    vmag = sqrt(v[0] * v[0]  +  v[1] * v[1]  +  v[2] * v[2]);
    if (vmag < MAT3_EPSILON) {
        return;
	}
    c = cos(a/2);
    s = sin(a/2);
    
    /* Construct the quaternion */
    q[0] = c;
    q[1] = s * v[0] / vmag;
    q[2] = s * v[1] / vmag;
    q[3] = s * v[2] / vmag;
}

+ (void) multqv: (const double[4]) q
              v: (const double[3]) v
            toU: (double[3]) u {
    double q0;
    double q1;
    double q2;
    double q3;
    double q0q0;
    double q0q1;
    double q0q2;
    double q0q3;
    double q1q1;
    double q1q2;
    double q1q3;
    double q2q2;
    double q2q3;
    double q3q3;
    
    /* Perform the multiplication */
    q0 = q[0];
    q1 = q[1];
    q2 = q[2];
    q3 = q[3];
    q0q0 = q0 * q0;
    q0q1 = q0 * q1;
    q0q2 = q0 * q2;
    q0q3 = q0 * q3;
    q1q1 = q1 * q1;
    q1q2 = q1 * q2;
    q1q3 = q1 * q3;
    q2q2 = q2 * q2;
    q2q3 = q2 * q3;
    q3q3 = q3 * q3;
    u[0] = v[0]*(q0q0+q1q1-q2q2-q3q3) + 2*v[1]*(q1q2-q0q3) + 2*v[2]*(q0q2+q1q3);
    u[1] = 2*v[0]*(q0q3+q1q2) + v[1]*(q0q0-q1q1+q2q2-q3q3) + 2*v[2]*(q2q3-q0q1);
    u[2] = 2*v[0]*(q1q3-q0q2) + 2*v[1]*(q0q1+q2q3) + v[2]*(q0q0-q1q1-q2q2+q3q3);
}

/*
 * Convert spherical coordinates to cartesian.
 * The azimuth will range between 0 to 2*PI, measured from the positive x axis, 
 * increasing towards the positive y axis. 
 * The declination will range between 0 and PI, measured from the positive Z axis 
 * (assumed to be down), increasing towards the xy plane.
 */
+ (void) sphericalToCartesian: (double)az
                          dec: (double)dec
                       radius: (double)radius
                          xyz: (double[])xyz {
    double rsinDec = radius * sin(dec);
    xyz[0] = rsinDec * cos(az);
    xyz[1] = rsinDec * sin(az);
    xyz[2] = radius * cos(dec);
}

+ (void) cartesianToSpherical:(const double[]) xyz
                       azDecR:(double[]) azDecR {
    double x = xyz[0], y = xyz[1], z = xyz[2];
    double radius = sqrt(x * x + y * y + z * z);
    double dec = acos(z / radius);
    double az = atan2(y, x);
    if (az < 0) az += 2*M_PI;
    azDecR[0] = az;
    azDecR[1] = dec;
    azDecR[2] = radius;
}

@end
