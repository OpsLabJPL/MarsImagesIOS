//
//  MarsScene.m
//  Mars-Images
//
//  Created by Mark Powell on 2/5/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import "MarsScene.h"

#import "CameraModel.h"
#import "CHCSVParser.h"
#import "ImageUtility.h"
#import "MarsImageNotebook.h"
#import "MarsPhoto.h"
#import "Math.h"
#import "MosaicViewController.h"

#define COMPASS_HEIGHT 0.5
#define COMPASS_RADIUS 5

#define ANGLE_THRESHOLD 3 / 180 * M_PI

@implementation MarsScene


static dispatch_queue_t downloadQueue = nil;

- (id) init {
    self = [super init];
    
    if (self) {
        _photoQuads = NSMutableDictionary.new;
        _photoTextures = NSMutableDictionary.new;
        _photosInScene = NSMutableDictionary.new;
        float textureCoords[] = { 0.f, 0.f, 0.f, 1.f, 1.f, 1.f, 1.f, 0.f };
        GLfloat vertPointer[] = {
            -COMPASS_RADIUS, COMPASS_HEIGHT, COMPASS_RADIUS,
            -COMPASS_RADIUS, COMPASS_HEIGHT, -COMPASS_RADIUS,
            COMPASS_RADIUS, COMPASS_HEIGHT, -COMPASS_RADIUS,
            COMPASS_RADIUS, COMPASS_HEIGHT, COMPASS_RADIUS };
        _compassQuad = [[ImageQuad alloc] initWithPositionCoords:vertPointer texCoords0:textureCoords numberOfPositions:4];
        UIImage* image = [UIImage imageNamed:@"hover_compass.png"];
        CGImageRef imageRef = [image CGImage];
        NSError* error = nil;
        _compassTextureInfo = [GLKTextureLoader textureWithCGImage:imageRef options:nil error:&error];

        if (error) {
            NSLog(@"Unable to make texture for compass, because %@", error);
            [ImageUtility imageDump:image];
        }

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesLoaded:) name:END_NOTE_LOADING object:nil];
    }
    
    if (downloadQueue == nil)
        downloadQueue = dispatch_queue_create("mosaic note downloader", DISPATCH_QUEUE_SERIAL);
    
    return self;
}

- (void) destroy {
    [self deleteImages];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) addImagesToScene: (NSArray*) rmc {
    _rmc = rmc;
    id<MarsRover> mission = [MarsImageNotebook instance].mission;
    site_index = [[rmc objectAtIndex:0] intValue];
    drive_index = [[rmc objectAtIndex:1] intValue];
    NSLog(@"RMC is %d,%d", site_index, drive_index);
    qLL = [mission localLevelQuaternion:site_index drive:drive_index];
    NSLog(@"Quaternion: %@", qLL);
    [MarsImageNotebook instance].searchWords = [NSString stringWithFormat:@"RMC %06d-%06d", site_index, drive_index];
    [[MarsImageNotebook instance] reloadNotes]; //rely on the resultant note load notifications to populate images in the scene
}

- (void) notesLoaded: (NSNotification*) notification {   
    int numNotesReturned = 0;
    NSNumber* num = [notification.userInfo objectForKey:NUM_NOTES_RETURNED];
    if (num != nil) {
        numNotesReturned = [num intValue];
    }
    if (numNotesReturned > 0)
        [[MarsImageNotebook instance] loadMoreNotes:[MarsImageNotebook instance].notesArray.count withTotal:NOTE_PAGE_SIZE];
    else {
        //when there are no more notes returned, we have all images for this location: add them to the scene
        dispatch_async(downloadQueue, ^{

            NSArray* notesForRMC = [[MarsImageNotebook instance] notePhotosArray];
            [self binImagesByPointing: notesForRMC];
            NSLog(@"%lu images returned.", (unsigned long)[notesForRMC count]);
            int mosaicCount = 0;
            for (NSString* photoTitle in _photosInScene) {
                MarsPhoto* photo = _photosInScene[photoTitle];
                if (![photo includedInMosaic])
                    continue;
                
                NSArray* model_json = [photo modelJson];
                if (!model_json)
                    continue;
                
                mosaicCount++;
                id<Model> model = [CameraModel model:model_json];
                NSArray* origin = [CameraModel origin:model_json];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    ImageQuad* imageQuad = [[ImageQuad alloc] initWithModel:model origin:origin qLL:qLL];
                    [_photoQuads setObject:imageQuad forKey:photo.note.title];
//                    NSLog(@"Photo quad count: %d", [_photoQuads count]);

//                    UIImage* image = [photo underlyingImage]; //TRYING to move this to drawImages method
//                    if (!image) {
//                        [photo performLoadUnderlyingImageAndNotify];
//                    } else {
//                        [self makeTexture:image withTitle:photo.note.title grayscale:[photo isGrayscale]];
//                    }
                });
            }
            NSLog(@"images in mosaic: %d", mosaicCount);
            dispatch_async(dispatch_get_main_queue(), ^{
                [((MosaicViewController*)_viewController) hideHud];
            });
        });
    }
}

