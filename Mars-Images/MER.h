//
//  MER.h
//  Mars-Images
//
//  Created by Mark Powell on 12/21/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Evernote.h"
#import "MERTitle.h"

static NSCharacterSet* slashAndDot;
static NSDateFormatter* formatter;
static NSSet* stereoInstruments;

@interface MER : NSObject

@property (strong, nonatomic) NSDate* epoch;
@property (nonatomic) int eyeIndex;
@property (nonatomic) int instrumentIndex;
@property (nonatomic) int sampleTypeIndex;
@property (nonatomic) NSString* roverName;
@property (nonatomic) NSString* regionName;

- (int) sol: (EDAMNote*) note;
- (NSString*) sectionTitle: (int) section;
- (NSString*) solAndDate: (int)sol;
- (NSString*) labelText: (EDAMNote*) note;
- (NSString*) detailLabelText: (EDAMNote*) note;
- (NSString*) imageName: (EDAMResource*) resource;
- (NSString*) captionText: (EDAMResource*) resource
                     note:(EDAMNote*) note;
- (NSArray*) stereoForImages: (NSArray*)resources;
+ (MERTitle*) tokenize: (NSString*) title;
+ (NSString*) imageID:(EDAMResource*) resource;
+ (MERTitle*) parseCoursePlotTitle: (NSString*)title
                          merTitle: (MERTitle*)mer;
- (NSString*) getSortableImageFilename: (NSString*) imageurl;
- (float) mastX;
- (float) mastY;
- (float) mastZ;

@end
