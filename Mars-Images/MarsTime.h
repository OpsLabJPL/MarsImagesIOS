//
//  MarsTime.h
//  Mars-Images
//
//  Created by Mark Powell on 5/21/13.
//  Copyright (c) 2013 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MarsTime : NSObject

+ (NSArray*) getMarsTimes: (NSDate*) date
                longitude: (float) longitude;
+ (float) taiutc: (NSDate*) date;
+ (double) getJulianDate: (NSDate*) date;
+ (double) canonicalValue24: (double) hours;
@end
