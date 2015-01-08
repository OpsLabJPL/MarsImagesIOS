//
//  Rover.m
//  Mars-Images
//
//  Created by Mark Powell on 6/24/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import "Rover.h"

#import "CHCSVParser.h"
#import "CameraModel.h"

@implementation Rover

- (NSDate*) epoch {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (int) eyeIndex {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (int) instrumentIndex {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (int) sampleTypeIndex {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString*) roverName {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString*) regionName {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (int) sol: (EDAMNote*) note {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString*) sectionTitle: (int) section {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString*) labelText: (EDAMNote*) note {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString*) detailLabelText: (EDAMNote*) note {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString*) imageName: (EDAMResource*) resource {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString*) captionText:(EDAMNote*) note {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSArray*) stereoForImages:(NSArray*) resources {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString*) getSortableImageFilename: (NSString*) imageurl {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (float) mastX {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (float) mastY {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (float) mastZ {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString*) imageId:(EDAMResource*) resource {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString*) getCameraId:(NSString *)imageId {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (int) layer:(NSString *)cameraId imageId:(NSString*)imageId {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSArray*) siteLocationData: (int) site_index {
    NSURL* siteUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/locations/site_%06d.csv", [self urlPrefix], site_index]];
    NSURLRequest *request = [NSURLRequest requestWithURL:siteUrl];
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest: request
                                                 returningResponse: &response
                                                             error: &error];
    if (response) {
        NSString *csvString = [[NSString alloc] initWithBytes:[responseData bytes] length:[responseData length] encoding:NSASCIIStringEncoding];
        NSArray *rows = [csvString CSVComponents];
        if ([rows count] <= 0)
            NSLog(@"Brown alert: no quaternions for site %d", site_index);
        return rows;
    }
    if (error) {
        NSLog(@"Brown alert: %@", error);
    }
    return nil;
}

- (Quaternion*) localLevelQuaternion: (int) site_index
                               drive: (int) drive_index {
    Quaternion* q = Quaternion.new;
    NSArray* locations = [self siteLocationData:site_index];
    for (NSArray* location in locations) {
        if ([location count] >= 5 && [[location objectAtIndex:0] integerValue] == drive_index) {
            q.w = [[location objectAtIndex:1] doubleValue];
            q.x = [[location objectAtIndex:2] doubleValue];
            q.y = [[location objectAtIndex:3] doubleValue];
            q.z = [[location objectAtIndex:4] doubleValue];
            break;
        }
    }
    return q;
}

- (NSString*) rmc: (EDAMNote*) note {
    NSArray* tokens = [note.title componentsSeparatedByString:@" "];
    return [tokens objectAtIndex:[tokens count]-1];
}

- (NSString*) urlPrefix {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (float) getCameraFOV: (NSString*)cameraId {
    NSNumber* fov = _cameraFOVs[cameraId];
    if (!fov) NSLog(@"Brown alert: requested camera FOV for unrecognized camera id: %@", cameraId);
    return [fov floatValue];
}

+ (NSArray*) imageSize:(EDAMResource*)imageResource {
    NSString* cmod_string = imageResource.attributes.cameraModel;
    if (!cmod_string || cmod_string.length == 0)
        return nil;
    NSData* json = [cmod_string dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    NSArray* model_json = [NSJSONSerialization JSONObjectWithData:json options:nil error:&error];
    CameraModel* cameraModel = [CameraModel model:model_json];
    return [cameraModel size];
}

@end
