//
//  MarsImageNotebook.m
//  Mars-Images
//
//  Created by Mark Powell on 12/15/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MarsImageNotebook.h"
#import "CHCSVParser.h"
#import "Curiosity.h"
#import "Evernote.h"
#import "MarsPhoto.h"
#import "Opportunity.h"
#import "Spirit.h"

@implementation MarsImageNotebook

static MarsImageNotebook *instance = nil;
static dispatch_queue_t noteDownloadQueue = nil;

+ (MarsImageNotebook *) instance {
    if (instance == nil) {
        instance = [[MarsImageNotebook alloc] init];
        noteDownloadQueue = dispatch_queue_create("note downloader", DISPATCH_QUEUE_SERIAL);
    }
    return instance;
}

- (MarsImageNotebook*) init {
    self = [super init];
    instance = self;
    _notes = [[NSMutableDictionary alloc] init];
    _notePhotosArray = [[NSMutableArray alloc] init];
    _notesArray = [[NSMutableArray alloc] init];
    _sections = [[NSMutableDictionary alloc] init];
    _sols = [[NSMutableArray alloc] init];
    _lastSleepTime = nil;

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if ([prefs stringForKey:MISSION] == nil) {
        [prefs setObject:OPPORTUNITY forKey: MISSION];
        [prefs synchronize];
    }
    self.missionName = [prefs stringForKey: MISSION];
    _missions = [NSDictionary dictionaryWithObjectsAndKeys:
                 [[Opportunity alloc] init], OPPORTUNITY,
                 [[Spirit alloc] init], SPIRIT,
                 [[Curiosity alloc] init], CURIOSITY,
                 nil];
    NSArray* notebookGUIDs = [NSArray arrayWithObjects:OPPY_NOTEBOOK_ID, SPIRIT_NOTEBOOK_ID, MSL_NOTEBOOK_ID, nil];
    NSArray* missionKeys = [NSArray arrayWithObjects:OPPORTUNITY, SPIRIT, CURIOSITY, nil];
    _notebookIDs = [NSDictionary dictionaryWithObjects:notebookGUIDs forKeys:missionKeys];
    NSArray* users = [NSArray arrayWithObjects:@"opportunitymars", @"spiritmars", @"mslmars", nil];
    _evernoteUsers = [NSDictionary dictionaryWithObjects:users forKeys:missionKeys];

    [Evernote instance].publicUser = [_evernoteUsers valueForKey:self.missionName];

    _networkAlert = [[UIAlertView alloc] initWithTitle:@"Network Error"
                                                           message:@"Unable to connect to the network."
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];

    _serviceAlert = [[UIAlertView alloc] initWithTitle:@"Service Unavailable"
                                               message:@"The Mars image service is currently unavailable. Please try again later."
                                              delegate:nil
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];

    // check for internet connection
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
    [self setInternetReachable:[Reachability reachabilityForInternetConnection]];
    [self.internetReachable startNotifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];

    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void) notify:(NSString*)message {
    [[NSNotificationCenter defaultCenter] postNotificationName:message object:self];
}

+ (void) notifyNotesReturned: (int) total {
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:total], NUM_NOTES_RETURNED, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:END_NOTE_LOADING object:nil userInfo:dict];
}

- (id<MarsRover>) mission {
    return [_missions objectForKey:_missionName];
}

- (void) defaultsChanged:(id)sender {
    _locations = nil;
    [self getLocations];
}

