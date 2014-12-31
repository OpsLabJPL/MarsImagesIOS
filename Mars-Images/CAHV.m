//
//  CAHV.m
//  Mars-Images
//
//  Created by Mark Powell on 2/3/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import "CAHV.h"
#import "Math.h"

@implementation CAHV


- (NSArray*) size {
    return [[NSArray alloc] initWithObjects:[NSNumber numberWithDouble:xdim], [NSNumber numberWithDouble:ydim], nil];
}

- (double) xdim {
    return xdim;
}

- (double) ydim {
    return ydim;
}

- (void) setXdim: (int)width {
    xdim = width;
}

- (void) setYdim: (int)height {
    ydim = height;
}

- (void) setC:(double)x y:(double)y z:(double)z {
    c[0] = x;
    c[1] = y;
    c[2] = z;
}

- (void) setA:(double)x y:(double)y z:(double)z {
    a[0] = x;
    a[1] = y;
    a[2] = z;
}

- (void) setH:(double)x y:(double)y z:(double)z {
    h[0] = x;
    h[1] = y;
    h[2] = z;
}

- (void) setV:(double)x y:(double)y z:(double)z {
    v[0] = x;
    v[1] = y;
    v[2] = z;
}

- (void) cmod_2d_to_3d: (const double[]) pos2
                  pos3: (double[]) pos3
                 uvec3: (double[]) uvec3 {
    double f[3];
    double g[3];
    double magi;
    double sgn;
    double t[3];
    
    /* The projection point is merely the C of the camera model */
    [Math copy:c toB:pos3];
    
    /* Calculate the projection ray assuming normal vector directions */
    [Math scale:pos2[1] a:a toB:f];
    [Math sub:v b:f toC:f];
    [Math scale:pos2[0] a:a toB:g];
    [Math sub:h b:g toC:g];
    [Math cross:f b:g toC:uvec3];
    magi = [Math mag:uvec3];
    magi = 1.0/magi;
    [Math scale:magi a:uvec3 toB:uvec3];
    
    /* Check and optionally correct for vector directions */
    sgn = 1;
    [Math cross:v b:h toC:t];
    if ([Math dot:t b:a] < 0) {
        [Math scale:-1.0 a:uvec3 toB:uvec3];
        sgn = -1;
	}
}

- (void) cmod_3d_to_2d: (const double[]) pos3
                 range: (double[]) range
                  pos2: (double[]) pos2 {
    
    double d[3];
    double r_1;
    
    /* Calculate the projection */
    [Math sub:pos3 b:c toC:d];
    range[0] = [Math dot:d b:a];
    r_1 = 1.0 / range[0];
    pos2[0] = [Math dot:d b:h] * r_1;
    pos2[1] = [Math dot:d b:v] * r_1;
}

@end
