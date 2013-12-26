//
//  MarsRover.h
//  Mars-Images
//
//  Created by Mark Powell on 12/21/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Evernote.h"

@protocol MarsRover <NSObject>

- (NSDate*) epoch;
- (int) eyeIndex;
- (int) instrumentIndex;
- (int) sampleTypeIndex;
- (NSString*) roverName;
- (NSString*) regionName;

- (NSString*) labelText: (EDAMNote*) note;
- (NSString*) detailLabelText: (EDAMNote*) note;
- (NSString*) imageName: (EDAMResource*) resource;
- (NSString*) captionText:(EDAMResource*) resource
                     note:(EDAMNote*) note;
- (NSArray*) stereoForImages:(NSArray*) resources;
@end
