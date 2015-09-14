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
    @property (nonatomic, strong) NSMutableDictionary *rmcsForPoints;
@end

@implementation MapViewController

static dispatch_queue_t mapDownloadQueue = nil;
bool viewControllerIsClosing = NO;

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
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];

    viewControllerIsClosing = NO;
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
    _mapView.adjustTilesForRetinaDisplay = YES;
    _mapView.hideAttribution = YES;
    _mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [_mapView setBackgroundImage:[UIImage imageNamed:@"black_background.png"]];
    [self.view addSubview:_mapView];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
    viewControllerIsClosing = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //these set statements have to be here...they don't work in viewDidLoad, either before or after adding the view to the hierarchy. Quirky.
    [_mapView setMinZoom:minZoom];
    [_mapView setMaxZoom:maxZoom];
    [_mapView setZoom:maxZoom-2];
    
    _traversePath = [[RMShapeAnnotation alloc] initWithMapView:_mapView points:_points];
    [_mapView addAnnotation:_traversePath];
    int i = 0;
    RMPointAnnotation* lastMarker = nil;
    int lastIndex = (int)[_points count]-1;
    for (CLLocation* loc in _points) {
        NSString* title = nil;
        if (i == lastIndex) {
            title = [MarsImageNotebook instance].missionName;
        }
        RMPointAnnotation *locationMarker = [[RMPointAnnotation alloc] initWithMapView:_mapView
                                                                            coordinate:CLLocationCoordinate2DMake(loc.coordinate.latitude, loc.coordinate.longitude)
                                                                              andTitle:title];
        locationMarker.userInfo = [_rmcsForPoints objectForKey:[NSNumber numberWithInt:i]];
        [_mapView addAnnotation:locationMarker];
        lastMarker = locationMarker;
        i += 1;
    }
    
    dispatch_async(mapDownloadQueue, ^{
        int siteIndex = latestSiteIndex-1;
        CLLocation *firstPointOfNextSite = [_traversePath.points objectAtIndex:0];
        while (siteIndex > 0) {
            if (viewControllerIsClosing) {
                return;
            }
            NSLog(@"Loading map markers for site %d", siteIndex);
            NSArray* locations = [[[MarsImageNotebook instance] mission] siteLocationData:siteIndex];
            NSMutableArray* pts = [[NSMutableArray alloc] init];
            NSMutableArray* markers = [[NSMutableArray alloc] init];
            for (NSArray* location in locations) {
                if ([location count] >= 7) {
                    int driveIndex = [[location objectAtIndex:0] intValue];
                    double mapPixelH = [[location objectAtIndex:5] doubleValue];
                    double mapPixelV = [[location objectAtIndex:6] doubleValue];
                    CLLocationCoordinate2D latLon = CLLocationCoordinate2DMake(
                                                                               upperLeftLat + (mapPixelV/mapPixelHeight) * (lowerLeftLat-upperLeftLat),
                                                                               upperLeftLon + (mapPixelH/mapPixelWidth) * (upperRightLon-upperLeftLon));
                    CLLocation *loc = [[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
                    RMPointAnnotation *locationMarker = [[RMPointAnnotation alloc] initWithMapView:_mapView
                                                                                        coordinate:CLLocationCoordinate2DMake(loc.coordinate.latitude, loc.coordinate.longitude)
                                                                                          andTitle:nil];
                    locationMarker.userInfo = [NSArray arrayWithObjects:[NSNumber numberWithInt:siteIndex], [NSNumber numberWithInt:driveIndex], nil];
                    [markers addObject:locationMarker];
                    [pts addObject:loc];
                }
            }

            if ([pts count] > 0) {
                [pts addObject:firstPointOfNextSite];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (viewControllerIsClosing) {
                        return;
                    }
                    for (RMPointAnnotation* locationMarker in markers) {
                        [_mapView addAnnotation:locationMarker];
                    }
                    [_mapView addAnnotation:[[RMShapeAnnotation alloc] initWithMapView:_mapView points:pts]];
                });
                firstPointOfNextSite = [pts objectAtIndex:0];
            }
            [NSThread sleepForTimeInterval:.5];
            siteIndex--;
        }
    });
}

- (void) defaultsChanged:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSDictionary*) getMapMetadata {
    NSString* missionName = [MarsImageNotebook instance].missionName;
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"https://s3-us-west-1.amazonaws.com/merpublic/maps/%@Map.json", missionName]];
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
    _rmcsForPoints = [[NSMutableDictionary alloc] init];
    NSArray* locationManifest = [[MarsImageNotebook instance] getLocations];
    int locationCount = (int)[locationManifest count];
    if (locationCount > 0) {
        latestSiteIndex = [[[locationManifest objectAtIndex:locationCount-1] objectAtIndex:0] intValue];
        int i = 0;
        do {
            NSArray* locations = [[[MarsImageNotebook instance] mission] siteLocationData:latestSiteIndex];
            for (NSArray* location in locations) {
                if ([location count] >= 7) {
                    int driveIndex = [((NSString*)[location objectAtIndex:0]) intValue];
                    double mapPixelH = [[location objectAtIndex:5] doubleValue];
                    double mapPixelV = [[location objectAtIndex:6] doubleValue];
                    CLLocationCoordinate2D latLon = CLLocationCoordinate2DMake(
                                                                               upperLeftLat + (mapPixelV/mapPixelHeight) * (lowerLeftLat-upperLeftLat),
                                                                               upperLeftLon + (mapPixelH/mapPixelWidth) * (upperRightLon-upperLeftLon));
                    CLLocation* point = [[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
                    [_points addObject:point];
                    NSArray* rmc = [NSArray arrayWithObjects:[NSNumber numberWithInt:latestSiteIndex], [NSNumber numberWithInt:driveIndex], nil];
                    [_rmcsForPoints setObject:rmc forKey:[NSNumber numberWithInt:i]];
                    i += 1;
                }
            }
            
            latestSiteIndex -= 1;
        } while ([_points count] == 0); //as soon as there are any points from the most recent location that has some, stop
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark RMMapViewDelegate

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

- (void)mapView:(RMMapView *)mapView didSelectAnnotation:(RMAnnotation *)annotation {
    NSLog(@"Selected %@", annotation);
    NSArray* rmc = annotation.userInfo;
    if (rmc && [rmc count] == 2) {
        NSLog(@"RMC %@:%@", [rmc objectAtIndex:0], [rmc objectAtIndex:1]);
        int site_index = [[rmc objectAtIndex:0] intValue];
        int drive_index = [[rmc objectAtIndex:1] intValue];
        [MarsImageNotebook instance].searchWords = [NSString stringWithFormat:@"RMC %06d-%06d", site_index, drive_index];
        [[MarsImageNotebook instance] reloadNotes]; //rely on the resultant note load notifications to populate images in the scene
    }
}

@end
