//
//  MarsNotebook.m
//  Mars-Images
//
//  Created by Mark Powell on 11/17/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import "MarsNotebook.h"
#import "Evernote.h"

#define OPPY_NOTEBOOK_ID @"758b3821-6e6d-484d-b297-f4bdfa2aabdc"
#define MSL_NOTEBOOK_ID @"c5ddfcb6-6878-4f9f-96ef-04fe50da1c10"
#define SPIRIT_NOTEBOOK_ID @"7db68065-53c3-4211-be9b-79dfa4a7a2be"

#define EARTH_SECS_PER_MARS_SEC 1.027491252;

@implementation MarsNotebook

@synthesize instrumentIndex;
@synthesize eyeIndex;
@synthesize sampleTypeIndex;
@synthesize titleImageIdPosition;
@synthesize internetReachable;
@synthesize currentNotebookId;
@synthesize searchWords;
@synthesize noteGUIDs;
@synthesize noteTitles;
@synthesize missionNames;
@synthesize currentMission;
@synthesize imageCache;
@synthesize lastSleepTime;
@synthesize currentEpochDate;
@synthesize spiritEpochDate;
@synthesize oppyEpochDate;
@synthesize mslEpochDate;
@synthesize formatter;

static MarsNotebook *instance = nil;

+ (MarsNotebook *) instance {
    if (instance == nil) {
        instance = [[MarsNotebook alloc] init];
    }
    return instance;
}

