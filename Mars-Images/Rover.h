//
//  Rover.h
//  Mars-Images
//
//  Created by Mark Powell on 6/24/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MarsRover.h"


@interface Rover : NSObject <MarsRover>

@property (strong, nonatomic) NSDictionary* cameraFOVs;

@end
