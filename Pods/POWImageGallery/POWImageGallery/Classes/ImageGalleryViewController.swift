//
//  ImageGalleryViewController.swift
//  FBSnapshotTestCase
//
//  Created by Powell, Mark W (397F) on 11/1/17.
//

import UIKit

open class ImageGalleryViewController : UIViewController {
    public static let darkGrayTranslucent = UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 0.8)
    @objc public var pageViewController: UIPageViewController!
    public var delegate: ImageGalleryViewControllerDelegate!
    public var toolbar = UIToolbar()
    public var captionView = UITextView()
    public private(set) var pageIndex = 0
    public var toolbarBottomConstraint = NSLayoutConstraint()
    public var captionViewHeightConstraint = NSLayoutConstraint()
    public var hidingTimer:Timer?
    public var delayToHideElements = 3.0
    public var singleTapDetection = UITapGestureRecognizer()
    public var doubleTapDetection = UITapGestureRecognizer()
    public var animationDuration = CFTimeInterval(0.35)

    public convenience init(delegate: ImageGalleryViewControllerDelegate) {
        self.init(nibName:nil, bundle:nil)
        self.delegate = delegate
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                  navigationOrientation: .horizontal,
                                                  options: nil)
        // Setup pages
        setupPageViewController()
        reloadData() //load for the first time, really
    }
    
    open func setPageIndex(_ pageIndex:Int) {
        self.pageIndex = pageIndex
        reloadData()
    }
    
    open func numberOfImages() -> Int {
        return delegate?.images.count ?? 0
    }
    
    open func reloadData() {
        if delegate.images.count > 0 && pageIndex < delegate.images.count {
            pageViewController.setViewControllers([makeImageViewController(imageIndex:pageIndex, image:delegate.images[pageIndex])],
                                                  direction: .forward,
                                                  animated: true,
                                                  completion: nil)
            updateCaptionsText()
        }
    }
    
    open func setupPageViewController() {
        addChildViewController(pageViewController)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.barStyle = .blackTranslucent
        captionView.translatesAutoresizingMaskIntoConstraints = false
        captionView.backgroundColor = ImageGalleryViewController.darkGrayTranslucent
        captionView.textColor = UIColor.white
        captionView.textAlignment = .center
        
        captionView.font = UIFont.systemFont(ofSize: 17)
        captionView.isSelectable = false
        captionView.isEditable = false
        view.addSubview(pageViewController.view)
        view.addSubview(toolbar)
        view.addSubview(captionView)
        toolbarBottomConstraint = toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        captionViewHeightConstraint = captionView.heightAnchor.constraint(equalToConstant: 120)
        let constraints = [
            pageViewController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            pageViewController.view.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0),
            pageViewController.view.heightAnchor.constraint(equalTo: view.heightAnchor, constant: 0),
            pageViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor, constant: 0),
            toolbarBottomConstraint,
            toolbar.leftAnchor.constraint(equalTo: view.leftAnchor, constant:0),
            toolbar.rightAnchor.constraint(equalTo: view.rightAnchor, constant:0),
            captionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant:0),
            captionView.rightAnchor.constraint(equalTo: view.rightAnchor, constant:0),
            captionView.bottomAnchor.constraint(equalTo: toolbar.topAnchor, constant:0),
            captionViewHeightConstraint
        ]
        NSLayoutConstraint.activate(constraints)
        
        singleTapDetection = UITapGestureRecognizer(target: self, action: #selector(ImageGalleryViewController.wasSingleTapped(recognizer:)))
        doubleTapDetection = UITapGestureRecognizer(target: self, action: #selector(ImageGalleryViewController.wasDoubleTapped(recognizer:)))
        doubleTapDetection.numberOfTapsRequired = 2
        singleTapDetection.require(toFail: doubleTapDetection)
        self.view.addGestureRecognizer(singleTapDetection)
        self.view.addGestureRecognizer(doubleTapDetection)
    }
    
    @objc public func wasSingleTapped(recognizer: UITapGestureRecognizer) {
        setControlsVisible(areControlsHidden())
    }
    
    @objc public func wasDoubleTapped(recognizer: UITapGestureRecognizer) {
        if let imageVC = pageViewController.viewControllers?[0] as? ImageViewController {
            UIView.animate(withDuration: animationDuration, animations: {
                let currentScale = imageVC.scrollView.zoomScale
                let deltaMin = currentScale - imageVC.scrollView.minimumZoomScale
                let deltaMax = imageVC.scrollView.maximumZoomScale - currentScale
                imageVC.scrollView.zoomScale = (deltaMax > deltaMin) ? imageVC.scrollView.maximumZoomScale : imageVC.scrollView.minimumZoomScale
            })
        }
    }
    
    open func makeImageViewController(imageIndex:Int, image: ImageCreator) -> ImageViewController {
        let vc = ImageViewController()
        vc.delegate = self
        vc.imageIndex = imageIndex
        vc.image = image
        image.delegate = vc
        image.requestImage()
        return vc
    }
}

