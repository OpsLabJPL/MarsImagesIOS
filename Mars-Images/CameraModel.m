//
//  CameraModel.m
//  Mars-Images
//
//  Created by Mark Powell on 2/4/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import "CameraModel.h"
#import "CAHV.h"
#import "CAHVOR.h"
#import "CAHVORE.h"

@implementation CameraModel

- (NSArray*) size {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (id<Model>) model: (NSArray*) modelJSON {
    id<Model> returnedModel = nil;
    NSString* type;
    NSArray *c, *a, *h, *v, *o, *r, *e;
    NSNumber *mtype, *mparm;
    NSNumber *width, *height;
    for (NSObject* obj in modelJSON) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary* dict = (NSDictionary*) obj;
            for (NSString* key in dict.allKeys) {
                if ([key isEqualToString:@"type"]) {
                    type = [dict objectForKey:key];
                } else if ([key isEqualToString:@"components"]) {
                    NSDictionary* comps = [dict objectForKey:key];
                    c = [comps objectForKey:@"c"];
                    a = [comps objectForKey:@"a"];
                    h = [comps objectForKey:@"h"];
                    v = [comps objectForKey:@"v"];
                    o = [comps objectForKey:@"o"];
                    r = [comps objectForKey:@"r"];
                    e = [comps objectForKey:@"e"];
                    mtype = [comps objectForKey:@"t"];
                    mparm = [comps objectForKey:@"p"];
                } else if ([key isEqualToString:@"area"]) {
                    NSArray* area = [dict objectForKey:key];
                    width = [area objectAtIndex:0];
                    height = [area objectAtIndex:1];
                }
            }
        }
    }
    
    if (!type) {
        NSLog(@"Brown alert: camera model type not found.");
        return NULL;
    } else if ([type isEqualToString:@"CAHV"]) {
        CAHV* model = [[CAHV alloc] init];
        [model setC: ((NSNumber*)[c objectAtIndex:0]).floatValue
                  y: ((NSNumber*)[c objectAtIndex:1]).floatValue
                  z: ((NSNumber*)[c objectAtIndex:2]).floatValue];
        [model setA: ((NSNumber*)[a objectAtIndex:0]).floatValue
                  y: ((NSNumber*)[a objectAtIndex:1]).floatValue
                  z: ((NSNumber*)[a objectAtIndex:2]).floatValue];
        [model setH: ((NSNumber*)[h objectAtIndex:0]).floatValue
                  y: ((NSNumber*)[h objectAtIndex:1]).floatValue
                  z: ((NSNumber*)[h objectAtIndex:2]).floatValue];
        [model setV: ((NSNumber*)[v objectAtIndex:0]).floatValue
                  y: ((NSNumber*)[v objectAtIndex:1]).floatValue
                  z: ((NSNumber*)[v objectAtIndex:2]).floatValue];
        returnedModel = model;
    } else if ([type isEqualToString:@"CAHVOR"]) {
        CAHVOR* model = [[CAHVOR alloc] init];
        [model setC: ((NSNumber*)[c objectAtIndex:0]).floatValue
                  y: ((NSNumber*)[c objectAtIndex:1]).floatValue
                  z: ((NSNumber*)[c objectAtIndex:2]).floatValue];
        [model setA: ((NSNumber*)[a objectAtIndex:0]).floatValue
                  y: ((NSNumber*)[a objectAtIndex:1]).floatValue
                  z: ((NSNumber*)[a objectAtIndex:2]).floatValue];
        [model setH: ((NSNumber*)[h objectAtIndex:0]).floatValue
                  y: ((NSNumber*)[h objectAtIndex:1]).floatValue
                  z: ((NSNumber*)[h objectAtIndex:2]).floatValue];
        [model setV: ((NSNumber*)[v objectAtIndex:0]).floatValue
                  y: ((NSNumber*)[v objectAtIndex:1]).floatValue
                  z: ((NSNumber*)[v objectAtIndex:2]).floatValue];
        [model setO: ((NSNumber*)[o objectAtIndex:0]).floatValue
                  y: ((NSNumber*)[o objectAtIndex:1]).floatValue
                  z: ((NSNumber*)[o objectAtIndex:2]).floatValue];
        [model setR: ((NSNumber*)[r objectAtIndex:0]).floatValue
                  y: ((NSNumber*)[r objectAtIndex:1]).floatValue
                  z: ((NSNumber*)[r objectAtIndex:2]).floatValue];
        returnedModel = model;
   } else if ([type isEqualToString:@"CAHVORE"]) {
       CAHVORE* model = [[CAHVORE alloc] init];
       [model setC: ((NSNumber*)[c objectAtIndex:0]).floatValue
                 y: ((NSNumber*)[c objectAtIndex:1]).floatValue
                 z: ((NSNumber*)[c objectAtIndex:2]).floatValue];
       [model setA: ((NSNumber*)[a objectAtIndex:0]).floatValue
                 y: ((NSNumber*)[a objectAtIndex:1]).floatValue
                 z: ((NSNumber*)[a objectAtIndex:2]).floatValue];
       [model setH: ((NSNumber*)[h objectAtIndex:0]).floatValue
                 y: ((NSNumber*)[h objectAtIndex:1]).floatValue
                 z: ((NSNumber*)[h objectAtIndex:2]).floatValue];
       [model setV: ((NSNumber*)[v objectAtIndex:0]).floatValue
                 y: ((NSNumber*)[v objectAtIndex:1]).floatValue
                 z: ((NSNumber*)[v objectAtIndex:2]).floatValue];
       [model setO: ((NSNumber*)[o objectAtIndex:0]).floatValue
                 y: ((NSNumber*)[o objectAtIndex:1]).floatValue
                 z: ((NSNumber*)[o objectAtIndex:2]).floatValue];
       [model setR: ((NSNumber*)[r objectAtIndex:0]).floatValue
                 y: ((NSNumber*)[r objectAtIndex:1]).floatValue
                 z: ((NSNumber*)[r objectAtIndex:2]).floatValue];
       [model setE: ((NSNumber*)[e objectAtIndex:0]).floatValue
                 y: ((NSNumber*)[e objectAtIndex:1]).floatValue
                 z: ((NSNumber*)[e objectAtIndex:2]).floatValue];
       [model setT: mtype.floatValue];
       [model setP: mparm.floatValue];
       returnedModel = model;
    }
    if (returnedModel) {
        [((CAHV*)returnedModel) setXdim: width.intValue];
        [((CAHV*)returnedModel) setYdim: height.intValue];
    }
    return returnedModel;
}

