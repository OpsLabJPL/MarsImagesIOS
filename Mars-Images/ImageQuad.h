//
//  ImageQuad.h
//  Mars-Images
//
//  Created by Mark Powell on 10/30/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import "SceneMesh.h"
#import "Model.h"
#import "Quaternion.h"

@interface ImageQuad : SceneMesh
{
    GLKVector3 center;
    GLfloat boundingSphereRadius;
    GLKVector3 v1;
    GLKVector3 v2;
    GLKVector3 v3;
    GLKVector3 v4;
    NSString* imageId;
}

@property (nonatomic, assign, readwrite) GLKVector3 center;
@property (nonatomic, assign, readwrite) GLfloat boundingSphereRadius;

@property (nonatomic, assign, readwrite) GLKVector3 v1;
@property (nonatomic, assign, readwrite) GLKVector3 v2;
@property (nonatomic, assign, readwrite) GLKVector3 v3;
@property (nonatomic, assign, readwrite) GLKVector3 v4;

@property (nonatomic, strong) NSString* imageId;
@property (nonatomic, strong) NSString* cameraId;
@property (nonatomic, assign) int textureSize;
@property (nonatomic, assign) int layer;

- (id)initWithModel:(id<Model>)model
                qLL:(Quaternion*)qLL
            imageID:(NSString*)imageID;

- (float) cameraFOVRadians;

+ (GLfloat*) getImageVertices: (id<Model>) model
                          qLL: (Quaternion*)qLL
                     vertices: (GLfloat*) vertices
                     distance: (float) distance;

@end