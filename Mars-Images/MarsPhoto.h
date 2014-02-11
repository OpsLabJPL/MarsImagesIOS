//
//  MarsPhoto.h
//  Mars-Images
//
//  Created by Mark Powell on 12/22/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MWPhoto.h"
#import "Evernote.h"

@interface MarsPhoto : MWPhoto

@property (strong, nonatomic) EDAMNote* note;
@property (strong, nonatomic) EDAMResource* resource;
@property (strong, nonatomic) NSArray* leftAndRight;
@property (weak) UIImage* leftImage;
@property (weak) UIImage* rightImage;

- (id) initWithResource: (EDAMResource*) resource
                   note: (EDAMNote*) note
                    url: (NSURL*) url;

- (id) initAnaglyph: (NSArray*) leftAndRight
               note: (EDAMNote*) note;

- (BOOL) isGrayscale;
- (BOOL) includedInMosaic;

@end