- (MarsNotebook *) init {
    MarsNotebook *notebook = [super init];
    NSString *missionKey = @"mission";
    instance = self;
    self.lastSleepTime = nil;
    
    // SPIRIT(254, "MER-A", 'A', "Spirit", "/mera/", new Date("03 Jan 2004 13:36:15 UTC")),
    // OPPORTUNITY(253, "MER-B", 'B', "Opportunity", "/merb/", new Date("24 Jan 2004 15:08:59 UTC")),
    // CURIOSITY new Date("6 Aug 2012 6:30:00 UTC")
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if ([prefs stringForKey:missionKey] == nil) {
        [prefs setObject:@"Curiosity" forKey: missionKey];
        [prefs synchronize];
    }
    self.currentMission = [prefs stringForKey: missionKey];
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:3];
    [comps setMonth:1];
    [comps setYear:2004];
    [comps setHour:13];
    [comps setMinute:36];
    [comps setSecond:15];
    [comps setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    self.spiritEpochDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
    
    comps = [[NSDateComponents alloc] init];
    [comps setDay:24];
    [comps setMonth:1];
    [comps setYear:2004];
    [comps setHour:15];
    [comps setMinute:8];
    [comps setSecond:59];
    [comps setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    self.oppyEpochDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
    
    comps = [[NSDateComponents alloc] init];
    [comps setDay:6];
    [comps setMonth:8];
    [comps setYear:2012];
    [comps setHour:6];
    [comps setMinute:30];
    [comps setSecond:00];
    [comps setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    self.mslEpochDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
    
    self.formatter = [[NSDateFormatter alloc] init];
	[self.formatter setTimeStyle:NSDateFormatterNoStyle];
    [self.formatter setDateStyle:NSDateFormatterLongStyle];
	
    // check for internet connection
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
    [self setInternetReachable:[Reachability reachabilityForInternetConnection]];
    [self.internetReachable startNotifier];
    
    self.noteTitles = [[NSMutableArray alloc] init];
    self.noteGUIDs = [[NSMutableDictionary alloc] init];
    self.imageCache = [[NSMutableDictionary alloc] init];
    self.missionNames = [[NSArray alloc] initWithArray: [NSArray arrayWithObjects:
                                                    @"Curiosity",
                                                    @"Opportunity",
                                                    @"Spirit",
                                                    nil]];
    
    [self setStateForCurrentMissionSetting];
    
    return notebook;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //ARC will call [super dealloc], we can't explicitly do that under ARC
}

- (void) setCurrentMission:(NSString *)mission {
    currentMission = mission;
    [self setStateForCurrentMissionSetting];
}

//TODO an enum for this would be cleaner
- (void) setStateForCurrentMissionSetting {
    if ([currentMission isEqualToString:@"Opportunity"]) {
        currentEpochDate = oppyEpochDate;
        currentNotebookId = OPPY_NOTEBOOK_ID;
        instrumentIndex = 1;
        eyeIndex = 23;
        sampleTypeIndex = 12;
        titleImageIdPosition = 2; // "Sol 123 1F123456789...."
        [Evernote sharedInstance].publicUser = @"marsrovers";
        //Android uses userStore.publicUserInfo(username) to get the shard...a cleaner way to do this?
        [Evernote sharedInstance].uriPrefix = @"https://www.evernote.com/shard/s139/notestore";
    } else if ([currentMission isEqualToString:@"Spirit"]) {
        currentEpochDate = spiritEpochDate;
        currentNotebookId = SPIRIT_NOTEBOOK_ID;
        instrumentIndex = 1;
        eyeIndex = 23;
        sampleTypeIndex = 12; // "Sol 123 2F123456789...."
        titleImageIdPosition = 2;
        [Evernote sharedInstance].publicUser = @"spiritrover";
        [Evernote sharedInstance].uriPrefix = @"https://www.evernote.com/shard/s209/notestore";
    }
    else {
        currentEpochDate = mslEpochDate;
        currentNotebookId = MSL_NOTEBOOK_ID;
        instrumentIndex = 0;
        eyeIndex = 1;
        sampleTypeIndex = 17;
        titleImageIdPosition = 3; // "Sol 12345 123456789 FLB_123456789...
        [Evernote sharedInstance].publicUser = @"curiosityrover";
        [Evernote sharedInstance].uriPrefix = @"https://www.evernote.com/shard/s241/notestore";
    }
}

- (EDAMNote*) getNote: (NSString*) guid {
    EDAMNote *note = nil;
    if ([[self internetReachable] currentReachabilityStatus] == NotReachable) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Network Error"
                                                          message:@"Unable to connect to the network."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
        return note;
    }
    @try {
        note = [[Evernote sharedInstance] getNote:guid];
        return note;
    }
    @catch (NSException *e) {
        @try {
            note = [[Evernote sharedInstance] getNote:guid reauthenticate:YES];
            return note;
        }
        @catch (NSException *e) {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Service Connection Error"
                                                              message:@"The Mars image service is temporarily unavailable. Please try again later."
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
            [message show];
            return note;
        }
    }
    return note;
}

- (void) loadMoreNotes: (int) startIndex
             withTotal: (int) total
    withNavigationItem: (UINavigationItem*) navigationItem
        withController: (MasterViewController*) viewController {
    @synchronized (self) {
        viewController.reloading = YES;
        
        if (internetReachable.currentReachabilityStatus == NotReachable) {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Network Error"
                                                              message:@"Unable to connect to the network."
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
            [message show];
            viewController.reloading = NO;
            return;
        }
        
        UIActivityIndicatorView *spinner =
        [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithCustomView:spinner];
        [navigationItem setRightBarButtonItem:barButton];
        [spinner startAnimating];
        
        dispatch_queue_t downloadQueue = dispatch_queue_create("note downloader", NULL);
        dispatch_async(downloadQueue, ^{
            EDAMNoteFilter* filter = [[EDAMNoteFilter alloc] init];
            
            filter.notebookGuid = currentNotebookId;
            filter.order = NoteSortOrder_TITLE;
            filter.ascending = NO;
            if (searchWords != nil && [searchWords length]>0) {
                filter.words = [self formatSearchWords: searchWords];
            }
            EDAMNotesMetadataList* metadataList = nil;
            EDAMNotesMetadataResultSpec* metadata = [[EDAMNotesMetadataResultSpec alloc] init];
            [metadata setIncludeTitle:YES];
            @try {
                metadataList = [[Evernote sharedInstance] findNotesMetadata: filter withStartIndex:startIndex withTotal:total withMetadata:metadata];
            }
            @catch (NSException *e) {
                NSLog(@"Exception listing note metadata: %@ %@", e.name, e.description);
                [[Evernote sharedInstance] setNoteStore: nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Service Unavailable"
                                                                      message:@"The Mars image service is currently unavailable. Please try again later."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    [message show];
                });
                viewController.reloading = NO;
                return;
            }
            @finally {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [navigationItem setRightBarButtonItem:nil];
                    [spinner stopAnimating];
                });
            }
            
            for (int j = 0; j < [[metadataList notes] count]; j++) {
                EDAMNoteMetadata* note = (EDAMNoteMetadata*)[[metadataList notes] objectAtIndex:j];
                [noteTitles addObject:note.title];
                [noteGUIDs setObject:note.guid forKey:note.title];
            }
            
            viewController.reloading = NO;
            
            if ([[metadataList notes] count] > 0 && [viewController tableView] != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[viewController tableView] reloadData];
                });
            }
        });
    }
}

