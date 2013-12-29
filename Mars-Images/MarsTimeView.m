//
//  MarsTimeView.m
//  Mars-Images
//
//  Created by Mark Powell on 12/28/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MarsTimeView.h"
#import "MarsTime.h"
#import "Opportunity.h"

@interface MarsTimeView ()

@end

@implementation MarsTimeView

static Opportunity* opportunity;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

+ (void) initialize {
    opportunity = [[Opportunity alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _dateFormat = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [_dateFormat setTimeZone:timeZone];
    [_dateFormat setDateFormat:@"yyyy-DDD"];
    _timeFormat = [[NSDateFormatter alloc] init];
    [_timeFormat setTimeZone:timeZone];
    [_timeFormat setDateFormat:@"HH:mm:ss"];

    //start clock update timer
	_timer = [NSTimer scheduledTimerWithTimeInterval:0.50 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
    [self updateTime:_timer];
}

- (void) updateTime: (NSTimer*)timer {
    NSDate *today = [NSDate dateWithTimeIntervalSinceNow:0];
    _utcLabel.text = [NSString stringWithFormat:@"%@T%@ UTC", [_dateFormat stringFromDate:today], [_timeFormat stringFromDate:today] ];
    
    NSTimeInterval timeDiff = [today timeIntervalSinceDate: opportunity.epoch];
    timeDiff = timeDiff / EARTH_SECS_PER_MARS_SEC;
    int sol = timeDiff / 86400;
    timeDiff -= sol * 86400;
    int hour = timeDiff / 3600;
    timeDiff -= hour * 3600;
    int minute = timeDiff / 60;
    int seconds = timeDiff - minute*60;
    sol += 1; //MER convention of landing day sol 1
    _opportunityTimeLabel.text = [NSString stringWithFormat:@"Sol %03d %02d:%02d:%02d", sol, hour, minute, seconds];
    
    NSDate* curiosityTime = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
    NSArray* marsTimes = [MarsTime getMarsTimes:curiosityTime longitude:CURIOSITY_WEST_LONGITUDE];
    NSNumber* msd = [marsTimes objectAtIndex:10];
    NSNumber* mtc = [marsTimes objectAtIndex:11];
    sol = (int)([msd doubleValue]-(360-CURIOSITY_WEST_LONGITUDE)/360)-49268;
    double mtcInHours = [MarsTime canonicalValue24:[mtc doubleValue] - CURIOSITY_WEST_LONGITUDE*24.0/360.0];
    hour = (int) mtcInHours;
    minute = (int) ((mtcInHours-hour)*60.0);
    seconds = (int) ((mtcInHours-hour)*3600 - minute*60);
//    curiositySolLabel.text = [NSString stringWithFormat:@"Sol %03d", sol];
//    curiosityTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", hour, minute];
//    curiositySeconds.text = [NSString stringWithFormat:@":%02d", seconds];
    _curiosityTimeLabel.text = [NSString stringWithFormat:@"Sol %03d %02d:%02d:%02d", sol, hour, minute, seconds];
}

@end
