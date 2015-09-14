//
//  Spirit.m
//  Mars-Images
//
//  Created by Mark Powell on 12/21/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "Spirit.h"

@implementation Spirit

- (id)init {
    self = [super init];
    self.roverName = @"Spirit";
    self.regionName = @"Gusev Crater";
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:3];
    [comps setMonth:1];
    [comps setYear:2004];
    [comps setHour:13];
    [comps setMinute:36];
    [comps setSecond:15];
    [comps setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    self.epoch = [[NSCalendar currentCalendar] dateFromComponents:comps];
    self.eyeIndex = 23;
    self.instrumentIndex = 1;
    self.sampleTypeIndex = 12;
    return self;
}

- (NSString*) urlPrefix {
    return @"https://s3-us-west-1.amazonaws.com/merpublic/spirit";
}

@end
