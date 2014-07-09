//
//  S3TileSource.m
//  MapDemo
//
//  Created by Mark Powell on 7/3/13.
//  Copyright (c) 2013 Mark Powell. All rights reserved.
//

#import "S3TileSource.h"
#import "RMFractalTileProjection.h"
#import "RMMBTilesSource.h"

@implementation S3TileSource

@synthesize cacheable = _cacheable, opaque = _opaque;
@synthesize s3url = _s3url;
@synthesize imageCache = _imageCache;
@synthesize mercatorToTileProjection = _mercatorToTileProjection;
@synthesize projection = _projection;
@synthesize uniqueTilecacheKey = _uniqueTilecacheKey;
@synthesize latitudeLongitudeBoundingBox = _latitudeLongitudeBoundingBox;
@synthesize tileSideLength = _tileSideLength;
@synthesize shortAttribution = _shortAttribution;
@synthesize longAttribution = _longAttribution;
@synthesize shortName = _shortName;
@synthesize longDescription = _longDescription;
@synthesize minZoom = _minZoom;
@synthesize maxZoom = _maxZoom;

- (id)initWithTileSetURL:(NSURL*)tileSetURL
                 minZoom:(int)zoomMin
                 maxZoom:(int)zoomMax
            upperLeftLat:(double)ulLat
            upperLeftLon:(double)ulLon
           lowerRightLat:(double)lrLat
           lowerRightLon:(double)lrLon {
	
    if ( ! (self = [super init]))
		return nil;
    
    self.imageCache = [[NSMutableDictionary alloc] init];

    upperLeftLat = ulLat;
    upperLeftLon = ulLon;
    lowerRightLat = lrLat;
    lowerRightLon = lrLon;
    _s3url = tileSetURL;
    _cacheable = NO;
    _opaque = YES;
    _minZoom = (float)zoomMin;
    _maxZoom = (float)zoomMax;
    _uniqueTilecacheKey = [NSString stringWithFormat:@"MBTiles%@", [_s3url lastPathComponent]];
    _latitudeLongitudeBoundingBox = ((RMSphericalTrapezium){
        .northEast = {.latitude = upperLeftLat, .longitude = lowerRightLon},
        .southWest = {.latitude = lowerRightLat, .longitude = upperLeftLon}});
    _projection = [RMProjection googleProjection];
	_mercatorToTileProjection = [[RMFractalTileProjection alloc] initFromProjection:_projection
                                                           tileSideLength:kMBTilesDefaultTileSize
                                                                  maxZoom:kMBTilesDefaultMaxTileZoom
                                                                  minZoom:kMBTilesDefaultMinTileZoom];
    _tileSideLength = _mercatorToTileProjection.tileSideLength;

	return self;
}

- (void)cancelAllDownloads {
    // TODO
}

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache {
    NSAssert4(((tile.zoom >= self.minZoom) && (tile.zoom <= self.maxZoom)),
			  @"%@ tried to retrieve tile with zoomLevel %d, outside source's defined range %f to %f",
			  self, tile.zoom, self.minZoom, self.maxZoom);
    
    NSInteger zoom = tile.zoom;
    NSInteger x    = tile.x;
    NSInteger y    = pow(2, zoom) - tile.y - 1;
    
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [[NSNotificationCenter defaultCenter] postNotificationName:RMTileRequested object:[NSNumber numberWithUnsignedLongLong:RMTileKey(tile)]];
                   });
    
    __block UIImage *image = nil;

    //do a download image file from URL here, construct as UIImage
    NSString* path = [NSString stringWithFormat:@"%@/%i/%i/%i.png", [_s3url absoluteString], zoom, x, y]; //META extension
//    NSLog(@"URL: %@", path);
    image = [self getImageFromCache: path];
    
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [[NSNotificationCenter defaultCenter] postNotificationName:RMTileRetrieved object:[NSNumber numberWithUnsignedLongLong:RMTileKey(tile)]];
                   });
    
    return image;
}

- (UIImage*) getImageFromCache:(NSString*)url {
    UIImage* retImage = [_imageCache objectForKey:url];
    if (retImage == nil) {
        //TODO clear the cache LRU to manage memory size
        retImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
        if (retImage != nil) {
            [_imageCache setObject:retImage forKey:url];
        }
    }
    return retImage;
}

- (BOOL)tileSourceHasTile:(RMTile)tile {
    return YES;
}

- (void)didReceiveMemoryWarning {
    NSLog(@"*** didReceiveMemoryWarning in %@", [self class]);
    [_imageCache removeAllObjects];
}

@end
