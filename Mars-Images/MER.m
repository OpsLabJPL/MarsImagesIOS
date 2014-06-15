//
//  MER.m
//  Mars-Images
//
//  Created by Mark Powell on 12/21/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MER.h"
#import "MarsImageNotebook.h"
#import "MarsTime.h"

#define SOL @"Sol"
#define LTST @"LTST"
#define RMC @"RMC"
#define COURSE @"Course"

#define MER_MAST_XYZ { 0.f, 0.f, -1.f }

@implementation MER

typedef enum {
    START,
    SOL_NUMBER,
    IMAGESET_ID,
    INSTRUMENT_NAME,
    MARS_LOCAL_TIME,
    DISTANCE,
    YAW,
    PITCH,
    ROLL,
    TILT,
    ROVER_MOTION_COUNTER
} TitleState;

- (id) init {
    self = [super init];
    
    _qLocalLevel = [[Quaternion alloc] init];
//    0.920865,-0.0942893,0.00495749,0.378277
    _qLocalLevel.w = 0.920865;
    _qLocalLevel.x = -0.0942893;
    _qLocalLevel.y = 0.00495749;
    _qLocalLevel.z = 0.378277;
    return self;
}

+ (void) initialize {
    slashAndDot = [NSCharacterSet characterSetWithCharactersInString:@"/."];
    formatter = [[NSDateFormatter alloc] init];
	[formatter setTimeStyle:NSDateFormatterNoStyle];
    [formatter setDateStyle:NSDateFormatterLongStyle];
    stereoInstruments = [[NSSet alloc] initWithObjects:@"F", @"R", @"N", @"P", nil];

}

- (NSString*) labelText: (EDAMNote*) note {
    MERTitle* merTitle = [MER tokenize: note.title];
    if (!merTitle.distance)
        return merTitle.instrumentName;
    else
        return [NSString stringWithFormat:@"Drive for %.2f meters", merTitle.distance];
}

- (int) sol: (EDAMNote*) note {
    NSArray* tokens = [note.title componentsSeparatedByString:@" "];
    if (tokens.count >= 2)
        return ((NSString*)[tokens objectAtIndex:1]).intValue;
    return 0;
}

- (NSString*) sectionTitle: (int) section {
    if (section >= [MarsImageNotebook instance].sols.count)
        return @"";
    
    NSNumber* sol = [[MarsImageNotebook instance].sols objectAtIndex:section];
    return [self solAndDate:sol.intValue];
}

- (NSString*) solAndDate: (int)sol {
    double interval = sol*24*60*60*EARTH_SECS_PER_MARS_SEC;
    NSDate* imageDate = [NSDate dateWithTimeInterval:interval sinceDate:_epoch];
    NSString* formattedDate = [formatter stringFromDate:imageDate];
    return [NSString stringWithFormat:@"Sol %d %@", sol, formattedDate];
}

- (NSString*) detailLabelText: (EDAMNote*) note {
    NSString* marstime = [MER tokenize: note.title].marsLocalTime;
    return (marstime) ? [NSString stringWithFormat:@"%@ LST", marstime] : @"";
}

- (NSString*) imageName:(EDAMResource*) resource {
    NSString* imageid = [MER imageID:resource];
    
    if ([resource.attributes.sourceURL rangeOfString:@"False"].location != NSNotFound)
        return @"Color";
    
    NSString* instrument = [imageid substringWithRange:NSMakeRange(_instrumentIndex, 1)];
    if ([instrument isEqualToString:@"N"] || [instrument isEqualToString:@"F"] || [instrument isEqualToString:@"R"]) {
        NSString* eye = [imageid substringWithRange:NSMakeRange(_eyeIndex, 1)];
        if ([eye isEqualToString:@"L"])
            return @"Left";
        else
            return @"Right";
    } else if ([instrument isEqualToString:@"P"]) {
        return [imageid substringWithRange:NSMakeRange(_eyeIndex, 2)];
    }
    
    return @"";
}

- (NSString*) captionText:(EDAMNote*) note {
    MERTitle* title = [MER tokenize: note.title];
    if (!title.distance)
        return [NSString stringWithFormat:@"%@ image taken on Sol %d.", title.instrumentName, title.sol];
    else
        return [NSString stringWithFormat:@"Drive for %.2f meters on Sol %d.", title.distance, title.sol];
}

