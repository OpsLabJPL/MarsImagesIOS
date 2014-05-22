//
//  MarsScene.m
//  Mars-Images
//
//  Created by Mark Powell on 2/5/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import "MarsScene.h"

#import "CameraModel.h"
#import "ImageUtility.h"
#import "MarsImageNotebook.h"
#import "MarsPhoto.h"
#import "Math.h"
#import "SceneMesh.h"

@implementation MarsScene

static const double x_axis[] = X_AXIS;
static const double y_axis[] = Y_AXIS;
static const double z_axis[] = Z_AXIS;

- (id) init {
    self = [super init];
    
    if (self) {
        _photoQuads = [[NSMutableDictionary alloc] init];
        _photoTextures = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) addImagesToScene: (NSArray*) photosForRMC {
    for (MarsPhoto* photo in photosForRMC) {
        if (![photo includedInMosaic])
            continue;
        NSString* cmod_string = photo.resource.attributes.cameraModel;
        if (!cmod_string || cmod_string.length == 0)
            continue;
        NSData* json = [cmod_string dataUsingEncoding:NSUTF8StringEncoding];
        NSError* error;
        NSArray *model_json = [NSJSONSerialization JSONObjectWithData:json options:nil error:&error];
        id<Model> model = [CameraModel model:model_json];
        NSArray* origin = [CameraModel origin:model_json];
        GLfloat vertices[12];
        [self getImageVertices:model origin:origin vertices:vertices];
        int num_vectors = sizeof(vertices)/sizeof(GLfloat)/3;
        if (num_vectors != 4) {
            NSLog(@"Brown alert: num_vectors expected to be 4 but was: %d", num_vectors);
        }
        float textureCoords[] = {0.f, 1.f, 1.f, 1.f, 1.f, 0.f, 0.f, 0.f};
        SceneMesh* imageQuad = [[SceneMesh alloc] initWithPositionCoords:vertices texCoords0:textureCoords numberOfPositions:4];
        [_photoQuads setObject:imageQuad forKey:photo.note.title];
        UIImage* image = [photo underlyingImage];
        if (!image) {
            [photo performLoadUnderlyingImageAndNotify];
        } else {
            [self makeTexture:image withTitle:photo.note.title grayscale:[photo isGrayscale]];
        }
    }
}

- (void) drawImages: (GLKBaseEffect*) baseEffect{
    for (NSString* title in _photoQuads) {
        SceneMesh* imageQuad = [_photoQuads objectForKey:title];
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
    }
}

- (void) deleteImages {
    [_photoQuads removeAllObjects];
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
    Quaternion* qLL = [mission localLevelQuaternion];
    llRotq[0] = qLL.w;
    llRotq[1] = -qLL.x;
    llRotq[2] = -qLL.y;
    llRotq[3] = -qLL.z;
    
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
//        [ImageUtility imageDump:image];
        CGImageRef imageRef = [image CGImage];
        GLKTextureInfo* textureInfo = [GLKTextureLoader
                                       textureWithCGImage:imageRef options:nil error:NULL];
        if (textureInfo) {
            [_photoTextures setObject:textureInfo forKey:title];
        } else {
            NSLog(@"Unable to make texture for %@", title);
        }
    }
}

@end
