//
//  MarsImageViewController.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/29/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit
import MKDropdownMenu
import MWPhotoBrowser

class MarsImageViewController : MWPhotoBrowser {
    
    let dropdownMenuWidth = 140
    let dropdownMenuRowHeight = 44

    var catalog:MarsImageCatalog?
    var navBarMenu:MKDropdownMenu

    required init?(coder aDecoder: NSCoder) {
        self.navBarMenu = MKDropdownMenu(frame: CGRect(x:0,y:0,width:dropdownMenuWidth,height:dropdownMenuRowHeight))
        super.init(coder: aDecoder)
        self.delegate = self
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.navBarMenu = MKDropdownMenu(frame: CGRect(x:0,y:0,width:dropdownMenuWidth,height:dropdownMenuRowHeight))
        super.init(nibName: nibNameOrNil, bundle:nibBundleOrNil)
        self.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navBarMenu.dataSource = self
        navBarMenu.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(imagesetsLoaded), name: .endImagesetLoading, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(imageSelected), name: .imageSelected, object: nil)
        self.title = nil
        
        self.navigationItem.titleView = UILabel() //hide 1 of n title
        self.enableGrid = false //The default behavior of this grid feature doesn't work well. Refinement needed to make it good.
        
    }
    
    override func performLayout() {
        super.performLayout()
        //hide Done button
        if let done = self.navigationItem.rightBarButtonItem {
            done.isEnabled = false
            done.title = ""
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navBarMenu)
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

extension MarsImageViewController: MKDropdownMenuDataSource {
    func numberOfComponents(in dropdownMenu: MKDropdownMenu) -> Int {
        return 1
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, numberOfRowsInComponent component: Int) -> Int {
        return 2
    }
}

extension MarsImageViewController: MKDropdownMenuDelegate {
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, didSelectRow row: Int, inComponent component: Int) {
        dropdownMenu.closeAllComponents(animated: true)
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, widthForComponent component: Int) -> CGFloat {
        return CGFloat(dropdownMenuWidth)
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, rowHeightForComponent component: Int) -> CGFloat {
        return CGFloat(dropdownMenuRowHeight)
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, titleForComponent component: Int) -> String? {
        return "Foo"
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, titleForRow row: Int, forComponent component: Int) -> String? {
        return "Foo"
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, backgroundColorForRow row: Int, forComponent component: Int) -> UIColor? {
        return UIColor.white
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, shouldUseFullRowWidthForComponent component: Int) -> Bool {
        return false
    }
}

