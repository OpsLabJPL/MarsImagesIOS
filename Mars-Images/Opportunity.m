//
//  Opportunity.m
//  Mars-Images
//
//  Created by Mark Powell on 12/21/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "Opportunity.h"

@implementation Opportunity

- (id)init {
    self = [super init];
    self.roverName = @"Opportunity";
    self.regionName = @"Meridiani Planum";
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    [comps setDay:24];
    [comps setMonth:1];
    [comps setYear:2004];
    [comps setHour:15];
    [comps setMinute:8];
    [comps setSecond:59];
    [comps setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    self.epoch =[[NSCalendar currentCalendar] dateFromComponents:comps];
    self.eyeIndex = 23;
    self.instrumentIndex = 1;
    self.sampleTypeIndex = 12;
    return self;
}

@end