+ (NSArray*) origin: (NSArray*) modelJson {
    for (NSObject* obj in modelJson) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary* dict = (NSDictionary*) obj;
            for (NSString* key in dict.allKeys) {
                if ([key isEqualToString:@"origin"]) {
                    NSArray* comps = [dict objectForKey:key];
                    NSNumber* x = [comps objectAtIndex:0];
                    NSNumber* y = [comps objectAtIndex:1];
                    return [NSArray arrayWithObjects: x, y, nil];
                }
            }
        }
    }
    NSLog(@"Brown alert: origin not found in camera model.");
    return [[NSArray alloc] init];
}

+ (NSArray*) pointingVector: (NSArray*) modelJson {
    for (NSObject* obj in modelJson) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary* dict = (NSDictionary*) obj;
            for (NSString* key in dict.allKeys) {
                if ([key isEqualToString:@"camera_vector"]) {
                    NSArray* comps = [dict objectForKey:key];
                    NSNumber* x = [comps objectAtIndex:0];
                    NSNumber* y = [comps objectAtIndex:1];
                    NSNumber* z = [comps objectAtIndex:2];
                    return [NSArray arrayWithObjects: x, y, z, nil];
                }
            }
        }
    }
    NSLog(@"Brown alert: pointing vector not found in camera model.");
    return [NSArray arrayWithObjects:nil];
}
@end
