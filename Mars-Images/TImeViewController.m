//
//  TimeViewController.m
//  Mars-Images
//
//  Created by Mark Powell on 5/20/13.
//  Copyright (c) 2013 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import "TimeViewController.h"
#import "MarsNotebook.h"
#import "MarsTime.h"

#define EARTH_SECS_PER_MARS_SEC 1.027491252
#define CURIOSITY_WEST_LONGITUDE 222.6

@interface TimeViewController ()

@end

@implementation TimeViewController

@synthesize clockView;
@synthesize imageView;
@synthesize curiosityTimeLabel;
@synthesize curiositySolLabel;
@synthesize curiosityTitleLabel;
@synthesize opportunityTimeLabel;
@synthesize opportunitySolLabel;
@synthesize opportunityTitleLabel;
@synthesize oppySeconds;
@synthesize curiositySeconds;
@synthesize utcLabel;
@synthesize timer;

NSDateFormatter *timeFormat, *dateFormat;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    dateFormat = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormat setTimeZone:timeZone];
    [dateFormat setDateFormat:@"yyyy-DDD"];
    timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setTimeZone:timeZone];
    [timeFormat setDateFormat:@"HH:mm:ss"];

    //start clock update timer
	timer = [NSTimer scheduledTimerWithTimeInterval:0.10 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateImageView: [self interfaceOrientation]];
    [self repositionLabels:[self interfaceOrientation]];
}

- (void) repositionLabels:(UIDeviceOrientation) orientation {
    CGRect bounds = [[self clockView] bounds];
    
    int view_width = bounds.size.width;
    int view_height = bounds.size.height;
    
    CGRect labelBounds = utcLabel.frame;
    utcLabel.frame = CGRectMake(labelBounds.origin.x, labelBounds.origin.y, view_width, labelBounds.size.height);
    
    if (UIDeviceOrientationIsLandscape(orientation)) {
        
        labelBounds = opportunityTitleLabel.frame;
        opportunityTitleLabel.frame = CGRectMake(view_width/4-labelBounds.size.width/2, bounds.origin.y, labelBounds.size.width, labelBounds.size.height);
        
        labelBounds = curiosityTitleLabel.frame;
        curiosityTitleLabel.frame = CGRectMake(3*view_width/4-labelBounds.size.width/2, bounds.origin.y, labelBounds.size.width, labelBounds.size.height);
        
        labelBounds = opportunitySolLabel.frame;
        opportunitySolLabel.frame = CGRectMake(view_width/2-100, opportunityTitleLabel.frame.origin.y+30, labelBounds.size.width, labelBounds.size.height);
        
        labelBounds = curiositySolLabel.frame;
        curiositySolLabel.frame = CGRectMake(view_width-100, curiosityTitleLabel.frame.origin.y+30, labelBounds.size.width, labelBounds.size.height);
        
        labelBounds = opportunityTimeLabel.frame;
        opportunityTimeLabel.frame = CGRectMake(view_width/2-100, opportunitySolLabel.frame.origin.y+30, labelBounds.size.width, labelBounds.size.height);
        
        labelBounds = curiosityTimeLabel.frame;
        curiosityTimeLabel.frame = CGRectMake(view_width-100, curiositySolLabel.frame.origin.y+30, labelBounds.size.width, labelBounds.size.height);
        
    } else {
        labelBounds = opportunityTitleLabel.frame;
        opportunityTitleLabel.frame = CGRectMake(view_width/2-labelBounds.size.width/2, bounds.origin.y, labelBounds.size.width, labelBounds.size.height);
        
        labelBounds = curiosityTitleLabel.frame;
        curiosityTitleLabel.frame = CGRectMake(view_width/2-labelBounds.size.width/2, bounds.origin.y+view_height/2, labelBounds.size.width, labelBounds.size.height);
        
        labelBounds = opportunitySolLabel.frame;
        opportunitySolLabel.frame = CGRectMake(view_width-100, opportunityTitleLabel.frame.origin.y+30, labelBounds.size.width, labelBounds.size.height);
        
        labelBounds = curiositySolLabel.frame;
        curiositySolLabel.frame = CGRectMake(view_width-100, curiosityTitleLabel.frame.origin.y+30, labelBounds.size.width, labelBounds.size.height);
        
        labelBounds = opportunityTimeLabel.frame;
        opportunityTimeLabel.frame = CGRectMake(view_width-100, opportunitySolLabel.frame.origin.y+30, labelBounds.size.width, labelBounds.size.height);
        
        labelBounds = curiosityTimeLabel.frame;
        curiosityTimeLabel.frame = CGRectMake(view_width-100, curiositySolLabel.frame.origin.y+30, labelBounds.size.width, labelBounds.size.height);
    }
    
    labelBounds = oppySeconds.frame;
    oppySeconds.frame = CGRectMake(opportunityTimeLabel.frame.origin.x+60, opportunityTimeLabel.frame.origin.y+3, labelBounds.size.width, labelBounds.size.height);
    
    labelBounds = curiositySeconds.frame;
    curiositySeconds.frame = CGRectMake(curiosityTimeLabel.frame.origin.x+60, curiosityTimeLabel.frame.origin.y+3, labelBounds.size.width, labelBounds.size.height);

}

