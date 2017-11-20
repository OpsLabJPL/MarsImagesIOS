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
        updateMinZoomScaleForSize(view.bounds.size)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateMinZoomScaleForSize(view.bounds.size)
    }
    
    fileprivate func updateMinZoomScaleForSize(_ size: CGSize) {
        if let image = imageView.image {
            let widthScale = size.width / image.size.width
            let heightScale = size.height / image.size.height
            let minScale = min(widthScale, heightScale)
            
            scrollView.minimumZoomScale = minScale
            scrollView.zoomScale = minScale
            updateConstraintsForSize(size)
        }
    }
    
    fileprivate func updateConstraintsForSize(_ size: CGSize) {
        if let image = imageView.image {
            let yOffset = max(0, (size.height - image.size.height*scrollView.minimumZoomScale) / 2)
            imageViewTopConstraint.constant = yOffset
            imageViewBottomConstraint.constant = yOffset
            
            let xOffset = max(0, (size.width - image.size.width*scrollView.minimumZoomScale) / 2)
            imageViewLeftConstraint.constant = xOffset
            imageViewRightConstraint.constant = xOffset
        }
        
        view.layoutIfNeeded()
    }
}

extension ImageViewController : UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForSize(view.bounds.size)
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
