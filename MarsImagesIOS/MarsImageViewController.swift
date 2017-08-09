//
//  MarsImageViewController.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/29/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit
import MWPhotoBrowser

class MarsImageViewController : MWPhotoBrowser {
    
    var catalog:MarsImageCatalog?
    let leftIcon = UIImage.init(named: "leftArrow.png")
    let rightIcon = UIImage.init(named: "rightArrow.png")
    
    var drawerClosed = true
    var drawerButton: UIBarButtonItem?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = self
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle:nibBundleOrNil)
        self.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(imagesetsLoaded), name: .endImagesetLoading, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(imageSelected), name: .imageSelected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openDrawer), name: .openDrawer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(closeDrawer), name: .closeDrawer, object: nil)

        self.title = nil
        
        self.navigationItem.titleView = UILabel() //hide 1 of n title
        self.enableGrid = false //The default behavior of this grid feature doesn't work well. Refinement needed to make it good.
        
        drawerButton = UIBarButtonItem(image: rightIcon, style: .plain, target: self, action: #selector(manageDrawer(_:)))
        navigationItem.rightBarButtonItem = drawerButton
    }

    @IBAction func manageDrawer(_ sender: Any) {
        if drawerClosed {
            NotificationCenter.default.post(name: .openDrawer, object: nil)
        } else {
            NotificationCenter.default.post(name: .closeDrawer, object: nil)
        }
    }
    
    func openDrawer() {
        drawerClosed = false
        drawerButton?.image = leftIcon
//        navigationController?.navigationBar.setNeedsLayout()
    }
    
    func closeDrawer() {
        drawerClosed = true
        drawerButton?.image = rightIcon
//        navigationController?.navigationBar.setNeedsLayout()
    }
    
    override func performLayout() {
        super.performLayout()
        //hide Done button
//        if let done = self.navigationItem.rightBarButtonItem {
//            done.isEnabled = false
//            done.title = ""
//        }
        navigationItem.rightBarButtonItem = drawerButton

    }
    
    func imagesetsLoaded(notification: Notification) {
        var numImagesetsReturned = 0
        let num = notification.userInfo?[numImagesetsReturnedKey]
        if (num != nil) {
            numImagesetsReturned = num as! Int
        }
        if numImagesetsReturned > 0 {
            DispatchQueue.main.async {
                self.reloadData()
            }
        }
    }
    
    func imageSelected(notification:Notification) {
        var index = 0;
        if let num = notification.userInfo?[Constants.imageIndexKey] as? Int {
            index = Int(num)
        }
        
        if let sender = notification.userInfo?[Constants.senderKey] as? NSObject {
            if sender != self && index != Int(currentIndex) {
                setCurrentPhotoIndex(UInt(index))
            }
        }
    }
}

extension MarsImageViewController : MWPhotoBrowserDelegate {
    func numberOfPhotos(in photoBrowser: MWPhotoBrowser!) -> UInt {
        return UInt(catalog!.imagesetCount)
    }
    
    func photoBrowser(_ photoBrowser: MWPhotoBrowser!, photoAt index: UInt) -> MWPhotoProtocol! {
        if catalog!.marsphotos.count > Int(index) {
            return catalog!.marsphotos[Int(index)]
        }
        return nil
    }
    
    func photoBrowser(_ photoBrowser: MWPhotoBrowser!, didDisplayPhotoAt index: UInt) {
        let count = UInt(catalog!.imagesetCount)
        if index == count-1 {
            catalog!.loadNextPage()
        }
        let dict:[String:Any] = [ Constants.imageIndexKey: Int(index), Constants.senderKey: self ]
        NotificationCenter.default.post(name: .imageSelected, object: nil, userInfo: dict)
    }
    
    func photoBrowser(_ photoBrowser: MWPhotoBrowser!, captionViewForPhotoAt index: UInt) -> MWCaptionView! {
        if catalog!.marsphotos.count > Int(index) {
            return MarsImageCaptionView(photo: catalog!.marsphotos[Int(index)])
        }
        return nil
    }
    
    override func thumbPhoto(at index: UInt) -> MWPhotoProtocol! {
        if let thumbURL = catalog!.imagesets[Int(index)].thumbnailUrl {
            return MWPhoto(url: URL(string:thumbURL))
        }
        return nil
    }
}

extension Notification.Name {
    static let openDrawer = Notification.Name("OpenDrawer")
    static let closeDrawer = Notification.Name("CloseDrawer")
}
