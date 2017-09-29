//
//  CAHVOR.swift
//  MarsImagesIOS
//
//  Created by Powell, Mark W (397F) on 8/20/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation

class CAHVOR : CAHV {
    
    
    let MAXITER = 20	// maximum number of iterations allowed
    let EPSILON = 1e-15
    let CONV    = 1.0e-8	// covergence tolerance

    var o:[Double] = []
    var r:[Double] = []

    override func cmod_2d_to_3d(pos2: [Double], pos3: inout [Double], uvec3: inout [Double]) {
        var deriv = 0.0
        var du = 0.0
        var f = [0.0, 0.0, 0.0]
        var g = [0.0, 0.0, 0.0]
        var k1 = 0.0
        var k3 = 0.0
        var k5 = 0.0
        var lambda = [0.0, 0.0, 0.0]
        var magi = 0.0
        var magv = 0.0
        var mu = 0.0
        var omega = 0.0
        var omega_2 = 0.0
        var poly = 0.0
        var pp = [0.0, 0.0, 0.0]
        var rr = [0.0, 0.0, 0.0]
//        var t = [0.0, 0.0, 0.0]
        var tau = 0.0
        var u = 0.0
        var u_2 = 0.0
        var wo = [0.0, 0.0, 0.0]
        
        /* The projection point is merely the C of the camera model. */
        copy(c, &pos3)
        
        /* Calculate the projection ray assuming normal vector directions, */
        /* neglecting distortion.                                          */
        scale(pos2[1], a, &f)
        sub(v, f, &f)
        scale(pos2[0], a, &g)
        sub(h, g, &g)
        cross(f, g, &rr)
        magi = mag(rr)
        magi = 1.0/magi
        scale(magi, rr, &rr)
        
        /* Check and optionally correct for vector directions. */
//        sgn = 1
//        cross(v, h, &t)
//        if dot(t, a) < 0 {
//            scale(-1.0, rr, &rr)
//            sgn = -1
//        }
        
        /* Remove the radial lens distortion.  Preliminary values of omega,  */
        /* lambda, and tau are computed from the rr vector including         */
        /* distortion, in order to obtain the coefficients of the equation   */
        /* k5*u^5 + k3*u^3 + k1*u = 1, which is solved for u by means of     */
        /* Newton's method.  This value is used to compute the corrected rr. */
        omega = dot(r, o)
        omega_2 = omega * omega
        scale(omega, o, &wo)
        sub(rr, wo, &lambda)
        tau = dot(lambda, lambda) / omega_2
        k1 = 1 + r[0]		/*  1 + rho0 */
        k3 = r[1] * tau		/*  rho1*tau  */
        k5 = r[2] * tau*tau	/*  rho2*tau^2  */
        mu = r[0] + k3 + k5
        u = 1.0 - mu	/* initial approximation for iterations */
        for _ in 0..<MAXITER {
            u_2 = u*u
            poly  =  ((k5*u_2  +  k3)*u_2 + k1)*u - 1
            deriv = (5*k5*u_2 + 3*k3)*u_2 + k1
            if deriv <= EPSILON {
                break
            }
            else {
                du = poly/deriv
                u -= du
                if fabs(du) < CONV {
                    break
                }
            }
        }
        mu = 1 - u
        scale(mu, lambda, &pp)
        sub(rr, pp, &uvec3)
        magv = mag(uvec3)
        
        scale(1.0/magv, uvec3, &uvec3)
    }
    
    override func cmod_3d_to_2d(pos3: [Double], range: inout [Double], pos2: inout [Double]) {
        var alpha = 0.0
        var beta = 0.0
        var gamma = 0.0
        var omega = 0.0
        var omega_2 = 0.0
        var tau = 0.0
        var mu = 0.0
        var p_c = [0.0, 0.0, 0.0]
        var pp = [0.0, 0.0, 0.0]
        var pp_c = [0.0, 0.0, 0.0]
        var wo = [0.0, 0.0, 0.0]
        var lambda = [0.0, 0.0, 0.0];
        
        /* Calculate p' and other necessary quantities */
        sub(pos3, c, &p_c)
        omega = dot(p_c, o)
        omega_2 = omega * omega
        scale(omega, o, &wo)
        sub(p_c, wo, &lambda)
        tau = dot(lambda, lambda) / omega_2;
        mu = r[0] + (r[1] * tau) + (r[2] * tau * tau);
        scale(mu, lambda, &pp)
        add(pos3, pp, &pp)
        
        /* Calculate alpha, beta, gamma, which are (p' - c) */
        /* dotted with a, h, v, respectively                */
        sub(pp, c, &pp_c)
        alpha  = dot(pp_c, a)
        beta   = dot(pp_c, h)
        gamma  = dot(pp_c, v)
        
        /* Calculate the projection */
        pos2[0] = beta  / alpha; //xh
        pos2[1] = gamma / alpha; //yh
        range[0] = alpha;
    }
}