- (void) loadMoreNotes: (int) startIndex
             withTotal: (int) total {
    if (_internetReachable.currentReachabilityStatus == NotReachable) {
        if (!_networkAlert.visible) {
            [_networkAlert show];
        }
        [MarsImageNotebook notifyNotesReturned:0];
        return;
    }
    
    dispatch_async(noteDownloadQueue, ^{
        if (_notesArray.count > startIndex) {
            return;
        }
        
        [MarsImageNotebook notify: BEGIN_NOTE_LOADING];
        
        EDAMNoteList* notelist = [[EDAMNoteList alloc] init];
        @try {
            EDAMNoteFilter* filter = [[EDAMNoteFilter alloc] init];
            filter.notebookGuid = [_notebookIDs valueForKey:_missionName];
            filter.order = NoteSortOrder_TITLE;
            filter.ascending = NO;
            if (_searchWords != nil && [_searchWords length]>0) {
                filter.words = [self formatSearch:_searchWords];
            }
            
            notelist = [[Evernote instance] findNotes: filter withStartIndex:startIndex withTotal:total];
            
            for (int j = 0; j < notelist.notes.count; j++) {
                EDAMNote* note = [notelist.notes objectAtIndex:j];
                note = [MarsImageNotebook reorderResources:note];
                [(NSMutableArray*)_notesArray addObject: note];
                NSNumber* sol = [NSNumber numberWithInt:[self.mission sol:note]];
                int lastSolIndex = _sols.count-1;
                if (lastSolIndex < 0 || ![[_sols objectAtIndex:lastSolIndex] isEqualToNumber: sol])
                    [(NSMutableArray*)_sols addObject:sol];
                NSMutableArray* notesForSol = [_notes objectForKey:sol];
                if (!notesForSol)
                    notesForSol = [[NSMutableArray alloc] init];
                [notesForSol addObject:note];
                [(NSMutableDictionary*)_notes setObject:notesForSol forKey:sol];
                MarsPhoto* photo = [self getNotePhoto:j+startIndex withIndex:0];
                [(NSMutableArray*)_notePhotosArray addObject:photo];
                [(NSMutableDictionary*)_sections removeObjectForKey:sol];
                [(NSMutableDictionary*)_sections setObject:[NSNumber numberWithInt:_sections.count] forKey:sol];
                if (_sections.count != _sols.count) {
                    NSLog(@"Brown alert: sections and sols counts don't match each other.");
                }
            }

            [MarsImageNotebook notifyNotesReturned:notelist.notes.count];

        } @catch (NSException *e) {
            NSLog(@"Exception listing notes: %@ %@", e.name, e.description);
            [[Evernote instance] setNoteStore: nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!_serviceAlert.visible) {
                    [_serviceAlert show];
                }
            });
            [MarsImageNotebook notifyNotesReturned:0];
            return;
        }
    });
}

