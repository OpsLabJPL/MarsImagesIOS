//
//  MSL.h
//  Mars-Images
//
//  Created by Mark Powell on 12/21/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MarsRover.h"

@interface Curiosity : NSObject <MarsRover>

@property (strong, nonatomic) NSDate* epoch;
@property (nonatomic) int eyeIndex;
@property (nonatomic) int instrumentIndex;
@property (nonatomic) int sampleTypeIndex;

@end
