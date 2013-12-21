//
//  MarsRovers.m
//  Mars-Images
//
//  Created by Mark Powell on 12/15/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MarsRovers.h"

@implementation MarsRovers

static MarsRovers* instance = nil;

+ (MarsRovers *) instance {
    if (instance == nil) {
        instance = [[MarsRovers alloc] init];
    }
    return instance;
}

- (MarsRovers*) init {
    MarsRovers* rovers = [super init];
    NSArray* missions = [NSArray arrayWithObjects: OPPORTUNITY, SPIRIT, CURIOSITY, nil];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:3];
    [comps setMonth:1];
    [comps setYear:2004];
    [comps setHour:13];
    [comps setMinute:36];
    [comps setSecond:15];
    [comps setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSDate* spiritEpochDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
    
    comps = [[NSDateComponents alloc] init];
    [comps setDay:24];
    [comps setMonth:1];
    [comps setYear:2004];
    [comps setHour:15];
    [comps setMinute:8];
    [comps setSecond:59];
    [comps setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSDate* oppyEpochDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
    
    comps = [[NSDateComponents alloc] init];
    [comps setDay:6];
    [comps setMonth:8];
    [comps setYear:2012];
    [comps setHour:6];
    [comps setMinute:30];
    [comps setSecond:00];
    [comps setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSDate* mslEpochDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
    NSArray* dates = [NSArray arrayWithObjects:oppyEpochDate, spiritEpochDate, mslEpochDate, nil];
    _epochs = [NSDictionary dictionaryWithObjects:dates forKeys:missions];
    
    NSArray* eyes = [NSArray arrayWithObjects:[NSNumber numberWithInt:23], [NSNumber numberWithInt:23], [NSNumber numberWithInt:1], nil];
    _eyeIndex = [NSDictionary dictionaryWithObjects:eyes forKeys:missions];
    
    NSArray* instruments = [NSArray arrayWithObjects:[NSNumber numberWithInt:1], [NSNumber numberWithInt:1], [NSNumber numberWithInt:0], nil];
    _instrumentIndex = [NSDictionary dictionaryWithObjects:instruments forKeys:missions];
    return rovers;
}

@end
