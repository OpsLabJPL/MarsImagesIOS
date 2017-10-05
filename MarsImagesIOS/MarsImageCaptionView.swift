//
//  MarsImageCaptionView.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/29/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit
import MWPhotoBrowser

class MarsImageCaptionView : MWCaptionView {
    
    //if it's still fine looking after testing, just let the caption always display even when in a compressed width
    override func sizeThatFits(_ size: CGSize) -> CGSize {
//        if size.width > 100 {
            return super.sizeThatFits(size)
//        }
//        return CGSize(width: 0, height: 0)
    }
}
