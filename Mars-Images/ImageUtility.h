//
//  ImageUtility.h
//  Mars-Images
//
//  Created by Mark Powell on 2/8/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageUtility : NSObject

+ (UIImage*)resizeToValidTexture:(UIImage*) sourceImage;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
+ (void)imageDump:(UIImage*) image;
+ (UIImage*) grayscale: (UIImage*)sourceImage;
+ (UIImage*) anaglyphImages: (UIImage*)leftImage right:(UIImage*)rightImage;
+ (uint8_t*) getGrayscalePixelArray: (UIImage*)image;

@end
