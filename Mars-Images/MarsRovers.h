//
//  MarsRovers.h
//  Mars-Images
//
//  Created by Mark Powell on 12/15/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MISSION @"mission"
#define OPPORTUNITY @"Opportunity"
#define SPIRIT @"Spirit"
#define CURIOSITY @"Curiosity"

@interface MarsRovers : NSObject

+ (MarsRovers*) instance;

@property (strong, nonatomic) NSDictionary* epochs;
@property (strong, nonatomic) NSDictionary* eyeIndex;
@property (strong, nonatomic) NSDictionary* instrumentIndex;
@property (strong, nonatomic) NSDictionary* sampleTypeIndex;

@end
