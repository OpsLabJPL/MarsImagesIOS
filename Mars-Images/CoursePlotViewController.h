//
//  CoursePlotViewController.h
//  Mars-Images
//
//  Created by Mark Powell on 5/8/13.
//  Copyright (c) 2013 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Evernote.h"

@interface CoursePlotViewController : UIViewController<UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) NSString* solDirectory;
@property (strong, nonatomic) EDAMNote* note;

- (void) loadMyImage;

@end
