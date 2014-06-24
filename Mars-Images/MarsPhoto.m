//
//  MarsPhoto.m
//  Mars-Images
//
//  Created by Mark Powell on 12/22/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MarsPhoto.h"
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

- (id) initWithResource: (EDAMResource*) resource
                   note: (EDAMNote*) note
                    url: (NSURL*) url {
    self = [super initWithURL:url];
    _note = note;
    _resource = resource;
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
    return ([_note.title rangeOfString:@"Navcam"].location != NSNotFound ||
            [_note.title rangeOfString:@"Mastcam"].location != NSNotFound ||
            [_note.title rangeOfString:@"Pancam"].location != NSNotFound);
}

- (void)performLoadUnderlyingImageAndNotify {
    // Load async from web (using SDWebImage)
    if (_leftAndRight) {
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        @try {
            EDAMResource* leftResource = [_leftAndRight objectAtIndex:0];
            NSString* resGUID = leftResource.guid;
            NSString* leftAddress = [NSString stringWithFormat:@"%@res/%@", Evernote.instance.user.webApiUrlPrefix, resGUID];
            NSURL* leftUrl = [NSURL URLWithString:leftAddress];
            _leftImageOperation = [manager downloadWithURL:leftUrl
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
                                                completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
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
            NSString* resGUID = rightResource.guid;
            NSString* rightAddress = [NSString stringWithFormat:@"%@res/%@", Evernote.instance.user.webApiUrlPrefix, resGUID];
            NSURL* rightUrl = [NSURL URLWithString:rightAddress];
            _rightImageOperation = [manager downloadWithURL:rightUrl
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
                                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
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



@end
