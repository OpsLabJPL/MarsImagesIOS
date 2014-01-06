//
//  MSL.h
//  Mars-Images
//
//  Created by Mark Powell on 12/21/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MarsRover.h"

static NSCharacterSet* slashAndDot;
static NSDateFormatter* formatter;
static NSSet* stereoInstruments;

@interface Curiosity : NSObject <MarsRover>

@property (strong, nonatomic) NSDate* epoch;
@property (nonatomic) int eyeIndex;
@property (nonatomic) int instrumentIndex;
@property (nonatomic) int sampleTypeIndex;
@property (nonatomic) NSString* roverName;
@property (nonatomic) NSString* regionName;

- (int) sol: (EDAMNote*) note;
- (NSString*) sectionTitle: (int) section;
- (NSString*) labelText: (EDAMNote*) note;
- (NSString*) detailLabelText: (EDAMNote*) note;
- (NSString*) imageName: (EDAMResource*) resource;
- (NSString*) captionText:(EDAMResource*) resource
                     note:(EDAMNote*) note;
- (NSArray*) stereoForImages:(NSArray*) resources;
- (NSString*) getSortableImageFilename: (NSString*) imageurl;

@end