- (void) drawImages: (GLKBaseEffect*) baseEffect {

    int skippedImages = 0;
    
    for (NSString* title in _photoQuads) {
        ImageQuad* imageQuad = _photoQuads[title];
        
        //frustum culling: don't draw if the bounding sphere of the image quad isn't in the camera frustum
        AGLKFrustum frustum = ((MosaicViewController*)_viewController).frustum;

        if (AGLKFrustumCompareSphere(&frustum, imageQuad.center, imageQuad.boundingSphereRadius) == AGLKFrustumOut) {
            imageQuad.isVisible = NO;
            skippedImages++;
            MarsPhoto* photo = _photosInScene[title];
            if ([photo underlyingImage]) {
                [photo unloadUnderlyingImage];
                GLKTextureInfo* texInfo = _photoTextures[title];
                if (texInfo) {
                    GLuint textureName = texInfo.name;
                    glDeleteTextures(1, &textureName);
                    [_photoTextures removeObjectForKey:title];
                }
           }
            
            continue;
        }
        imageQuad.isVisible = YES;
        
        GLKTextureInfo* textureInfo = [_photoTextures objectForKey:title];
        if (textureInfo) {
            baseEffect.texture2d0.name = textureInfo.name;
            baseEffect.texture2d0.target = textureInfo.target;
            [baseEffect prepareToDraw];
            [imageQuad prepareToDraw];
            [imageQuad drawUnindexedWithMode:GL_TRIANGLE_FAN startVertexIndex:0 numberOfVertices:4];
            GLenum error = glGetError();
            if (GL_NO_ERROR != error) {
                NSLog(@"GL Error: 0x%x", error);
            }
        }
        else {
            // Draw lines to represent normal vectors and light direction
            // Don't use light so that line color shows
            baseEffect.light0.enabled = GL_FALSE;
            baseEffect.useConstantColor = GL_TRUE;
            baseEffect.constantColor = GLKVector4Make(1.0, 0.9, 0.7, 1.0);
            glLineWidth(1.0);
            [baseEffect prepareToDraw];
            [imageQuad prepareToDraw];
            [imageQuad drawUnindexedWithMode:GL_LINE_LOOP startVertexIndex:0 numberOfVertices:4];
            GLenum error = glGetError();
            if (GL_NO_ERROR != error) {
                NSLog(@"GL Error: 0x%x", error);
            }
            baseEffect.light0.enabled = GL_TRUE;
            
            MarsPhoto* photo = _photosInScene[title];
            UIImage* image = [photo underlyingImage];
            if (!image) {
                if (!photo.isLoading) {
                    [photo performLoadUnderlyingImageAndNotify];
                }
            } else {
                [self makeTexture:image withTitle:photo.note.title grayscale:[photo isGrayscale]];
            }
        }
    }
//    NSLog(@"Skipped images: %d", skippedImages);
}

- (void) drawCompass: (GLKBaseEffect*) baseEffect {
    if (_compassTextureInfo) {
        baseEffect.texture2d0.name = _compassTextureInfo.name;
        baseEffect.texture2d0.target = _compassTextureInfo.target;
        [baseEffect prepareToDraw];
        [_compassQuad prepareToDraw];
        [_compassQuad drawUnindexedWithMode:GL_TRIANGLE_FAN startVertexIndex:0 numberOfVertices:4];
        GLenum error = glGetError();
        if (GL_NO_ERROR != error) {
            NSLog(@"GL Error: 0x%x", error);
        }
    }
}

- (void) deleteImages {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    [_photosInScene removeAllObjects];
    [_photoQuads removeAllObjects];
    for (id key in [_photoTextures keyEnumerator]) {
        GLKTextureInfo* texInfo = [_photoTextures objectForKey:key];
        GLuint textureName = texInfo.name;
        glDeleteTextures(1, &textureName);
    }
    [_photoTextures removeAllObjects];
    NSLog(@"textures deleted");
}

- (UIImage *)imageForPhoto:(id<MWPhoto>)photo {
	if (photo) {
		// Get image or obtain in background
		if ([photo underlyingImage]) {
			return [photo underlyingImage];
		} else {
            [photo loadUnderlyingImageAndNotify];
		}
	}
	return nil;
}

- (void)makeTexture:(UIImage*) image
          withTitle:(NSString*) title
          grayscale:(BOOL) grayscale {
    
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    
    if (image) {
        if (grayscale) {
            image = [ImageUtility grayscale:image];
        }
        image = [ImageUtility resizeToValidTexture:image];
        CGImageRef imageRef = [image CGImage];
        NSError* error = nil;
        GLKTextureInfo* textureInfo = [GLKTextureLoader textureWithCGImage:imageRef options:nil error:&error];
        if (textureInfo) {
            [_photoTextures setObject:textureInfo forKey:title];
        }
        if (error) {
            NSLog(@"Unable to make texture for %@, because %@", title, error);
            [ImageUtility imageDump:image];
        }
//        NSLog(@"Texture count: %d", [_photoTextures count]);
    }
}

- (void) binImagesByPointing: (NSArray*) imagesForRMC {
    for (MarsPhoto* prospectiveImage in [imagesForRMC reverseObjectEnumerator]) {
        BOOL tooCloseToAnotherImage = NO;
        for (NSString* imageTitle in _photosInScene) {
            MarsPhoto* image = _photosInScene[imageTitle];
            if ([image angularDistance:prospectiveImage] < ANGLE_THRESHOLD) {
                tooCloseToAnotherImage = YES;
                break;
            }
        }
        if (!tooCloseToAnotherImage)
            _photosInScene[prospectiveImage.note.title] = prospectiveImage;
    }
}

@end
