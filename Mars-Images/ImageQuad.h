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
    BOOL isVisible;
}

@property (nonatomic, assign, readwrite) GLKVector3 center;
@property (nonatomic, assign, readwrite) GLfloat boundingSphereRadius;

@property (nonatomic, assign, readwrite) GLKVector3 v1;
@property (nonatomic, assign, readwrite) GLKVector3 v2;
@property (nonatomic, assign, readwrite) GLKVector3 v3;
@property (nonatomic, assign, readwrite) GLKVector3 v4;

@property (nonatomic, assign) BOOL isVisible;

- (id)initWithModel:(id<Model>)model
             origin:(NSArray*)origin
                qLL:(Quaternion*)qLL;

- (GLfloat*) getImageVertices: (id<Model>) model
                       origin: (NSArray*) origin
                          qLL: (Quaternion*)qLL
                     vertices: (GLfloat*) vertices;

@end