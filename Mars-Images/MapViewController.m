//
//  MapViewController.m
//  Mars-Images
//
//  Created by Mark Powell on 2/11/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import "MapViewController.h"
#import "MapBox.h"
#import "MarsImageNotebook.h"
#import "S3TileSource.h"

@interface MapViewController ()
    @property (nonatomic, strong) NSMutableArray *points;
@end

@implementation MapViewController

static dispatch_queue_t mapDownloadQueue = nil;

+ (void) initialize {
    mapDownloadQueue = dispatch_queue_create("map downloader", DISPATCH_QUEUE_SERIAL);
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //custom init here
    }
    return self;
}

- (void) viewDidLoad {
    [self parseMapMetadata];
    [self loadLatestTraversePath];
    S3TileSource *source = [[S3TileSource alloc] initWithTileSetURL:[NSURL URLWithString:_tileSetUrl]
                                                            minZoom:minZoom
                                                            maxZoom:maxNativeZoom
                                                       upperLeftLat:upperLeftLat
                                                       upperLeftLon:upperLeftLon
                                                      lowerRightLat:lowerRightLat
                                                      lowerRightLon:lowerRightLon];
    
    CLLocation* lastPos = [_points objectAtIndex:[_points count]-1];
    NSLog(@"center coordinate: %@", lastPos);
    _mapView = [[RMMapView alloc] initWithFrame:self.view.bounds andTilesource:source centerCoordinate:lastPos.coordinate zoomLevel:maxZoom-2 maxZoomLevel:maxZoom minZoomLevel:minZoom backgroundImage:nil];
    _mapView.delegate = self;
    //_mapView.showLogoBug = NO; //there is a bug that makes this crash...check for fix later
    _mapView.adjustTilesForRetinaDisplay = YES;
    _mapView.hideAttribution = YES;
    _mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [_mapView setBackgroundImage:[UIImage imageNamed:@"black_background.png"]];
    [self.view addSubview:_mapView];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //these set statements have to be here...they don't work in viewDidLoad, either before or after adding the view to the hierarchy. Quirky.
    [_mapView setMinZoom:minZoom];
    [_mapView setMaxZoom:maxZoom];
    [_mapView setZoom:maxZoom-2];
    
    RMShapeAnnotation *traversePath = [[RMShapeAnnotation alloc] initWithMapView:_mapView points:_points];
    [_mapView addAnnotation:traversePath];
    
    for (CLLocation* loc in _points) {
        RMPointAnnotation *locationMarker = [[RMPointAnnotation alloc] initWithMapView:_mapView
                                                                            coordinate:CLLocationCoordinate2DMake(loc.coordinate.latitude, loc.coordinate.longitude)
                                                                              andTitle:nil];
        [_mapView addAnnotation:locationMarker];
    }
}

- (NSDictionary*) getMapMetadata {
    NSString* missionName = [MarsImageNotebook instance].missionName;
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"http://merpublic.s3.amazonaws.com/maps/%@Map.json", missionName]];
    NSData* json = [NSData dataWithContentsOfURL:url];
    NSError* error;
    return [NSJSONSerialization JSONObjectWithData:json options:nil error:&error];
}

- (void) parseMapMetadata {
    NSDictionary* metadata = [self getMapMetadata];
    for (NSObject* obj in metadata) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSString* key = (NSString*) obj;
            if ([key isEqualToString:@"tileSet"]) {
                _tileSetUrl = [metadata objectForKey:key];
            } else if ([key isEqualToString:@"minZoom"]) {
                minZoom = [[metadata objectForKey:key] intValue];
            } else if ([key isEqualToString:@"maxNativeZoom"]) {
                maxNativeZoom = [[metadata objectForKey:key] intValue];
            } else if ([key isEqualToString:@"maxZoom"]) {
                maxZoom = [[metadata objectForKey:key] intValue];
            } else if ([key isEqualToString:@"defaultZoom"]) {
                defaultZoom = [[metadata objectForKey:key] intValue];
            } else if ([key isEqualToString:@"center"]) {
                NSDictionary* latLon = (NSDictionary*) [metadata objectForKey:key];
                centerLat = [[latLon objectForKey:@"lat"] doubleValue];
                centerLon = [[latLon objectForKey:@"lon"] doubleValue];
            } else if ([key isEqualToString:@"upperLeft"]) {
                NSDictionary* latLon = (NSDictionary*) [metadata objectForKey:key];
                upperLeftLat = [[latLon objectForKey:@"lat"] doubleValue];
                upperLeftLon = [[latLon objectForKey:@"lon"] doubleValue];
            } else if ([key isEqualToString:@"upperRight"]) {
                NSDictionary* latLon = (NSDictionary*) [metadata objectForKey:key];
                upperRightLat = [[latLon objectForKey:@"lat"] doubleValue];
                upperRightLon = [[latLon objectForKey:@"lon"] doubleValue];
            } else if ([key isEqualToString:@"lowerLeft"]) {
                NSDictionary* latLon = (NSDictionary*) [metadata objectForKey:key];
                lowerLeftLat = [[latLon objectForKey:@"lat"] doubleValue];
                lowerLeftLon = [[latLon objectForKey:@"lon"] doubleValue];
            } else if ([key isEqualToString:@"lowerRight"]) {
                NSDictionary* latLon = (NSDictionary*) [metadata objectForKey:key];
                lowerRightLat = [[latLon objectForKey:@"lat"] doubleValue];
                lowerRightLon = [[latLon objectForKey:@"lon"] doubleValue];
            } else if ([key isEqualToString:@"pixelSize"]) {
                NSDictionary* size = (NSDictionary*) [metadata objectForKey:key];
                mapPixelWidth = [[size objectForKey:@"width"] intValue];
                mapPixelHeight = [[size objectForKey:@"height"] intValue];
            }
        }
    }
}

