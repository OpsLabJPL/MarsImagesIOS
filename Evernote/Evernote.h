//
//  evernote.h
//  client
//
//  Evernote API sample code is provided under the terms specified in the file LICENSE.txt which was included with this distribution.
//

#import <Foundation/Foundation.h>
#import "EvernoteSDK.h"

@interface Evernote : NSObject {
    EDAMNoteStoreClient *noteStore;
    EDAMPublicUserInfo* user;
    NSString* publicUser;
    NSString* uriPrefix;
    Evernote *sharedEvernoteManager;
    BOOL shared;
}
@property(strong) EDAMNoteStoreClient* noteStore;
@property(strong) EDAMPublicUserInfo* user;
@property(strong) NSString* publicUser;
@property(strong) NSString* uriPrefix;

+ (Evernote *)sharedInstance;

- (void) connect;

- (NSArray *) listNotebooks;
- (EDAMNoteList *) findNotes: (EDAMNoteFilter *) filter;
- (EDAMNoteList *) findNotes: (EDAMNoteFilter *) filter withStartIndex: (int) start withTotal: (int) total;
- (EDAMNotesMetadataList*) findNotesMetadata: (EDAMNoteFilter*) filter withStartIndex: (int) start withTotal: (int)total withMetadata: (EDAMNotesMetadataResultSpec*) metadata;
- (EDAMNote *) getNote: (NSString *) guid;
- (EDAMNote *) getNote: (NSString *) guid reauthenticate: (BOOL) reauth;
- (void) deleteNote: (NSString *) guid;
- (void) createNote: (EDAMNote *) note;

@end
