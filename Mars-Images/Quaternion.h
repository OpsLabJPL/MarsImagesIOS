//
//  Quaternion.h
//  Mars-Images
//
//  Created by Mark Powell on 5/21/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IDENTITY { 1.0, 0.0, 0.0, 0.0 }

@interface Quaternion : NSObject

@property (nonatomic) double w;
@property (nonatomic) double x;
@property (nonatomic) double y;
@property (nonatomic) double z;

@end
