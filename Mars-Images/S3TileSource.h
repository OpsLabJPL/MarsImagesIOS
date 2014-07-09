//
//  S3TileSource.h
//  MapDemo
//
//  Created by Mark Powell on 7/3/13.
//  Copyright (c) 2013 Mark Powell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMTileSource.h"

@interface S3TileSource : NSObject<RMTileSource>
{
    double upperLeftLat;
    double upperLeftLon;
    double lowerRightLat;
    double lowerRightLon;
}
@property (strong, nonatomic) NSURL* s3url;

@property (nonatomic, strong) NSMutableDictionary* imageCache;

- (id)initWithTileSetURL:(NSURL*)tileSetURL
                 minZoom:(int)zoomMin
                 maxZoom:(int)zoomMax
            upperLeftLat:(double)ulLat
            upperLeftLon:(double)ulLon
           lowerRightLat:(double)lrLat
           lowerRightLon:(double)lrLon;

- (void)cancelAllDownloads;
- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache;
- (BOOL)tileSourceHasTile:(RMTile)tile;

@end
