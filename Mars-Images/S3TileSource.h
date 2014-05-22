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

@property (strong, nonatomic) NSURL* s3url;
@property (strong, nonatomic) NSNumber* upperLeftLat;
@property (strong, nonatomic) NSNumber* upperLeftLon;
@property (strong, nonatomic) NSNumber* lowerRightLat;
@property (strong, nonatomic) NSNumber* lowerRightLon;

@property (nonatomic, strong) NSMutableDictionary* imageCache;

- (id)initWithTileSetURL:(NSURL*)tileSetURL
                 minZoom:(NSNumber*)minZoom
                 maxZoom:(NSNumber*)maxZoom
            upperLeftLat:(NSNumber*)upperLeftLat
            upperLeftLon:(NSNumber*)upperLeftLon
           lowerRightLat:(NSNumber*)lowerRightLat
           lowerRightLon:(NSNumber*)lowerRightLon;

- (void)cancelAllDownloads;
- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache;
- (BOOL)tileSourceHasTile:(RMTile)tile;

@end
