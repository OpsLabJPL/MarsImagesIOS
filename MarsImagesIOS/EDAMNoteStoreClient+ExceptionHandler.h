//
//  EDAMNoteStoreClient+ExceptionHandler.h
//  MarsImages
//
//  This wrapper class is only needed here because EvernoteSDK throw exceptions when things go wrong,
//  and Swift language has no ability to handle them. Would that this weren't so.
//
//  Created by Powell, Mark W (397F) on 11/30/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

#import <EvernoteSDK/EvernoteSDK.h>

@interface EDAMNoteStoreClient (ExceptionHandler)

- (EDAMNoteList*) findNotesSafely: (NSString *) authenticationToken
                           filter: (EDAMNoteFilter *) filter
                           offset: (int32_t) offset
                         maxNotes: (int32_t) maxNotes;

@end
