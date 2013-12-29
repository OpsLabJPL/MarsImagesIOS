//
//  MarsTime.h
//  Mars-Images
//
//  Created by Mark Powell on 5/21/13.
//  Copyright (c) 2013 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

#define EARTH_SECS_PER_MARS_SEC 1.027491252
#define CURIOSITY_WEST_LONGITUDE 222.6

@interface MarsTime : NSObject

+ (NSArray*) getMarsTimes: (NSDate*) date
                longitude: (float) longitude;
+ (float) taiutc: (NSDate*) date;
+ (double) getJulianDate: (NSDate*) date;
+ (double) canonicalValue24: (double) hours;
@end