- (NSString*) formatSearchWords: (NSString*) origSearch {
    NSArray *chunks = [origSearch componentsSeparatedByString: @" "];
    NSMutableArray* tokens = [[NSMutableArray alloc] init];
    for (int i = 0; i < [chunks count]; i++) {
        NSString* chunk = [chunks objectAtIndex:i];
        if ( ! [[chunk lowercaseString] isEqualToString:@"sol"]) {
            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
            NSNumber* number = [f numberFromString: chunk];
            if (number != nil) {
                [tokens addObject:[NSString stringWithFormat:@"\"Sol %04d\"", [number intValue]]];
            } else {
                [tokens addObject: chunk];
            }
        }
    }
    NSString* formattedSearch = [tokens componentsJoinedByString: @" "];
    return formattedSearch;
}

- (NSString*) getUpperCellText: (NSString*) imageID
                     withTitle: (NSString*) title {
    
    if ([imageID isEqualToString:@"Course"]) {
        NSArray* tokens = [title componentsSeparatedByString:@" "];
        if ([tokens count] >= 5) {
            return [NSString stringWithFormat:@"Drive for %@ meters", [tokens objectAtIndex:4]];
        }
        return title;
    }
    
    NSString* text = @"";
    NSString* instrumentChar0 = [imageID substringWithRange:NSMakeRange(0,1)];
    NSString* instrumentChar1 = [imageID substringWithRange:NSMakeRange(instrumentIndex,1)];
    BOOL isMERPancamColor = [@"P" isEqualToString: instrumentChar0];
    BOOL isMSSS = ([self isNumeric:[imageID characterAtIndex:0]] && [currentMission isEqualToString: @"Curiosity"]);
    
    //start with the camera name
    if (isMSSS) {
        instrumentChar1 = [imageID substringWithRange:NSMakeRange(5,1)];
        if ([@"L" isEqualToString:instrumentChar1]) {
            text = [text stringByAppendingString: @"Mastcam Left 34"];
        }
        else if ([@"R" isEqualToString:instrumentChar1]) {
            text = [text stringByAppendingString: @"Mastcam Right 100"];
        }
        else if ([@"H" isEqualToString:instrumentChar1]) {
            text = [text stringByAppendingString: @"MAHLI"];
        }
        else if ([@"D" isEqualToString:instrumentChar1]) {
            text = [text stringByAppendingString: @"MARDI"];
        }
    } else {
        if ([@"F" isEqualToString:instrumentChar1]) {
            text = [text stringByAppendingString: @"Front Hazcam"];
        }
        else if ([@"R" isEqualToString: instrumentChar1]) {
            text = [text stringByAppendingString: @"Rear Hazcam"];
        }
        else if ([@"N" isEqualToString: instrumentChar1]) {
            text = [text stringByAppendingString: @"Navcam"];
        }
        else if ([@"P" isEqualToString: instrumentChar1] || isMERPancamColor) {
            text = [text stringByAppendingString: @"Pancam"];
        }
        else if ([@"M" isEqualToString: instrumentChar1]) {
            text = [text stringByAppendingString: @"Microscopic Imager"];
        }
    }
    
    //add the camera eye
    if (isMERPancamColor) {
        text = [text stringByAppendingString: @" Left"];
    } else if (! isMSSS){
        NSString* eye = [imageID substringWithRange:NSMakeRange(eyeIndex, 1)];
        if ([@"L" isEqualToString:eye]) {
            text = [text stringByAppendingString: @" Left"];
        }
        else if ( ! [@"M" isEqualToString: instrumentChar1]) {
            text = [text stringByAppendingString: @" Right"];
        }
    }
    
    //for MER Pancam Color, return out early with false color
    if (isMERPancamColor) {
        text = [text stringByAppendingString: @" False Color"];
        return text;
    }
    
    //filter position number from the image ID
    if ([@"P" isEqualToString: instrumentChar1]) {
        text = [text stringByAppendingString: [NSString stringWithFormat:@" %@", [imageID substringWithRange: NSMakeRange(24, 1)]]];
    }
    
    //sample type: Full Frame, Subframed, or Downsampled from the image ID
    if (!isMSSS) {
        NSString* sample = [imageID substringWithRange:NSMakeRange(sampleTypeIndex,1)];
        if ([@"F" isEqualToString: sample]) {
            text = [text stringByAppendingString:@" Full Frame"];
        }
        else if ([@"S" isEqualToString: sample]) {
            text = [text stringByAppendingString:@" Subframed"];
        }
        else if ([@"D" isEqualToString: sample]) {
            text = [text stringByAppendingString:@" Downsampled"];
        }
    }
    return text;
}

