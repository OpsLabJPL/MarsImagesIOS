//
//  MarsImageNotebook.h
//  Mars-Images
//
//  Created by Mark Powell on 12/15/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Evernote.h"
#import "MarsRover.h"
#import "MarsPhoto.h"
#import "Reachability.h"

#define MISSION @"mission"
#define OPPORTUNITY @"Opportunity"
#define SPIRIT @"Spirit"
#define CURIOSITY @"Curiosity"

#define BEGIN_NOTE_LOADING @"beginNoteLoading"
#define END_NOTE_LOADING   @"endNoteLoading"
#define NUM_NOTES_RETURNED @"numNotesReturned"

#define OPPY_NOTEBOOK_ID   @"a7271bf8-0b06-495a-bb48-7c0c7af29f70"
#define MSL_NOTEBOOK_ID    @"0296f732-694d-4ccd-9f5b-5983dc98b9e0"
#define SPIRIT_NOTEBOOK_ID @"f1a72415-56e7-4244-8e12-def9be9c512b"

#define NOTE_PAGE_SIZE 15

@interface MarsImageNotebook : NSObject

@property(nonatomic, strong) NSDictionary* evernoteUsers;
@property(nonatomic, strong) Reachability* internetReachable;
@property(nonatomic, strong) NSDate*       lastSleepTime;
@property(nonatomic, strong) NSDictionary* missions;
@property(nonatomic, strong) NSString*     missionName;
@property(nonatomic, strong) NSDictionary* notebookIDs;
@property(nonatomic, strong) NSDictionary* notes;
@property(nonatomic, strong) UIAlertView*  networkAlert;
@property(nonatomic, strong) UIAlertView*  serviceAlert;
@property(nonatomic, strong) NSArray*      sols;
@property(nonatomic, strong) NSDictionary* sections;
@property(nonatomic, strong) NSArray*      notesArray;
@property(nonatomic, strong) NSArray*      notePhotosArray;
@property(nonatomic, strong) NSString*     searchWords;

+ (MarsImageNotebook*) instance;

- (id<MarsRover>) mission;

- (void) loadMoreNotes: (int) startIndex
             withTotal: (int) total;

- (MarsPhoto*) getNotePhoto: (int) noteIndex
                withIndex: (int) imageIndex;

- (void) changeToImage: (int)imageIndex
               forNote: (int)noteIndex;

- (void) changeToAnaglyph: (NSArray*) leftAndRight
                     noteIndex: (int)noteIndex;

- (NSString*) formatSearch: (NSString*) text;

- (void) reloadNotes;

- (void) checkNetworkStatus:(NSNotification *)notice;

+ (void) notify: (NSString*) message;

+ (EDAMNote*) reorderResources: (EDAMNote*) note;

- (NSArray*) getLatestRMC;

- (NSArray*) notesForRMC: (NSArray*) latestRMC;

@end
