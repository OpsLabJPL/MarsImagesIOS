//
//  Math.swift
//  MarsImagesIOS
//
//  Created by Powell, Mark W (397F) on 8/20/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation

let MAT3_EPSILON:Double = 1e-7

func epsilonEquals(_ a:Double, _ b:Double) -> Bool {
    return fabs(a-b) <= 0.001
}

func isPowerOfTwo(x:Int) -> Bool {
    let exp = log2(Double(x))
    return epsilonEquals(round(exp), exp)
}

func ceilingPowerOfTwo(x:Double) -> Int {
    let y = ceil(log2(x))
    return Int(pow(2.0, y))
}

func floorPowerOfTwo(x:Double) -> Int {
    let y = floor(log2(x))
    return Int(pow(2.0, y))
}

func nextHighestPowerOfTwo(n:Int) -> Int {
    let y = floor(log2(Double(n)))
    return Int(pow(2.0, y + 1))
}

func nextLowestPowerOfTwo(n:Int) -> Int {
    let y = floor(log2(Double(n)))
    return Int(pow(2.0, y - 1))
}

func copy(_ a:[Double], _ b: inout [Double]) {
    b[0] = a[0]
    b[1] = a[1]
    b[2] = a[2]
}

func scale(_ s: Double, _ a:[Double], _ b: inout [Double]) {
    b[0] = s*a[0]
    b[1] = s*a[1]
    b[2] = s*a[2]
}

func add(_ a:[Double], _ b:[Double], _ c: inout [Double]) {
    c[0] = a[0]+b[0]
    c[1] = a[1]+b[1]
    c[2] = a[2]+b[2]
}

func sub(_ a:[Double], _ b:[Double], _ c: inout [Double]) {
    c[0] = a[0]-b[0]
    c[1] = a[1]-b[1]
    c[2] = a[2]-b[2]
    
}

func cross(_ a:[Double], _ b:[Double], _ c: inout [Double]) {
    c[0]  =  a[1] * b[2] - a[2] * b[1]
    c[1]  =  a[2] * b[0] - a[0] * b[2]
    c[2]  =  a[0] * b[1] - a[1] * b[0]
}

func dot(_ a:[Double], _ b:[Double]) -> Double {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
}

func mag(_ a:[Double]) -> Double {
    return sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2])
}

func unit(_ a:[Double], _ b: inout [Double]) {
    let mag = sqrt(a[0] * a[0]  +  a[1] * a[1]  +  a[2] * a[2])
    b[0] = a[0] / mag
    b[1] = a[1] / mag
    b[2] = a[2] / mag
}

func quatva(_ v: [Double], _ a: Double, _ q: inout [Double]) {

    /* Precompute some needed quantities */
    let vmag = sqrt(v[0] * v[0]  +  v[1] * v[1]  +  v[2] * v[2])
    if (vmag < MAT3_EPSILON) {
        return
    }
    let c = cos(a/2)
    let s = sin(a/2)

    /* Construct the quaternion */
    q[0] = c
    q[1] = s * v[0] / vmag
    q[2] = s * v[1] / vmag
    q[3] = s * v[2] / vmag
}

func multqv(_ q:[Double], _ v:[Double], _ u: inout [Double]) {
    /* Perform the multiplication */
    let q0 = q[0]
    let q1 = q[1]
    let q2 = q[2]
    let q3 = q[3]
    let q0q0 = q0 * q0
    let q0q1 = q0 * q1
    let q0q2 = q0 * q2
    let q0q3 = q0 * q3
    let q1q1 = q1 * q1
    let q1q2 = q1 * q2
    let q1q3 = q1 * q3
    let q2q2 = q2 * q2
    let q2q3 = q2 * q3
    let q3q3 = q3 * q3
    u[0] = v[0]*(q0q0+q1q1-q2q2-q3q3) + 2*v[1]*(q1q2-q0q3) + 2*v[2]*(q0q2+q1q3)
    u[1] = 2*v[0]*(q0q3+q1q2) + v[1]*(q0q0-q1q1+q2q2-q3q3) + 2*v[2]*(q2q3-q0q1)
    u[2] = 2*v[0]*(q1q3-q0q2) + 2*v[1]*(q0q1+q2q3) + v[2]*(q0q0-q1q1-q2q2+q3q3)
}

/*
 * Convert spherical coordinates to cartesian.
 * The azimuth will range between 0 to 2*PI, measured from the positive x axis,
 * increasing towards the positive y axis.
 * The declination will range between 0 and PI, measured from the positive Z axis
 * (assumed to be down), increasing towards the xy plane.
 */
func sphericalToCartesian(_ az: Double, _ dec: Double, _ radius: Double, _ xyz: inout [Double]) {
    let rsinDec = radius * sin(dec)
    xyz[0] = rsinDec * cos(az)
    xyz[1] = rsinDec * sin(az)
    xyz[2] = radius * cos(dec)
}

func cartesianToSpherical(_ xyz: [Double], _ azDecR: inout [Double]) {
    let x = xyz[0]
    let y = xyz[1]
    let z = xyz[2]
    let radius = sqrt(x * x + y * y + z * z)
    let dec = acos(z / radius)
    var az = atan2(y, x)
    if az < 0 {
        az += 2*Double.pi
    }
    azDecR[0] = az
    azDecR[1] = dec
    azDecR[2] = radius
}
