//
//  MarsScene.h
//  Mars-Images
//
//  Created by Mark Powell on 2/5/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "AGLKContext.h"
#import "Model.h"
#import "MWPhoto.h"
#import "Quaternion.h"
#import "SceneMesh.h"

@interface MarsScene : NSObject
{
//    GLuint vertexBufferID;
    int site_index;
    int drive_index;
    Quaternion* qLL;
}

@property (strong, nonatomic) NSArray* rmc;
@property (strong, nonatomic) NSMutableDictionary* photoQuads;
@property (strong, nonatomic) NSMutableDictionary* photoTextures;
@property (strong, nonatomic) GLKTextureInfo* compassTextureInfo;
@property (strong, nonatomic) SceneMesh* compassQuad;
@property (strong, nonatomic) UIViewController* viewController;

- (void) notesLoaded: (NSNotification*) notification;

- (void) addImagesToScene: (NSArray*) rmc;

- (void) deleteImages;

- (void) drawImages: (GLKBaseEffect*) baseEffect;

- (void) drawCompass: (GLKBaseEffect*) baseEffect;

- (GLfloat*) getImageVertices: (id<Model>) model
                       origin: (NSArray*) origin
                     vertices: (GLfloat*) vertices;

- (UIImage *)imageForPhoto:(id<MWPhoto>)photo;

- (void)makeTexture:(UIImage*) image
          withTitle:(NSString*) title
          grayscale:(BOOL)grayscale;

@end
