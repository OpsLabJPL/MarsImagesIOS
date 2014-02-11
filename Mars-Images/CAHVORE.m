//
//  CAHVORE.m
//  Mars-Images
//
//  Created by Mark Powell on 2/3/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import "CAHVORE.h"
#import "Math.h"

@implementation CAHVORE

enum {
    MAX_NEWTON = 100
};

#ifndef EPSILON
#define EPSILON (1e-15)
#endif


- (void) setE:(double)x y:(double)y z:(double)z {
    e[0] = x;
    e[1] = y;
    e[2] = z;
}

- (void) setT: (double)type {
    t = type;
}

- (void) setP: (double)param {
    p = param;
}

- (void) cmod_2d_to_3d: (const double[]) pos2
                  pos3: (double[]) pos3
                 uvec3: (double[]) uvec3 {
    double avh1;
    double chi;
    double chi2;
    double chi3;
    double chi4;
    double chi5;
    double chip;
    double cp[3];
    double lambdap;
    double lambdap3[3];
    double linchi;
    double ri[3];
    double rp[3];
    double theta;
    double theta2;
    double theta3;
    double theta4;
    double u3[3];
    double v3[3];
    double w3[3];
    double zetap;
    double linearity = 0;
    
    /* In the following there is a mixture of nomenclature from several */
    /* versions of Gennery's write-ups and Litwin's software. Beware!   */
    
    chi = 0;
    chi3 = 0;
    theta = 0;
    theta2 = 0;
    theta3 = 0;
    theta4 = 0;
    
    /* Calculate initial terms */
    
    [Math scale:pos2[1] a:a toB:u3];
    [Math sub:v b:u3 toC:u3];
    [Math scale:pos2[0] a:a toB:v3];
    [Math sub:h b:v3 toC:v3];
    [Math cross:u3 b:v3 toC:w3];
    [Math cross:v b:h toC:u3];
    avh1 = [Math dot:a b:u3];
    avh1 = 1/avh1;
    [Math scale:avh1 a:w3 toB:rp];
    
    zetap = [Math dot:rp b:o];
    
    [Math scale:zetap a:o toB:u3];
    [Math sub:rp b:u3 toC:lambdap3];
    
    lambdap = [Math mag:lambdap3];
    
    chip = lambdap / zetap;
    
    /* Approximations for small angles */
    if (chip < 1e-8) {
        [Math copy:c toB:cp];
        [Math copy:o toB:ri];
	}
    
    /* Full calculations */
    else {
        int n;
        double dchi;
        double s;
        
        /* Calculate chi using Newton's Method */
        n = 0;
        chi = chip;
        dchi = 1;
        for (;;) {
            double deriv;
            
            /* Make sure we don't iterate forever */
            if (++n > MAX_NEWTON) {
                break;
            }
            
            /* Compute terms from the current value of chi */
            chi2 = chi * chi;
            chi3 = chi * chi2;
            chi4 = chi * chi3;
            chi5 = chi * chi4;
            
            /* Check exit criterion from last update */
            if (fabs(dchi) < 1e-8) {
                break;
            }
            
            /* Update chi */
            deriv = (1 + r[0]) + 3*r[1]*chi2 + 5*r[2]*chi4;
            dchi = ((1 + r[0])*chi + r[1]*chi3 + r[2]*chi5 - chip) / deriv;
            chi -= dchi;
	    }
        
        /* Compute the incoming ray's angle */
        linchi = linearity * chi;
        theta = chi;
        
        theta2 = theta * theta;
        theta3 = theta * theta2;
        theta4 = theta * theta3;
        
        /* Compute the shift of the entrance pupil */
        s = sin(theta);
        s = (theta/s - 1) * (e[0] + e[1]*theta2 + e[2]*theta4);
        
        /* The position of the entrance pupil */
        [Math scale:s a:o toB:cp];
        [Math add:c b:cp toC:cp];
        
        /* The unit vector along the ray */
        [Math unit:lambdap3 toB:u3];
        [Math scale:sin(theta) a:u3 toB:u3];
        [Math scale:cos(theta) a:o toB:v3];
        [Math add:u3 b:v3 toC:ri];
	}
    
    [Math copy:cp toB:pos3];
    [Math copy:ri toB:uvec3];
}

@end
