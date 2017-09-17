//
//  MarsImageViewController.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/29/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit
import MWPhotoBrowser
import PSMenuItem
import SDWebImage

class MarsImageViewController : MWPhotoBrowser {
    
    var catalog:MarsImageCatalog?
    let leftIcon = UIImage.init(named: "leftArrow.png")
    let rightIcon = UIImage.init(named: "rightArrow.png")
    
    var drawerClosed = true
    var drawerButton = UIBarButtonItem()
    var imageSelectionButton = UIBarButtonItem()
    var infoButton = UIButton(type: UIButtonType.infoLight)
    var aboutTheAppButton = UIBarButtonItem(image: nil, style: .plain, target: self, action: #selector(showAboutView))
    var mosaicViewButton = UIBarButtonItem(image: UIImage(named: "panorama_icon.png"), style: .plain, target: self, action: #selector(showMosaicView))
    var timeViewButton = UIBarButtonItem(image: UIImage(named: "clock.png"), style: .plain, target: self, action: #selector(showTimeView))
    var selectedImageIndexInImageset = 0
    
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
        drawerButton = UIBarButtonItem(image: rightIcon, style: .plain, target: self, action: #selector(manageDrawer(_:)))
    }
    
    override func viewDidLoad() {
        SDImageCache.shared().maxMemoryCost = 0

        PSMenuItem.installMenuHandler(for: self)
        NotificationCenter.default.addObserver(self, selector: #selector(imagesetsLoaded), name: .endImagesetLoading, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(imageSelected), name: .imageSelected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openDrawer), name: .openDrawer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(closeDrawer), name: .closeDrawer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)

        self.title = nil
        
        self.navigationItem.titleView = UILabel() //hide 1 of n title
        self.enableGrid = false //The default behavior of this grid feature doesn't work well. Refinement needed to make it good.
        
        aboutTheAppButton.image = infoButton.currentImage
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(closeDrawerSwipe))
        swipeLeft.direction = .left
        self.navigationController?.navigationBar.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(openDrawerSwipe))
        swipeRight.direction = .right
        self.navigationController?.navigationBar.addGestureRecognizer(swipeRight)
        catalog?.reload()

        super.viewDidLoad()
        
        imageSelectionButton = UIBarButtonItem(title:"", style:.plain, target:self, action:#selector(imageSelectionPressed))
        addToolbarButtons()
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
        addToolbarButtons()
    }
    
    func closeDrawer() {
        drawerClosed = true
        drawerButton.image = rightIcon
        addToolbarButtons()
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func addToolbarButtons() {
        //add image selection button to bottom toolbar
        if let toolbar = getToolbar() {
            let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            if let items = toolbar.items {
                setImageSelectionButtonWidth()
                let share = items.last!
                if (drawerClosed || UIDevice.current.userInterfaceIdiom == .pad) {
                    toolbar.setItems([ imageSelectionButton, flex, aboutTheAppButton, flex, mosaicViewButton, flex, timeViewButton, flex, share], animated: true)
                } else {
                    toolbar.setItems([ imageSelectionButton, flex, share], animated: true)
                }
            }
        }
    }
    
    func setImageSelectionButtonWidth() {
        if let title = imageSelectionButton.title {
            imageSelectionButton.width = title.width(withConstraintedHeight: getToolbar()!.frame.size.height, font: UIFont.systemFont(ofSize: 20))
        }
    }
    
    override func performLayout() {
        super.performLayout()
        //replace MWPhotoBrowser Done button with our action buttons
        navigationItem.rightBarButtonItems = [ drawerButton ]
        
        addToolbarButtons()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if let presentationController = popover {
            presentationController.presentedViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    func defaultsChanged() {
        //set the image page to the first page when the mission changes
        self.setCurrentPhotoIndex(UInt(0))
    }
    
    func imagesetsLoaded(notification: Notification) {
        self.reloadData()
        //need to reload the image in case the mission has changed and current image page index has stayed the same
        self.photo(at: self.currentIndex)?.performLoadUnderlyingImageAndNotify()
    }
    
    func imageSelected(notification:Notification) {
        var index = 0
        if let num = notification.userInfo?[Constants.imageIndexKey] as? Int {
            index = Int(num)
        }
        
        if let sender = notification.userInfo?[Constants.senderKey] as? NSObject {
            if sender != self && index != Int(currentIndex) {
                setCurrentPhotoIndex(UInt(index))
            }
        }
        selectedImageIndexInImageset = catalog!.marsphotos[index].indexInImageset
        
        let imageset = catalog!.imagesets[Int(currentIndex)]
        let photo = catalog!.marsphotos[Int(currentIndex)]
        var imageName = ""
        if photo.leftAndRight != nil {
            imageName = "Anaglyph"
        }
        else {
            imageName = catalog!.imageName(imageset:imageset, imageIndexInSet:selectedImageIndexInImageset)
        }
        imageSelectionButton.title = imageName
        setImageSelectionButtonWidth()
        getToolbar()?.setNeedsLayout()
    }
    
    func sourceRectForPopupController(_ bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0)
    }
    
    func getToolbar() -> UIToolbar? {
        for subview in self.view.subviews {
            if let v = subview as? UIToolbar {
                return v
            }
        }
        return nil
    }
    
    func imageSelectionPressed() {
        becomeFirstResponder()
        let imageset = catalog!.imagesets[Int(currentIndex)]
        let imageCount = catalog!.getImagesetCount(imageset: imageset)
        
        var menuItems:[PSMenuItem] = []
        for r in 0..<imageCount {
            let imageName = catalog!.imageName(imageset: imageset, imageIndexInSet: r)
            let menuItem = PSMenuItem(title: imageName, block: {
                self.catalog!.changeToImage(imagesetIndex: Int(self.currentIndex), imageIndexInSet: r)
                self.reloadData()
                self.imageSelectionButton.title = imageName
                self.setImageSelectionButtonWidth()
            })!
            menuItems.append(menuItem)
        }
        
        let leftAndRight = catalog!.stereoForImages(imagesetIndex: Int(currentIndex))
        if let leftAndRight = leftAndRight {
            let menuItem = PSMenuItem(title: "Anaglyph", block: {
                self.catalog!.changeToAnaglyph(leftAndRight: leftAndRight, imageIndex: Int(self.currentIndex))
                self.reloadData()
                self.imageSelectionButton.title = "Anaglyph"
                self.setImageSelectionButtonWidth()
            })!
            menuItems.append(menuItem)
        }
                
        if menuItems.count > 1 {
            UIMenuController.shared.menuItems = menuItems
            UIMenuController.shared.setTargetRect(getToolbar()!.bounds, in: getToolbar()!)
            UIMenuController.shared.setMenuVisible(true, animated: true)
        }
    }
    
    func showAboutView() {
        showPopoverVC("aboutVC")
    }
    
    func showTimeView() {
        showPopoverVC("timeVC")
    }
    
    func showPopoverVC(_ vcName:String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: vcName)
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
    
    func showMosaicView() {
        performSegue(withIdentifier: "mosaic", sender: self)
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

extension MarsImageViewController: UIPopoverPresentationControllerDelegate {
    
}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstraintedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        
        return ceil(boundingBox.width)
    }
}
