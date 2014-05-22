//
//  MapViewController.h
//  Mars-Images
//
//  Created by Mark Powell on 2/11/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapBox.h"

@interface MapViewController : UIViewController<RMMapViewDelegate>

@property (strong, nonatomic) NSString* tileSetUrl;
@property (strong, nonatomic) NSNumber* minZoom;
@property (strong, nonatomic) NSNumber* maxZoom;
@property (strong, nonatomic) NSNumber* maxNativeZoom;
@property (strong, nonatomic) NSNumber* defaultZoom;
@property (strong, nonatomic) NSNumber* centerLat;
@property (strong, nonatomic) NSNumber* centerLon;
@property (strong, nonatomic) NSNumber* upperLeftLat;
@property (strong, nonatomic) NSNumber* upperLeftLon;
@property (strong, nonatomic) NSNumber* upperRightLat;
@property (strong, nonatomic) NSNumber* upperRightLon;
@property (strong, nonatomic) NSNumber* lowerLeftLat;
@property (strong, nonatomic) NSNumber* lowerLeftLon;
@property (strong, nonatomic) NSNumber* lowerRightLat;
@property (strong, nonatomic) NSNumber* lowerRightLon;

@end
