//
//  MarsPhoto.m
//  Mars-Images
//
//  Created by Mark Powell on 12/22/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MarsPhoto.h"
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
    self.caption = [[MarsImageNotebook instance].mission captionText:resource note:note];
    return self;
}

- (id) initAnaglyph: (NSArray*) leftAndRight
               note: (EDAMNote*) note {
    self = [super init];
    _note = note;
    _leftAndRight = leftAndRight;
    EDAMResource* resource = [leftAndRight objectAtIndex:0];
    self.caption = [[MarsImageNotebook instance].mission captionText:resource note:note];
    return self;
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
                                                 progress:^(NSUInteger receivedSize, long long expectedSize) {
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
                                                        self.underlyingImage = [self anaglyphImages:_leftImage right:_rightImage];
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
                                                  progress:^(NSUInteger receivedSize, long long expectedSize) {
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
                                                         self.underlyingImage = [self anaglyphImages:_leftImage right:_rightImage];
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

- (UIImage*) anaglyphImages: (UIImage*)leftImage right:(UIImage*)rightImage {
    int width = (int)CGImageGetWidth(leftImage.CGImage);
    int height = (int)CGImageGetHeight(leftImage.CGImage);
    uint8_t* leftPixels = [self getGrayscalePixelArray:leftImage];
    uint8_t* rightPixels = [self getGrayscalePixelArray:rightImage];
    // now convert to anaglyph
    uint32_t *anaglyph = (uint32_t *) malloc(width * height * 4);
    for(int y = 0; y < height; y++) {
        for(int x = 0; x < width; x++) {
            uint32_t leftRed = (uint32_t)leftPixels[y*width+x];
            uint32_t rightCyan = (uint32_t)rightPixels[y*width+x];
            anaglyph[y*width+x]=leftRed<<24 | rightCyan <<16 | rightCyan<<8;
        }
    }
    free(leftPixels);
    free(rightPixels);
    
    // create a UIImage
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(anaglyph, width, height, 8, width * sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    UIImage *resultUIImage = [UIImage imageWithCGImage:image];
    CGImageRelease(image);
    
    // make sure the data will be released by giving it to an autoreleased NSData
    [NSData dataWithBytesNoCopy:anaglyph length:width * height];
    return resultUIImage;
}

-(uint8_t*) getGrayscalePixelArray: (UIImage*)image {
    int width = (int)CGImageGetWidth(image.CGImage);
    int height = (int)CGImageGetHeight(image.CGImage);
    uint8_t *gray = (uint8_t *) malloc(width * height * sizeof(uint8_t));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(gray, width, height, 8, width, colorSpace, kCGColorSpaceModelMonochrome);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetShouldAntialias(context, NO);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return gray;
}

@end