- (NSString*) getLowerCellText: (NSString*) imageID withSol: (int) sol {
    
    double interval = sol*24*60*60*EARTH_SECS_PER_MARS_SEC;
    NSDate* imageDate = [NSDate dateWithTimeInterval:interval sinceDate:currentEpochDate];
    
    //    return [NSString stringWithFormat: @"Sol %d SeqID %@  SCLK %@", sol,
    //            [imageID substringWithRange: NSMakeRange(18,5)],
    //            [imageID substringWithRange: NSMakeRange(2, 9)]];
        
    return [NSString stringWithFormat: @"Sol %d  %@", sol
            , [formatter stringFromDate:imageDate]
            ];
}

- (BOOL) isNumeric: (char) c {
    return c >= '0' && c <= '9';
}

- (void) startThumbnailLoaderThread:(NSString*) imageID withCell: (UITableViewCell*) cell withSol: (int) sol {
    
    if ([internetReachable currentReachabilityStatus] == NotReachable)
        return;
    
    BOOL isMERColorPancam = [@"P" isEqualToString: [imageID substringWithRange:NSMakeRange(0,1)]];
    BOOL isFirstCharNumeric = [self isNumeric:[imageID characterAtIndex:0]];
    BOOL isMSSS = ([self isNumeric:[imageID characterAtIndex:0]] && [currentMission isEqualToString: @"Curiosity"]);
    NSString *thumbnailFilename;
    if ([currentMission isEqualToString:@"Opportunity"] || [currentMission isEqualToString:@"Spirit"]) {
        if (isFirstCharNumeric) {
            thumbnailFilename = [imageID stringByReplacingCharactersInRange:NSMakeRange(11, 3) withString:@"ETH"];
        }
    }
    else {
        if (!isMSSS) { //MIPL
            thumbnailFilename =
            [imageID stringByReplacingCharactersInRange:NSMakeRange(sampleTypeIndex, 1) withString:@"T"];
        }
    }
    
    dispatch_queue_t downloadQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(downloadQueue, ^{
        NSString* path;
        if ([currentMission isEqualToString:@"Opportunity"]) {
            if ([imageID isEqualToString:@"Course"])
                path = [NSString stringWithFormat:
                        @"http://merpublic.s3.amazonaws.com/oss/merb/ops/ops/surface/tactical/sol/%.3d/sret/mobidd/mot-all-report/cache-mot-all-report/hyperplots/raw_north_vs_raw_east_thumb.png",
                        sol];
            else if (isMERColorPancam) {
                //http://marswatch.astro.cornell.edu/pancam_instrument/images/False/Sol3112B_P2419_1_False_L257_pos_3_thumb.jpg
                path = @"http://marswatch.astro.cornell.edu/pancam_instrument/images/False/Sol";
                path = [path stringByAppendingString:[NSString stringWithFormat:@"%.3dB_", sol]];
                path = [path stringByAppendingString:imageID];
                path = [path stringByAppendingString:@"_thumb.jpg"];
            } else {
                path = @"http://merpublic.s3.amazonaws.com/oss_maestro/merb/ops/ops/surface/tactical/sol/";
                path = [path stringByAppendingString:[NSString stringWithFormat:@"%.3d", sol]];
                path = [path stringByAppendingString:@"/opgs/edr/"];
                path = [path stringByAppendingString:[self getInstrumentDirForImageId: imageID]];
                path = [path stringByAppendingString:@"/"];
                path = [path stringByAppendingString:thumbnailFilename];
                path = [path stringByAppendingString:@".JPG"];
            }
        } else if ([currentMission isEqualToString:@"Spirit"]) {
            if ([imageID isEqualToString:@"Course"])
                path = [NSString stringWithFormat:
                        @"http://merpublic.s3.amazonaws.com/oss/mera/ops/ops/surface/tactical/sol/%.3d/sret/mobidd/mot-all-report/cache-mot-all-report/hyperplots/raw_north_vs_raw_east_thumb.png",
                        sol];
            else if (isMERColorPancam) {
                //http://marswatch.astro.cornell.edu/pancam_instrument/images/False/Sol2018A_P2284_1_False_L456_pos_9_thumb.jpg
                path = @"http://marswatch.astro.cornell.edu/pancam_instrument/images/False/Sol";
                path = [path stringByAppendingString:[NSString stringWithFormat:@"%.3dA_", sol]];
                path = [path stringByAppendingString:imageID];
                path = [path stringByAppendingString:@"_thumb.jpg"];
            } else {
                path = @"http://merpublic.s3.amazonaws.com/oss_maestro/mera/ops/ops/surface/tactical/sol/";
                path = [path stringByAppendingString:[NSString stringWithFormat:@"%.3d", sol]];
                path = [path stringByAppendingString:@"/opgs/edr/"];
                path = [path stringByAppendingString:[self getInstrumentDirForImageId: imageID]];
                path = [path stringByAppendingString:@"/"];
                path = [path stringByAppendingString:thumbnailFilename];
                path = [path stringByAppendingString:@".JPG"];
            }
        }
        else {
            if (isMSSS) {
                path = @"http://mars.jpl.nasa.gov/msl-raw-images/msss/";
                path = [path stringByAppendingString:[NSString stringWithFormat:@"%.5d/", sol]];
                path = [path stringByAppendingString:[self getInstrumentDirForImageId: imageID]];
                path = [path stringByAppendingString:@"/"];
                path = [path stringByAppendingString:imageID];
                path = [path stringByAppendingString:@"-thm.jpg"];
            } else {
                path = @"http://mars.jpl.nasa.gov/msl-raw-images/proj/msl/redops/ods/surface/sol/";
                path = [path stringByAppendingString:[NSString stringWithFormat:@"%.5d", sol]];
                path = [path stringByAppendingString:@"/opgs/edr/"];
                path = [path stringByAppendingString:[self getInstrumentDirForImageId: imageID]];
                path = [path stringByAppendingString:@"/"];
                path = [path stringByAppendingString:thumbnailFilename];
                path = [path stringByAppendingString:@".JPG"];
            }
        }
//        NSLog(@"thumbnail URL %@", path);
        
        UIImage* image = [self getImageFromCache: path];
        dispatch_async(dispatch_get_main_queue(), ^{
            [cell.imageView setImage: image];
            [cell setNeedsLayout];
        });
    });
}

