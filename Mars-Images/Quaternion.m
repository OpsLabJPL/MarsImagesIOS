//
//  Quaternion.m
//  Mars-Images
//
//  Created by Mark Powell on 5/21/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import "Quaternion.h"

@implementation Quaternion

- (NSString *)description {
    return [NSString stringWithFormat: @"%f %f %f %f", _w, _x, _y, _z];
}

@end
