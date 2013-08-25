//
//  MarsNotebook.h
//  Mars-Images
//
//  Created by Mark Powell on 11/17/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
#import "MasterViewController.h"
#import "Evernote.h"

@interface MarsNotebook : NSObject

+ (MarsNotebook *) instance;

@property                    int                  instrumentIndex;
@property                    int                  eyeIndex;
@property                    int                  sampleTypeIndex;
@property                    int                  titleImageIdPosition;
@property(nonatomic, strong) Reachability*        internetReachable;
@property(nonatomic, strong) NSString*            currentNotebookId;
@property(nonatomic, strong) NSString*            searchWords;
@property(nonatomic, strong) NSString*            currentMission;
@property(nonatomic, strong) NSArray*             missionNames;
@property(nonatomic, strong) NSMutableDictionary* imageCache;
@property(nonatomic, strong) NSMutableArray*      noteTitles;
@property(nonatomic, strong) NSMutableDictionary* noteGUIDs;
@property(nonatomic, strong) NSDate*              lastSleepTime;
@property(nonatomic, strong) NSDate*              currentEpochDate;
@property(nonatomic, strong) NSDate*              spiritEpochDate;
@property(nonatomic, strong) NSDate*              oppyEpochDate;
@property(nonatomic, strong) NSDate*              mslEpochDate;
@property(nonatomic, strong) NSDateFormatter*     formatter;

- (EDAMNote*) getNote: (NSString*) guid;

- (void) loadMoreNotes: (int) startIndex
             withTotal: (int) total
    withNavigationItem: (UINavigationItem*) navigationItem
         withController: (MasterViewController*) viewController;

- (void) setStateForCurrentMissionSetting;

- (NSString*) formatSearchWords: (NSString*) searchWords;

- (NSString*) getUpperCellText: (NSString*) imageID
                 withTitle: (NSString*) title;

- (NSString*) getLowerCellText: (NSString*) imageID
                       withSol: (int) sol;

- (void)startThumbnailLoaderThread:(NSString*) imageID
                          withCell: (UITableViewCell*) cell
                           withSol: (int) sol;

- (UIImage*) getImageFromCache:(NSString*)url;

- (NSString*) getInstrumentDirForImageId:(NSString*) imageID;

- (BOOL) isNumeric: (char) c;

- (NSArray*) parseTitleChunks: (NSString*) title;

- (NSString*) getSolForNote: (EDAMNote*) note;

- (int) getSolForTitle: (NSString*) title;

- (NSString*) getImageIDForTitle: (NSString*) title;

- (NSString*) getAnaglyphTitle: (NSString*) title;

- (BOOL) isImageIdLeftEye: (NSString*) imageID;

- (void) checkNetworkStatus:(NSNotification *)notice;

@end
