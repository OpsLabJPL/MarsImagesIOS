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
#import "ImageQuad.h"

@interface MarsScene : NSObject
{
//    GLuint vertexBufferID;
    int site_index;
    int drive_index;
}

@property (strong, nonatomic) NSArray* rmc;
@property (strong, nonatomic) NSMutableDictionary* photosInScene;
@property (strong, nonatomic) NSMutableDictionary* photoQuads;
@property (strong, nonatomic) NSMutableDictionary* photoTextures;
@property (strong, nonatomic) GLKTextureInfo* compassTextureInfo;
@property (strong, nonatomic) ImageQuad* compassQuad;
@property (strong, nonatomic) UIViewController* viewController;

- (void) destroy;

- (void) notesLoaded: (NSNotification*) notification;

- (void) addImagesToScene: (NSArray*) rmc;

- (void) loadImageAndTexture: (NSString*)title;
- (void) deleteImageAndTexture: (NSString*)title;

- (void) deleteImages;

- (void) drawImages: (GLKBaseEffect*) baseEffect;
- (void) drawImage:(ImageQuad*)imageQuad withTitle:(NSString*)title effect:(GLKBaseEffect*)baseEffect;
- (void) drawCompass: (GLKBaseEffect*) baseEffect;

- (UIImage *)imageForPhoto:(id<MWPhoto>)photo;

- (void) makeTexture: (UIImage*) image
           withTitle: (NSString*) title
           grayscale: (BOOL) grayscale;

- (void) handleZoomChanged;
- (int) computeBestTextureResolution: (ImageQuad*) imageQuad;
- (void) binImagesByPointing: (NSArray*) imagesForRMC;

@end
