
#import "Evernote.h"
#import "Thrift.h"

// NOTE: You must change the consumer key and consumer secret to the
// key and secret that you received from Evernote. If you do not have
// an API key, visit http://www.evernote.com/about/developer/api/ to
// get one.

// NOTE: You must change the username and password to the username and
// password of an account that you have created on the appropriate
// Evernote service. If you are testing against the sandbox service,
// you must create an account by visiting

//NSString * const userStoreUri = @"https://www.evernote.com/edam/user";
//NSString * const noteStoreUriBase = @"https://www.evernote.com/edam/note/";


@implementation Evernote

@synthesize noteStore, user;

/************************************************************
 *
 *  Implementing the singleton pattern
 *
 ************************************************************/

static Evernote *sharedEvernoteManager = nil;

/************************************************************
 *
 *  Accessing the static version of the instance
 *
 ************************************************************/

+ (Evernote *)instance {
    
    if (sharedEvernoteManager == nil) {
        sharedEvernoteManager = [[Evernote alloc] init];
    }
    
    return sharedEvernoteManager;
    
}

-(id)init{
    self = [super init];
    return self;
}

- (NSString*)publicUser {
    return publicUser;
}

- (void) setPublicUser:(NSString *)username {
    publicUser = username;
    noteStore = nil; //force next connect() call to rebuild NoteStore with new public user
}

- (NSString*)uriPrefix {
    return uriPrefix;
}

- (void) setUriPrefix:(NSString *)prefix {
    uriPrefix = prefix;
    noteStore = nil; //force next connect() call to rebuild NoteStore with new uriPrefix
}

/************************************************************
 *
 *  Connecting to the Evernote server using simple
 *  authentication
 *
 ************************************************************/

- (void) connect {
    
    if (noteStore == nil) {
        NSURL* userStoreUri = [[NSURL alloc] initWithString:@"https://www.evernote.com/edam/user"];
        THTTPClient* userStoreHttpClient = [[THTTPClient alloc] initWithURL:userStoreUri];
        TBinaryProtocol* userStoreProtocol = [[TBinaryProtocol alloc] initWithTransport:userStoreHttpClient];
        EDAMUserStoreClient* userStore = [[EDAMUserStoreClient alloc] initWithProtocol:userStoreProtocol];
        
        self.user = [userStore getPublicUserInfo: publicUser]; //e.g. @"marsrovers"
        NSLog(@"userStore %@", self.user);
        
        NSURL* noteStoreUri = [[NSURL alloc] initWithString: user.noteStoreUrl];
        NSString* agentString = [NSString stringWithFormat:@"Mars Images/2.0;iOS/%@", [UIDevice currentDevice].systemVersion];
        THTTPClient* noteStoreHttpClient = [[THTTPClient alloc] initWithURL:noteStoreUri userAgent:agentString timeout:15000];
        
        TBinaryProtocol* noteStoreProtocol = [[TBinaryProtocol alloc] initWithTransport:noteStoreHttpClient];
        self.noteStore = [[EDAMNoteStoreClient alloc] initWithProtocol:noteStoreProtocol];
    }
}

/************************************************************
 *
 *  Listing all the user's notebooks
 *
 ************************************************************/

- (NSArray *) listNotebooks {
    
    // Checking the connection
    [self connect];
    
    // Calling a function in the API
    NSArray *notebooks = [[NSArray alloc] initWithArray:[[self noteStore] listNotebooks:@""] ];
    
    return notebooks;
}

/************************************************************
 *
 *  Searching for notes using a EDAM Note Filter
 *
 ************************************************************/

- (EDAMNoteList *) findNotes: (EDAMNoteFilter *) filter {
    // Checking the connection
    [self connect];
    
    // Calling a function in the API
    return [noteStore findNotes:@"" filter:filter offset:0 maxNotes:100];
}

/************************************************************
 *
 *  Searching for notes using a EDAM Note Filter
 *
 ************************************************************/

- (EDAMNoteList *) findNotes: (EDAMNoteFilter *) filter withStartIndex: (int) start withTotal: (int)total {
    // Checking the connection
    [self connect];
    
    // Calling a function in the API
    return [noteStore findNotes:@"" filter:filter offset:start maxNotes:total];
}

- (EDAMNotesMetadataList*) findNotesMetadata: (EDAMNoteFilter*) filter withStartIndex: (int) start withTotal: (int)total withMetadata: (EDAMNotesMetadataResultSpec*) metadata {
    [self connect];
    
    return [noteStore findNotesMetadata:@"" filter:filter offset:start maxNotes:total resultSpec:metadata];
}

- (EDAMNote*) getNote:(NSString *)guid {
    return [self getNote:guid reauthenticate:NO];
}

/************************************************************
 *
 *  Loading a note using the guid
 *
 ************************************************************/

- (EDAMNote *) getNote: (NSString *) guid
        reauthenticate: (BOOL) reauth {
    
    if (reauth) {
        noteStore = nil;
    }
    
    // Checking the connection
    [self connect];
    
    // Calling a function in the API
    return [noteStore getNote:@"" guid:guid withContent:YES withResourcesData:YES withResourcesRecognition:NO withResourcesAlternateData:NO];
}


/************************************************************
 *
 *  Deleting a note using the guid
 *
 ************************************************************/

- (void) deleteNote: (NSString *) guid {
    // Checking the connection
    [self connect];
    
    // Calling a function in the API
    [noteStore deleteNote:@"" guid:guid];
}

/************************************************************
 *
 *  Creating a note
 *
 ************************************************************/

- (void) createNote: (EDAMNote *) note {
    // Checking the connection
    [self connect];
    
    // Calling a function in the API
    [noteStore createNote:@"" note:note];
}

- (NSString *) getApplicationDataEntry: (NSString*) guid
                                forKey: (NSString *)applicationKey {
    return [noteStore getNoteApplicationDataEntry:@"" guid:guid key:applicationKey];
}

@end