- (NSString*) formatSearch: (NSString*) text {
    NSArray* words = [text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableString* formattedText = [[NSMutableString alloc] init];
    for (NSString* w in words) {
        NSString* word = [NSString stringWithString:w];
        if ([word length] == 13 && [word characterAtIndex:6] == '-')
            ; //do nothing for an RMC formatted as XXXXXX-XXXXXX
        else if ([word intValue] > 0 && ![word hasSuffix:@"*"])
            word = [NSString stringWithFormat:@"\"Sol %05d\"", [word intValue]];
        
        if (formattedText.length > 0)
            [formattedText appendString:@" "];
        
        [formattedText appendString: [NSString stringWithFormat:@"intitle:%@", word]];
    }
    NSLog(@"formatted text: %@", formattedText);
    return formattedText;
}

- (MarsPhoto*) getNotePhoto: (int) noteIndex
                withIndex: (int) imageIndex {
    EDAMNote* note = [_notesArray objectAtIndex:noteIndex];
    if (!note) return nil;
    if (imageIndex >= note.resources.count)
        NSLog(@"Brown alert: requested image index is out of bounds.");

    EDAMResource* resource = [note.resources objectAtIndex:imageIndex];
    NSString* resGUID = resource.guid;
    NSString* imageURL = [NSString stringWithFormat:@"%@res/%@", Evernote.instance.user.webApiUrlPrefix, resGUID];
    return [[MarsPhoto alloc] initWithResource:resource note:note url:[NSURL URLWithString:imageURL]];
}

- (void) changeToImage: (int)imageIndex
               forNote: (int)noteIndex {
    MarsPhoto* photo = [self getNotePhoto:noteIndex withIndex:imageIndex];
    [(NSMutableArray*)_notePhotosArray replaceObjectAtIndex:noteIndex withObject:photo];
}

- (void) changeToAnaglyph: (NSArray*) leftAndRight
                noteIndex: (int) noteIndex {
    EDAMNote* note = [_notesArray objectAtIndex:noteIndex];
    if (!note) return;
    MarsPhoto* anaglyph = [[MarsPhoto alloc] initAnaglyph: leftAndRight note:note];
    [(NSMutableArray*)_notePhotosArray replaceObjectAtIndex:noteIndex withObject:anaglyph];
}

- (void) reloadNotes {
    [(NSMutableDictionary*)_notes removeAllObjects];
    [(NSMutableArray*)_notesArray removeAllObjects];
    [(NSMutableArray*)_notePhotosArray removeAllObjects];
    [(NSMutableDictionary*) _sections removeAllObjects];
    [(NSMutableArray*) _sols removeAllObjects];
    [self loadMoreNotes:0 withTotal:NOTE_PAGE_SIZE];
}

- (void) checkNetworkStatus:(NSNotification *)notice {
    // called after network status changes from Reachability selector
    NSLog(@"start checkNetwork");
    NetworkStatus internetStatus = [_internetReachable currentReachabilityStatus];
    switch (internetStatus) {
        case NotReachable: {
            NSLog(@"The internet is down.");
            break;
        }
        case ReachableViaWiFi: {
            NSLog(@"The internet is working via WIFI.");
            break;
        }
        case ReachableViaWWAN: {
            NSLog(@"The internet is working via WWAN.");
            break;
        }
    }
    NSLog(@"end checkNetwork");
}

+ (EDAMNote*) reorderResources: (EDAMNote*) note {
    NSMutableArray* sortedResources = [[NSMutableArray alloc] init];
    NSMutableArray* resourceFilenames = [[NSMutableArray alloc] init];
    NSMutableDictionary* resourcesByFile = [[NSMutableDictionary alloc] init];
    
    for (EDAMResource* resource in note.resources) {
        NSString* filename = [[MarsImageNotebook instance].mission getSortableImageFilename:resource.attributes.sourceURL];
        [resourceFilenames addObject:filename];
        [resourcesByFile setObject:resource forKey:filename];
    }
    
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:nil ascending:YES];
    NSArray* sortedFilenames = [resourceFilenames sortedArrayUsingDescriptors:@[sd]];
    for (NSString* filename in sortedFilenames) {
        [sortedResources addObject: [resourcesByFile objectForKey:filename]];
    }
    
    note.resources = sortedResources;
    return note;
}

- (NSArray*) getNearestRMC {
    int user_site = 0;
    int user_drive = 0;
    
    //find the RMC of the newest image/note
    NSNumberFormatter* format = [[NSNumberFormatter alloc] init];
    [format setNumberStyle:NSNumberFormatterDecimalStyle];
    for (EDAMNote* note in _notesArray) {
        if ([note.title rangeOfString:@"RMC"].location == NSNotFound) {
            continue;
        }
        NSString* rmcString = [note.title substringFromIndex:note.title.length-13];
        NSString* siteString = [rmcString substringToIndex:6];
        NSString* driveString = [rmcString substringFromIndex:7];
        NSNumber* site = [format numberFromString:siteString];
        NSNumber* drive = [format numberFromString:driveString];
        user_site = site.intValue;
        user_drive = drive.intValue;
        break;
    }
    
    //find the RMC in locations closest to the RMC of the newest image
    int site_index = [[[_locations objectAtIndex:[_locations count]-1] objectAtIndex:0] intValue];
    int drive_index = [[[_locations objectAtIndex:[_locations count]-1] objectAtIndex:1] intValue];
    
    if (user_site != 0 || user_drive != 0) {
        for (int i = [_locations count]-1; i >=0; i--) {
            int a_site_index = [[[_locations objectAtIndex:i] objectAtIndex:0] intValue];
            int a_drive_index = [[[_locations objectAtIndex:i] objectAtIndex:1] intValue];
            if (a_site_index*100000+a_drive_index < user_site*100000+user_drive)
                break;
            site_index = a_site_index;
            drive_index = a_drive_index;
        }
    }
    
    return [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:site_index], [NSNumber numberWithInt:drive_index], nil];
}

