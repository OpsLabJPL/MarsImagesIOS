//
//  CameraModel.h
//  Mars-Images
//
//  Created by Mark Powell on 2/4/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

@interface CameraModel : NSObject

- (NSArray*) size;

+ (id<Model>) model: (NSArray*) modelJSON;
+ (NSArray*) origin: (NSArray*) modelJSON;
+ (NSArray*) pointingVector: (NSArray*) modelJson;
@end