- (NSArray*) stereoForImages:(NSArray *)resources {
    if (resources.count == 0)
        return [[NSArray alloc] initWithObjects:nil];
    NSString* imageid = [MER imageID:[resources objectAtIndex:0]];
    NSString* instrument = [imageid substringWithRange:NSMakeRange(_instrumentIndex, 1)];
    if (![stereoInstruments containsObject:instrument] && ![imageid hasPrefix:@"Sol"])
        return [[NSArray alloc] initWithObjects:nil];
    
    int leftImageIndex = -1;
    int rightImageIndex = -1;
    int index = 0;
    for (EDAMResource* resource in resources) {
        NSString* imageid = [MER imageID:resource];
        NSString* eye = [imageid substringWithRange:NSMakeRange(_eyeIndex, 1)];
        if (leftImageIndex == -1 && [eye isEqualToString:@"L"] && ![imageid hasPrefix:@"Sol"])
            leftImageIndex = index;
        if (rightImageIndex == -1 && [eye isEqualToString:@"R"])
            rightImageIndex = index;
        index += 1;
    }
    if (leftImageIndex >= 0 && rightImageIndex >= 0) {
        return [[NSArray alloc] initWithObjects:[resources objectAtIndex:leftImageIndex], [resources objectAtIndex:rightImageIndex], nil];
    }
    return [[NSArray alloc] initWithObjects: nil];
}

+ (NSString*) imageID:(EDAMResource*) resource {
    NSString* url = resource.attributes.sourceURL;
    NSArray* tokens = [url componentsSeparatedByCharactersInSet:slashAndDot];
    int numTokens = tokens.count;
    NSString* imageid = [tokens objectAtIndex:numTokens-2];
    return imageid;
}

+ (MERTitle*) tokenize: (NSString*) title {
    MERTitle* mer = [[MERTitle alloc] init];
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
                mer.sol = word.intValue;
                state = IMAGESET_ID;
                break;
            case IMAGESET_ID:
                if ([word isEqualToString:COURSE]) {
                    mer = [MER parseCoursePlotTitle:title merTitle:mer];
                    return mer;
                } else {
                    mer.imageSetID = word;
                }
                state = INSTRUMENT_NAME;
                break;
            case INSTRUMENT_NAME:
                if (!mer.instrumentName) {
                    mer.instrumentName = [NSMutableString stringWithString:word];
                } else {
                    [(NSMutableString*)mer.instrumentName appendString:[NSString stringWithFormat:@" %@", word]];
                }
                break;
            case MARS_LOCAL_TIME:
                mer.marsLocalTime = word;
                break;
            case ROVER_MOTION_COUNTER:
                indices = [word componentsSeparatedByString:@"-"];
                mer.siteIndex = [[indices objectAtIndex:0] intValue];
                mer.driveIndex = [[indices objectAtIndex:1] intValue];
                break;
            default:
                NSLog(@"Unexpected state in parsing image title: %d", state);
                break;
        }
    }
    return mer;
}

+ (MERTitle*) parseCoursePlotTitle: (NSString*)title
                          merTitle: (MERTitle*)mer {
    NSArray* tokens = [title componentsSeparatedByString:@" "];
    TitleState state = START;
    for (NSString* word in tokens) {
        if ([word isEqualToString:COURSE]) {
            mer.instrumentName = @"Course Plot";
        } else if ([word isEqualToString:@"Distance"]) {
            state = DISTANCE;
            continue;
        } else if ([word isEqualToString:@"yaw"]) {
            state = YAW;
            continue;
        } else if ([word isEqualToString:@"pitch"]) {
            state = PITCH;
            continue;
        } else if ([word isEqualToString:@"roll"]) {
            state = ROLL;
            continue;
        } else if ([word isEqualToString:@"tilt"]) {
            state = TILT;
            continue;
        } else if ([word isEqualToString:@"RMC"]) {
            state = ROVER_MOTION_COUNTER;
            continue;
        }
        NSArray* indices;
        switch (state) {
            case START:
                break;
            case DISTANCE:
                mer.distance = [word floatValue];
                break;
            case YAW:
                mer.yaw = [word floatValue];
                break;
            case PITCH:
                mer.pitch = [word floatValue];
                break;
            case ROLL:
                mer.roll = [word floatValue];
                break;
            case TILT:
                mer.tilt = [word floatValue];
                break;
            case ROVER_MOTION_COUNTER:
                indices = [word componentsSeparatedByString:@"-"];
                mer.siteIndex = [[indices objectAtIndex:0] intValue];
                mer.driveIndex = [[indices objectAtIndex:1] intValue];
                break;
            default:
                NSLog(@"Unexpected state in parsing course plot title: %d", state);
                break;
        }
    }
    return mer;
}

- (NSString*) getSortableImageFilename: (NSString*) imageurl {
    NSArray* tokens = [imageurl componentsSeparatedByString:@"/"];
    NSString* filename = [tokens objectAtIndex: tokens.count-1];
    if ([filename hasPrefix:@"Sol"])
        return @"0"; //sort Cornell Pancam images first
    else if (([filename hasPrefix:@"1"] || [filename hasPrefix:@"2"]) && filename.length == 31)
        return [filename substringFromIndex:23];
    
    return filename;
}

- (float) mastX {
    return 0.456f;
}

- (float) mastY {
    return 0.026f;
}

- (float) mastZ {
    return -1.0969;
}

- (Quaternion*) localLevelQuaternion {
    return _qLocalLevel;
}

@end