- (NSArray*) getPreviousRMC: (NSArray*) rmc {
    NSArray *prevRMC = nil, *location = nil;
    int prevSite = [[rmc objectAtIndex:0] intValue];
    int prevDrive = [[rmc objectAtIndex:1] intValue];
    
    if (_locations == nil) {
        [self getLocations];
    }
    
    for (int i = 0; i < [_locations count]; i++) {
        NSArray* anRMC = [_locations objectAtIndex:i];
        if ([[anRMC objectAtIndex:0] intValue] == prevSite &&
            [[anRMC objectAtIndex:1] intValue] == prevDrive &&
            i > 0) {
            location = [_locations objectAtIndex:i-1];
            break;
        }
    }
    if (location) {
        prevRMC = [[NSArray alloc] initWithObjects:
                   [NSNumber numberWithInt:[[location objectAtIndex:0] intValue]],
                   [NSNumber numberWithInt:[[location objectAtIndex:1] intValue]],
                   nil];
    }
    return prevRMC;
}

- (NSArray*) getNextRMC: (NSArray*) rmc {
    NSArray *nextRMC = nil, *location = nil;
    int nextSite = [[rmc objectAtIndex:0] intValue];
    int nextDrive = [[rmc objectAtIndex:1] intValue];
    
    if (_locations == nil) {
        [self getLocations];
    }
    
    for (int i = 0; i < [_locations count]; i++) {
        NSArray* anRMC = [_locations objectAtIndex:i];
        if ([[anRMC objectAtIndex:0] intValue] == nextSite &&
            [[anRMC objectAtIndex:1] intValue] == nextDrive &&
            i < [_locations count]-1) {
            location = [_locations objectAtIndex:i+1];
            break;
        }
    }
    if (location) {
        nextRMC = [[NSArray alloc] initWithObjects:
                   [NSNumber numberWithInt:[[location objectAtIndex:0] intValue]],
                   [NSNumber numberWithInt:[[location objectAtIndex:1] intValue]],
                   nil];
    }
    
    return nextRMC;
}

- (NSArray*) getLocations {
    
    if (_locations) return _locations;
    
    NSString* urlPrefix = [[MarsImageNotebook instance] mission].urlPrefix;
    NSURL* locationsURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/locations/location_manifest.csv", urlPrefix]];
    NSLog(@"location url: %@", locationsURL);
    NSURLRequest *request = [NSURLRequest requestWithURL:locationsURL];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (response) {
            NSString *csvString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding];

            NSArray* rows = [csvString CSVComponents];
            if ([rows count] <= 0) {
                NSLog(@"Brown alert: there are no locations. %@", csvString);
            }

            _locations = [[NSMutableArray alloc] initWithCapacity:[rows count]];
            for (int i = 0; i < [rows count]; i++) {
                NSArray* row = [rows objectAtIndex:i];
                if ([row count] >= 2) {
                    NSNumber* site_index = [NSNumber numberWithInt:[[row objectAtIndex:0] integerValue]];
                    NSNumber* drive_index = [NSNumber numberWithInt:[[row objectAtIndex:1] integerValue]];
                    [((NSMutableArray*)_locations) addObject: [NSArray arrayWithObjects:site_index, drive_index, nil]];
                }
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:LOCATIONS_LOADED object:nil userInfo:nil];

        } else {
            NSLog(@"Brown alert: Unexpected nil response from locations.");
        }
        
        if (connectionError) {
            NSLog(@"Error: %@", connectionError);
        }
    }];
    return _locations;
}

@end
