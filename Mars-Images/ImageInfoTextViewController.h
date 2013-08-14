//
//  ImageInfoTextViewController.h
//  Mars-Images
//
//  Created by Mark Powell on 11/30/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Evernote.h"

@interface ImageInfoTextViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *textview;
@property (strong, nonatomic) EDAMNote* note;

- (NSString *) filterContent: (NSString *)text;

@end
