//
//  MSL.m
//  Mars-Images
//
//  Created by Mark Powell on 12/21/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "Curiosity.h"

@implementation Curiosity

- (id) init {
    self = [super init];

    NSDateComponents* comps = [[NSDateComponents alloc] init];
    [comps setDay:6];
    [comps setMonth:8];
    [comps setYear:2012];
    [comps setHour:6];
    [comps setMinute:30];
    [comps setSecond:00];
    [comps setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    _epoch = [[NSCalendar currentCalendar] dateFromComponents:comps];
    _eyeIndex = 1;
    _instrumentIndex = 0;
    _sampleTypeIndex = 17;

    return self;
}

- (NSString*) labelText:(EDAMNote *)note {
    return @"foo";
}

- (NSString*) detailLabelText:(EDAMNote *)note {
    return @"bar";
}

@end
