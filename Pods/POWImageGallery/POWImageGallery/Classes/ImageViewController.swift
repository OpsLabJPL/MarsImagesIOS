//
//  ImageViewController.swift
//  POWImageGallery
//
//  Created by Powell, Mark W (397F) on 11/2/17.
//

import UIKit
import MBProgressHUD
import SDWebImage

@objc public protocol ImageViewControllerDelegate {
    @objc optional func imageLoaded()
}

open class ImageViewController : UIViewController {
    
    @objc public var imageView: UIImageView!
    @objc public var scrollView: UIScrollView!
    public var loadInProgress = false
    var lastZoomScale: CGFloat = -1
    public var image: ImageCreator? {
        didSet {
            loadInProgress = true
            DispatchQueue.main.async {
                self.progressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
                self.progressHUD.mode = .annularDeterminate
                self.progressHUD.label.text = "Loading"
            }
            self.image?.requestImage()
         }
    }
    
    public var imageIndex:Int?
    
    var imageViewLeftConstraint = NSLayoutConstraint()
    var imageViewRightConstraint = NSLayoutConstraint()
    var imageViewTopConstraint = NSLayoutConstraint()
    var imageViewBottomConstraint = NSLayoutConstraint()

    public var delegate: ImageViewControllerDelegate?
    @objc public var progressHUD: MBProgressHUD!

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public convenience init() {
        self.init(nibName:nil, bundle:nil)
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.insertSubview(imageView, at: 0)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = false
        view.insertSubview(scrollView, at: 0)
        self.scrollView.maximumZoomScale = 4
        
        imageViewTopConstraint = imageView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 0)
        imageViewBottomConstraint = imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 0)
        imageViewLeftConstraint = imageView.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 0)
        imageViewRightConstraint = imageView.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: 0)
        let constraints = [
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            imageViewTopConstraint, imageViewLeftConstraint, imageViewRightConstraint, imageViewBottomConstraint
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateZoom()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateZoom()
    }
    
    // Update zoom scale and constraints with animation.
    @available(iOS 8.0, *)
    open override func viewWillTransition(to size: CGSize,
                                          with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.updateZoom()
            }, completion: nil)
    }
    
    fileprivate func updateZoom() {
        if let image = imageView.image {
            var minZoom = min(scrollView.bounds.size.width / image.size.width,
                              scrollView.bounds.size.height / image.size.height)
            
            if minZoom > 1 { minZoom = 1 }
            
            scrollView.minimumZoomScale = 0.3 * minZoom
            
            // Force scrollViewDidZoom fire if zoom did not change
            if minZoom == lastZoomScale { minZoom += 0.000001 }
            
            scrollView.zoomScale = minZoom
            lastZoomScale = minZoom
        }
    }
    
    fileprivate func updateConstraints() {
        if let image = imageView.image {
            let imageWidth = image.size.width
            let imageHeight = image.size.height
            
            let viewWidth = scrollView.bounds.size.width
            let viewHeight = scrollView.bounds.size.height
            
            // center image if it is smaller than the scroll view
            var hPadding = (viewWidth - scrollView.zoomScale * imageWidth) / 2
            if hPadding < 0 { hPadding = 0 }
            
            var vPadding = (viewHeight - scrollView.zoomScale * imageHeight) / 2
            if vPadding < 0 { vPadding = 0 }
            
            imageViewLeftConstraint.constant = hPadding
            imageViewRightConstraint.constant = hPadding
            
            imageViewTopConstraint.constant = vPadding
            imageViewBottomConstraint.constant = vPadding
        }
        
        view.layoutIfNeeded()
    }
}

extension ImageViewController : UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraints()
    }
}

extension ImageViewController: ImageDelegate {
    public func progress(receivedSize: Int, expectedSize:Int){
        DispatchQueue.main.async {
            self.progressHUD.progress = Float(receivedSize)/Float(expectedSize)
        }
    }
    
    public func finished(image: UIImage) {
        loadViewIfNeeded()
        imageView?.image = image
        loadInProgress = false
        DispatchQueue.main.async {
            self.progressHUD.hide(animated:true)
        }
        delegate?.imageLoaded?()
    }
    
    public func failure() {
        //TODO
        loadInProgress = false
        DispatchQueue.main.async {
            self.progressHUD.hide(animated:true)
        }
    }
}
