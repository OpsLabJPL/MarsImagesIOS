//
//  MarsRover.h
//  Mars-Images
//
//  Created by Mark Powell on 12/21/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Evernote.h"
#import "Quaternion.h"

@protocol MarsRover <NSObject>

- (NSDate*) epoch;
- (int) eyeIndex;
- (int) instrumentIndex;
- (int) sampleTypeIndex;
- (NSString*) roverName;
- (NSString*) regionName;
- (int) sol: (EDAMNote*) note;
- (NSString*) sectionTitle: (int) section;
- (NSString*) labelText: (EDAMNote*) note;
- (NSString*) detailLabelText: (EDAMNote*) note;
- (NSString*) imageName: (EDAMResource*) resource;
- (NSString*) captionText:(EDAMNote*) note;
- (NSArray*) stereoForImages:(NSArray*) resources;
- (NSString*) getSortableImageFilename: (NSString*) imageurl;
- (float) mastX;
- (float) mastY;
- (float) mastZ;
- (Quaternion*) localLevelQuaternion: (int)site_index
                               drive: (int)drive_index;
- (NSString*) rmc: (EDAMNote*) note;
- (NSString*) urlPrefix;
- (NSArray*) siteLocationData: (int) site_index;
- (NSString*) imageId:(EDAMResource*) resource;
- (NSString*) getCameraId:(NSString*) imageId;
- (float) getCameraFOV:(NSString*) cameraId;
- (int) layer:(NSString*) cameraId imageId:(NSString*)imageId;

@end
