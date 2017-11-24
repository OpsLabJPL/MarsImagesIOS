//
//  ImageCreator.swift
//  Pods
//
//  Created by Mark Powell on 11/10/17.
//

import Foundation
import SDWebImage

@objc public protocol ImageDelegate {
    @objc optional func progress(receivedSize: Int, expectedSize:Int)
    func finished(image: UIImage)
    func failure()
}

open class ImageCreator {

    public let url:URL
    public var delegate:ImageDelegate?
    public var loadInProgress = false
    
    public init(url: URL, delegate:ImageDelegate?) {
        self.url = url
        self.delegate = delegate
    }
    
    open func requestImage() {
        if loadInProgress {
            return
        }
        loadInProgress = true
        SDWebImageManager.shared().loadImage(with: url, options: .refreshCached,
            progress:  { (receivedSize, expectedSize, targetUrl) -> Void in
                self.delegate?.progress?(receivedSize:receivedSize, expectedSize:expectedSize)
            },
            completed: { (image, data, error, cacheType, finished, imageURL) -> Void in
                self.loadInProgress = false
                if let image = image {
                    self.delegate?.finished(image:image)
                } else {
                    self.delegate?.failure()
                }
            })
    }
}

