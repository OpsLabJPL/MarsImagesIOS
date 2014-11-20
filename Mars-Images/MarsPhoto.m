//
//  MarsPhoto.m
//  Mars-Images
//
//  Created by Mark Powell on 12/22/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MarsPhoto.h"
#import "CameraModel.h"
#import "Math.h"
#import "ImageUtility.h"
#import "MarsImageNotebook.h"
#import "SDWebImageManager.h"
#import "SDWebImageDecoder.h"

@interface MarsPhoto () {
    BOOL _anaglyphLoadingInProgress;
    id <SDWebImageOperation> _leftImageOperation;
    id <SDWebImageOperation> _rightImageOperation;
}
@end

@implementation MarsPhoto

double d1[3], d2[3];

- (id) initWithResource: (EDAMResource*) resource
                   note: (EDAMNote*) note
                    url: (NSURL*) url {
    self = [super initWithURL:url];
    _note = note;
    _resource = resource;
    _model_json = nil;
    self.caption = [[MarsImageNotebook instance].mission captionText:note];
    return self;
}

- (id) initAnaglyph: (NSArray*) leftAndRight
               note: (EDAMNote*) note {
    self = [super init];
    _note = note;
    _leftAndRight = leftAndRight;
    self.caption = [[MarsImageNotebook instance].mission captionText:note];
    return self;
}

- (BOOL) isGrayscale {
    if ([_note.title rangeOfString:@"Mastcam"].location != NSNotFound ||
        [_note.title rangeOfString:@"MAHLI"].location != NSNotFound ||
        [_note.title rangeOfString:@"MARDI"].location != NSNotFound ||
        [_note.title rangeOfString:@"Color"].location != NSNotFound)
        return NO;

    return _leftAndRight == nil;
}

- (BOOL) includedInMosaic {
    return ([_note.title rangeOfString:@"Navcam"].location != NSNotFound
//           || [_note.title rangeOfString:@"Mastcam"].location != NSNotFound
//           || [_note.title rangeOfString:@"Pancam"].location != NSNotFound
            );
    //TODO include these when texture memory can be managed effectively
}

- (NSURL*) url: (EDAMResource*) resource {
    NSString* resGUID = resource.guid;
    NSString* address = [NSString stringWithFormat:@"%@res/%@", Evernote.instance.user.webApiUrlPrefix, resGUID];
    return [NSURL URLWithString:address];
}

- (void)performLoadUnderlyingImageAndNotify {
    // Load async from web (using SDWebImage)
    if (_leftAndRight) {
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        @try {
            EDAMResource* leftResource = [_leftAndRight objectAtIndex:0];
            NSURL* leftUrl = [self url:leftResource];
            _leftImageOperation = [manager downloadImageWithURL:leftUrl
                                                      options:0
                                                 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                     if (expectedSize > 0) {
                                                         float progress = receivedSize / (float)expectedSize;
                                                         NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                               [NSNumber numberWithFloat:progress], @"progress",
                                                                               self, @"photo", nil];
                                                         [[NSNotificationCenter defaultCenter] postNotificationName:MWPHOTO_PROGRESS_NOTIFICATION object:dict];
                                                     }
                                                 }
                                                completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL* url) {
                                                    if (error) {
                                                        NSLog(@"SDWebImage failed to download image: %@", error);
                                                    }
                                                    _leftImageOperation = nil;
                                                    _leftImage = image;
                                                    if (_rightImage) {
                                                        self.underlyingImage = [ImageUtility anaglyphImages:_leftImage right:_rightImage];
                                                        [self decompressImageAndFinishLoading];
                                                    }
                                                }];
        } @catch (NSException *e) {
            NSLog(@"Photo from web: %@", e);
            _leftImageOperation = nil;
            [self decompressImageAndFinishLoading];
        }

        @try {
            EDAMResource* rightResource = [_leftAndRight objectAtIndex:1];
            NSURL* rightUrl = [self url:rightResource];
            _rightImageOperation = [manager downloadImageWithURL:rightUrl
                                                   options:0
                                                  progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                      if (expectedSize > 0) {
                                                          float progress = receivedSize / (float)expectedSize;
                                                          NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                                [NSNumber numberWithFloat:progress], @"progress",
                                                                                self, @"photo", nil];
                                                          [[NSNotificationCenter defaultCenter] postNotificationName:MWPHOTO_PROGRESS_NOTIFICATION object:dict];
                                                      }
                                                  }
                                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL* url) {
                                                     if (error) {
                                                         NSLog(@"SDWebImage failed to download image: %@", error);
                                                     }
                                                     _rightImageOperation = nil;
                                                     _rightImage = image;
                                                     if (_leftImage) {
                                                         self.underlyingImage = [ImageUtility anaglyphImages:_leftImage right:_rightImage];
                                                         [self decompressImageAndFinishLoading];
                                                     }
                                                 }];
        } @catch (NSException *e) {
            NSLog(@"Photo from web: %@", e);
            _rightImageOperation = nil;
            [self decompressImageAndFinishLoading];
        }
    }
    else {
        [super performLoadUnderlyingImageAndNotify];
    }
}

- (void)decompressImageAndFinishLoading {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    if (self.underlyingImage) {
        // Decode image async to avoid lagging when UIKit lazy loads
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.underlyingImage = [UIImage decodedImageWithImage:self.underlyingImage];
            dispatch_async(dispatch_get_main_queue(), ^{
                // Finish on main thread
                [self imageLoadingComplete];
            });
        });
    } else {
        // Failed
        [self imageLoadingComplete];
    }
}

- (void)imageLoadingComplete {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    // Complete so notify
    _anaglyphLoadingInProgress = NO;
    // Notify on next run loop
    [self performSelector:@selector(postCompleteNotification) withObject:nil afterDelay:0];
}

- (NSArray*) modelJson {
    if (!_model_json) {
        NSString* cmod_string = self.resource.attributes.cameraModel;
        if (!cmod_string || cmod_string.length == 0)
            return nil;
        NSData* json = [cmod_string dataUsingEncoding:NSUTF8StringEncoding];
        NSError* error;
        _model_json = [NSJSONSerialization JSONObjectWithData:json options:nil error:&error];
    }
    return _model_json;
}

- (double) angularDistance: (MarsPhoto*) otherImage {
    NSArray* v1 = [CameraModel pointingVector:_model_json];
    NSArray* v2 = [CameraModel pointingVector:[otherImage modelJson]];
    if (v1.count==0 || v2.count==0)
        return 0;
    
    d1[0] = [(NSNumber*)[v1 objectAtIndex:0] doubleValue];
    d1[1] = [(NSNumber*)[v1 objectAtIndex:1] doubleValue];
    d1[2] = [(NSNumber*)[v1 objectAtIndex:2] doubleValue];
    d2[0] = [(NSNumber*)[v2 objectAtIndex:0] doubleValue];
    d2[1] = [(NSNumber*)[v2 objectAtIndex:1] doubleValue];
    d2[2] = [(NSNumber*)[v2 objectAtIndex:2] doubleValue];
    
    double dot = [Math dot:d1 b:d2];
    return acos(dot);
}

@end
