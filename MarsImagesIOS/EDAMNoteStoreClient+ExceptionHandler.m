//
//  EDAMNoteStoreClient+ExceptionHandler.m
//  MarsImages
//
//  Created by Powell, Mark W (397F) on 11/30/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

#import "EDAMNoteStoreClient+ExceptionHandler.h"

@implementation EDAMNoteStoreClient (ExceptionHandler)

- (EDAMNoteList*) findNotesSafely: (NSString *) authenticationToken
                           filter: (EDAMNoteFilter *) filter
                           offset: (int32_t) offset
                         maxNotes: (int32_t) maxNotes {
    @try {
        [ENTProtocolUtil sendMessage:@"findNotes"
                          toProtocol:_outProtocol
                       withArguments:@[
                                       [FATArgument argumentWithField:[FATField fieldWithIndex:1 type:TType_STRING optional:NO name:@"authenticationToken"] value: authenticationToken],
                                       [FATArgument argumentWithField:[FATField fieldWithIndex:2 type:TType_STRUCT optional:NO name:@"filter" structClass:[EDAMNoteFilter class]] value: filter],
                                       [FATArgument argumentWithField:[FATField fieldWithIndex:3 type:TType_I32 optional:NO name:@"offset"] value: @(offset)],
                                       [FATArgument argumentWithField:[FATField fieldWithIndex:4 type:TType_I32 optional:NO name:@"maxNotes"] value: @(maxNotes)],
                                       ]];
        
        return [ENTProtocolUtil readMessage:@"findNotes"
                               fromProtocol:_inProtocol
                          withResponseTypes:@[
                                              [FATField fieldWithIndex:0 type:TType_STRUCT optional:NO name:@"success" structClass:[EDAMNoteList class]],
                                              [FATField fieldWithIndex:1 type:TType_STRUCT optional:NO name:@"userException" structClass:[EDAMUserException class]],
                                              [FATField fieldWithIndex:2 type:TType_STRUCT optional:NO name:@"systemException" structClass:[EDAMSystemException class]],
                                              [FATField fieldWithIndex:3 type:TType_STRUCT optional:NO name:@"notFoundException" structClass:[EDAMNotFoundException class]],
                                              ]];
    } @catch (NSException *e) {
        NSLog(@"Exception listing notes: %@ %@", e.name, e.description);
    }
    return nil;
}

@end
