//
//  MarsPhoto.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/28/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation
import MWPhotoBrowser
import SDWebImage

class MarsPhoto: MWPhoto {
    
    var url:URL
    var imageset:Imageset
    var indexInImageset:Int
    var isLoading = false
    
    weak var leftImage:UIImage?
    weak var rightImage:UIImage?
    var leftAndRight:(String,String)?
    
    
    init (url:URL, imageset: Imageset, indexInImageset: Int) {
        self.url = url
        self.imageset = imageset
        self.indexInImageset = indexInImageset
        super.init(url:url)
        self.caption = Mission.currentMission().caption(self.imageset.title)
    }
    
    init (_ imageset: Imageset, leftAndRight:(String,String)) {
        self.imageset = imageset
        self.leftAndRight = leftAndRight
        self.url = URL(string:leftAndRight.0)!
        self.indexInImageset = 0
        super.init()
        self.caption = Mission.currentMission().caption(self.imageset.title)
    }
    
    func downloadImage(_ url:URL, _ setImageFunc:@escaping (_ image:UIImage?)->()) {
        let manager = SDWebImageManager.shared()!

        manager.downloadImage(with: url, options: [.retryFailed, .refreshCached],
                              progress:  { (receivedSize, expectedSize) -> Void in
                                if expectedSize > 0 {
                                    let progress = Float(receivedSize)/Float(expectedSize)
                                    let dict:[String:Any] = ["progress": progress, "photo": self]
                                    NotificationCenter.default.post(name: .mwphotoProgressNotification, object: dict)
                                }
        },
                              completed: { (image, error, cacheType, finished, imageURL) -> Void in
                                if let error = error {
                                    print("Error: \(url) \(error)")
                                    return
                                }
                                setImageFunc(image)
                                if let leftImage = self.leftImage, let rightImage = self.rightImage {
                                    ImageUtility.anaglyphImages(leftImage, right:rightImage)
                                    self.decompressImageAndFinishLoading()
                                }
        })
    }
    
    override func performLoadUnderlyingImageAndNotify() {
        isLoading = true
        guard (leftAndRight != nil) else {
            super.performLoadUnderlyingImageAndNotify()
            return
        }
        
        do {
            let leftUrl = leftAndRight!.0
            downloadImage(URL(string:leftUrl)!, { image in
                self.leftImage = image
            })
            let rightUrl = leftAndRight!.1
            downloadImage(URL(string:rightUrl)!, { image in
                self.rightImage = image
            })
            
//            _leftImageOperation = [manager downloadImageWithURL:leftUrl
//                options:0
//                progress:^(NSInteger receivedSize, NSInteger expectedSize) {
//                if (expectedSize > 0) {
//                float progress = receivedSize / (float)expectedSize;
//                NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
//                [NSNumber numberWithFloat:progress], @"progress",
//                self, @"photo", nil];
//                [[NSNotificationCenter defaultCenter] postNotificationName:MWPHOTO_PROGRESS_NOTIFICATION object:dict];
//                }
//                }
//                completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL* url) {
//                if (error) {
//                NSLog(@"SDWebImage failed to download image: %@", error);
//                }
//                _leftImageOperation = nil;
//                _leftImage = image;
//                if (_rightImage) {
//                self.underlyingImage = [ImageUtility anaglyphImages:_leftImage right:_rightImage];
//                [self decompressImageAndFinishLoading];
//                }
//                }];
//        } catch  {
//            NSLog(@"Photo from web: %@", e);
//            _leftImageOperation = nil;
//            [self decompressImageAndFinishLoading];
        }
    }

    func decompressImageAndFinishLoading() {
    //    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    //    if (self.underlyingImage) {
    //        // Decode image async to avoid lagging when UIKit lazy loads
    //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    //            self.underlyingImage = [UIImage decodedImageWithImage:self.underlyingImage];
    //            dispatch_async(dispatch_get_main_queue(), ^{
    //                // Finish on main thread
    //                [self imageLoadingComplete];
    //                });
    //            });
    //    } else {
    //        // Failed
    //        [self imageLoadingComplete];
    //    }
    }

    func imageLoadComplete() {
        isLoading = false
        DispatchQueue.global().async {
            NotificationCenter.default.post(name: .mwphotoLoadingDidEndNotification, object: self)
        }
    }
}

extension Notification.Name {
    static let mwphotoLoadingDidEndNotification = Notification.Name(MWPHOTO_LOADING_DID_END_NOTIFICATION)
    static let mwphotoProgressNotification = Notification.Name(MWPHOTO_PROGRESS_NOTIFICATION)
}
