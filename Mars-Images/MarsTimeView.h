//
//  MarsTimeView.h
//  Mars-Images
//
//  Created by Mark Powell on 12/28/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MarsTimeView : UIViewController

@property (strong, nonatomic) NSDateFormatter* dateFormat;
@property (strong, nonatomic) NSDateFormatter* timeFormat;
@property (strong, nonatomic) NSTimer* timer;
@property (weak, nonatomic) IBOutlet UILabel* utcLabel;
@property (weak, nonatomic) IBOutlet UILabel* opportunityTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel* curiosityTimeLabel;

@end
