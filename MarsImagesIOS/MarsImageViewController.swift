//
//  MarsImageViewController.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/29/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit
import EFInternetIndicator
import POWImageGallery
import Reachability
import SDWebImage

class MarsImageViewController :  ImageGalleryViewController, InternetStatusIndicable {
    var internetConnectionIndicator: InternetViewIndicator?
    var reachability = try! Reachability(hostname:"evernote.com")!
    
    var catalogs = (UIApplication.shared.delegate as! AppDelegate).catalogs
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
        catalogs[Mission.currentMissionName()]!.reload()
        catalogs[Mission.currentMissionName()]!.reloadLocations()
        super.viewDidLoad()
        
        imageSelectionButton = UIBarButtonItem(title:"", style:.plain, target:self, action:#selector(imageSelectionPressed))
        addToolbarButtons()
        
        UINavigationBar.appearance().tintColor = UIColor.white
        toolbar.tintColor = UIColor.white

        startMonitoringInternet()
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
        reachability.whenReachable = { reachability in
            if self.catalogs[Mission.currentMissionName()]!.hasMoreImages() {
                self.catalogs[Mission.currentMissionName()]!.loadNextPage()
            }
            for vc in self.pageViewController.viewControllers! {
                if let imageVC = vc as? ImageViewController {
                    imageVC.image?.requestImage()
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //this awkwardness avoids the PageViewController showing nothing (white, empty) after transitioning back from popping the mosaic VC off the nav VC
        //TODO: figure out a better way to achieve this
        if let count = pageViewController.viewControllers?.count {
            if count > 0 {
                pageViewController.setViewControllers(pageViewController.viewControllers, direction: .forward, animated: false, completion: nil)
            }
        }
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
            imageSelectionButton.width = title.width(withConstrainedHeight: toolbar.frame.size.height, font: UIFont.systemFont(ofSize: 20))
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if let presentationController = popover {
            presentationController.presentedViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func missionChanged(_ notification: Notification) {
        self.hasMissionChanged = true
    }
    
    @objc func imagesetsLoaded(notification: Notification) {

        DispatchQueue.main.async {
            if self.pageViewController.viewControllers?.count == 0 {
                self.reloadData()
            }
            if self.hasMissionChanged {
                self.imageSelectionButton.title = ""
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
        selectedImageIndexInImageset = catalogs[Mission.currentMissionName()]!.marsphotos[index].indexInImageset
        
        let imageset = catalogs[Mission.currentMissionName()]!.imagesets[Int(pageIndex)]
        let photo = catalogs[Mission.currentMissionName()]!.marsphotos[Int(pageIndex)]
        if photo.leftAndRight != nil {
            setImageSelectionButtonTitle("Anaglyph")
        }
        else {
            setImageSelectionButtonTitle(catalogs[Mission.currentMissionName()]!.imageName(imageset:imageset, imageIndexInSet:selectedImageIndexInImageset))
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
        let imageset = catalogs[Mission.currentMissionName()]!.imagesets[Int(pageIndex)]
        let imageCount = catalogs[Mission.currentMissionName()]!.getImagesetCount(imageset: imageset)
        guard imageCount > 1 else {
            return
        }
        
        var menuItems:[String] = []
        for r in 0..<imageCount {
            let imageName = catalogs[Mission.currentMissionName()]!.imageName(imageset: imageset, imageIndexInSet: r)
            menuItems.append(imageName)
        }
        
        let leftAndRight = catalogs[Mission.currentMissionName()]!.stereoForImages(imagesetIndex: Int(pageIndex))
        if leftAndRight != nil {
            let menuItem = "Anaglyph"
            menuItems.append(menuItem)
        }

        let imageMenuVC = showPopoverVC("imageMenuVC", compact:true)! as! ImageSelectionMenuViewController
        imageMenuVC.imageNames = menuItems
        imageMenuVC.imageVC = self
    }
    
    func setImageAt(_ index: Int, _ imageName: String) {
        self.catalogs[Mission.currentMissionName()]!.changeToImage(imagesetIndex: Int(self.pageIndex), imageIndexInSet: index)
        self.reloadData()
        self.imageSelectionButton.title = imageName
        self.setImageSelectionButtonWidth()
    }
    
    func showAnaglyph() {
        let leftAndRight = catalogs[Mission.currentMissionName()]!.stereoForImages(imagesetIndex: Int(pageIndex))
        if let leftAndRight = leftAndRight {
            self.catalogs[Mission.currentMissionName()]!.changeToAnaglyph(leftAndRight: leftAndRight, imageIndex: Int(self.pageIndex))
            self.reloadData()
            self.imageSelectionButton.title = "Anaglyph"
            self.setImageSelectionButtonWidth()
        }
    }
    
    @objc func showAboutView() {
        _ = showPopoverVC("aboutVC", compact:false)
    }
    
    @objc func showTimeView() {
        _ = showPopoverVC("timeVC", compact:false)
    }
    
    func showPopoverVC(_ vcName:String, compact: Bool) -> UIViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: vcName)
        vc.modalPresentationStyle = .popover
        popover = vc.popoverPresentationController
        if let presentationController = popover {
            presentationController.delegate = self
            presentationController.permittedArrowDirections =  UIPopoverArrowDirection(rawValue: 0)
            presentationController.sourceView = self.view
            if !compact {
                presentationController.sourceRect = sourceRectForPopupController(self.view.bounds)
                presentationController.presentedViewController.preferredContentSize =
                    CGSize(width: self.view.bounds.size.width*0.8,
                           height: self.view.bounds.size.height*0.8)
            } else {
                var rect = self.view.bounds
                rect.origin.y = rect.size.height/2
                rect.origin.x = rect.origin.x - rect.size.width/2
                presentationController.sourceRect = sourceRectForPopupController(rect)
                presentationController.presentedViewController.preferredContentSize =
                    CGSize(width: rect.size.width*0.4,
                           height: rect.size.height*0.2)
            }
            self.present(vc, animated: true, completion: nil)
            return vc
        }
        return nil
    }
    
    @objc func showMosaicView() {
        setControlsVisible(true)
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
        if pageIndex == catalogs[Mission.currentMissionName()]!.imagesetCount-1 && catalogs[Mission.currentMissionName()]!.hasMoreImages() {
            catalogs[Mission.currentMissionName()]!.loadNextPage()
        }
        let dict:[String:Any] = [ Constants.imageIndexKey: pageIndex, Constants.senderKey: self ]
        NotificationCenter.default.post(name: .imageSelected, object: nil, userInfo: dict)
    }
    
    override func imageLoaded() {
        super.imageLoaded()
        //TODO: This was causing the tableview to scroll to back to the current image even if it was the table that was scrolled to the end that initiated the load, which I don't want. Keep an eye on this. Is this needed for anything else?
//        let dict:[String:Any] = [ Constants.imageIndexKey: pageIndex, Constants.senderKey: self ]
//        NotificationCenter.default.post(name: .imageSelected, object: nil, userInfo: dict)
        if imageSelectionButton.title == "" && pageIndex == 0  && catalogs[Mission.currentMissionName()]!.imagesetCount > 0 {
            let imageset = catalogs[Mission.currentMissionName()]!.imagesets[0]
            setImageSelectionButtonTitle(catalogs[Mission.currentMissionName()]!.imageName(imageset:imageset, imageIndexInSet:0))
        }
    }
}


extension MarsImageViewController: ImageGalleryViewControllerDelegate {
    var captions: [String?] {
        get {
            return catalogs[Mission.currentMissionName()]!.captions
        }
    }
    
    var images: [ImageCreator] {
        get {
            return catalogs[Mission.currentMissionName()]!.marsphotos
        }
    }
}

extension Notification.Name {
    static let openDrawer = Notification.Name("OpenDrawer")
    static let closeDrawer = Notification.Name("CloseDrawer")
}

extension MarsImageViewController: UIPopoverPresentationControllerDelegate {
    
}

extension String {
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        return ceil(boundingBox.width)
    }
}
