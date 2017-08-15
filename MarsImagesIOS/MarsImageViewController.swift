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
import SDWebImage

class MarsImageViewController : MWPhotoBrowser {
    
    let dropdownMenuWidth = 140
    let dropdownMenuRowHeight = 44

    var catalog:MarsImageCatalog?
    let leftIcon = UIImage.init(named: "leftArrow.png")
    let rightIcon = UIImage.init(named: "rightArrow.png")
    
    var drawerClosed = true
    var drawerButton = UIBarButtonItem()
    var navBarMenu = MKDropdownMenu()
    var navBarButton = UIBarButtonItem()
    let menuItemNames = [ "Clock", "About" ]
    
    var popover:UIPopoverPresentationController?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = self
        self.makeButtons()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle:nibBundleOrNil)
        self.delegate = self
        self.makeButtons()
    }
    
    func makeButtons() {
        self.navBarMenu = MKDropdownMenu(frame: CGRect(x:0,y:0,width:dropdownMenuWidth,height:dropdownMenuRowHeight))
        self.navBarButton = UIBarButtonItem(customView: navBarMenu)
        drawerButton = UIBarButtonItem(image: rightIcon, style: .plain, target: self, action: #selector(manageDrawer(_:)))
    }
    
    override func viewDidLoad() {
        SDImageCache.shared().maxMemoryCost = 0

        navBarMenu.dataSource = self
        navBarMenu.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(imagesetsLoaded), name: .endImagesetLoading, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(imageSelected), name: .imageSelected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openDrawer), name: .openDrawer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(closeDrawer), name: .closeDrawer, object: nil)

        self.title = nil
        
        self.navigationItem.titleView = UILabel() //hide 1 of n title
        self.enableGrid = false //The default behavior of this grid feature doesn't work well. Refinement needed to make it good.
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(closeDrawerSwipe))
        swipeLeft.direction = .left
        self.navigationController?.navigationBar.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(openDrawerSwipe))
        swipeRight.direction = .right
        self.navigationController?.navigationBar.addGestureRecognizer(swipeRight)
        catalog?.reload()

        super.viewDidLoad()
    }
    
    @IBAction func manageDrawer(_ sender: Any) {
        if drawerClosed {
            NotificationCenter.default.post(name: .openDrawer, object: nil)
        } else {
            NotificationCenter.default.post(name: .closeDrawer, object: nil)
        }
    }
    
    func closeDrawerSwipe() {
        guard drawerClosed == false else {
            return
        }
        NotificationCenter.default.post(name: .closeDrawer, object: nil)
    }
    
    func openDrawerSwipe() {
        guard drawerClosed else {
            return
        }
        NotificationCenter.default.post(name: .openDrawer, object: nil)
    }
    
    func openDrawer() {
        drawerClosed = false
        drawerButton.image = leftIcon
    }
    
    func closeDrawer() {
        drawerClosed = true
        drawerButton.image = rightIcon
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    override func performLayout() {
        super.performLayout()
        //replace MWPhotoBrowser Done button with our action buttons
        navigationItem.rightBarButtonItems = [ drawerButton, navBarButton]
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if let presentationController = popover {
            presentationController.presentedViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    func imagesetsLoaded(notification: Notification) {
        var numImagesetsReturned = 0
        let num = notification.userInfo?[numImagesetsReturnedKey]
        if (num != nil) {
            numImagesetsReturned = num as! Int
        }
        if numImagesetsReturned > 0 {
            self.reloadData()
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
    
    func sourceRectForPopupController(_ bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0)
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

extension MarsImageViewController: MKDropdownMenuDataSource {
    func numberOfComponents(in dropdownMenu: MKDropdownMenu) -> Int {
        return 1
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, numberOfRowsInComponent component: Int) -> Int {
        return menuItemNames.count
    }
}

extension MarsImageViewController: MKDropdownMenuDelegate {
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, didSelectRow row: Int, inComponent component: Int) {
        dropdownMenu.closeAllComponents(animated: true)
        let menuItemName = menuItemNames[row]
        if menuItemName == "About" {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "aboutVC") as! AboutViewController
            vc.modalPresentationStyle = .popover
            popover = vc.popoverPresentationController
            if let presentationController = popover {
                presentationController.delegate = self
                presentationController.permittedArrowDirections =  UIPopoverArrowDirection(rawValue: 0)
                presentationController.sourceView = self.view
                presentationController.sourceRect = sourceRectForPopupController(self.view.bounds)
                presentationController.presentedViewController.preferredContentSize =
                    CGSize(width: self.view.bounds.size.width*0.8,
                            height: self.view.bounds.size.height*0.8)
                self.present(vc, animated: true, completion: nil)
            }
        }
        else if menuItemName == "Clock" {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "timeVC") as! TimeViewController
            vc.modalPresentationStyle = .popover
            popover = vc.popoverPresentationController
            if let presentationController = popover {
                presentationController.delegate = self
                presentationController.permittedArrowDirections =  UIPopoverArrowDirection(rawValue: 0)
                presentationController.sourceView = self.view
                presentationController.sourceRect = sourceRectForPopupController(self.view.bounds)
                presentationController.presentedViewController.preferredContentSize =
                    CGSize(width: self.view.bounds.size.width*0.8,
                           height: self.view.bounds.size.height*0.8)
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, widthForComponent component: Int) -> CGFloat {
        return CGFloat(dropdownMenuWidth)
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, rowHeightForComponent component: Int) -> CGFloat {
        return CGFloat(dropdownMenuRowHeight)
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, titleForComponent component: Int) -> String? {
        return ""
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, titleForRow row: Int, forComponent component: Int) -> String? {
        return menuItemNames[row]
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, backgroundColorForRow row: Int, forComponent component: Int) -> UIColor? {
        return UIColor.white
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, shouldUseFullRowWidthForComponent component: Int) -> Bool {
        return false
    }
}

extension MarsImageViewController: UIPopoverPresentationControllerDelegate {
    
}