- (void) loadLatestTraversePath {
    _points = [[NSMutableArray alloc] init];
    NSArray* locationManifest = [[MarsImageNotebook instance] getLocations];
    int locationCount = [locationManifest count];
    if (locationCount > 0) {
        int latestSiteIndex = [[[locationManifest objectAtIndex:locationCount-1] objectAtIndex:0] intValue];
        NSArray* locations = [[[MarsImageNotebook instance] mission] siteLocationData:latestSiteIndex];
        for (NSArray* location in locations) {
            if ([location count] >= 7) {
                double mapPixelH = [[location objectAtIndex:5] doubleValue];
                double mapPixelV = [[location objectAtIndex:6] doubleValue];
                CLLocationCoordinate2D latLon = CLLocationCoordinate2DMake(
                                                                           upperLeftLat + (mapPixelV/mapPixelHeight) * (lowerLeftLat-upperLeftLat),
                                                                           upperLeftLon + (mapPixelH/mapPixelWidth) * (upperRightLon-upperLeftLon));
                [_points addObject:[[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude]];
            }
        }
    }
}

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation {

    if (annotation.class == [RMShapeAnnotation class]) {
        RMShapeAnnotation* path = (RMShapeAnnotation*) annotation;
        RMShape *shape = [[RMShape alloc] initWithView:mapView];
        shape.lineColor = [[UIColor yellowColor] colorWithAlphaComponent:0.25];
        shape.lineWidth = 3.0;
        
        [shape performBatchOperations:^(RMShape* aShape) {
            for (CLLocation *point in path.points)
                [aShape addLineToCoordinate:point.coordinate];
        }];
        
        return shape;
    }
    
    return nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//            CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(-14.568421956470699, 175.47546601810708);
//            RMPointAnnotation *landerAnnotation = [[RMPointAnnotation alloc] initWithMapView:mapView
//                                                                                  coordinate:loc
//                                                                                    andTitle:@"Columbia Memorial Station"];
//            [mapView addAnnotation:landerAnnotation];
//            loc = CLLocationCoordinate2DMake(-14.602956462611218, 175.52579149235137);
//            landerAnnotation = [[RMPointAnnotation alloc] initWithMapView:mapView
//                                                               coordinate:loc
//                                                                 andTitle:@"Troy"];
//            [mapView addAnnotation:landerAnnotation];

//            dispatch_async(mapDownloadQueue, ^{
//                double startTime = [[NSDate date] timeIntervalSince1970];
//              NSData* traverseData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:@"http://merpublic.s3.amazonaws.com/maps/Spirit-traverse.json"]]; //META
//                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:traverseData
//                                                                     options:0
//                                                                       error:nil];
//                double endTime = [[NSDate date] timeIntervalSince1970];
//                NSLog(@"Time to read path JSON: %g", (endTime-startTime));
//
//                self.points = [[[[json objectForKey:@"features"] objectAtIndex:0] valueForKeyPath:@"geometry.coordinates"] mutableCopy];
//
//                for (NSUInteger i = 0; i < [self.points count]; i++)
//                    [self.points replaceObjectAtIndex:i
//                                           withObject:[[CLLocation alloc] initWithLatitude:[[[self.points objectAtIndex:i] objectAtIndex:1] doubleValue]
//                                                                                 longitude:[[[self.points objectAtIndex:i] objectAtIndex:0] doubleValue]]];
//                RMAnnotation *traversePath = [[RMAnnotation alloc] initWithMapView:mapView
//                                                                        coordinate:mapView.centerCoordinate
//                                                                          andTitle:@"Spirit's Traverse Path"];
//                [traversePath setBoundingBoxFromLocations:self.points];
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [mapView addAnnotation:traversePath];
//                });
//            });

@end
