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

static const double x_axis[] = X_AXIS;
static const double z_axis[] = Z_AXIS;

static dispatch_queue_t downloadQueue = nil;

- (id) init {
    self = [super init];
    
    if (self) {
        _photoQuads = [[NSMutableDictionary alloc] init];
        _photoTextures = [[NSMutableDictionary alloc] init];

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
            NSArray* binnedNotesForRMC = [self binImagesByPointing: notesForRMC];
            NSLog(@"%lu images returned.", (unsigned long)[notesForRMC count]);
            int mosaicCount = 0;
            for (MarsPhoto* photo in binnedNotesForRMC) {
                if (![photo includedInMosaic])
                    continue;
                
                NSArray* model_json = [photo modelJson];
                if (!model_json)
                    continue;
                
                mosaicCount++;
                GLfloat *vertPointer = malloc(sizeof(GLfloat)*12);
                id<Model> model = [CameraModel model:model_json];
                NSArray* origin = [CameraModel origin:model_json];
                
                [self getImageVertices:model origin:origin vertices:vertPointer];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    float textureCoords[] = {0.f, 1.f, 1.f, 1.f, 1.f, 0.f, 0.f, 0.f};
                    ImageQuad* imageQuad = [[ImageQuad alloc] initWithPositionCoords:vertPointer texCoords0:textureCoords numberOfPositions:4];
                    free(vertPointer);
                    [_photoQuads setObject:imageQuad forKey:photo.note.title];
//                    NSLog(@"Photo quad count: %d", [_photoQuads count]);
                    UIImage* image = [photo underlyingImage];
                    if (!image) {
                        [photo performLoadUnderlyingImageAndNotify];
                    } else {
                        [self makeTexture:image withTitle:photo.note.title grayscale:[photo isGrayscale]];
                    }
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
        ImageQuad* imageQuad = [_photoQuads objectForKey:title];
        
        //frustum culling: don't draw if the bounding sphere of the image quad isn't in the camera frustum
        AGLKFrustum frustum = ((MosaicViewController*)_viewController).frustum;

        if (AGLKFrustumCompareSphere(&frustum, imageQuad.center, imageQuad.boundingSphereRadius) == AGLKFrustumOut) {
            skippedImages++;
            continue;
        }
        
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
        }
    }
//    NSLog(@"Skipped images: %d", skippedImages);
}

- (BOOL) testInFrustum:(ImageQuad*) quad {
    static int count;
    count++;
    if (count % 100 != 0) {
        return YES;
    }
    GLfloat vx = quad.v1.x;
    GLfloat vy = quad.v1.y;
    GLfloat vz = quad.v1.z;
    NSLog(@"Quad x,y,z: %f, %f, %f", vx, vy, vz);
    vx = quad.v2.x;
    vy = quad.v2.y;
    vz = quad.v2.z;
    NSLog(@"Quad x,y,z: %f, %f, %f", vx, vy, vz);
    vx = quad.v3.x;
    vy = quad.v3.y;
    vz = quad.v3.z;
    NSLog(@"Quad x,y,z: %f, %f, %f", vx, vy, vz);
    vx = quad.v4.x;
    vy = quad.v4.y;
    vz = quad.v4.z;
    NSLog(@"Quad x,y,z: %f, %f, %f", vx, vy, vz);
    
    return NO;
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
    [_photoQuads removeAllObjects];
    for (id key in [_photoTextures keyEnumerator]) {
        GLKTextureInfo* texInfo = [_photoTextures objectForKey:key];
        GLuint textureName = texInfo.name;
        glDeleteTextures(1, &textureName);
    }
    [_photoTextures removeAllObjects];
    NSLog(@"textures deleted");
}

- (GLfloat*) getImageVertices: (id<Model>) model
                       origin: (NSArray*) origin
                     vertices: (GLfloat*) vertices {
    
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
    pos3[0] += vec3[0]*10;
    pos3[1] += vec3[1]*10;
    pos3[2] += vec3[2]*10;
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
    pos3[0] += vec3[0]*10;
    pos3[1] += vec3[1]*10;
    pos3[2] += vec3[2]*10;
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
    pos3[0] += vec3[0]*10;
    pos3[1] += vec3[1]*10;
    pos3[2] += vec3[2]*10;
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
    pos3[0] += vec3[0]*10;
    pos3[1] += vec3[1]*10;
    pos3[2] += vec3[2]*10;
    [Math multqv:llRotq v:pos3 toU:pos3LL];
    [Math multqv:zrotq v:pos3LL toU:pinitial];
    [Math multqv:xrotq v:pinitial toU:pfinal];
    vertices[9] = (float)pfinal[0];
    vertices[10] = (float)pfinal[1];
    vertices[11] = (float)pfinal[2];
//    NSLog(@"vertex: %g %g %g", vertices[9], vertices[10], vertices[11]);
    return vertices;
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

- (NSArray*) binImagesByPointing: (NSArray*) imagesForRMC {
    NSMutableArray* binnedImages = [[NSMutableArray alloc] init];
    for (MarsPhoto* prospectiveImage in [imagesForRMC reverseObjectEnumerator]) {
        BOOL tooCloseToAnotherImage = NO;
        for (MarsPhoto* image in binnedImages) {
            if ([image angularDistance:prospectiveImage] < ANGLE_THRESHOLD) {
                tooCloseToAnotherImage = YES;
                break;
            }
        }
        if (!tooCloseToAnotherImage)
            [binnedImages addObject:prospectiveImage];
    }
    
    return binnedImages;
}

@end
