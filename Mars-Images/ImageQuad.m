//
//  ImageQuad.m
//  Mars-Images
//
//  Created by Mark Powell on 10/30/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageQuad.h"

@implementation ImageQuad

@synthesize v1;
@synthesize v2;
@synthesize v3;
@synthesize v4;
@synthesize center;
@synthesize boundingSphereRadius;

- (id)initWithPositionCoords:(const GLfloat *)somePositions
                  texCoords0:(const GLfloat *)someTexCoords0
           numberOfPositions:(size_t)countPositions {
    if (nil != (self = [super initWithPositionCoords:somePositions texCoords0:someTexCoords0 numberOfPositions:countPositions])) {
        v1.x = somePositions[0];
        v1.y = somePositions[1];
        v1.z = somePositions[2];
        v2.x = somePositions[3];
        v2.y = somePositions[4];
        v2.z = somePositions[5];
        v3.x = somePositions[6];
        v3.y = somePositions[7];
        v3.z = somePositions[8];
        v4.x = somePositions[9];
        v4.y = somePositions[10];
        v4.z = somePositions[11];
        
        center.x = (v1.x+v3.x)/2;
        center.y = (v1.y+v3.y)/2;
        center.z = (v1.z+v3.z)/2;
        
        //assign to the radius the distance from the center to the farthest vertex
        GLfloat d1 = [self distanceBetween:center b:v1];
        GLfloat d2 = [self distanceBetween:center b:v2];
        GLfloat d3 = [self distanceBetween:center b:v3];
        GLfloat d4 = [self distanceBetween:center b:v4];
        boundingSphereRadius = d1;
        if (d2>boundingSphereRadius) boundingSphereRadius=d2;
        if (d3>boundingSphereRadius) boundingSphereRadius=d3;
        if (d4>boundingSphereRadius) boundingSphereRadius=d4;
    }
    
    return self;
}

- (GLfloat) distanceBetween:(const GLKVector3)pt1 b:(const GLKVector3)pt2 {
    float dx = pt1.x-pt2.x;
    float dy = pt1.y-pt2.y;
    float dz = pt1.z-pt2.z;
    return (GLfloat)sqrt(dx*dx+dy*dy+dz*dz);
}

@end
