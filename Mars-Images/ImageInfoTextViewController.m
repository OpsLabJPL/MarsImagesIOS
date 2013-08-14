//
//  ImageInfoTextViewController.m
//  Mars-Images
//
//  Created by Mark Powell on 11/30/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import "ImageInfoTextViewController.h"
#import "MarsNotebook.h"
#import "Evernote.h"

@interface ImageInfoTextViewController ()

@end

@implementation ImageInfoTextViewController
@synthesize note;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (note) {
        NSString *filteredText = [self filterContent: note.content];
        self.textview.text = filteredText;
    }
}

- (void)viewDidUnload {
    [self setTextview:nil];
    [super viewDidUnload];
}

#pragma mark - device rotation support

//IOS 5
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation { //chain to IOS 6 implementation, requires converting the argument enum value to a bit mask value to compare
    return (1 << toInterfaceOrientation) & [self supportedInterfaceOrientationsForWindow];
}

//IOS 6 (returns a bit mask of accepted orientation values
- (NSUInteger) supportedInterfaceOrientationsForWindow {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (NSString *)filterContent: (NSString *) text {
    NSString* retcon = [NSString stringWithString:text];
    retcon = [retcon stringByReplacingOccurrencesOfString:@"<br/>" withString: @"\n"];
    retcon = [retcon stringByReplacingOccurrencesOfString:@"Mission Manager's Report" withString:@""];
    for (NSRange rangeOfLeftBracket = [retcon rangeOfString:@"<"];
         rangeOfLeftBracket.location != NSNotFound;
         rangeOfLeftBracket = [retcon rangeOfString:@"<"]) {
        NSRange rangeOfRightBracket = [retcon rangeOfString:@">"];
        NSString* leftSide = [retcon substringToIndex:rangeOfLeftBracket.location];
        int endPos = rangeOfRightBracket.location+1;
        if (endPos >= retcon.length)
            endPos = retcon.length;
        NSString* rightSide = [retcon substringFromIndex:endPos];
        retcon = [leftSide stringByAppendingString:rightSide];
    }
    
    NSArray *chunks = [note.title componentsSeparatedByString: @" "];
    int idPosition = [MarsNotebook instance].titleImageIdPosition;
    if (idPosition >= [chunks count])
        idPosition = [chunks count] - 1;
    NSString* imageId = [chunks objectAtIndex:idPosition];
    
    return [NSString stringWithFormat:@"Image ID %@\n%@", imageId, retcon];
}
@end
