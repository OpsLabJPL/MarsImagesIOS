//
//  MarsImageViewController.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/29/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit
import POWImageGallery
import PSMenuItem
import SDWebImage

class MarsImageViewController :  ImageGalleryViewController {
    
    var catalog:MarsImageCatalog?
    let leftIcon = UIImage.init(named: "leftArrow.png")
    let rightIcon = UIImage.init(named: "rightArrow.png")
    
    var drawerClosed = true
    var drawerButton = UIBarButtonItem()
    var imageSelectionButton = UIBarButtonItem()
    var infoButton = UIButton(type: UIButtonType.infoLight)
    var aboutTheAppButton = UIBarButtonItem(image: nil, style: .plain, target: self, action: #selector(MarsImageViewController.showAboutView))
    var mosaicViewButton = UIBarButtonItem(image: UIImage(named: "panorama_icon.png"), style: .plain, target: self, action: #selector(MarsImageViewController.showMosaicView))
    var timeViewButton = UIBarButtonItem(image: UIImage(named: "clock.png"), style: .plain, target: self, action: #selector(MarsImageViewController.showTimeView))
    var shareImageButton = UIBarButtonItem(barButtonSystemItem: .action, target:self, action:#selector(MarsImageViewController.shareImage))
    var selectedImageIndexInImageset = 0
    var hasMissionChanged = false
    
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
    
    override func viewDidLoad() {
        SDImageCache.shared().maxMemoryCost = 128000

        PSMenuItem.installMenuHandler(for: self)
        NotificationCenter.default.addObserver(self, selector: #selector(imagesetsLoaded), name: .endImagesetLoading, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(imageSelected), name: .imageSelected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openDrawer), name: .openDrawer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(closeDrawer), name: .closeDrawer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(missionChanged), name: .missionChanged, object: nil)

        self.title = nil
        
        self.navigationItem.titleView = UILabel() //hide 1 of n title
        
        aboutTheAppButton.image = infoButton.currentImage
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(closeDrawerSwipe))
        swipeLeft.direction = .left
        self.navigationController?.navigationBar.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(openDrawerSwipe))
        swipeRight.direction = .right
        self.navigationController?.navigationBar.addGestureRecognizer(swipeRight)
        catalog?.reload()
        catalog?.reloadLocations()
        super.viewDidLoad()
        
        imageSelectionButton = UIBarButtonItem(title:"", style:.plain, target:self, action:#selector(imageSelectionPressed))
        addToolbarButtons()
        
        UINavigationBar.appearance().tintColor = UIColor.white
        toolbar.tintColor = UIColor.white
    }
    
    func makeButtons() {
        drawerButton = UIBarButtonItem(image: rightIcon, style: .plain, target: self, action: #selector(toggleDrawer(_:)))
        navigationItem.rightBarButtonItem = drawerButton
        navigationItem.rightBarButtonItem?.tintColor = UIColor.white
    }
    
    @IBAction func toggleDrawer(_ sender: Any) {
        if drawerClosed {
            NotificationCenter.default.post(name: .openDrawer, object: nil)
        } else {
            NotificationCenter.default.post(name: .closeDrawer, object: nil)
        }
    }

    @objc func closeDrawerSwipe() {
        guard drawerClosed == false else {
            return
        }
        NotificationCenter.default.post(name: .closeDrawer, object: nil)
    }
    
    @objc func openDrawerSwipe() {
        guard drawerClosed else {
            return
        }
        NotificationCenter.default.post(name: .openDrawer, object: nil)
    }
    
    @objc func openDrawer() {
        drawerClosed = false
        drawerButton.image = leftIcon
        if UIDevice.current.userInterfaceIdiom == .phone {
            addToolbarButtons()
        }
    }
    
    @objc func closeDrawer() {
        drawerClosed = true
        drawerButton.image = rightIcon
        if UIDevice.current.userInterfaceIdiom == .phone {
            addToolbarButtons()
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func addToolbarButtons() {
        //add image selection button to bottom toolbar
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        setImageSelectionButtonWidth()
        if (drawerClosed) {
            toolbar.setItems([ imageSelectionButton, flex, aboutTheAppButton, flex, mosaicViewButton, flex, timeViewButton, flex, shareImageButton], animated: true)
        } else {
            toolbar.setItems([ imageSelectionButton, flex, shareImageButton], animated: true)
        }
    }
    
    func setImageSelectionButtonWidth() {
        if let title = imageSelectionButton.title {
            imageSelectionButton.width = title.width(withConstraintedHeight: toolbar.frame.size.height, font: UIFont.systemFont(ofSize: 20))
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if let presentationController = popover {
            presentationController.presentedViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func missionChanged(_ notification: Notification) {
        self.hasMissionChanged = true
    }
    
    @objc func imagesetsLoaded(notification: Notification) {
        DispatchQueue.main.async {
            self.reloadData()
            if self.hasMissionChanged {
                self.setPageIndex(0)
                self.hasMissionChanged = false
            }
        }
    }
    
    @objc func imageSelected(notification:Notification) {
        var index = 0
        if let num = notification.userInfo?[Constants.imageIndexKey] as? Int {
            index = Int(num)
        }
        
        if let sender = notification.userInfo?[Constants.senderKey] as? NSObject {
            if sender != self && index != pageIndex {
                setPageIndex(index)
            }
        }
        selectedImageIndexInImageset = catalog!.marsphotos[index].indexInImageset
        
        let imageset = catalog!.imagesets[Int(pageIndex)]
        let photo = catalog!.marsphotos[Int(pageIndex)]
        if photo.leftAndRight != nil {
            setImageSelectionButtonTitle("Anaglyph")
        }
        else {
            setImageSelectionButtonTitle(catalog!.imageName(imageset:imageset, imageIndexInSet:selectedImageIndexInImageset))
        }
        toolbar.setNeedsLayout()
    }
    
    func setImageSelectionButtonTitle(_ title: String) {
        imageSelectionButton.title = title
        setImageSelectionButtonWidth()
    }
    
    func sourceRectForPopupController(_ bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0)
    }
    
    @objc func imageSelectionPressed() {
        becomeFirstResponder()
        let imageset = catalog!.imagesets[Int(pageIndex)]
        let imageCount = catalog!.getImagesetCount(imageset: imageset)
        
        var menuItems:[PSMenuItem] = []
        for r in 0..<imageCount {
            let imageName = catalog!.imageName(imageset: imageset, imageIndexInSet: r)
            let menuItem = PSMenuItem(title: imageName, block: {
                self.catalog!.changeToImage(imagesetIndex: Int(self.pageIndex), imageIndexInSet: r)
                self.reloadData()
                self.imageSelectionButton.title = imageName
                self.setImageSelectionButtonWidth()
            })!
            menuItems.append(menuItem)
        }
        
        let leftAndRight = catalog!.stereoForImages(imagesetIndex: Int(pageIndex))
        if let leftAndRight = leftAndRight {
            let menuItem = PSMenuItem(title: "Anaglyph", block: {
                self.catalog!.changeToAnaglyph(leftAndRight: leftAndRight, imageIndex: Int(self.pageIndex))
                self.reloadData()
                self.imageSelectionButton.title = "Anaglyph"
                self.setImageSelectionButtonWidth()
            })!
            menuItems.append(menuItem)
        }
                
        if menuItems.count > 1 {
            UIMenuController.shared.menuItems = menuItems
            UIMenuController.shared.setTargetRect(toolbar.bounds, in: toolbar)
            UIMenuController.shared.setMenuVisible(true, animated: true)
        }
    }
    
    @objc func showAboutView() {
        showPopoverVC("aboutVC")
    }
    
    @objc func showTimeView() {
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
    
    @objc func showMosaicView() {
        performSegue(withIdentifier: "mosaic", sender: self)
    }
    
    @objc func shareImage() {
        if let image = (pageViewController.viewControllers?[0] as? ImageViewController)?.imageView.image {
            
            let imageToShare = [ image ]
            let activityVC = UIActivityViewController(activityItems: imageToShare, applicationActivities: [])
            activityVC.excludedActivityTypes = []
            activityVC.popoverPresentationController?.sourceView = self.view
            
            pageViewController.present(activityVC, animated: true, completion: {})
        }
    }
    
    override public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers:[UIViewController], transitionCompleted completed: Bool) {
        super.pageViewController(pageViewController, didFinishAnimating: finished, previousViewControllers: previousViewControllers, transitionCompleted: completed)
        if pageIndex == catalog!.imagesetCount-1 && catalog!.hasMoreImages() {
            catalog!.loadNextPage()
        }
        let dict:[String:Any] = [ Constants.imageIndexKey: pageIndex, Constants.senderKey: self ]
        NotificationCenter.default.post(name: .imageSelected, object: nil, userInfo: dict)
    }
    
    override func imageLoaded() {
        let dict:[String:Any] = [ Constants.imageIndexKey: pageIndex, Constants.senderKey: self ]
        NotificationCenter.default.post(name: .imageSelected, object: nil, userInfo: dict)
    }
}


extension MarsImageViewController: ImageGalleryViewControllerDelegate {
    var captions: [String?] {
        get {
            return catalog!.captions
        }
    }
    
    var images: [ImageCreator] {
        get {
            return catalog!.marsphotos
        }
    }
    
    
}

extension Notification.Name {
    static let openDrawer = Notification.Name("OpenDrawer")
    static let closeDrawer = Notification.Name("CloseDrawer")
}

extension MarsImageViewController: UIPopoverPresentationControllerDelegate {
    
}

//TODO still need?
extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        return ceil(boundingBox.height)
    }
    
    func width(withConstraintedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        return ceil(boundingBox.width)
    }
}
