//
//  CAHVOR.m
//  Mars-Images
//
//  Created by Mark Powell on 2/3/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import "CAHVOR.h"
#import "Math.h"

@implementation CAHVOR

enum {
    MAXITER = 20	/* maximum number of iterations allowed */
};

#ifndef EPSILON
#define EPSILON (1e-15)
#endif

#define	PI (3.14159265358979323846)

#define CONV   (1.0e-8)	/* covergence tolerance */

- (void) setO:(double)x y:(double)y z:(double)z {
    o[0] = x;
    o[1] = y;
    o[2] = z;
}

- (void) setR:(double)x y:(double)y z:(double)z {
    r[0] = x;
    r[1] = y;
    r[2] = z;
}

- (void) cmod_2d_to_3d: (const double[]) pos2
                  pos3: (double[]) pos3
                 uvec3: (double[]) uvec3 {
    int i;
    double deriv;
    double du;
    double f[3];
    double g[3];
    double k1;
    double k3;
    double k5;
    double lambda[3];
    double magi;
    double magv;
    double mu;
    double omega;
    double omega_2;
    double poly;
    double pp[3];
    double rr[3];
    double sgn;
    double t[3];
    double tau;
    double u;
    double u_2;
    double wo[3];
    
    /* The projection point is merely the C of the camera model. */
    [Math copy:c toB:pos3];
    
    /* Calculate the projection ray assuming normal vector directions, */
    /* neglecting distortion.                                          */
    [Math scale:pos2[1] a:a toB:f];
    [Math sub:v b:f toC:f];
    [Math scale:pos2[0] a:a toB:g];
    [Math sub:h b:g toC:g];
    [Math cross:f b:g toC:rr];
    magi = [Math mag:rr];
    magi = 1.0/magi;
    [Math scale:magi a:rr toB:rr];
    
    /* Check and optionally correct for vector directions. */
    sgn = 1;
    [Math cross:v b:h toC:t];
    if ([Math dot:t b:a] < 0) {
        [Math scale:-1.0 a:rr toB:rr];
        sgn = -1;
	}
    
    /* Remove the radial lens distortion.  Preliminary values of omega,  */
    /* lambda, and tau are computed from the rr vector including         */
    /* distortion, in order to obtain the coefficients of the equation   */
    /* k5*u^5 + k3*u^3 + k1*u = 1, which is solved for u by means of     */
    /* Newton's method.  This value is used to compute the corrected rr. */
    omega = [Math dot:rr b:o];
    omega_2 = omega * omega;
    [Math scale:omega a:o toB:wo];
    [Math sub:rr b:wo toC:lambda];
    tau = [Math dot:lambda b:lambda] / omega_2;
    k1 = 1 + r[0];		/*  1 + rho0 */
    k3 = r[1] * tau;		/*  rho1*tau  */
    k5 = r[2] * tau*tau;	/*  rho2*tau^2  */
    mu = r[0] + k3 + k5;
    u = 1.0 - mu;	/* initial approximation for iterations */
    for (i=0; i<MAXITER; i++) {
        u_2 = u*u;
        poly  =  ((k5*u_2  +  k3)*u_2 + k1)*u - 1;
        deriv = (5*k5*u_2 + 3*k3)*u_2 + k1;
        if (deriv <= EPSILON) {
            break;
	    }
        else {
            du = poly/deriv;
            u -= du;
            if (fabs(du) < CONV) {
                break;
            }
	    }
	}
    mu = 1 - u;
    [Math scale:mu a:lambda toB:pp];
    [Math sub:rr b:pp toC:uvec3];
    magv = [Math mag:uvec3];

    [Math scale:1.0/magv a:uvec3 toB:uvec3];
}

@end