- (void) updateImageView:(UIDeviceOrientation) orientation {
    if (UIDeviceOrientationIsLandscape(orientation)) {
        UIImage* image = [UIImage imageNamed: [self getBestImageAssetName:@"marstime-landscape"]];
        [imageView setImage: image];
    } else { //landscape orientation
        UIImage* image = [UIImage imageNamed: [self getBestImageAssetName:@"marstime"]];
        [imageView setImage: image];
    }
}

- (void) updateTime: (NSTimer*)timer {
    NSDate *today = [NSDate dateWithTimeIntervalSinceNow:0];
    utcLabel.text = [NSString stringWithFormat:@"%@T%@ UTC", [dateFormat stringFromDate:today], [timeFormat stringFromDate:today] ];
    
    NSTimeInterval timeDiff = [today timeIntervalSinceDate: [[MarsNotebook instance] oppyEpochDate]];
    timeDiff = timeDiff / EARTH_SECS_PER_MARS_SEC;
    int sol = timeDiff / 86400;
    timeDiff -= sol * 86400;
    int hour = timeDiff / 3600;
    timeDiff -= hour * 3600;
    int minute = timeDiff / 60;
    int seconds = timeDiff - minute*60;
    sol += 1; //MER convention of landing day sol 1
    opportunitySolLabel.text = [NSString stringWithFormat:@"Sol %03d", sol];
    opportunityTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", hour, minute];
    oppySeconds.text = [NSString stringWithFormat:@":%02d", seconds];
    
    NSDate* curiosityTime = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
    NSArray* marsTimes = [MarsTime getMarsTimes:curiosityTime longitude:CURIOSITY_WEST_LONGITUDE];
    NSNumber* msd = [marsTimes objectAtIndex:10];
    NSNumber* mtc = [marsTimes objectAtIndex:11];
    sol = (int)([msd doubleValue]-(360-CURIOSITY_WEST_LONGITUDE)/360)-49268;
    double mtcInHours = [MarsTime canonicalValue24:[mtc doubleValue] - CURIOSITY_WEST_LONGITUDE*24.0/360.0];
    hour = (int) mtcInHours;
    minute = (int) ((mtcInHours-hour)*60.0);
    seconds = (int) ((mtcInHours-hour)*3600 - minute*60);
    curiositySolLabel.text = [NSString stringWithFormat:@"Sol %03d", sol];
    curiosityTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", hour, minute];
    curiositySeconds.text = [NSString stringWithFormat:@":%02d", seconds];
}

- (NSString*) getBestImageAssetName:(NSString *)assetRootName {
    BOOL isRetina = [[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0);
    BOOL isiPhone = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone;
    NSString* bestName = assetRootName;
    if ([[UIScreen mainScreen] bounds].size.height <= 480.0 && isiPhone) {
        bestName = [bestName stringByAppendingString:@"-568h"];
    }
    bestName = (isRetina) ? [bestName stringByAppendingString:@"@2x"] : bestName;
    bestName = (isiPhone) ? [bestName stringByAppendingString:@"~iphone"] : [bestName stringByAppendingString:@"~ipad"];
//    NSLog(@"Best Image Asset Name: %@", bestName);
    return bestName;
}

- (void)viewDidUnload {
    [self setCuriosityTimeLabel:nil];
    [self setOpportunityTimeLabel:nil];
    [self setImageView:nil];
    [self setOpportunitySolLabel:nil];
    [self setCuriositySolLabel:nil];
    [self setOpportunityTitleLabel:nil];
    [self setCuriosityTitleLabel:nil];
    [self setUtcLabel:nil];
    [self setClockView:nil];
    [self setOppySeconds:nil];
    [self setCuriositySeconds:nil];
    [super viewDidUnload];
}
@end
