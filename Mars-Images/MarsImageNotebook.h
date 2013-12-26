//
//  MarsImageNotebook.h
//  Mars-Images
//
//  Created by Mark Powell on 12/15/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MarsRover.h"
#import "MWPhoto.h"
#import "Reachability.h"

#define MISSION @"mission"
#define OPPORTUNITY @"Opportunity"
#define SPIRIT @"Spirit"
#define CURIOSITY @"Curiosity"

#define BEGIN_NOTE_LOADING @"beginNoteLoading"
#define END_NOTE_LOADING   @"endNoteLoading"
#define NUM_NOTES_RETURNED @"numNotesReturned"

#define OPPY_NOTEBOOK_ID   @"a7271bf8-0b06-495a-bb48-7c0c7af29f70"
#define MSL_NOTEBOOK_ID    @"c5ddfcb6-6878-4f9f-96ef-04fe50da1c10"
#define SPIRIT_NOTEBOOK_ID @"7db68065-53c3-4211-be9b-79dfa4a7a2be"

@interface MarsImageNotebook : NSObject

@property(nonatomic, strong) NSDictionary*        evernoteUsers;
@property(nonatomic, strong) Reachability*        internetReachable;
@property(nonatomic, readonly) int                lastRequestedStartIndexToLoad;
@property(nonatomic, strong) NSDate*              lastSleepTime;
@property(nonatomic, strong) NSDictionary*        missions;
@property(nonatomic, strong) NSString*            missionName;
@property(nonatomic, strong) NSDictionary*        notebookIDs;
@property(nonatomic, strong) NSMutableArray*      notes;
@property(nonatomic, strong) NSMutableArray*      notePhotos;
@property(nonatomic, strong) NSString*            searchWords;

+ (MarsImageNotebook*) instance;

- (id<MarsRover>) mission;

- (void) loadMoreNotes: (int) startIndex
             withTotal: (int) total;

- (MWPhoto*) getNotePhoto: (int) noteIndex
                withIndex: (int) imageIndex;

- (NSArray*) getResources: (int) noteIndex;

- (void) changeToImage: (int)imageIndex
               forNote: (int)noteIndex;

- (void) changeToAnaglyph: (NSArray*) leftAndRight
                noteIndex: (int)noteIndex;

- (void) reloadNotes;

- (void) checkNetworkStatus:(NSNotification *)notice;

+ (void) notify: (NSString*) message;

@end