extension ImageGalleryViewController : UIPageViewControllerDataSource {
    open func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let imageVC = viewController as? ImageViewController {
            if let index = imageVC.imageIndex {
                if index > 0 {
                    let image = delegate.images[index-1]
                    print("Image view \(index-1) is being made")
                    return makeImageViewController(imageIndex:index-1, image: image)
                }
            }
        }
        return nil
    }
    
    open func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let imageVC = viewController as? ImageViewController {
            if let index = imageVC.imageIndex {
                if index < delegate.images.count-1 {
                    let image = delegate.images[index+1]
                    print("Image view \(index+1) is being made")
                    return makeImageViewController(imageIndex:index+1, image: image)
                }
            }
        }
        return nil
    }
    
    open func hideControlsAfterDelay() {
        guard !areControlsHidden() else {
            return
        }
        cancelHidingTimer()
        hidingTimer = Timer.scheduledTimer(
            timeInterval: delayToHideElements,
            target: self,
            selector: #selector(ImageGalleryViewController.hideControls),
            userInfo: nil,
            repeats: false)
    }
    
    open func cancelHidingTimer() {
        hidingTimer?.invalidate()
        hidingTimer = nil
    }
    
    open func areControlsHidden() -> Bool {
        return toolbar.alpha == 0.0
    }
    
    @objc open func hideControls() {
        setControlsVisible(false)
    }
    
    open func setControlsVisible(_ visible:Bool) {
        
        // Cancel any timers
        cancelHidingTimer()
        
        // Navigation bar
        self.navigationController?.setNavigationBarHidden(!visible, animated: true)
        
        UIView.animate(withDuration: animationDuration, animations: {
            self.toolbarBottomConstraint.constant = visible ? 0 : self.toolbar.frame.height
            self.view.layoutIfNeeded()
            self.toolbar.alpha = visible ? 1.0 : 0.0
            self.captionView.alpha = visible ? 1.0 : 0.0
        })
    }
    
    open func updateCaptionsText() {
        if delegate.captions.count > self.pageIndex {
            captionView.text = delegate.captions[pageIndex] ?? ""
            captionView.layoutIfNeeded()
            captionView.sizeToFit()
            captionViewHeightConstraint.constant = captionView.bounds.size.height
            captionView.layoutIfNeeded()
       }
    }
}

extension ImageGalleryViewController : UIPageViewControllerDelegate {
    
    open func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        captionView.text = ""
        setControlsVisible(true)
    }
    
    open func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let imageVC = pageViewController.viewControllers?[0] as? ImageViewController {
            if let index = imageVC.imageIndex {
                self.pageIndex = index
            }
            updateCaptionsText()
        }
        hideControlsAfterDelay()
    }
}

extension ImageGalleryViewController : ImageViewControllerDelegate {
    open func imageLoaded() {
        //do nothing by default
    }
}
