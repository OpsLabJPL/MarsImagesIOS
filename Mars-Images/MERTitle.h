//
//  MERTitle.h
//  Mars-Images
//
//  Created by Mark Powell on 12/21/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MERTitle : NSObject

@property int sol;
@property NSString* imageSetID;
@property NSString* instrumentName;
@property NSString* marsLocalTime;
@property int siteIndex;
@property int driveIndex;
@property float distance;
@property float yaw;
@property float pitch;
@property float roll;
@property float tilt;

@end
