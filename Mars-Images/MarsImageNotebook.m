//
//  MarsImageNotebook.m
//  Mars-Images
//
//  Created by Mark Powell on 12/15/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MarsImageNotebook.h"
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
    _lastRequestedStartIndexToLoad = -1;
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
    NSArray* users = [NSArray arrayWithObjects:@"opportunitymars", @"spiritmars", @"curiositymars", nil];
    _evernoteUsers = [NSDictionary dictionaryWithObjects:users forKeys:missionKeys];

    [Evernote instance].publicUser = [_evernoteUsers valueForKey:self.missionName];

    // check for internet connection
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
    [self setInternetReachable:[Reachability reachabilityForInternetConnection]];
    [self.internetReachable startNotifier];

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

- (void) loadMoreNotes: (int) startIndex
             withTotal: (int) total {
    
    @synchronized (self) {
        [MarsImageNotebook notify: BEGIN_NOTE_LOADING];
        
        //if we already have these notes, don't load them again.
        if (startIndex == _lastRequestedStartIndexToLoad) {
            return;
        }
        _lastRequestedStartIndexToLoad = startIndex;
        
        if (_internetReachable.currentReachabilityStatus == NotReachable) {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Network Error"
                                                              message:@"Unable to connect to the network."
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
            [message show];
            [MarsImageNotebook notifyNotesReturned:0];
            return;
        }
        
        dispatch_async(noteDownloadQueue, ^{
            EDAMNoteFilter* filter = [[EDAMNoteFilter alloc] init];
            
            filter.notebookGuid = [_notebookIDs valueForKey:_missionName];
            filter.order = NoteSortOrder_TITLE;
            filter.ascending = NO;
            if (_searchWords != nil && [_searchWords length]>0) {
                filter.words = [self formatSearch:_searchWords];
            }
            EDAMNoteList* notelist = [[EDAMNoteList alloc] init];
            @try {
                notelist = [[Evernote instance] findNotes: filter withStartIndex:startIndex withTotal:total];
            }
            @catch (NSException *e) {
                NSLog(@"Exception listing notes: %@ %@", e.name, e.description);
                [[Evernote instance] setNoteStore: nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Service Unavailable"
                                                                      message:@"The Mars image service is currently unavailable. Please try again later."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    [message show];
                });
                [MarsImageNotebook notifyNotesReturned:0];
                return;
            }

            [(NSMutableArray*)_notesArray addObjectsFromArray: notelist.notes];
            for (int j = 0; j < notelist.notes.count; j++) {
                EDAMNote* note = [notelist.notes objectAtIndex:j];
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
        });
    }
}

- (NSString*) formatSearch: (NSString*) text {
    NSArray* words = [text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableString* formattedText = [[NSMutableString alloc] init];
    for (NSString* w in words) {
        NSString* word = [NSString stringWithString:w];
        
        if ([word intValue] > 0 && ![word hasSuffix:@"*"])
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
    _lastRequestedStartIndexToLoad = -1;
    [self loadMoreNotes:0 withTotal:15];
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

@end
