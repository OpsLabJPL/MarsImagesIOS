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
{
    double minZoom;
    double maxZoom;
    double maxNativeZoom;
    double defaultZoom;
    double centerLat;
    double centerLon;
    double upperLeftLat;
    double upperLeftLon;
    double upperRightLat;
    double upperRightLon;
    double lowerLeftLat;
    double lowerLeftLon;
    double lowerRightLat;
    double lowerRightLon;
    int mapPixelWidth;
    int mapPixelHeight;
    int latestSiteIndex;
}

@property (strong, nonatomic) NSString* tileSetUrl;
@property (strong, nonatomic) RMMapView* mapView;
@property (strong, nonatomic) RMShapeAnnotation* traversePath;

- (void) loadLatestTraversePath;
- (void) parseMapMetadata;

@end
