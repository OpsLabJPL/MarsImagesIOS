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

- (NSDictionary*) getMapMetadata {
    NSString* missionName = [MarsImageNotebook instance].missionName;
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"http://merpublic.s3.amazonaws.com/maps/%@Map.json", missionName]];
    NSData* json = [NSData dataWithContentsOfURL:url];
    NSError* error;
    return [NSJSONSerialization JSONObjectWithData:json options:nil error:&error];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    dispatch_async(mapDownloadQueue, ^{
        NSDictionary* metadata = [self getMapMetadata];
        for (NSObject* obj in metadata) {
            if ([obj isKindOfClass:[NSString class]]) {
                NSString* key = (NSString*) obj;
                if ([key isEqualToString:@"tileSet"]) {
                    _tileSetUrl = [metadata objectForKey:key];
                } else if ([key isEqualToString:@"minZoom"]) {
                    _minZoom = [metadata objectForKey:key];
                } else if ([key isEqualToString:@"maxNativeZoom"]) {
                    _maxNativeZoom = [metadata objectForKey:key];
                } else if ([key isEqualToString:@"maxZoom"]) {
                    _maxZoom = [metadata objectForKey:key];
                } else if ([key isEqualToString:@"defaultZoom"]) {
                    _defaultZoom = [metadata objectForKey:key];
                } else if ([key isEqualToString:@"center"]) {
                    NSDictionary* latLon = (NSDictionary*) [metadata objectForKey:key];
                    _centerLat = [latLon objectForKey:@"lat"];
                    _centerLon = [latLon objectForKey:@"lon"];
                } else if ([key isEqualToString:@"upperLeft"]) {
                    NSDictionary* latLon = (NSDictionary*) [metadata objectForKey:key];
                    _upperLeftLat = [latLon objectForKey:@"lat"];
                    _upperLeftLon = [latLon objectForKey:@"lon"];
                } else if ([key isEqualToString:@"upperRight"]) {
                    NSDictionary* latLon = (NSDictionary*) [metadata objectForKey:key];
                    _upperRightLat = [latLon objectForKey:@"lat"];
                    _upperRightLon = [latLon objectForKey:@"lon"];
                } else if ([key isEqualToString:@"lowerLeft"]) {
                    NSDictionary* latLon = (NSDictionary*) [metadata objectForKey:key];
                    _lowerLeftLat = [latLon objectForKey:@"lat"];
                    _lowerLeftLon = [latLon objectForKey:@"lon"];
                } else if ([key isEqualToString:@"lowerRight"]) {
                    NSDictionary* latLon = (NSDictionary*) [metadata objectForKey:key];
                    _lowerRightLat = [latLon objectForKey:@"lat"];
                    _lowerRightLon = [latLon objectForKey:@"lon"];
                }
            }
        }
        
        S3TileSource *source = [[S3TileSource alloc] initWithTileSetURL:[NSURL URLWithString:_tileSetUrl]
                                                                minZoom:_minZoom
                                                                maxZoom:_maxNativeZoom
                                                           upperLeftLat:_upperLeftLat
                                                           upperLeftLon:_upperLeftLon
                                                          lowerRightLat:_lowerRightLat
                                                          lowerRightLon:_lowerRightLon];

        dispatch_async(dispatch_get_main_queue(), ^{
            RMMapView *mapView = [[RMMapView alloc] initWithFrame:self.view.bounds andTilesource:source centerCoordinate:CLLocationCoordinate2DMake(_centerLat.floatValue, _centerLon.floatValue) zoomLevel:_defaultZoom.intValue maxZoomLevel:_maxZoom.intValue minZoomLevel:_minZoom.intValue backgroundImage:nil];
            mapView.delegate = self;
            mapView.minZoom = _minZoom.intValue;
            mapView.maxZoom = _maxZoom.intValue;
            mapView.zoom = _defaultZoom.intValue;
            //    mapView.showLogoBug = NO; //there is a bug that makes this crash...check for fix later
            mapView.hideAttribution = YES;
            mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            [self.view addSubview:mapView];
            
            CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(-14.568421956470699, 175.47546601810708);
            RMPointAnnotation *landerAnnotation = [[RMPointAnnotation alloc] initWithMapView:mapView
                                                                                  coordinate:loc
                                                                                    andTitle:@"Columbia Memorial Station"];
            [mapView addAnnotation:landerAnnotation];
            loc = CLLocationCoordinate2DMake(-14.602956462611218, 175.52579149235137);
            landerAnnotation = [[RMPointAnnotation alloc] initWithMapView:mapView
                                                               coordinate:loc
                                                                 andTitle:@"Troy"];
            [mapView addAnnotation:landerAnnotation];
            
            dispatch_async(mapDownloadQueue, ^{
                double startTime = [[NSDate date] timeIntervalSince1970];
              NSData* traverseData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:@"http://merpublic.s3.amazonaws.com/maps/Spirit-traverse.json"]]; //META
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:traverseData
                                                                     options:0
                                                                       error:nil];
                double endTime = [[NSDate date] timeIntervalSince1970];
                NSLog(@"Time to read path JSON: %g", (endTime-startTime));
              
                self.points = [[[[json objectForKey:@"features"] objectAtIndex:0] valueForKeyPath:@"geometry.coordinates"] mutableCopy];
                
                for (NSUInteger i = 0; i < [self.points count]; i++)
                    [self.points replaceObjectAtIndex:i
                                           withObject:[[CLLocation alloc] initWithLatitude:[[[self.points objectAtIndex:i] objectAtIndex:1] doubleValue]
                                                                                 longitude:[[[self.points objectAtIndex:i] objectAtIndex:0] doubleValue]]];
                RMAnnotation *traversePath = [[RMAnnotation alloc] initWithMapView:mapView
                                                                        coordinate:mapView.centerCoordinate
                                                                          andTitle:@"Spirit's Traverse Path"];
                [traversePath setBoundingBoxFromLocations:self.points];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [mapView addAnnotation:traversePath];
                });
            });
        });
    });
}

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation {
    if (annotation.isUserLocationAnnotation)
        return nil;
    
    RMShape *shape = [[RMShape alloc] initWithView:mapView];
    shape.lineColor = [UIColor whiteColor];
    shape.lineWidth = 1.0;
    
    [shape performBatchOperations:^(RMShape* aShape) {
        for (CLLocation *point in self.points)
            [aShape addLineToCoordinate:point.coordinate];
    }];
    
    return shape;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