- (UIImage*) getImageFromCache:(NSString*)url {
    UIImage* retImage = [imageCache objectForKey:url];
    if (retImage == nil) {
        NSString* escapedURL = [url stringByReplacingOccurrencesOfString:@"#" withString:@"%23"];
        retImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:escapedURL]]];
        if (retImage != nil) {
            [imageCache setObject:retImage forKey:url];
        }
    }
    return retImage;
}

- (NSString*) getInstrumentDirForImageId:(NSString*) imageID {
    BOOL isMSSS = ([self isNumeric:[imageID characterAtIndex:0]] && [currentMission isEqualToString:@"Curiosity"]);
    NSString* instrument = [imageID substringWithRange:NSMakeRange(instrumentIndex,1)];
    if (isMSSS) {
        instrument = [imageID substringWithRange:NSMakeRange(5,1)];
        if ([@"L" isEqualToString:instrument] || [@"R" isEqualToString:instrument]) {
            return @"mcam";
        }
        else if ([@"H" isEqualToString:instrument]) {
            return @"mhli";
        }
        else if ([@"D" isEqualToString:instrument]) {
            return @"mrdi";
        }
    }
    else {
        if ([@"F" isEqualToString:instrument]) {
            return @"fcam";
        }
        else if ([@"R" isEqualToString: instrument]) {
            return @"rcam";
        }
        else if ([@"N" isEqualToString: instrument]) {
            return @"ncam";
        }
        else if ([@"P" isEqualToString: instrument]) {
            return @"pcam";
        }
        else if ([@"M" isEqualToString: instrument]) {
            return @"mi";
        }
    }
    return @"";
}

