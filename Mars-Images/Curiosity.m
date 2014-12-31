//
//  MSL.m
//  Mars-Images
//
//  Created by Mark Powell on 12/21/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "Curiosity.h"
#import "MarsImageNotebook.h"
#import "MarsTime.h"
#import "Title.h"

#define SOL @"Sol"
#define LTST @"LTST"
#define RMC @"RMC"

@implementation Curiosity

typedef enum {
    START,
    SOL_NUMBER,
    IMAGESET_ID,
    INSTRUMENT_NAME,
    MARS_LOCAL_TIME,
    ROVER_MOTION_COUNTER
} TitleState;

- (id) init {
    self = [super init];
    self.roverName = @"Curiosity";
    self.regionName = @"Gale Crater";
    
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    [comps setDay:6];
    [comps setMonth:8];
    [comps setYear:2012];
    [comps setHour:6];
    [comps setMinute:30];
    [comps setSecond:00];
    [comps setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    _epoch = [[NSCalendar currentCalendar] dateFromComponents:comps];
    _eyeIndex = 1;
    _instrumentIndex = 0;
    _sampleTypeIndex = 17;
    
    self.cameraFOVs = [[NSDictionary alloc]
                  initWithObjectsAndKeys:
                  [NSNumber numberWithFloat:0.785398163], @"NL",
                  [NSNumber numberWithFloat:0.785398163], @"NR",
                  [NSNumber numberWithFloat:0.261799388], @"ML",
                  [NSNumber numberWithFloat:0.087266463], @"MR",
                  nil];
    
    return self;
}

+ (void) initialize {
    slashAndDot = [NSCharacterSet characterSetWithCharactersInString:@"/."];
    formatter = [[NSDateFormatter alloc] init];
	[formatter setTimeStyle:NSDateFormatterNoStyle];
    [formatter setDateStyle:NSDateFormatterLongStyle];
    stereoInstruments = [[NSSet alloc] initWithObjects:@"F", @"R", @"N", nil];
}

- (NSString*) labelText: (EDAMNote*) note {
    Title* mslTitle = [Curiosity tokenize: note.title];
    return mslTitle.instrumentName;
}

- (int) sol: (EDAMNote*) note { //TODO pull into superclass with MER
    NSArray* tokens = [note.title componentsSeparatedByString:@" "];
    if (tokens.count >= 2)
        return ((NSString*)[tokens objectAtIndex:1]).intValue;
    return 0;
}

- (NSString*) sectionTitle: (int) section { //TOOD pull into superclass with MER
    if (section >= [MarsImageNotebook instance].sols.count)
        return @"";
    
    NSNumber* sol = [[MarsImageNotebook instance].sols objectAtIndex:section];
    return [self solAndDate:sol.intValue];
}

- (NSString*) solAndDate: (int)sol { //TODO pull into superclass with MER
    double interval = sol*24*60*60*EARTH_SECS_PER_MARS_SEC;
    NSDate* imageDate = [NSDate dateWithTimeInterval:interval sinceDate:_epoch];
    NSString* formattedDate = [formatter stringFromDate:imageDate];
    return [NSString stringWithFormat:@"Sol %d %@", sol, formattedDate];
}

- (NSString*) detailLabelText: (EDAMNote*) note { //TODO pull into superclass with MER
    NSString* marstime = [Curiosity tokenize: note.title].marsLocalTime;
    return (marstime) ? [NSString stringWithFormat:@"%@ LST", marstime] : @"";
}

- (NSString*) imageName:(EDAMResource*) resource {
    NSString* imageid = [Curiosity imageID:resource];
    NSString* instrument = [imageid substringWithRange:NSMakeRange(_instrumentIndex, 1)];
    if ([instrument isEqualToString:@"N"] || [instrument isEqualToString:@"F"] || [instrument isEqualToString:@"R"]) {
        NSString* eye = [imageid substringWithRange:NSMakeRange(_eyeIndex, 1)];
        if ([eye isEqualToString:@"L"])
            return @"Left";
        else
            return @"Right";
    }
    
    return @"";
}

- (NSString*) captionText:(EDAMNote*) note {
    Title* title = [Curiosity tokenize: note.title];
    return [NSString stringWithFormat:@"%@ image taken on Sol %d.", title.instrumentName, title.sol];
}

- (NSArray*) stereoForImages:(NSArray *)resources {
    if (resources.count == 0)
        return [[NSArray alloc] initWithObjects:nil];
    NSString* imageid = [Curiosity imageID:[resources objectAtIndex:0]];
    NSString* instrument = [imageid substringWithRange:NSMakeRange(_instrumentIndex, 1)];
    if (![stereoInstruments containsObject:instrument])
        return [[NSArray alloc] initWithObjects:nil];
    
    int leftImageIndex = -1;
    int rightImageIndex = -1;
    int index = 0;
    for (EDAMResource* resource in resources) {
        NSString* imageid = [Curiosity imageID:resource];
        NSString* eye = [imageid substringWithRange:NSMakeRange(_eyeIndex, 1)];
        if (leftImageIndex == -1 && [eye isEqualToString:@"L"])
            leftImageIndex = index;
        if (rightImageIndex == -1 && [eye isEqualToString:@"R"])
            rightImageIndex = index;
        index += 1;
    }
    if (leftImageIndex >= 0 && rightImageIndex >= 0) {
        EDAMResource* leftResource = [resources objectAtIndex:leftImageIndex];
        EDAMResource* rightResource = [resources objectAtIndex:rightImageIndex];
        //check width and height of left and right images and don't return them unless they match
        NSArray* leftSize = [Rover imageSize:leftResource];
        NSArray* rightSize = [Rover imageSize:rightResource];
        int leftWidth = round(((NSNumber*)leftSize[0]).doubleValue);
        int rightWidth = round(((NSNumber*)rightSize[0]).doubleValue);
        int leftHeight = round(((NSNumber*)leftSize[1]).doubleValue);
        int rightHeight = round(((NSNumber*)rightSize[1]).doubleValue);
        if (leftWidth == rightWidth && leftHeight == rightHeight) {
            return [[NSArray alloc] initWithObjects:leftResource, rightResource, nil];
        }
    }
    return [[NSArray alloc] initWithObjects: nil];
}

+ (NSString*) imageID:(EDAMResource*) resource { //TODO pull into superclass with MER
    NSString* url = resource.attributes.sourceURL;
    NSArray* tokens = [url componentsSeparatedByCharactersInSet:slashAndDot];
    int numTokens = (int)tokens.count;
    NSString* imageid = [tokens objectAtIndex:numTokens-2];
    return imageid;
}

- (NSString*) imageId:(EDAMResource *)resource {
    return [Curiosity imageID:resource];
}

- (NSString*) getCameraId:(NSString*) imageId {
    unichar c = [imageId characterAtIndex:0];
    if (c >= '0' && c <= '9') {
        return [imageId substringWithRange:NSMakeRange(4,2)];
    }
    return [imageId substringWithRange:NSMakeRange(0, 2)];
}

- (BOOL) isTopLayer:(NSString *)cameraId {
    if ([cameraId characterAtIndex:0] == 'N') {
        return NO;
    }
    return YES;
}

+ (Title*) tokenize: (NSString*) title {
    Title* msl = [[Title alloc] init];
    NSArray* tokens = [title componentsSeparatedByString:@" "];
    TitleState state = START;
    for (NSString* word in tokens) {
        if ([word isEqualToString:SOL]) {
            state = SOL_NUMBER;
            continue;
        }
        else if ([word isEqualToString:LTST]) {
            state = MARS_LOCAL_TIME;
            continue;
        }
        else if ([word isEqualToString:RMC]) {
            state = ROVER_MOTION_COUNTER;
            continue;
        }
        NSArray* indices;
        switch (state) {
            case START:
                break;
            case SOL_NUMBER:
                msl.sol = word.intValue;
                state = IMAGESET_ID;
                break;
            case IMAGESET_ID:
                msl.imageSetID = word;
                state = INSTRUMENT_NAME;
                break;
            case INSTRUMENT_NAME:
                if (!msl.instrumentName) {
                    msl.instrumentName = [NSMutableString stringWithString:word];
                } else {
                    [(NSMutableString*)msl.instrumentName appendString:[NSString stringWithFormat:@" %@", word]];
                }
                break;
            case MARS_LOCAL_TIME:
                msl.marsLocalTime = word;
                break;
            case ROVER_MOTION_COUNTER:
                indices = [word componentsSeparatedByString:@"-"];
                msl.siteIndex = [[indices objectAtIndex:0] intValue];
                msl.driveIndex = [[indices objectAtIndex:1] intValue];
                break;
            default:
                NSLog(@"Unexpected state in parsing image title: %d", state);
                break;
        }
    }
    return msl;
}

- (NSString*) getSortableImageFilename: (NSString*) imageurl {
    NSArray* tokens = [imageurl componentsSeparatedByString:@"/"];
    NSString* filename = [tokens objectAtIndex: tokens.count-1];    
    return filename;
}

- (float) mastX {
    return 0.80436f;
}

- (float) mastY {
    return 0.55942f;
}

- (float) mastZ {
    return -1.90608f;
}

- (NSString*) urlPrefix {
    return @"https://msl-raws.s3.amazonaws.com";
}

@end
