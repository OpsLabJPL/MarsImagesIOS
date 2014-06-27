//
//  MarsScene.h
//  Mars-Images
//
//  Created by Mark Powell on 2/5/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "Model.h"
#import "MWPhoto.h"
#import "Quaternion.h"

@interface MarsScene : NSObject
{
//    GLuint vertexBufferID;
}

@property (strong, nonatomic) NSMutableDictionary* photoQuads;
@property (strong, nonatomic) NSMutableDictionary* photoTextures;

- (void) notesLoaded: (NSNotification*) notification;

- (void) addImagesToScene;

- (void) deleteImages;

- (void) drawImages: (GLKBaseEffect*) baseEffect;

- (GLfloat*) getImageVertices: (id<Model>) model
                       origin: (NSArray*) origin
                     attitude: (Quaternion*) qLL
                     vertices: (GLfloat*) vertices;

- (UIImage *)imageForPhoto:(id<MWPhoto>)photo;

- (void)makeTexture:(UIImage*) image
          withTitle:(NSString*) title
          grayscale:(BOOL)grayscale;

@end
