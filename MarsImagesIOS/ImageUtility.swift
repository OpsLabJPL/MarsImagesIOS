//
//  ImageUtility.swift
//  MarsImagesIOS
//
//  Created by Powell, Mark W (397F) on 8/24/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit
import CoreGraphics

class ImageUtility {
    
    static func scale(_ image: UIImage, newSize: CGSize) -> UIImage? {
        
        let scale = CGFloat(0.0) // Automatically use scale factor of main screen
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        image.draw(in: CGRect(origin:CGPoint.zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    static func anaglyph(left: UIImage, right: UIImage) -> UIImage {

        let context = CIContext(options: nil)
        let redImage = tint(image:left, color:UIColor.red, context:context)
        let cyanImage = tint(image:right, color:UIColor.cyan, context:context)
        let compFilter = CIFilter(name: "CIAdditionCompositing")!
        compFilter.setDefaults()
        compFilter.setValue(CIImage(image: cyanImage), forKey: kCIInputImageKey)
        compFilter.setValue(CIImage(image: redImage), forKey: kCIInputBackgroundImageKey)
        let outputImage = compFilter.outputImage!
        let cgimg = context.createCGImage(outputImage, from: outputImage.extent)!
        return UIImage(cgImage: cgimg)
    }
    
    static func tint(image: UIImage, color: UIColor, context:CIContext) -> UIImage {
        
        let ciImage = CIImage(image: image)

        let filter = CIFilter(name: "CIMultiplyCompositing")!
        let colorFilter = CIFilter(name: "CIConstantColorGenerator")!
        let ciColor = CIColor(color: color)
        colorFilter.setValue(ciColor, forKey: kCIInputColorKey)
        let colorImage = colorFilter.outputImage

        filter.setValue(colorImage, forKey: kCIInputImageKey)
        filter.setValue(ciImage, forKey: kCIInputBackgroundImageKey)
        let outputImage = filter.outputImage!

        //TODO had a crash here twice, tinting the left eye image. Watch for it again. Only in the debugger?
        let cgimg = context.createCGImage(outputImage, from: outputImage.extent)!
        return UIImage(cgImage: cgimg)
    }
}