- (void) checkNetworkStatus:(NSNotification *)notice {
    // called after network status changes from Reachability selector
    NSLog(@"start checkNetwork");
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    switch (internetStatus)
    {
        case NotReachable:
        {
            NSLog(@"The internet is down.");
            break;
        }
        case ReachableViaWiFi:
        {
            NSLog(@"The internet is working via WIFI.");
            break;
        }
        case ReachableViaWWAN:
        {
            NSLog(@"The internet is working via WWAN.");
            break;
        }
    }
    NSLog(@"end checkNetwork");
}

- (NSString*) getSolForNote: (EDAMNote*) note {
    NSArray* tokens = [note.title componentsSeparatedByString:@" "];
    if (tokens.count >= 2) {
        int sol = [[tokens objectAtIndex:1] integerValue];
        return [NSString stringWithFormat:@"%03d", sol];
    }
    else
        return @"UNKNOWN";
}

- (NSArray*) parseTitleChunks: (NSString*) title {
    return [title componentsSeparatedByString: @" "];
}

- (NSString*) getAnaglyphTitle: (NSString*) title {
    NSString* imageID = [self getImageIDForTitle:title];
    
    if ([currentMission isEqualToString:@"Curiosity"]) {
        //early out on MSSS images
        BOOL isMSSS = ([self isNumeric:[imageID characterAtIndex:0]]);
        if (isMSSS)
            return nil;

        //only Hazcams and Navcams are anaglyph capable for now
        NSArray* chunks = [self parseTitleChunks:title];
        char eye = [imageID characterAtIndex:1];
        NSMutableString* anaglyphId = [[NSMutableString alloc] initWithString: imageID];
        NSString* otherEye = (eye == 'R') ? @"L" : @"R";
        [anaglyphId replaceCharactersInRange:NSMakeRange(1,1) withString:otherEye];
        return [NSString stringWithFormat:@"%@ %@ %@ %@", [chunks objectAtIndex:0], [chunks objectAtIndex:1], [chunks objectAtIndex: 2], anaglyphId];
        
    } else if ([currentMission isEqualToString:@"Opportunity"] || [currentMission isEqualToString:@"Spirit"]) {
        //early out on MIs, Course Plots and false color Pancams
        BOOL isMERColorPancam = [@"P" isEqualToString: [imageID substringWithRange:NSMakeRange(0,1)]];
        BOOL isMI = [@"M" isEqualToString:[imageID substringWithRange:NSMakeRange(1,2)]];
        BOOL isCoursePlot = [imageID isEqualToString:@"Course"];
        if (isMI || isMERColorPancam || isCoursePlot)
            return nil;
    
        //any Hazcams, Navcams, or Pancams with the same SCLK, SeqID and filter number may anaglyph
        NSArray* chunks = [self parseTitleChunks:title];
        char eye = [imageID characterAtIndex:23];
        NSMutableString* anaglyphId = [[NSMutableString alloc] initWithString: imageID];
        NSString* otherEye = (eye == 'R') ? @"L" : @"R";
        [anaglyphId replaceCharactersInRange:NSMakeRange(23,1) withString:otherEye];
        return [NSString stringWithFormat:@"%@ %@ %@", [chunks objectAtIndex:0], [chunks objectAtIndex:1], anaglyphId];
    }
    
    return nil;
}

- (BOOL) isImageIdLeftEye: (NSString*) imageID {
    char eye = 'R';
    if ([currentMission isEqualToString: @"Curiosity"]) {
        eye = [imageID characterAtIndex:1];
    } else if ([currentMission isEqualToString:@"Opportunity"] || [currentMission isEqualToString:@"Spirit"]) {
        eye = [imageID characterAtIndex:23];
    }
    return eye == 'L';
}

- (NSString*) getImageIDForTitle: (NSString *) title {
    NSArray* chunks = [self parseTitleChunks: title];
    if ([chunks count] < 4) {
        return [chunks objectAtIndex:2];
    }
    return [chunks objectAtIndex:titleImageIdPosition];
}

- (int) getSolForTitle : (NSString*) title {
    NSArray* chunks = [self parseTitleChunks: title];
    int sol = [[chunks objectAtIndex: 1] intValue];
    return sol;
}

@end
