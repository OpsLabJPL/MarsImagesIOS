//
//  ImageUtility.m
//  Mars-Images
//
//  Created by Mark Powell on 2/8/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import "ImageUtility.h"

@implementation ImageUtility

+ (BOOL) powerOfTwo: (int) x {
    return !(x == 0) && !(x & (x - 1));
}

+ (int) nextHighestPowerOfTwo: (int) n {
    double y = floor(log2(n));
    return (int)pow(2, y + 1);
}

+ (int) nextLowestPowerOfTwo: (int) n {
    double y = floor(log2(n));
    return (int)pow(2, y - 1);
}

+ (UIImage*)resizeToValidTexture:(UIImage*) sourceImage {
    CGSize size = sourceImage.size;
    if (size.width != size.height ||
        ![ImageUtility powerOfTwo:(int)size.width] ||
        ![ImageUtility powerOfTwo:(int)size.height]) {
        
        int length = MAX((int)size.width, (int)size.height);
        if (![ImageUtility powerOfTwo:length]) {
            length = [ImageUtility nextLowestPowerOfTwo:length];
        }
        return [ImageUtility imageWithImage:sourceImage scaledToSize:CGSizeMake(length, length)];
    }
    return sourceImage;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

/* Convert an image with only one band of useful intensities to grayscale */
+ (UIImage*)grayscale:(UIImage *)sourceImage {
    int width = (int)CGImageGetWidth(sourceImage.CGImage);
    int height = (int)CGImageGetHeight(sourceImage.CGImage);
    uint8_t* pixels = [ImageUtility getGrayscalePixelArray:sourceImage];
    
    // create a UIImage
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaNone);
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    UIImage *resultUIImage = [UIImage imageWithCGImage:image];
    CGImageRelease(image);
    
    // make sure the data will be released by giving it to an autoreleased NSData
    [NSData dataWithBytesNoCopy:pixels length:width * height];
    return resultUIImage;
}

+ (UIImage*) anaglyphImages: (UIImage*)leftImage right:(UIImage*)rightImage {
    int width = (int)CGImageGetWidth(leftImage.CGImage);
    int height = (int)CGImageGetHeight(leftImage.CGImage);
    uint8_t* leftPixels = [ImageUtility getGrayscalePixelArray:leftImage];
    uint8_t* rightPixels = [ImageUtility getGrayscalePixelArray:rightImage];
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

+ (uint8_t*) getGrayscalePixelArray: (UIImage*)image {
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

+(void)imageDump:(UIImage*) image
{
    CGImageRef cgimage = image.CGImage;
    
    size_t width  = CGImageGetWidth(cgimage);
    size_t height = CGImageGetHeight(cgimage);
    
    size_t bpr = CGImageGetBytesPerRow(cgimage);
    size_t bpp = CGImageGetBitsPerPixel(cgimage);
    size_t bpc = CGImageGetBitsPerComponent(cgimage);
    CGBitmapInfo info = CGImageGetBitmapInfo(cgimage);
    
    NSLog(
          @"\n"
          "CGImageGetHeight: %d\n"
          "CGImageGetWidth:  %d\n"
          "CGImageGetColorSpace: %@\n"
          "CGImageGetBitsPerPixel:     %d\n"
          "CGImageGetBitsPerComponent: %d\n"
          "CGImageGetBytesPerRow:      %d\n"
          "CGImageGetBitmapInfo: 0x%.8X\n"
          "  kCGBitmapAlphaInfoMask     = %s\n"
          "  kCGBitmapFloatComponents   = %s\n"
          "  kCGBitmapByteOrderMask     = 0x%.8X\n"
          "  kCGBitmapByteOrderDefault  = %s\n"
          "  kCGBitmapByteOrder16Little = %s\n"
          "  kCGBitmapByteOrder32Little = %s\n"
          "  kCGBitmapByteOrder16Big    = %s\n"
          "  kCGBitmapByteOrder32Big    = %s\n",
          (int)width,
          (int)height,
          CGImageGetColorSpace(cgimage),
          (int)bpp,
          (int)bpc,
          (int)bpr,
          (unsigned)info,
          (info & kCGBitmapAlphaInfoMask)     ? "YES" : "NO",
          (info & kCGBitmapFloatComponents)   ? "YES" : "NO",
          (info & kCGBitmapByteOrderMask),
          ((info & kCGBitmapByteOrderMask) == kCGBitmapByteOrderDefault)  ? "YES" : "NO",
          ((info & kCGBitmapByteOrderMask) == kCGBitmapByteOrder16Little) ? "YES" : "NO",
          ((info & kCGBitmapByteOrderMask) == kCGBitmapByteOrder32Little) ? "YES" : "NO",
          ((info & kCGBitmapByteOrderMask) == kCGBitmapByteOrder16Big)    ? "YES" : "NO",
          ((info & kCGBitmapByteOrderMask) == kCGBitmapByteOrder32Big)    ? "YES" : "NO"
          );
}

@end
