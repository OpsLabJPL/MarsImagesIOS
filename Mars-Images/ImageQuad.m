//
//  ImageQuad.m
//  Mars-Images
//
//  Created by Mark Powell on 10/30/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageQuad.h"
#import "MarsImageNotebook.h"
#import "MarsRover.h"
#import "Math.h"

@implementation ImageQuad

@synthesize v1;
@synthesize v2;
@synthesize v3;
@synthesize v4;
@synthesize center;
@synthesize boundingSphereRadius;
@synthesize imageId;

static const double x_axis[] = X_AXIS;
static const double z_axis[] = Z_AXIS;
static const int numberOfPositions = 4;
static const float textureCoords[] = {0.f, 1.f, 1.f, 1.f, 1.f, 0.f, 0.f, 0.f};


- (id)initWithModel:(id<Model>)model
             origin:(NSArray*)origin
                qLL:(Quaternion*)qLL
                 imageID:(NSString*)imageID {
    
    GLfloat *vertPointer = malloc(sizeof(GLfloat)*12);
    NSString* cameraId = [[MarsImageNotebook instance].mission getCameraId:imageID];
    BOOL topLayer = [[MarsImageNotebook instance].mission isTopLayer:cameraId];
    
    [ImageQuad getImageVertices:model origin:origin qLL:qLL vertices:vertPointer distance:(topLayer) ? 5 : 10];

    if (nil != (self = [super initWithPositionCoords:vertPointer
                                          texCoords0:textureCoords
                                   numberOfPositions:numberOfPositions])) {
        v1.x = vertPointer[0];
        v1.y = vertPointer[1];
        v1.z = vertPointer[2];
        v2.x = vertPointer[3];
        v2.y = vertPointer[4];
        v2.z = vertPointer[5];
        v3.x = vertPointer[6];
        v3.y = vertPointer[7];
        v3.z = vertPointer[8];
        v4.x = vertPointer[9];
        v4.y = vertPointer[10];
        v4.z = vertPointer[11];
        
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

        self.imageId = imageID;
        self.cameraId = cameraId;
        self.isTopLayer = topLayer;
    }
    
    free(vertPointer);

    return self;
}

- (float) cameraFOVRadians {
    return [[MarsImageNotebook instance].mission getCameraFOV:self.cameraId];
}

- (GLfloat) distanceBetween:(const GLKVector3)pt1 b:(const GLKVector3)pt2 {
    float dx = pt1.x-pt2.x;
    float dy = pt1.y-pt2.y;
    float dz = pt1.z-pt2.z;
    return (GLfloat)sqrt(dx*dx+dy*dy+dz*dz);
}

+ (GLfloat*) getImageVertices: (id<Model>) model
                       origin: (NSArray*) origin
                          qLL: (Quaternion*)qLL
                     vertices: (GLfloat*) vertices
                     distance: (float) distance {
    
    id<MarsRover> mission = [MarsImageNotebook instance].mission;
    double eye[] = {[mission mastX], [mission mastY], [mission mastZ]};
    double pos[2], pos3[3], vec3[3];
    double pos3LL[3], pinitial[3], pfinal[3];
    double xrotq[4];
    [Math quatva:x_axis a:M_PI_2 toQ:xrotq];
    double zrotq[4];
    [Math quatva:z_axis a:-M_PI_2 toQ:zrotq];
    double llRotq[4];
    
    llRotq[0] = qLL.w;
    llRotq[1] = qLL.x;
    llRotq[2] = qLL.y;
    llRotq[3] = qLL.z;
    
    double originX = ((NSNumber*)[origin objectAtIndex:0]).doubleValue;
    double originY = ((NSNumber*)[origin objectAtIndex:1]).doubleValue;
    pos[0] = originX;
    pos[1] = [model ydim];
    [model cmod_2d_to_3d:pos pos3:pos3 uvec3:vec3];
    pos3[0] -= eye[0];
    pos3[1] -= eye[1];
    pos3[2] -= eye[2];
    pos3[0] += vec3[0]*distance;
    pos3[1] += vec3[1]*distance;
    pos3[2] += vec3[2]*distance;
    [Math multqv:llRotq v:pos3 toU:pos3LL];
    [Math multqv:zrotq v:pos3LL toU:pinitial];
    [Math multqv:xrotq v:pinitial toU:pfinal];
    vertices[0] = (float)pfinal[0];
    vertices[1] = (float)pfinal[1];
    vertices[2] = (float)pfinal[2];
    //    NSLog(@"vertex: %g %g %g", vertices[0], vertices[1], vertices[2]);
    
    pos[0] = [model xdim];
    pos[1] = [model ydim];
    [model cmod_2d_to_3d:pos pos3:pos3 uvec3:vec3];
    pos3[0] -= eye[0];
    pos3[1] -= eye[1];
    pos3[2] -= eye[2];
    pos3[0] += vec3[0]*distance;
    pos3[1] += vec3[1]*distance;
    pos3[2] += vec3[2]*distance;
    [Math multqv:llRotq v:pos3 toU:pos3LL];
    [Math multqv:zrotq v:pos3LL toU:pinitial];
    [Math multqv:xrotq v:pinitial toU:pfinal];
    vertices[3] = (float)pfinal[0];
    vertices[4] = (float)pfinal[1];
    vertices[5] = (float)pfinal[2];
    //    NSLog(@"vertex: %g %g %g", vertices[3], vertices[4], vertices[5]);
    
    pos[0] = [model xdim];
    pos[1] = originY;
    [model cmod_2d_to_3d:pos pos3:pos3 uvec3:vec3];
    pos3[0] -= eye[0];
    pos3[1] -= eye[1];
    pos3[2] -= eye[2];
    pos3[0] += vec3[0]*distance;
    pos3[1] += vec3[1]*distance;
    pos3[2] += vec3[2]*distance;
    [Math multqv:llRotq v:pos3 toU:pos3LL];
    [Math multqv:zrotq v:pos3LL toU:pinitial];
    [Math multqv:xrotq v:pinitial toU:pfinal];
    vertices[6] = (float)pfinal[0];
    vertices[7] = (float)pfinal[1];
    vertices[8] = (float)pfinal[2];
    //    NSLog(@"vertex: %g %g %g", vertices[6], vertices[7], vertices[8]);
    
    pos[0] = originX;
    pos[1] = originY;
    [model cmod_2d_to_3d:pos pos3:pos3 uvec3:vec3];
    pos3[0] -= eye[0];
    pos3[1] -= eye[1];
    pos3[2] -= eye[2];
    pos3[0] += vec3[0]*distance;
    pos3[1] += vec3[1]*distance;
    pos3[2] += vec3[2]*distance;
    [Math multqv:llRotq v:pos3 toU:pos3LL];
    [Math multqv:zrotq v:pos3LL toU:pinitial];
    [Math multqv:xrotq v:pinitial toU:pfinal];
    vertices[9] = (float)pfinal[0];
    vertices[10] = (float)pfinal[1];
    vertices[11] = (float)pfinal[2];
    //    NSLog(@"vertex: %g %g %g", vertices[9], vertices[10], vertices[11]);
    return vertices;
}


@end
