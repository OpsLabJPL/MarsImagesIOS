//
//  TImeViewController.h
//  Mars-Images
//
//  Created by Mark Powell on 5/20/13.
//  Copyright (c) 2013 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimeViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *clockView;
@property (weak, nonatomic) IBOutlet UILabel *opportunitySolLabel;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *opportunityTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *curiosityTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *curiositySolLabel;
@property (weak, nonatomic) IBOutlet UILabel *opportunityTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *curiosityTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *oppySeconds;
@property (weak, nonatomic) IBOutlet UILabel *curiositySeconds;
@property (weak, nonatomic) IBOutlet UILabel *utcLabel;
@property (strong, nonatomic) NSTimer* timer;

- (void) updateImageView: (UIDeviceOrientation) orientation;
- (NSString*) getBestImageAssetName: (NSString*) assetRootName;
@end
